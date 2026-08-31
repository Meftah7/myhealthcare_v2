// Repository behaviour against an in-memory database (P1-12…P1-18, P6-02).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/patient_repository_impl.dart';
import 'package:myhealthcare/data/repositories/record_repository_impl.dart';
import 'package:myhealthcare/data/repositories/system_repository_impl.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/domain/repositories/record_repository.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late AuthRepositoryImpl auth;

  setUp(() {
    db = newTestDatabase();
    auth = AuthRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<Patient> registerPatient({
    String name = 'Sara Ahmed',
    String email = 'sara@example.com',
    String password = 'correct horse',
    List<String> chronic = const [],
  }) async {
    final r = await auth.registerPatient(
      PatientRegistration(
        fullName: name,
        email: email,
        password: password,
        chronicConditions: chronic,
      ),
    );
    return r.valueOrNull ?? (throw StateError('register failed: $r'));
  }

  group('AuthRepository', () {
    test('register then login round-trips; wrong password fails', () async {
      final patient = await registerPatient(
        email: 'Sara@Example.com',
        chronic: ['Asthma'],
      );
      expect(patient.chronicConditions, ['Asthma']);
      expect(patient.user.email, 'sara@example.com'); // normalised

      expect(
        (await auth.login(
          email: 'sara@example.com',
          password: 'correct horse',
        )).isOk,
        isTrue,
      );

      final bad = await auth.login(
        email: 'sara@example.com',
        password: 'wrong',
      );
      expect(bad.failureOrNull, isA<AuthFailure>());
    });

    test('duplicate email is rejected', () async {
      await registerPatient(email: 'dup@example.com');
      final second = await auth.registerPatient(
        const PatientRegistration(
          fullName: 'A',
          email: 'dup@example.com',
          password: 'pw12345',
        ),
      );
      expect(second.isErr, isTrue);
    });
  });

  group('PatientRepository', () {
    test('search matches by name', () async {
      await registerPatient(name: 'Khalid Nasser', email: 'k@example.com');
      final hits = (await PatientRepositoryImpl(
        db,
      ).search('khalid')).valueOrNull!;
      expect(hits, hasLength(1));
      expect(hits.single.fullName, 'Khalid Nasser');
    });
  });

  group('AppointmentRepository', () {
    test('open slots exclude booked times and reject double-booking', () async {
      final patient = await registerPatient(email: 'p@example.com');

      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'staff-1',
              role: UserRole.staff,
              fullName: 'Dr Who',
              email: 'dr@example.com',
              passwordHash: 'x',
              passwordSalt: 'y',
            ),
          );
      final monday = _nextWeekday(DateTime.monday);
      await db
          .into(db.scheduleTemplates)
          .insert(
            ScheduleTemplatesCompanion.insert(
              id: 'tmpl-1',
              staffId: 'staff-1',
              weekday: DateTime.monday,
              startMinutes: 9 * 60,
              endMinutes: 10 * 60,
            ),
          );

      final appts = AppointmentRepositoryImpl(db);
      final slots1 = (await appts.openSlots('staff-1', monday)).valueOrNull!;
      expect(slots1, hasLength(3)); // 09:00, 09:20, 09:40

      final first = slots1.first;
      BookingRequest request() => BookingRequest(
        patientId: patient.id,
        staffId: 'staff-1',
        start: first.start,
        end: first.end,
        visitType: VisitType.followUp,
      );

      expect((await appts.book(request())).isOk, isTrue);
      expect(
        (await appts.openSlots('staff-1', monday)).valueOrNull!,
        hasLength(2),
      );
      expect((await appts.book(request())).isErr, isTrue);
    });
  });

  group('RecordRepository', () {
    test('lab values are classified against their reference range', () async {
      final patient = await registerPatient(email: 'l@example.com');

      final rec = (await RecordRepositoryImpl(db).add(
        NewRecord(
          patientId: patient.id,
          recordType: RecordType.labResult,
          title: 'CBC',
          occurredAt: DateTime(2026, 6, 15),
          labValues: const [
            NewLabValue(analyte: 'Hb', value: 9, refLow: 13, refHigh: 17),
            NewLabValue(analyte: 'K', value: 4.2, refLow: 3.5, refHigh: 5.1),
          ],
        ),
      )).valueOrNull!;

      expect(rec.hasAbnormalLabs, isTrue);
      expect(
        rec.labValues.firstWhere((v) => v.analyte == 'Hb').abnormalFlag,
        AbnormalFlag.critical,
      );
      expect(
        rec.labValues.firstWhere((v) => v.analyte == 'K').abnormalFlag,
        AbnormalFlag.normal,
      );
    });
  });

  group('RiskRepository', () {
    test('upsertByDedupeKey does not create a second row', () async {
      final patient = await registerPatient(email: 'r@example.com');
      final risk = RiskRepositoryImpl(db);

      RiskFlag flag() => RiskFlag(
        id: 'flag-${DateTime.now().microsecondsSinceEpoch}',
        patientId: patient.id,
        kind: RiskFlagKind.abnormalVitals,
        severity: Severity.warning,
        rationale: 'BP high',
        detectedAt: DateTime.now(),
        source: FlagSource.rule,
        dedupeKey: 'bp:${patient.id}',
      );

      await risk.upsertByDedupeKey(flag());
      await risk.upsertByDedupeKey(flag());
      expect((await risk.forPatient(patient.id)).valueOrNull, hasLength(1));
    });
  });

  group('SettingsRepository', () {
    test('creates a default row on first read', () async {
      final s = (await SettingsRepositoryImpl(db).get()).valueOrNull!;
      expect(s.mockMode, isTrue);
      expect(s.seedVersion, 0);
    });
  });
}

DateTime _nextWeekday(int weekday) {
  var d = DateTime.now().add(const Duration(days: 1));
  while (d.weekday != weekday) {
    d = d.add(const Duration(days: 1));
  }
  return DateTime(d.year, d.month, d.day);
}
