// Walk-in queue + doctor→admin referral request repositories, plus the new
// appointment status transitions, on an in-memory database.

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/consultation_repository_impl.dart';
import 'package:myhealthcare/data/repositories/patient_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/domain/repositories/consultation_repository.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabaseHarness h;

  setUp(() async {
    h = await AppDatabaseHarness.create();
  });

  group('WalkInTicketRepository', () {
    test(
      'create issues a per-department tag and lists by department',
      () async {
        final a = await h.walkIns.create(
          NewWalkInTicket(
            patientId: h.patientId,
            departmentId: h.deptId,
            createdByStaffId: h.adminId,
            reason: 'Referred for cardiac review',
          ),
        );
        final b = await h.walkIns.create(
          NewWalkInTicket(
            patientId: h.patientId,
            departmentId: h.deptId,
            createdByStaffId: h.adminId,
          ),
        );
        expect(a.valueOrNull!.ticketTag, 'C-1');
        expect(b.valueOrNull!.ticketTag, 'C-2');

        final open = await h.walkIns.forDepartment(h.deptId, openOnly: true);
        expect(open.valueOrNull, hasLength(2));
      },
    );

    test('claim → resolve walks the status through', () async {
      final t = (await h.walkIns.create(
        NewWalkInTicket(
          patientId: h.patientId,
          departmentId: h.deptId,
          createdByStaffId: h.adminId,
        ),
      )).valueOrNull!;

      final visit = (await h.appts.openWalkInVisit(
        patientId: h.patientId,
        staffId: h.doctorId,
        departmentId: h.deptId,
        ticketTag: t.ticketTag,
      )).valueOrNull!;
      expect(visit.status, AppointmentStatus.inProgress);
      expect(visit.ticketTag, 'C-1');

      final claimed = await h.walkIns.claim(
        id: t.id,
        doctorId: h.doctorId,
        resultAppointmentId: visit.id,
      );
      expect(claimed.valueOrNull!.status, WalkInStatus.inProgress);
      expect(claimed.valueOrNull!.resultAppointmentId, visit.id);

      final done = await h.walkIns.resolve(t.id);
      expect(done.valueOrNull!.status, WalkInStatus.done);
      expect(done.valueOrNull!.resolvedAt, isNotNull);
    });
  });

  group('ReferralRequestRepository', () {
    test('create → pending → decide', () async {
      final appt = (await h.appts.openWalkInVisit(
        patientId: h.patientId,
        staffId: h.doctorId,
        departmentId: h.deptId,
        ticketTag: 'C-1',
      )).valueOrNull!;

      final made = await h.referrals.create(
        NewReferralRequest(
          patientId: h.patientId,
          requestedByStaffId: h.doctorId,
          reason: 'Needs specialist cardiology input.',
          appointmentId: appt.id,
        ),
      );
      expect(made.isOk, isTrue);

      expect((await h.referrals.pending()).valueOrNull, hasLength(1));
      expect(
        (await h.referrals.pendingForAppointment(appt.id)).valueOrNull,
        isNotNull,
      );

      await h.referrals.decide(
        id: made.valueOrNull!.id,
        status: ReferralRequestStatus.actioned,
        adminId: h.adminId,
        note: 'Booked a Cardiology walk-in.',
      );
      expect((await h.referrals.pending()).valueOrNull, isEmpty);
      final forPatient = await h.referrals.forPatient(h.patientId);
      expect(
        forPatient.valueOrNull!.single.status,
        ReferralRequestStatus.actioned,
      );
    });

    test('rejects an empty reason', () async {
      final r = await h.referrals.create(
        NewReferralRequest(
          patientId: h.patientId,
          requestedByStaffId: h.doctorId,
          reason: '   ',
        ),
      );
      expect(r.isErr, isTrue);
    });
  });

  group('appointment status transitions', () {
    test('call → arrive → complete', () async {
      final appt = (await h.appts.openWalkInVisit(
        patientId: h.patientId,
        staffId: h.doctorId,
        departmentId: h.deptId,
        ticketTag: 'C-9',
      )).valueOrNull!;

      // openWalkInVisit already lands in-progress; drive a normal one instead.
      await h.appts.markCalledIn(appt.id, DateTime(2026, 5, 1, 9));
      await h.appts.markArrived(appt.id, DateTime(2026, 5, 1, 9, 5));
      var row = (await h.appts.byId(appt.id)).valueOrNull!;
      expect(row.status, AppointmentStatus.inProgress);
      expect(row.calledInAt, isNotNull);
      expect(row.checkedInAt, isNotNull);

      await h.appts.completeVisit(
        id: appt.id,
        outcomeNote: 'Reviewed, stable.',
      );
      row = (await h.appts.byId(appt.id)).valueOrNull!;
      expect(row.status, AppointmentStatus.completed);
      expect(row.outcomeNote, 'Reviewed, stable.');
    });
  });
}

/// A minimal seeded harness: one patient, one doctor (in a department), one
/// admin, one department.
class AppDatabaseHarness {
  AppDatabaseHarness._(this._db);

  final AppDatabase _db;

  late final AppointmentRepositoryImpl appts = AppointmentRepositoryImpl(_db);
  late final WalkInTicketRepositoryImpl walkIns = WalkInTicketRepositoryImpl(
    _db,
  );
  late final ReferralRequestRepositoryImpl referrals =
      ReferralRequestRepositoryImpl(_db);

  late String patientId;
  late String doctorId;
  late String adminId;
  late String deptId;

  static Future<AppDatabaseHarness> create() async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final h = AppDatabaseHarness._(db);
    final auth = AuthRepositoryImpl(db);
    final users = UserRepositoryImpl(db);
    final depts = DepartmentRepositoryImpl(db);

    h.deptId = 'dept_c';
    await depts.upsert(const Department(id: 'dept_c', name: 'Cardiology'));
    h.patientId = (await auth.registerPatient(
      const PatientRegistration(
        fullName: 'Pat Ient',
        email: 'p@cons.test',
        password: 'pw123456',
      ),
    )).valueOrNull!.id;
    h.doctorId = (await users.createStaff(
      fullName: 'Dr Heart',
      email: 'dr@cons.test',
      temporaryPassword: 'temp12345',
      departmentId: 'dept_c',
    )).valueOrNull!.id;
    h.adminId = (await users.createAdmin(
      fullName: 'The Admin',
      email: 'a@cons.test',
      temporaryPassword: 'temp12345',
    )).valueOrNull!.id;
    return h;
  }
}
