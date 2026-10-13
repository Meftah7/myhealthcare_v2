// The staff patient picker applies clinical scope before its limit and
// includes care-assignment relationships, not only appointment history.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';

import '../support/sessions.dart';

void main() {
  test('assignment-only patients are found; reception sees none', () async {
    final (c, db) = await seededContainer();
    // A patient staff_01 has never had an appointment with.
    final seen =
        await (db.selectOnly(db.appointments, distinct: true)
              ..addColumns([db.appointments.patientId])
              ..where(db.appointments.staffId.equals('staff_01')))
            .map((r) => r.read(db.appointments.patientId)!)
            .get();
    final stranger =
        (await (db.select(db.users)..where(
                  (u) =>
                      u.role.equalsValue(UserRole.patient) & u.id.isNotIn(seen),
                ))
                .get())
            .first;
    await signInAs(c, 'staff1@myhealth.demo');
    final repo = c.read(patientRepositoryProvider);
    final before = (await repo.clinicallyVisible(
      query: stranger.fullName,
    )).valueOrNull!;
    expect(before.map((p) => p.id), isNot(contains(stranger.id)));

    await db
        .into(db.careTeamAssignments)
        .insert(
          CareTeamAssignmentsCompanion.insert(
            id: 'assign-1',
            patientId: stranger.id,
            staffId: 'staff_01',
            role: CareTeamRole.values.first,
            assignedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );
    final after = (await repo.clinicallyVisible(
      query: stranger.fullName,
    )).valueOrNull!;
    expect(after.map((p) => p.id), contains(stranger.id));

    await signInAs(c, 'reception@myhealth.demo');
    expect(
      (await c.read(patientRepositoryProvider).clinicallyVisible()).valueOrNull,
      isEmpty,
    );
  });
}
