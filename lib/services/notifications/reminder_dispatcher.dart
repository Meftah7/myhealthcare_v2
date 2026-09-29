/// Delivers appointment reminders that have fallen due (Phase 5).
///
/// Each queued reminder ends in exactly one recorded outcome, and nothing is
/// claimed as delivered that was not:
///
/// * **in-app** — written to the patient's inbox through the outbox, in the
///   same transaction that marks the reminder delivered, so it can never be
///   delivered twice or lost between the two;
/// * **push** (browser alert) — shown only with the device's permission.
///   Permission refused → `failed` (the in-app copy still reaches them); a
///   transient failure is retried with backoff, then `failed`;
/// * **SMS / email** — no provider in this prototype → `suppressed` with
///   `channel_unavailable`, never "sent".
///
/// **App closed.** Nothing runs while the app is closed. On the next start
/// (and on a timer while open) due reminders are caught up: if the visit is
/// still ahead the reminder is delivered then; if the visit has started or
/// passed it is `suppressed` as `missed_while_closed`; if the visit was
/// cancelled, rescheduled away or closed it is `suppressed` as
/// `appointment_closed`.
library;

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../data/db/app_database.dart';
import '../../data/sync/outbox.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/notification_repository.dart';
import 'device_notifier.dart';

/// Why a reminder ended without reaching the patient on its channel.
abstract final class ReminderOutcome {
  static const appointmentClosed = 'appointment_closed';
  static const missedWhileClosed = 'missed_while_closed';
  static const channelUnavailable = 'channel_unavailable';
  static const permissionDenied = 'permission_denied';
  static const unsupported = 'unsupported';
  static const transientFailure = 'transient_failure';
}

/// What one run did.
class ReminderRun {
  const ReminderRun({
    this.delivered = 0,
    this.suppressed = 0,
    this.failed = 0,
    this.retrying = 0,
  });

  final int delivered;
  final int suppressed;
  final int failed;
  final int retrying;
}

class ReminderDispatcher {
  ReminderDispatcher(
    this._db, {
    DeviceNotifier device = const UnsupportedDeviceNotifier(),
    DateTime Function()? now,
    this.maxAttempts = 5,
  }) : _device = device,
       _now = now ?? DateTime.now,
       _outbox = Outbox(_db, now: now);

  final AppDatabase _db;
  final DeviceNotifier _device;
  final DateTime Function() _now;
  final Outbox _outbox;
  final int maxAttempts;
  Future<ReminderRun>? _running;

  /// Retry delay after the [attempt]th transient failure: 1, 2, 4… minutes,
  /// at most an hour.
  static Duration backoff(int attempt) =>
      Duration(minutes: min(60, pow(2, attempt - 1).toInt()));

