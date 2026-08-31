// Rule-based risk detection + task generation (P5-01, P5-02, P5-03).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/utils/ids.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/record_repository_impl.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/domain/repositories/record_repository.dart';
import 'package:myhealthcare/services/rules/risk_detection_service.dart';
import 'package:myhealthcare/services/rules/task_generator.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late RecordRepositoryImpl records;
  late VitalsRepositoryImpl vitals;
  late MedicationRepositoryImpl meds;
  late AppointmentRepositoryImpl appts;
  late RiskRepositoryImpl risk;
  late TaskRepositoryImpl tasks;
  late RiskDetectionService detector;

  setUp(() {
    db = newTestDatabase();
    records = RecordRepositoryImpl(db);
    vitals = VitalsRepositoryImpl(db);
    meds = MedicationRepositoryImpl(db);
    appts = AppointmentRepositoryImpl(db);
    risk = RiskRepositoryImpl(db);
    tasks = TaskRepositoryImpl(db);
    detector = RiskDetectionService(
      records: records,
      vitals: vitals,
      medications: meds,
      appointments: appts,
      risk: risk,
    );
  });
  tearDown(() => db.close());

  Future<Patient> patientWith(List<String> chronic) async {
    final r = await AuthRepositoryImpl(db).registerPatient(
      PatientRegistration(
        fullName: 'Test Patient',
        email: 'p${DateTime.now().microsecondsSinceEpoch}@e.com',
        password: 'correct horse battery',
        chronicConditions: chronic,
      ),
    );
    return r.valueOrNull!;
  }

  test('flags severe hypertension as urgent', () async {
    final p = await patientWith(const []);
    await vitals.add(
      Vitals(
        id: newId('v'),
        patientId: p.id,
        recordedAt: DateTime.now(),
        systolic: 190,
        diastolic: 120,
      ),
    );

    final flags = await detector.scan(p);
    final bp = flags.firstWhere((f) => f.kind == RiskFlagKind.abnormalVitals);
    expect(bp.severity, Severity.urgent);
    expect(bp.dedupeKey, '${p.id}:vitals:bp');
  });

  test('flags a critical lab and a medication gap', () async {
    final p = await patientWith(const ['Hypertension']);
    await records.add(
      NewRecord(
        patientId: p.id,
        recordType: RecordType.labResult,
        title: 'Renal panel',
        occurredAt: DateTime.now(),
        labValues: const [
          NewLabValue(analyte: 'Potassium', value: 9.0, refHigh: 5.0),
        ],
      ),
    );

    final flags = await detector.scan(p);
    expect(
      flags.any(
        (f) =>
            f.kind == RiskFlagKind.abnormalLab && f.severity == Severity.urgent,
      ),
      isTrue,
    );
    expect(
      flags.any((f) => f.kind == RiskFlagKind.medicationGap),
      isTrue,
      reason: 'Hypertension with no antihypertensive is a gap',
    );
  });

  test('no medication gap once the drug is on record', () async {
    final p = await patientWith(const ['Hypertension']);
    await meds.prescribe(
      Medication(
        id: newId('m'),
        patientId: p.id,
        name: 'Amlodipine 5mg',
        startDate: DateTime.now(),
        isActive: true,
      ),
    );
    final flags = await detector.scan(p);
    expect(flags.any((f) => f.kind == RiskFlagKind.medicationGap), isFalse);
  });

  test('runAndPersist is idempotent on dedupeKey', () async {
    final p = await patientWith(const []);
    await vitals.add(
      Vitals(
        id: newId('v'),
        patientId: p.id,
        recordedAt: DateTime.now(),
        spo2: 84,
      ),
    );

    await detector.runAndPersist(p);
    await detector.runAndPersist(p);

    final stored = (await risk.forPatient(p.id)).valueOrNull!;
    expect(stored.where((f) => f.dedupeKey.endsWith('spo2')), hasLength(1));
  });

  test('task generator turns flags into scored staff tasks', () async {
    final staff = (await UserRepositoryImpl(db).createStaff(
      fullName: 'Dr Test',
      email: 'dr${DateTime.now().microsecondsSinceEpoch}@e.com',
      temporaryPassword: 'temp horse battery',
    )).valueOrNull!;
    final staffId = staff.id;
    final p = await patientWith(const []);
    await vitals.add(
      Vitals(
        id: newId('v'),
        patientId: p.id,
        recordedAt: DateTime.now(),
        systolic: 195,
        diastolic: 125,
      ),
    );
    await detector.runAndPersist(p);
    final open = (await risk.unacknowledged()).valueOrNull!;

    final gen = TaskGenerator(tasks: tasks, risk: risk);
    final written = await gen.generateFor(staffId: staffId, flags: open);
    expect(written.valueOrNull, greaterThan(0));

    final list = (await tasks.forStaff(staffId, openOnly: true)).valueOrNull!;
    expect(list, isNotEmpty);
    expect(list.first.ruleScore, closeTo(0.9, 1e-9));

    // Re-running does not duplicate.
    await gen.generateFor(staffId: staffId, flags: open);
    final again = (await tasks.forStaff(staffId)).valueOrNull!;
    expect(again, hasLength(list.length));
  });
}
