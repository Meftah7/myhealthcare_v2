import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/patient_repository_impl.dart';
import 'package:myhealthcare/data/repositories/record_repository_impl.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/domain/repositories/record_repository.dart';
import 'package:myhealthcare/domain/risk_sources.dart';
import 'package:myhealthcare/services/rules/risk_detection_service.dart';
import 'package:myhealthcare/services/rules/task_generator.dart';

import '../support/test_database.dart';

RiskDetectionService detector(AppDatabase db) => RiskDetectionService(
  records: RecordRepositoryImpl(db),
  vitals: VitalsRepositoryImpl(db),
  medications: MedicationRepositoryImpl(db),
  appointments: AppointmentRepositoryImpl(db),
  risk: RiskRepositoryImpl(db),
);

Future<Patient> patient(
  AppDatabase db, {
  List<String> conditions = const [],
}) async => (await AuthRepositoryImpl(db).registerPatient(
  PatientRegistration(
    fullName: 'Episode Patient',
    email: 'episodes@example.com',
    password: 'correct horse battery',
    chronicConditions: conditions,
  ),
)).valueOrNull!;

Future<String> staff(AppDatabase db) async =>
    (await UserRepositoryImpl(db).createStaff(
      fullName: 'Episode Doctor',
      email: 'episodes-doctor@example.com',
      temporaryPassword: 'correct horse battery',
    )).valueOrNull!.id;

Future<void> lab(
  AppDatabase db,
  String patientId,
  String id,
  DateTime at,
) async {
  await db
      .into(db.medicalRecords)
      .insert(
        MedicalRecordsCompanion.insert(
          id: id,
          patientId: patientId,
          recordType: RecordType.labResult,
          title: 'Critical result $id',
          occurredAt: at,
          createdAt: Value(at),
        ),
      );
  await db
      .into(db.labValues)
      .insert(
        LabValuesCompanion.insert(
          id: 'value_$id',
          recordId: id,
          analyte: 'Potassium',
          value: 9,
          abnormalFlag: const Value(AbnormalFlag.critical),
        ),
      );
}

