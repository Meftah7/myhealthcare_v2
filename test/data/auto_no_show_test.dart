// Visits nobody turned up for become no-shows 30 minutes after the start.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only unattended visits past the 30-minute grace are marked', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final template = (await (db.select(db.appointments)..limit(1)).get()).first;
    final now = DateTime(2030, 1, 10, 12);

    Future<void> visit(
      String id,
      DateTime start, {
      AppointmentStatus status = AppointmentStatus.booked,
      DateTime? checkedInAt,
    }) => db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: id,
            patientId: template.patientId,
            staffId: template.staffId,
            slotStart: start,
            slotEnd: start.add(const Duration(minutes: 20)),
            visitType: template.visitType,
            status: Value(status),
            checkedInAt: Value(checkedInAt),
          ),
        );

    await visit('late', now.subtract(const Duration(minutes: 31)));
    await visit(
      'late_confirmed',
      now.subtract(const Duration(hours: 2)),
      status: AppointmentStatus.confirmed,
    );
    await visit('within_grace', now.subtract(const Duration(minutes: 29)));
    await visit(
      'checked_in',
      now.subtract(const Duration(hours: 1)),
      status: AppointmentStatus.confirmed,
      checkedInAt: now.subtract(const Duration(minutes: 50)),
    );
    await visit(
      'seen',
      now.subtract(const Duration(hours: 1)),
      status: AppointmentStatus.inProgress,
    );

    await AppointmentRepositoryImpl(db).markOverdueNoShows(now: now);
    Future<AppointmentStatus> status(String id) async => (await (db.select(
      db.appointments,
    )..where((a) => a.id.equals(id))).getSingle()).status;

    expect(await status('late'), AppointmentStatus.noShow);
    expect(await status('late_confirmed'), AppointmentStatus.noShow);
    expect(await status('within_grace'), AppointmentStatus.booked);
    expect(await status('checked_in'), AppointmentStatus.confirmed);
    expect(await status('seen'), AppointmentStatus.inProgress);

    final audits = await (db.select(
      db.auditLog,
    )..where((a) => a.action.equals('appointment.auto_no_show'))).get();
    expect(
      audits.map((a) => a.entityId),
      containsAll(['late', 'late_confirmed']),
    );
  });
}
