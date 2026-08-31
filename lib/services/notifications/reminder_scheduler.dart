/// Risk-adaptive reminder scheduling (P4-19).
///
/// The number and timing of reminders scales with the appointment's predicted
/// no-show band:
///   low     → one reminder, 24 h before
///   medium  → two: 48 h and 3 h before
///   high    → three: 5 days before (confirm-or-release), 24 h, 2 h before
///
/// Writes `reminders` rows; delivery is [PlatformNotifier]'s job (P4-18).
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
  Future<Result<int>> scheduleFor({
    required String appointmentId,
    required DateTime slotStart,
    required RiskBand band,
  }) {
    return Result.guardAsync(() async {
      await (_db.delete(_db.reminders)..where(
            (r) => r.appointmentId.equals(appointmentId) & r.sentAt.isNull(),
          ))
          .go();

      final now = DateTime.now();
      var written = 0;
      for (final plan in reminderPlanFor(band)) {
        final at = slotStart.subtract(plan.offsetBeforeSlot);
        if (at.isBefore(now)) continue; // no point scheduling the past
        await _db
            .into(_db.reminders)
            .insert(
              RemindersCompanion.insert(
                id: newId('rem'),
                appointmentId: appointmentId,
                scheduledFor: at,
                channel: plan.channel,
                kind: Value(plan.kind),
              ),
            );
        written++;
      }
      return written;
    });
  }

  /// Reminders that are due but not yet sent (the in-app surface polls this).
  Future<List<ReminderRow>> due({DateTime? asOf}) {
    final at = asOf ?? DateTime.now();
    return (_db.select(_db.reminders)
          ..where(
            (r) => r.sentAt.isNull() & r.scheduledFor.isSmallerOrEqualValue(at),
          )
          ..orderBy([(r) => OrderingTerm(expression: r.scheduledFor)]))
        .get();
  }

  Future<void> markSent(String reminderId) {
    return (_db.update(_db.reminders)..where((r) => r.id.equals(reminderId)))
        .write(RemindersCompanion(sentAt: Value(DateTime.now())));
  }
}