void main() {
  test(
    'new readings create new work while repeated scans preserve completed work',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final p = await patient(db);
      final owner = await staff(db);
      final vitals = VitalsRepositoryImpl(db);
      final risk = RiskRepositoryImpl(db);
      final tasks = TaskRepositoryImpl(db);
      final gen = TaskGenerator(tasks: tasks, risk: risk);
      await vitals.add(
        Vitals(
          id: 'reading-1',
          patientId: p.id,
          recordedAt: DateTime.now().subtract(const Duration(minutes: 1)),
          systolic: 190,
          diastolic: 120,
        ),
      );
      await detector(db).runAndPersist(p);
      await gen.generateFor(
        staffId: owner,
        flags: (await risk.unacknowledged()).valueOrNull!,
      );
      final original = (await tasks.forStaff(owner)).valueOrNull!.single;
      await tasks.setStatus(
        id: original.id,
        staffId: owner,
        status: TaskStatus.done,
        outcome: 'Reviewed source; recorded clinical decision in chart.',
      );
      await detector(db).runAndPersist(p);
      await gen.generateFor(
        staffId: owner,
        flags: (await risk.unacknowledged()).valueOrNull!,
      );
      expect(
        (await tasks.forStaff(owner)).valueOrNull!.single.status,
        TaskStatus.done,
      );
      await vitals.add(
        Vitals(
          id: 'reading-2',
          patientId: p.id,
          recordedAt: DateTime.now(),
          systolic: 195,
          diastolic: 125,
        ),
      );
      await detector(db).runAndPersist(p);
      await gen.generateFor(
        staffId: owner,
        flags: (await risk.unacknowledged()).valueOrNull!,
      );
      final all = (await tasks.forStaff(owner)).valueOrNull!;
      expect(all, hasLength(2));
      expect(
        all.firstWhere((t) => t.id == original.id).status,
        TaskStatus.done,
      );
      expect(all.firstWhere((t) => t.id == original.id).dueAt, original.dueAt);
      expect(all.where((t) => t.isOpen), hasLength(1));
    },
  );

  test('critical reports have separate stable identities', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final p = await patient(db);
    await lab(
      db,
      p.id,
      'report-1',
      DateTime.now().subtract(const Duration(days: 1)),
    );
    await lab(db, p.id, 'report-2', DateTime.now());
    final first = await detector(db).scan(p);
    final second = await detector(db).scan(p);
    expect(first.map((f) => f.dedupeKey).toSet(), {
      RiskSources.key('${p.id}:lab:critical', 'report-1'),
      RiskSources.key('${p.id}:lab:critical', 'report-2'),
    });
    expect(second.map((f) => f.dedupeKey), first.map((f) => f.dedupeKey));
  });

  test(
    'source IDs that collided in the old short hash create distinct tasks',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final p = await patient(db);
      final owner = await staff(db);
      final tasks = TaskRepositoryImpl(db);
      final risk = RiskRepositoryImpl(db);
      final gen = TaskGenerator(tasks: tasks, risk: risk);
      final flags = [
        for (final id in ['Aa', 'BB'])
          RiskFlag(
            id: id,
            patientId: p.id,
            kind: RiskFlagKind.abnormalLab,
            severity: Severity.urgent,
            rationale: 'Review result',
            detectedAt: DateTime.now(),
            source: FlagSource.rule,
            dedupeKey: RiskSources.key('${p.id}:lab:critical', id),
          ),
      ];
      expect((await gen.generateFor(staffId: owner, flags: flags)).isOk, true);
      expect((await tasks.forStaff(owner)).valueOrNull, hasLength(2));
      await gen.generateFor(staffId: owner, flags: flags);
      expect((await tasks.forStaff(owner)).valueOrNull, hasLength(2));
    },
  );

  test(
    'medication gap recurs after a treatment course, not an unrelated prescription',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final p = await patient(db, conditions: ['Hypertension']);
      final initial = (await detector(db).scan(p)).single;
      final meds = MedicationRepositoryImpl(db);
      await meds.prescribe(
        Medication(
          id: 'course-1',
          patientId: p.id,
          name: 'Amlodipine',
          startDate: DateTime.now(),
          isActive: true,
        ),
      );
      expect(await detector(db).scan(p), isEmpty);
      await meds.discontinue('course-1', DateTime.now());
      final recurrence = (await detector(db).scan(p)).single;
      expect(recurrence.dedupeKey, isNot(initial.dedupeKey));
      await meds.prescribe(
        Medication(
          id: 'unrelated',
          patientId: p.id,
          name: 'Paracetamol',
          startDate: DateTime.now(),
          isActive: true,
        ),
      );
      expect(
        (await detector(db).scan(p)).single.dedupeKey,
        recurrence.dedupeKey,
      );
    },
  );

  test(
    'follow-up identity follows the last encounter, not the scan date',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final p = await patient(db, conditions: ['Unmapped condition']);
      final records = RecordRepositoryImpl(db);
      await records.add(
        NewRecord(
          patientId: p.id,
          recordType: RecordType.visitNote,
          title: 'Old visit',
          occurredAt: DateTime.now().subtract(const Duration(days: 400)),
        ),
      );
      final original = (await detector(db).scan(p)).single.dedupeKey;
      expect((await detector(db).scan(p)).single.dedupeKey, original);
      await records.add(
        NewRecord(
          patientId: p.id,
          recordType: RecordType.visitNote,
          title: 'Later visit',
          occurredAt: DateTime.now().subtract(const Duration(days: 280)),
        ),
      );
      expect((await detector(db).scan(p)).single.dedupeKey, isNot(original));
    },
  );

  test(
    'v27 upgrade aliases old sources without changing flags or task workflow',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'myhealth_episode_migration_',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/clinic.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      final p = await patient(db, conditions: ['Hypertension']);
      final owner = await staff(db);
      final oldAt = DateTime.now().subtract(const Duration(days: 1));
      await VitalsRepositoryImpl(db).add(
        Vitals(
          id: 'legacy-reading',
          patientId: p.id,
          recordedAt: oldAt,
          systolic: 190,
          diastolic: 120,
        ),
      );
      await lab(db, p.id, 'legacy-report-a', oldAt);
      await lab(db, p.id, 'legacy-report-b', oldAt);
      final oldFlags = [
        for (final (rule, kind) in [
          ('vitals:bp', RiskFlagKind.abnormalVitals),
          ('lab:critical', RiskFlagKind.abnormalLab),
          ('medgap:Hypertension', RiskFlagKind.medicationGap),
        ])
          RiskFlag(
            id: 'legacy-$rule',
            patientId: p.id,
            kind: kind,
            severity: Severity.urgent,
            rationale: 'Original aggregate rationale',
            detectedAt: DateTime.now(),
            source: FlagSource.rule,
            dedupeKey: '${p.id}:$rule',
          ),
      ];
      final risk = RiskRepositoryImpl(db);
      final tasks = TaskRepositoryImpl(db);
      for (final f in oldFlags) {
        await risk.upsertByDedupeKey(f);
      }
      await TaskGenerator(
        tasks: tasks,
        risk: risk,
      ).generateFor(staffId: owner, flags: oldFlags);
      for (final t in (await tasks.forStaff(owner)).valueOrNull!) {
        await tasks.applyAiPriority(
          id: t.id,
          staffId: owner,
          score: 0.75,
          rationale: 'Retain AI',
        );
        await tasks.setStatus(
          id: t.id,
          staffId: owner,
          status: TaskStatus.dismissed,
          outcome: 'Reviewed source; recorded clinical decision in chart.',
        );
      }
      final before = (await tasks.forStaff(owner)).valueOrNull!;
      final beforeFlags = (await risk.forPatient(p.id)).valueOrNull!;
      await db.customStatement('DROP TABLE risk_source_aliases');
      await db.customStatement('PRAGMA user_version = 27');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());
      final migratedPatient = (await PatientRepositoryImpl(
        db,
      ).byId(p.id)).valueOrNull!;
      final migratedRisk = RiskRepositoryImpl(db);
      final migratedTasks = TaskRepositoryImpl(db);
      expect((await detector(db).runAndPersist(migratedPatient)).isOk, true);
      expect(
        (await migratedRisk.forPatient(p.id)).valueOrNull!.toSet(),
        beforeFlags.toSet(),
      );
      await TaskGenerator(tasks: migratedTasks, risk: migratedRisk).generateFor(
        staffId: owner,
        flags: (await migratedRisk.unacknowledged()).valueOrNull!,
      );
      expect(
        (await migratedTasks.forStaff(owner)).valueOrNull!.toSet(),
        before.toSet(),
      );
      // Re-running a partially-applied migration is safe too.
      await db.backfillRiskSourceAliases();
      await VitalsRepositoryImpl(db).add(
        Vitals(
          id: 'new-reading',
          patientId: p.id,
          recordedAt: DateTime.now().add(const Duration(minutes: 1)),
          systolic: 195,
          diastolic: 125,
        ),
      );
      await detector(db).runAndPersist(migratedPatient);
      await TaskGenerator(tasks: migratedTasks, risk: migratedRisk).generateFor(
        staffId: owner,
        flags: (await migratedRisk.unacknowledged()).valueOrNull!,
      );
      final after = (await migratedTasks.forStaff(owner)).valueOrNull!;
      expect(after, hasLength(before.length + 1));
      expect(after.where((t) => t.isOpen), hasLength(1));
      expect(after.where((t) => !t.isOpen).toSet(), before.toSet());
    },
  );
}
