// Dental FDI chart: dentist-only writes within a care relationship, bound
// to the patient's own visit, plan → completed linkage, append-only.
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/dental_chart_repository.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';

import '../support/sessions.dart';

void main() {
  test('FDI numbering', () {
    for (final n in [11, 18, 28, 31, 48, 51, 85]) {
      expect(isFdiTooth(n), isTrue, reason: '$n');
    }
    for (final n in [10, 19, 29, 49, 56, 86, 91, 0, 100]) {
      expect(isFdiTooth(n), isFalse, reason: '$n');
    }
    expect(fdiUpper.length + fdiLower.length, 32);
  });

  test('dentist charts a booked patient; others cannot write', () async {
    final (c, db) = await seededContainer();
    // The patient books the dentist, creating the care relationship.
    await signInAs(c, 'patient1@myhealth.demo');
    final day = DateTime.now().add(const Duration(days: 3));
    OpenSlot? slot;
    for (var i = 0; i < 10 && slot == null; i++) {
      final s =
          (await c
                  .read(appointmentRepositoryProvider)
                  .openSlots('staff_dentist', day.add(Duration(days: i))))
              .valueOrNull;
      if (s != null && s.isNotEmpty) slot = s.first;
    }
    expect(slot, isNotNull, reason: 'dentist has a seeded schedule');
    final visit =
        (await c
                .read(appointmentRepositoryProvider)
                .book(
                  BookingRequest(
                    patientId: 'patient_001',
                    staffId: 'staff_dentist',
                    start: slot!.start,
                    end: slot.end,
                    visitType: VisitType.newPatient,
                    idempotencyKey: IdempotencyKey.generate(),
                  ),
                ))
            .valueOrNull!;

    await signInAs(c, 'dentist@myhealth.demo');
    final repo = c.read(dentalChartRepositoryProvider);
    NewDentalEntry entry(
      DentalEntryKind kind,
      String key, {
      int tooth = 36,
      String? fulfils,
      String? appointmentId,
    }) => NewDentalEntry(
      patientId: 'patient_001',
      appointmentId: appointmentId ?? visit.id,
      tooth: tooth,
      kind: kind,
      note: 'Occlusal caries',
      surface: 'O',
      fulfilsId: fulfils,
      idempotencyKey: key,
    );

    final plan = (await repo.add(
      entry(DentalEntryKind.planned, 'p1'),
    )).valueOrNull!;
    expect((await repo.add(entry(DentalEntryKind.planned, 'p1'))).isOk, isTrue);
    expect(
      (await repo.add(
        entry(
          DentalEntryKind.completed,
          'c-wrong',
          tooth: 37,
          fulfils: plan.id,
        ),
      )).failureOrNull,
      isA<ValidationFailure>(),
    );
    expect(
      (await repo.add(
        entry(DentalEntryKind.completed, 'c1', fulfils: plan.id),
      )).isOk,
      isTrue,
    );
    expect(
      (await repo.add(
        entry(DentalEntryKind.observation, 'bad', tooth: 19),
      )).failureOrNull,
      isA<ValidationFailure>(),
    );
    final entries = (await repo.forPatient('patient_001')).valueOrNull!;
    expect(entries.map((e) => e.kind), [
      DentalEntryKind.planned,
      DentalEntryKind.completed,
    ]);
    expect(entries.every((e) => e.authorId == 'staff_dentist'), isTrue);

    // Another patient's visit cannot carry this patient's entry.
    final other =
        await (db.select(db.appointments)
              ..where((a) => a.patientId.equals('patient_002'))
              ..limit(1))
            .getSingle();
    expect(
      (await repo.add(
        entry(DentalEntryKind.observation, 'x', appointmentId: other.id),
      )).failureOrNull,
      isA<ValidationFailure>(),
    );

    // Entries are append-only.
    expect(
      () =>
          db.customStatement("UPDATE dental_chart_entries SET note = 'edited'"),
      throwsA(anything),
    );

    // A doctor has no dental-chart permission; reception cannot read it.
    await signInAs(c, 'staff1@myhealth.demo');
    expect(
      (await c
              .read(dentalChartRepositoryProvider)
              .add(entry(DentalEntryKind.observation, 'd1')))
          .failureOrNull,
      isA<AccessDeniedFailure>(),
    );
    await signInAs(c, 'reception@myhealth.demo');
    expect(
      (await c.read(dentalChartRepositoryProvider).forPatient('patient_001'))
          .failureOrNull,
      isA<AccessDeniedFailure>(),
    );
  });
}
