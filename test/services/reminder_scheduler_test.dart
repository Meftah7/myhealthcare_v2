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
    expect(first.valueOrNull, 3);

    // Re-scheduling clears the unsent ones first — no duplicates.
    final second = await scheduler.scheduleFor(
      appointmentId: 'a',
      slotStart: slot,
      band: RiskBand.medium,
    );
    expect(second.valueOrNull, 2);

    final rows = await db.select(db.reminders).get();
    expect(rows, hasLength(2));
  });
}
