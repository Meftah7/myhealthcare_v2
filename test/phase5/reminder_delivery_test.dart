// Phase 5 gate: booking, rescheduling and cancelling produce the right
// reminder outcome even when the app was closed when a reminder fell due —
// and no reminder is ever claimed as delivered that was not.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/sync/outbox.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/services/notifications/device_notifier.dart';
import 'package:myhealthcare/services/notifications/reminder_dispatcher.dart';
import 'package:myhealthcare/services/notifications/reminder_scheduler.dart';

import '../support/test_database.dart';

/// A device whose permission and failures a test controls.
class _FakeDevice implements DeviceNotifier {
  _FakeDevice(this.permissionState, {this.failures = 0});

  AlertPermission permissionState;
  int failures;
  final shown = <String>[];

  @override
  Future<AlertPermission> permission() async => permissionState;

  @override
  Future<AlertPermission> requestPermission() async => permissionState;

  @override
  Future<void> show({required String title, required String body}) async {
    if (failures > 0) {
      failures--;
      throw StateError('browser busy');
    }
    shown.add(body);
  }
}

void main() {
  late AppDatabase db;
  late AppointmentRepositoryImpl appointments;

  setUp(() async {
    db = newTestDatabase();
    appointments = AppointmentRepositoryImpl(db);
    for (final (id, role) in const [
      ('doc', UserRole.staff),
      ('pat', UserRole.patient),
    ]) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              role: role,
              fullName: id,
              email: '$id@example.test',
              passwordHash: 'h',
              passwordSalt: 's',
            ),
          );
    }
    // Working 08:00–18:00 every day.
    for (var weekday = 1; weekday <= 7; weekday++) {
      await db
          .into(db.scheduleTemplates)
          .insert(
            ScheduleTemplatesCompanion.insert(
              id: 'tpl-$weekday',
              staffId: 'doc',
              weekday: weekday,
              startMinutes: 8 * 60,
              endMinutes: 18 * 60,
            ),
          );
    }
  });

  tearDown(() => db.close());

  DateTime slotInDays(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return DateTime(d.year, d.month, d.day, 10);
  }

  Future<Appointment> book(DateTime start) async {
    final r = await appointments.book(
      BookingRequest(
        patientId: 'pat',
        staffId: 'doc',
        start: start,
        end: start.add(const Duration(minutes: 20)),
        visitType: VisitType.followUp,
        riskBand: RiskBand.low, // one step, 24 h before
      ),
    );
    return r.valueOrNull!;
  }

  Future<List<ReminderRow>> remindersFor(String appointmentId) => (db.select(
    db.reminders,
  )..where((r) => r.appointmentId.equals(appointmentId))).get();

  Future<List<Map<String, Object?>>> reminderNotices() async {
    final events = await (db.select(
      db.outboxEvents,
    )..where((e) => e.type.equals(OutboxTypes.deliverNotification))).get();
    return [
      for (final e in events)
        if ((jsonDecode(e.payload) as Map<String, Object?>)['title'] ==
            'Appointment reminder')
          jsonDecode(e.payload) as Map<String, Object?>,
    ];
  }

  /// A fresh dispatcher at [now] — the app reopening at that moment.
  ReminderDispatcher reopenAt(DateTime now, {DeviceNotifier? device}) =>
      ReminderDispatcher(
        db,
        now: () => now,
        device: device ?? _FakeDevice(AlertPermission.granted),
      );

  test('only deliverable channels are queued; in-app is always one', () {
    expect(reminderChannelsFor(null), {
      ReminderChannel.inApp,
      ReminderChannel.push,
    });
    expect(
      reminderChannelsFor(const {ReminderChannel.inApp, ReminderChannel.sms}),
      {ReminderChannel.inApp},
    );
  });

  test('a reminder due while the app was closed is delivered on reopen, '
      'once', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    final rows = await remindersFor(appt.id);
    expect(rows.map((r) => r.channel).toSet(), {
      ReminderChannel.inApp,
      ReminderChannel.push,
    });

    // The app was closed at the due time (24 h before) and reopens 20 h
    // before the visit.
    final device = _FakeDevice(AlertPermission.granted);
    final run = await reopenAt(
      slot.subtract(const Duration(hours: 20)),
      device: device,
    ).deliverDue();
    expect(run.delivered, 2);
    expect(device.shown, hasLength(1));
    final notices = await reminderNotices();
    expect(notices, hasLength(1));
    expect(notices.single['recipientId'], 'pat');
    expect(notices.single['body'], contains('Sent when you reopened'));

    // Another run (or another tab) never delivers it again.
    final again = await reopenAt(
      slot.subtract(const Duration(hours: 19)),
    ).deliverDue();
    expect(again.delivered, 0);
    expect(await reminderNotices(), hasLength(1));

    // The outbox turns the notice into an inbox notification, once.
    await OutboxDispatcher(
      db,
      now: () => slot.subtract(const Duration(hours: 19)),
    ).drain();
    final inbox = await (db.select(
      db.notifications,
    )..where((n) => n.recipientId.equals('pat'))).get();
    expect(inbox, hasLength(1));
    expect(inbox.single.deepLink, '/patient/appointments/detail/${appt.id}');
  });

  test('reopening after the visit started records the reminder as missed, '
      'not sent', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    final run = await reopenAt(
      slot.add(const Duration(minutes: 5)),
    ).deliverDue();
    expect(run.delivered, 0);
    expect(run.suppressed, 2);
    final rows = await remindersFor(appt.id);
    expect(
      rows.every(
        (r) =>
            r.deliveryStatus == ReminderDeliveryStatus.suppressed &&
            r.lastError == ReminderOutcome.missedWhileClosed &&
            r.sentAt == null,
      ),
      isTrue,
    );
    expect(await reminderNotices(), isEmpty);
  });

  test('a cancelled visit never sends its reminder', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    await appointments.cancel(appt.id, patientId: 'pat');
    final run = await reopenAt(
      slot.subtract(const Duration(hours: 20)),
    ).deliverDue();
    expect(run.delivered, 0);
    expect(await reminderNotices(), isEmpty);
    expect(
      (await remindersFor(
        appt.id,
      )).every((r) => r.deliveryStatus == ReminderDeliveryStatus.suppressed),
      isTrue,
    );
  });

  test('a visit closed by another path while a reminder was still queued is '
      'suppressed at delivery time', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    await (db.update(
      db.appointments,
    )..where((a) => a.id.equals(appt.id))).write(
      const AppointmentsCompanion(status: Value(AppointmentStatus.noShow)),
    );
    final run = await reopenAt(
      slot.subtract(const Duration(hours: 20)),
    ).deliverDue();
    expect(run.suppressed, 2);
    final rows = await remindersFor(appt.id);
    expect(
      rows.every((r) => r.lastError == ReminderOutcome.appointmentClosed),
      isTrue,
    );
  });

  test(
    'a rescheduled visit reminds at the new time, not the old one',
    () async {
      final slot = slotInDays(3);
      final appt = await book(slot);
      final newSlot = slotInDays(5);
      final moved = await appointments.reschedule(
        id: appt.id,
        patientId: 'pat',
        newStart: newSlot,
        newEnd: newSlot.add(const Duration(minutes: 20)),
      );
      expect(moved.isOk, isTrue);

      // The old due time passes: nothing goes out.
      final atOld = await reopenAt(
        slot.subtract(const Duration(hours: 20)),
      ).deliverDue();
      expect(atOld.delivered, 0);

      // The new one fires, naming the new time.
      final atNew = await reopenAt(
        newSlot.subtract(const Duration(hours: 20)),
      ).deliverDue();
      expect(atNew.delivered, 2);
      final notice = (await reminderNotices()).single;
      expect(notice['body'], contains('${newSlot.day}'));
    },
  );

  test('alerts refused by the browser are recorded as failed; the in-app '
      'reminder still arrives', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    final run = await reopenAt(
      slot.subtract(const Duration(hours: 23)),
      device: _FakeDevice(AlertPermission.denied),
    ).deliverDue();
    expect(run.delivered, 1);
    expect(run.failed, 1);
    final rows = {for (final r in await remindersFor(appt.id)) r.channel: r};
    expect(
      rows[ReminderChannel.push]!.lastError,
      ReminderOutcome.permissionDenied,
    );
    expect(rows[ReminderChannel.push]!.sentAt, isNull);
    expect(
      rows[ReminderChannel.inApp]!.deliveryStatus,
      ReminderDeliveryStatus.delivered,
    );
  });

  test(
    'a transient alert failure retries with backoff, then gives up',
    () async {
      final slot = slotInDays(3);
      final appt = await book(slot);
      final due = slot.subtract(const Duration(hours: 23));
      final device = _FakeDevice(AlertPermission.granted, failures: 1);

      await reopenAt(due, device: device).deliverDue();
      var push = (await remindersFor(
        appt.id,
      )).firstWhere((r) => r.channel == ReminderChannel.push);
      expect(push.deliveryStatus, ReminderDeliveryStatus.queued);
      expect(push.deliveryAttempts, 1);
      expect(push.nextAttemptAt, due.add(ReminderDispatcher.backoff(1)));

      // Too soon: not retried yet.
      await reopenAt(due, device: device).deliverDue();
      expect(device.shown, isEmpty);

      // After the backoff it goes through.
      await reopenAt(
        due.add(const Duration(minutes: 2)),
        device: device,
      ).deliverDue();
      push = (await remindersFor(
        appt.id,
      )).firstWhere((r) => r.channel == ReminderChannel.push);
      expect(push.deliveryStatus, ReminderDeliveryStatus.delivered);
      expect(device.shown, hasLength(1));

      // A device that keeps failing is given up on after maxAttempts.
      final other = await book(slotInDays(4));
      final stubborn = _FakeDevice(AlertPermission.granted, failures: 99);
      var at = slotInDays(4).subtract(const Duration(hours: 23));
      for (var i = 0; i < 5; i++) {
        await ReminderDispatcher(
          db,
          now: () => at,
          device: stubborn,
          maxAttempts: 3,
        ).deliverDue();
        at = at.add(const Duration(hours: 1));
      }
      final gaveUp = (await remindersFor(
        other.id,
      )).firstWhere((r) => r.channel == ReminderChannel.push);
      expect(gaveUp.deliveryStatus, ReminderDeliveryStatus.failed);
      expect(gaveUp.deliveryAttempts, 3);
      expect(gaveUp.sentAt, isNull);
    },
  );

  test('an SMS reminder is suppressed as unavailable, never "sent"', () async {
    final slot = slotInDays(3);
    final appt = await book(slot);
    await db
        .into(db.reminders)
        .insert(
          RemindersCompanion.insert(
            id: 'legacy-sms',
            appointmentId: appt.id,
            scheduledFor: slot.subtract(const Duration(hours: 24)),
            channel: ReminderChannel.sms,
          ),
        );
    await reopenAt(slot.subtract(const Duration(hours: 23))).deliverDue();
    final sms = await (db.select(
      db.reminders,
    )..where((r) => r.id.equals('legacy-sms'))).getSingle();
    expect(sms.deliveryStatus, ReminderDeliveryStatus.suppressed);
    expect(sms.lastError, ReminderOutcome.channelUnavailable);
    expect(sms.sentAt, isNull);
  });
}
