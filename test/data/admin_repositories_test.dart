// Task, risk, admin-user and appointment-range repositories on an in-memory
// database (P6-02). Complements repositories_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/patient_repository_impl.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late UserRepositoryImpl users;

  setUp(() {
    db = newTestDatabase();
    users = UserRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<String> patient(String email) async {
    final r = await AuthRepositoryImpl(db).registerPatient(
      PatientRegistration(fullName: 'P', email: email, password: 'pw123456'),
    );
    return r.valueOrNull!.id;
  }

  group('UserRepository (admin)', () {
    test('createStaff, then it shows up in byRole(staff)', () async {
      final s = await users.createStaff(
        fullName: 'Dr A',
        email: 'a@clinic.test',
        temporaryPassword: 'temp12345',
        specialty: 'Cardiology',
      );
      expect(s.isOk, isTrue);
      final staff = (await users.byRole(UserRole.staff)).valueOrNull!;
      expect(staff.map((u) => u.email), contains('a@clinic.test'));
    });

    test('setActive deactivates and login is then refused', () async {
      final s = (await users.createStaff(
        fullName: 'Dr B',
        email: 'b@clinic.test',
        temporaryPassword: 'temp12345',
      )).valueOrNull!;

      expect(
        (await AuthRepositoryImpl(
          db,
        ).login(email: 'b@clinic.test', password: 'temp12345')).isOk,
        isTrue,
      );

      await users.setActive(id: s.id, active: false);
      final after = await AuthRepositoryImpl(
        db,
      ).login(email: 'b@clinic.test', password: 'temp12345');
      expect(after.isErr, isTrue);
    });

    test('resetPassword changes the credential', () async {
      final s = (await users.createStaff(
        fullName: 'Dr C',
        email: 'c@clinic.test',
        temporaryPassword: 'temp12345',
      )).valueOrNull!;
      await users.resetPassword(id: s.id, newPassword: 'brandnew123');

      expect(
        (await AuthRepositoryImpl(
          db,
        ).login(email: 'c@clinic.test', password: 'temp12345')).isErr,
        isTrue,
      );
      expect(
        (await AuthRepositoryImpl(
          db,
        ).login(email: 'c@clinic.test', password: 'brandnew123')).isOk,
        isTrue,
      );
    });
  });

  group('DepartmentRepository', () {
    test('upsert then read back; upsert with same id updates', () async {
      final repo = DepartmentRepositoryImpl(db);
      await repo.upsert(
        const Department(id: 'd1', name: 'Cardiology', description: 'Heart'),
      );
      await repo.upsert(const Department(id: 'd1', name: 'Cardio'));
      final all = (await repo.all()).valueOrNull!;
      expect(all, hasLength(1));
      expect(all.single.name, 'Cardio');
      expect(all.single.description, isNull);
    });

    test('delete removes an unused department', () async {
      final repo = DepartmentRepositoryImpl(db);
      await repo.upsert(const Department(id: 'd1', name: 'Cardiology'));
      expect((await repo.delete('d1')).isOk, isTrue);
      expect((await repo.all()).valueOrNull, isEmpty);
    });

    test('delete is refused while staff are assigned', () async {
      final repo = DepartmentRepositoryImpl(db);
      await repo.upsert(const Department(id: 'd1', name: 'Cardiology'));
      await users.createStaff(
        fullName: 'Dr D',
        email: 'd@clinic.test',
        temporaryPassword: 'temp12345',
        departmentId: 'd1',
      );
      final r = await repo.delete('d1');
      expect(r.isErr, isTrue);
      expect((await repo.all()).valueOrNull, hasLength(1));
    });
  });

  group('UserRepository.createAdmin', () {
    test('creates an admin that shows up in byRole(admin)', () async {
      final r = await users.createAdmin(
        fullName: 'Root',
        email: 'root@myhealth.test',
        temporaryPassword: 'temp12345',
      );
      expect(r.isOk, isTrue);
      final admins = (await users.byRole(UserRole.admin)).valueOrNull!;
      expect(admins.map((u) => u.email), contains('root@myhealth.test'));
    });

    test('rejects a duplicate email', () async {
      await users.createAdmin(
        fullName: 'Root',
        email: 'dupe@myhealth.test',
        temporaryPassword: 'temp12345',
      );
      final r = await users.createAdmin(
        fullName: 'Root 2',
        email: 'dupe@myhealth.test',
        temporaryPassword: 'temp12345',
      );
      expect(r.isErr, isTrue);
    });
  });

  group('TaskRepository', () {
    Future<String> staff() async {
      final s = await users.createStaff(
        fullName: 'Dr T',
        email: 't${DateTime.now().microsecondsSinceEpoch}@clinic.test',
        temporaryPassword: 'temp12345',
      );
      return s.valueOrNull!.id;
    }

    test(
      'forStaff orders by rule score, applyAiPriority + setStatus',
      () async {
        final sid = await staff();
        final tasks = TaskRepositoryImpl(db);
        final now = DateTime.now();

        await tasks.upsert(
          StaffTask(
            id: 'low',
            staffId: sid,
            title: 'Low',
            kind: TaskKind.other,
            status: TaskStatus.open,
            ruleScore: 0.3,
            createdAt: now,
          ),
        );
        await tasks.upsert(
          StaffTask(
            id: 'high',
            staffId: sid,
            title: 'High',
            kind: TaskKind.unreviewedAbnormalLab,
            status: TaskStatus.open,
            ruleScore: 0.9,
            createdAt: now,
          ),
        );

        var list = (await tasks.forStaff(sid, openOnly: true)).valueOrNull!;
        expect(list.map((t) => t.id), ['high', 'low']);

        await tasks.applyAiPriority(
          id: 'low',
          score: 0.95,
          rationale: 'bumped',
        );
        list = (await tasks.forStaff(sid)).valueOrNull!;
        final low = list.firstWhere((t) => t.id == 'low');
        expect(low.aiPriorityScore, 0.95);
        expect(low.aiRationale, 'bumped');
        expect(low.effectivePriority(1), closeTo(0.95, 1e-9));

        await tasks.setStatus('high', TaskStatus.done);
        final open = (await tasks.forStaff(sid, openOnly: true)).valueOrNull!;
        expect(open.map((t) => t.id), ['low']);
      },
    );
  });

  group('AppointmentRepository range queries', () {
    test('forStaffInRange / inRange window by slot start', () async {
      final pid = await patient('rangep@e.com');
      final sid = (await users.createStaff(
        fullName: 'Dr R',
        email: 'r@clinic.test',
        temporaryPassword: 'temp12345',
      )).valueOrNull!.id;
      final appts = AppointmentRepositoryImpl(db);

      Future<void> book(DateTime start) => appts
          .book(
            BookingRequest(
              patientId: pid,
              staffId: sid,
              start: start,
              end: start.add(const Duration(minutes: 20)),
              visitType: VisitType.followUp,
            ),
          )
          .then((_) {});

      final base = DateTime(2026, 7, 6, 9); // a Monday
      await book(base);
      await book(base.add(const Duration(days: 2)));
      await book(base.add(const Duration(days: 30)));

      final week = (await appts.forStaffInRange(
        sid,
        base,
        base.add(const Duration(days: 7)),
      )).valueOrNull!;
      expect(week, hasLength(2));

      final all = (await appts.inRange(
        base.subtract(const Duration(days: 1)),
        base.add(const Duration(days: 60)),
      )).valueOrNull!;
      expect(all, hasLength(3));
    });
  });
}
