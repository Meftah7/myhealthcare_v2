// Risk-adaptive reminder scheduling (P4-19).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/notifications/reminder_scheduler.dart';

import '../support/test_database.dart';

void main() {
  test('plan size scales with the risk band', () {
    expect(reminderPlanFor(RiskBand.low), hasLength(1));
    expect(reminderPlanFor(RiskBand.medium), hasLength(2));
    expect(reminderPlanFor(RiskBand.high), hasLength(3));
    expect(
      reminderPlanFor(RiskBand.high).first.kind,
      ReminderKind.confirmRequest,
    );
  });

  test('scheduleFor writes future reminders and is idempotent', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final scheduler = ReminderScheduler(db);

    // A staff, patient and appointment far enough out that all reminders land
    // in the future.
    for (final (id, role) in const [
      ('s', UserRole.staff),
      ('p', UserRole.patient),
    ]) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              role: role,
              fullName: id.toUpperCase(),
              email: '$id@e.com',
              passwordHash: 'h',
              passwordSalt: 'x',
            ),
          );
    }
    final slot = DateTime.now().add(const Duration(days: 10));
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: 'a',
            patientId: 'p',
            staffId: 's',
            slotStart: slot,
            slotEnd: slot.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        );

    final first = await scheduler.scheduleFor(
      appointmentId: 'a',
      slotStart: slot,
      band: RiskBand.high,
    );
    // Three plan steps, each in-app and push.
    expect(first.valueOrNull, 6);

    // Re-scheduling clears the unsent ones first — no duplicates.
    final second = await scheduler.scheduleFor(
      appointmentId: 'a',
      slotStart: slot,
      band: RiskBand.medium,
    );
    expect(second.valueOrNull, 4);

    final rows = await db.select(db.reminders).get();
    expect(
      rows.where((row) => row.deliveryStatus == ReminderDeliveryStatus.queued),
      hasLength(4),
    );
    expect(
      rows.where(
        (row) => row.deliveryStatus == ReminderDeliveryStatus.suppressed,
      ),
      hasLength(6),
    );
  });

  test('delivery failure can be retried and then delivered', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final scheduler = ReminderScheduler(db);
    for (final (id, role) in const [
      ('staff', UserRole.staff),
      ('patient', UserRole.patient),
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
    final slot = DateTime.now().add(const Duration(days: 2));
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: 'appointment',
            patientId: 'patient',
            staffId: 'staff',
            slotStart: slot,
            slotEnd: slot.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        );
    await scheduler.scheduleFor(
      appointmentId: 'appointment',
      slotStart: slot,
      band: RiskBand.low,
      enabledChannels: const {ReminderChannel.push},
    );
    final reminder = (await (db.select(
      db.reminders,
    )..where((r) => r.channel.equalsValue(ReminderChannel.push))).get()).single;

    await scheduler.markFailed(reminder.id, 'permission denied');
    var updated = await (db.select(
      db.reminders,
    )..where((row) => row.id.equals(reminder.id))).getSingle();
    expect(updated.deliveryStatus, ReminderDeliveryStatus.failed);
    expect(updated.deliveryAttempts, 1);

    await scheduler.retry(reminder.id);
    await scheduler.markSent(reminder.id);
    updated = await (db.select(
      db.reminders,
    )..where((row) => row.id.equals(reminder.id))).getSingle();
    expect(updated.deliveryStatus, ReminderDeliveryStatus.delivered);
    expect(updated.sentAt, isNotNull);
  });
}
