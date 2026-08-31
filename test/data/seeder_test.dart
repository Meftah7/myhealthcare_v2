// The synthetic seeder: volume, correlation, determinism, idempotency
// (P1-19…P1-21).

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';

import '../support/test_database.dart';

void main() {
  test('produces the expected population', () async {
    final db = newTestDatabase();
    addTearDown(db.close);

    final result = (await Seeder(db).run())!;
    expect(result.departments, 5);
    expect(result.staff, 12);
    expect(result.patients, 60);
    expect(result.appointments, greaterThan(400));
    expect(result.records, greaterThan(200));

    final templates = await db.select(db.scheduleTemplates).get();
    expect(templates.length, 12 * 5);

    final orphans = await db
        .customSelect(
          'SELECT COUNT(*) c FROM appointments a '
          'LEFT JOIN users u ON u.id = a.patient_id WHERE u.id IS NULL',
        )
        .getSingle();
    expect(orphans.read<int>('c'), 0);
  });

  test('data is correlated, not random', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final profiles = await db.select(db.patientProfiles).get();
    final appts = await db.select(db.appointments).get();

    final apptsByPatient = <String, int>{};
    for (final a in appts) {
      apptsByPatient.update(a.patientId, (v) => v + 1, ifAbsent: () => 1);
    }

    double avg(bool wantChronic) {
      final ids = profiles
          .where((p) => p.chronicConditions.isNotEmpty == wantChronic)
          .map((p) => p.userId);
      final counts = ids.map((id) => apptsByPatient[id] ?? 0).toList();
      return counts.isEmpty
          ? 0
          : counts.reduce((a, b) => a + b) / counts.length;
    }

    expect(avg(true), greaterThan(avg(false) * 1.4));

    final noShowRate = <String, double>{};
    for (final id in apptsByPatient.keys) {
      final past = appts.where(
        (a) =>
            a.patientId == id &&
            a.status != AppointmentStatus.booked &&
            a.status != AppointmentStatus.confirmed,
      );
      if (past.isEmpty) continue;
      final ns = past.where((a) => a.status == AppointmentStatus.noShow).length;
      noShowRate[id] = ns / past.length;
    }
    final rates = noShowRate.values.toList()..sort();
    expect(rates.first, lessThan(0.15));
    expect(rates.last, greaterThan(0.35));

    final abnormal = await db
        .customSelect(
          "SELECT COUNT(*) c FROM lab_values WHERE abnormal_flag != 'normal'",
        )
        .getSingle();
    expect(abnormal.read<int>('c'), greaterThan(50));
  });

  test('is byte-identical across runs (seeded RNG)', () async {
    Future<List<String>> fingerprint() async {
      final db = newTestDatabase();
      final r = (await Seeder(db).run())!;
      final users = await (db.select(
        db.users,
      )..orderBy([(u) => OrderingTerm(expression: u.id)])).get();
      final names = users
          .map((u) => '${u.id}:${u.fullName}:${u.email}')
          .toList();
      await db.close();
      return [
        '${r.patients}/${r.staff}/${r.appointments}/${r.records}',
        ...names,
      ];
    }

    expect(await fingerprint(), equals(await fingerprint()));
  });

  test('run() is idempotent; reset() regenerates', () async {
    final db = newTestDatabase();
    addTearDown(db.close);

    expect(await Seeder(db).run(), isNotNull);
    expect(await Seeder(db).run(), isNull, reason: 'already at seedVersion');

    final usersAfterRun = (await db.select(db.users).get()).length;
    final reset = await Seeder(db).reset();
    expect(reset.patients, 60);
    expect((await db.select(db.users).get()).length, usersAfterRun);
  });

  test('every seeded account logs in with the demo password', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final firstUser = (await db.select(db.users).get()).first;
    final result = await AuthRepositoryImpl(
      db,
    ).login(email: firstUser.email, password: Seeder.demoPassword);
    expect(result.isOk, isTrue);
  });
}
