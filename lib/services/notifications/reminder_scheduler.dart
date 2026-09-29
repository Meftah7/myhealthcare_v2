/// Risk-adaptive reminder scheduling (P4-19).
///
/// The number and timing of reminders scales with the appointment's predicted
/// no-show band:
///   low     → one reminder, 24 h before
///   medium  → two: 48 h and 3 h before
///   high    → three: 5 days before (confirm-or-release), 24 h, 2 h before
///
/// Writes `reminders` rows; OS/in-app delivery is handled separately (P4-18).
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import '../../domain/enums.dart';

class ReminderPlan {
  const ReminderPlan(this.offsetBeforeSlot, this.kind, this.channel);

  final Duration offsetBeforeSlot;
  final ReminderKind kind;
  final ReminderChannel channel;
}

/// Channels this prototype can actually deliver on: in-app (always, the
/// guaranteed fallback) and browser alerts. SMS and email need a delivery
/// provider the release scope excludes, so they are never queued — a reminder
/// is not written down for a channel that would silently drop it (Phase 5).
const deliverableReminderChannels = {
  ReminderChannel.inApp,
  ReminderChannel.push,
};

/// Which channels a reminder goes out on, given the patient's preferences
/// ([enabled] null = no preference, so every deliverable channel). In-app is
/// always included, so switching everything else off still leaves one.
Set<ReminderChannel> reminderChannelsFor(Set<ReminderChannel>? enabled) => {
  ReminderChannel.inApp,
  if (enabled == null || enabled.contains(ReminderChannel.push))
    ReminderChannel.push,
};

List<ReminderPlan> reminderPlanFor(RiskBand band) {
  switch (band) {
    case RiskBand.low:
      return const [
        ReminderPlan(
          Duration(hours: 24),
          ReminderKind.standard,
          ReminderChannel.push,
        ),
      ];
    case RiskBand.medium:
      return const [
        ReminderPlan(
          Duration(hours: 48),
          ReminderKind.standard,
          ReminderChannel.push,
        ),
        ReminderPlan(
          Duration(hours: 3),
          ReminderKind.standard,
          ReminderChannel.push,
        ),
      ];
    case RiskBand.high:
      return const [
        ReminderPlan(
          Duration(days: 5),
          ReminderKind.confirmRequest,
          ReminderChannel.push,
        ),
        ReminderPlan(
          Duration(hours: 24),
          ReminderKind.escalated,
          ReminderChannel.push,
        ),
        ReminderPlan(
          Duration(hours: 2),
          ReminderKind.escalated,
          ReminderChannel.push,
        ),
      ];
  }
}

class ReminderScheduler {
  ReminderScheduler(this._db);

  final AppDatabase _db;

  /// (Re)builds the reminder rows for [appointmentId]. Existing unsent
  /// reminders for it are cleared first, so this is safe to call again after a
  /// reschedule.
  /// [enabledChannels], when given, drops any plan step whose channel isn't
  /// in the set — the patient's own notification preferences, so a disabled
  /// channel is never queued for delivery. Null (the default) schedules
  /// every channel [reminderPlanFor] specifies, for callers that don't have
  /// a preference to apply.
  Future<Result<int>> scheduleFor({
    required String appointmentId,
    required DateTime slotStart,
    required RiskBand band,
    Set<ReminderChannel>? enabledChannels,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.reminders)..where(
            (r) =>
                r.appointmentId.equals(appointmentId) &
                r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued),
          ))
          .write(
            const RemindersCompanion(
              deliveryStatus: Value(ReminderDeliveryStatus.suppressed),
            ),
          );

      final now = DateTime.now();
      var written = 0;
      final channels = reminderChannelsFor(enabledChannels);
      for (final plan in reminderPlanFor(band)) {
        final at = slotStart.subtract(plan.offsetBeforeSlot);
        if (at.isBefore(now)) continue; // no point scheduling the past
        for (final channel in channels) {
          await _db
              .into(_db.reminders)
              .insert(
                RemindersCompanion.insert(
                  id: newId('rem'),
                  appointmentId: appointmentId,
                  scheduledFor: at,
                  channel: channel,
                  kind: Value(plan.kind),
                ),
              );
          written++;
        }
      }
      return written;
    });
  }

  /// Reminders that are due but not yet sent (the in-app surface polls this).
  Future<List<ReminderRow>> due({DateTime? asOf}) {
    final at = asOf ?? DateTime.now();
    return (_db.select(_db.reminders)
          ..where(
            (r) =>
                r.deliveryStatus.equalsValue(ReminderDeliveryStatus.queued) &
                r.scheduledFor.isSmallerOrEqualValue(at),
          )
          ..orderBy([(r) => OrderingTerm(expression: r.scheduledFor)]))
        .get();
  }

  Future<void> markSent(String reminderId) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((r) => r.id.equals(reminderId))).getSingle();
    await (_db.update(
      _db.reminders,
    )..where((r) => r.id.equals(reminderId))).write(
      RemindersCompanion(
        sentAt: Value(DateTime.now()),
        deliveryStatus: const Value(ReminderDeliveryStatus.delivered),
        deliveryAttempts: Value(row.deliveryAttempts + 1),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(String reminderId, String error) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((r) => r.id.equals(reminderId))).getSingle();
    await (_db.update(
      _db.reminders,
    )..where((r) => r.id.equals(reminderId))).write(
      RemindersCompanion(
        deliveryStatus: const Value(ReminderDeliveryStatus.failed),
        deliveryAttempts: Value(row.deliveryAttempts + 1),
        lastError: Value(error),
      ),
    );
  }

  Future<void> retry(String reminderId) {
    return (_db.update(
      _db.reminders,
    )..where((r) => r.id.equals(reminderId))).write(
      const RemindersCompanion(
        deliveryStatus: Value(ReminderDeliveryStatus.queued),
        lastError: Value(null),
      ),
    );
  }
}