  /// Deliver everything due. Safe to call repeatedly and concurrently: one
  /// run at a time, and every state change is conditional on the reminder
  /// still being queued.
  Future<ReminderRun> deliverDue() {
    final running = _running;
    if (running != null) return running;
    final run = _deliverDue().whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  Future<ReminderRun> _deliverDue() async {
    final now = _now();
    final due =
        await (_db.select(_db.reminders).join([
                innerJoin(
                  _db.appointments,
                  _db.appointments.id.equalsExp(_db.reminders.appointmentId),
                ),
              ])
              ..where(
                _db.reminders.deliveryStatus.equalsValue(
                      ReminderDeliveryStatus.queued,
                    ) &
                    _db.reminders.scheduledFor.isSmallerOrEqualValue(now) &
                    (_db.reminders.nextAttemptAt.isNull() |
                        _db.reminders.nextAttemptAt.isSmallerOrEqualValue(now)),
              )
              ..orderBy([OrderingTerm.asc(_db.reminders.scheduledFor)]))
            .get();

    var delivered = 0, suppressed = 0, failed = 0, retrying = 0;
    for (final row in due) {
      final reminder = row.readTable(_db.reminders);
      final appt = row.readTable(_db.appointments);

      if (appt.status != AppointmentStatus.booked &&
          appt.status != AppointmentStatus.confirmed) {
        if (await _end(
          reminder,
          ReminderDeliveryStatus.suppressed,
          now,
          ReminderOutcome.appointmentClosed,
        )) {
          suppressed++;
        }
        continue;
      }
      if (!appt.slotStart.isAfter(now)) {
        if (await _end(
          reminder,
          ReminderDeliveryStatus.suppressed,
          now,
          ReminderOutcome.missedWhileClosed,
        )) {
          suppressed++;
        }
        continue;
      }

      switch (reminder.channel) {
        case ReminderChannel.inApp:
          if (await _deliverInApp(reminder, appt, now)) delivered++;
        case ReminderChannel.push:
          switch (await _deliverAlert(reminder, appt, now)) {
            case ReminderDeliveryStatus.delivered:
              delivered++;
            case ReminderDeliveryStatus.failed:
              failed++;
            case ReminderDeliveryStatus.queued:
              retrying++;
            case ReminderDeliveryStatus.suppressed:
              suppressed++;
          }
        case ReminderChannel.sms || ReminderChannel.email:
          if (await _end(
            reminder,
            ReminderDeliveryStatus.suppressed,
            now,
            ReminderOutcome.channelUnavailable,
          )) {
            suppressed++;
          }
      }
    }
    if (autoRetry) await _armTimer();
    return ReminderRun(
      delivered: delivered,
      suppressed: suppressed,
      failed: failed,
      retrying: retrying,
    );
  }

  /// Inbox delivery: the notice is queued in the outbox in the same
  /// transaction that marks the reminder delivered.
  Future<bool> _deliverInApp(
    ReminderRow reminder,
    AppointmentRow appt,
    DateTime now,
  ) {
    return _db.transaction(() async {
      final changed = await _write(
        reminder,
        RemindersCompanion(
          deliveryStatus: const Value(ReminderDeliveryStatus.delivered),
          sentAt: Value(now),
          deliveryAttempts: Value(reminder.deliveryAttempts + 1),
          lastError: const Value(null),
        ),
      );
      if (!changed) return false;
      await _outbox.enqueueNotification(
        NewNotification(
          recipientId: appt.patientId,
          category: NotificationCategory.appointment,
          title: _title(reminder.kind),
          body: _body(appt, reminder, now),
          deepLink: '/patient/appointments/detail/${appt.id}',
          createdAt: now,
        ),
      );
      return true;
    });
  }

  Future<ReminderDeliveryStatus> _deliverAlert(
    ReminderRow reminder,
    AppointmentRow appt,
    DateTime now,
  ) async {
    final permission = await _device.permission();
    if (permission != AlertPermission.granted) {
      // Refused or unavailable: recorded as such, not retried. The in-app
      // reminder for the same step still reaches the patient.
      await _end(
        reminder,
        ReminderDeliveryStatus.failed,
        now,
        permission == AlertPermission.unsupported
            ? ReminderOutcome.unsupported
            : ReminderOutcome.permissionDenied,
      );
      return ReminderDeliveryStatus.failed;
    }
    final attempts = reminder.deliveryAttempts + 1;
    try {
      await _device.show(
        title: _title(reminder.kind),
        body: _body(appt, reminder, now),
      );
    } on Object {
      final exhausted = attempts >= maxAttempts;
      await _write(
        reminder,
        RemindersCompanion(
          deliveryStatus: Value(
            exhausted
                ? ReminderDeliveryStatus.failed
                : ReminderDeliveryStatus.queued,
          ),
          deliveryAttempts: Value(attempts),
          lastError: const Value(ReminderOutcome.transientFailure),
          nextAttemptAt: Value(exhausted ? null : now.add(backoff(attempts))),
        ),
      );
      return exhausted
          ? ReminderDeliveryStatus.failed
          : ReminderDeliveryStatus.queued;
    }
    await _write(
      reminder,
      RemindersCompanion(
        deliveryStatus: const Value(ReminderDeliveryStatus.delivered),
        sentAt: Value(now),
        deliveryAttempts: Value(attempts),
        lastError: const Value(null),
        nextAttemptAt: const Value(null),
      ),
    );
    return ReminderDeliveryStatus.delivered;
  }

  Future<bool> _end(
    ReminderRow reminder,
    ReminderDeliveryStatus status,
    DateTime now,
    String reason,
  ) => _write(
    reminder,
    RemindersCompanion(
      deliveryStatus: Value(status),
      lastError: Value(reason),
      nextAttemptAt: const Value(null),
    ),
  );

  /// Applies [changes] only if the reminder is still queued — a concurrent
  /// run, a cancellation or a reschedule got there first otherwise.
  Future<bool> _write(ReminderRow reminder, RemindersCompanion changes) async {
    final n =
        await (_db.update(_db.reminders)..where(
              (r) =>
                  r.id.equals(reminder.id) &
                  r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued),
            ))
            .write(changes);
    return n == 1;
  }

  static String _title(ReminderKind kind) => switch (kind) {
    ReminderKind.confirmRequest => 'Please confirm your appointment',
    ReminderKind.escalated || ReminderKind.standard => 'Appointment reminder',
  };

  static String _body(AppointmentRow appt, ReminderRow reminder, DateTime now) {
    final when = DateFormat('EEE d MMM, HH:mm').format(appt.slotStart);
    final place = [
      if (appt.roomNumber != null) 'room ${appt.roomNumber}',
      if (appt.ticketTag != null) 'ticket ${appt.ticketTag}',
    ].join(', ');
    // Say so when it arrives late because the app was closed.
    final late =
        now.difference(reminder.scheduledFor) > const Duration(hours: 1)
        ? ' (Sent when you reopened the app.)'
        : '';
    return 'Your appointment is on $when'
        '${place.isEmpty ? '' : ' — $place'}.$late';
  }

  // --- self-scheduling while the app is open --------------------------------

  /// When true, the dispatcher wakes itself for the next due reminder or
  /// retry while the app is open. Off for dispatchers built in tests.
  bool autoRetry = false;
  Timer? _timer;

  /// Callback after each self-woken run (e.g. drain the outbox).
  Future<void> Function()? onDelivered;

  Future<void> _armTimer() async {
    _timer?.cancel();
    _timer = null;
    final next =
        await (_db.select(_db.reminders)
              ..where(
                (r) =>
                    r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.scheduledFor)])
              ..limit(1))
            .getSingleOrNull();
    if (next == null) return;
    final at =
        next.nextAttemptAt != null &&
            next.nextAttemptAt!.isAfter(next.scheduledFor)
        ? next.nextAttemptAt!
        : next.scheduledFor;
    var wait = at.difference(_now());
    if (wait.isNegative) wait = const Duration(seconds: 1);
    // Re-check at least hourly so a long wait never drifts.
    if (wait > const Duration(hours: 1)) wait = const Duration(hours: 1);
    _timer = Timer(wait, () async {
      try {
        await deliverDue();
        await onDelivered?.call();
      } on Object {
        // Recorded per reminder; the next run retries.
      }
    });
  }

  void dispose() {
    autoRetry = false;
    _timer?.cancel();
    _timer = null;
  }
}
