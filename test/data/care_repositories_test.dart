// Care-services repositories on an in-memory database (P10 Batch B).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/repositories/care_repository_impl.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/domain/repositories/care_repository.dart';

import '../support/test_database.dart';

void main() {
  late AuthRepositoryImpl auth;
  late UserRepositoryImpl users;
  late SickLeaveRepositoryImpl sick;
  late CareMessageRepositoryImpl messages;
  late HomeVisitRepositoryImpl visits;

  late String patientId;
  late String staffId;

  setUp(() async {
    final db = newTestDatabase();
    addTearDown(db.close);
    auth = AuthRepositoryImpl(db);
    users = UserRepositoryImpl(db);
    sick = SickLeaveRepositoryImpl(db);
    messages = CareMessageRepositoryImpl(db);
    visits = HomeVisitRepositoryImpl(db);

    patientId = (await auth.registerPatient(
      const PatientRegistration(
        fullName: 'Pat Ient',
        email: 'p@care.test',
        password: 'pw123456',
      ),
    )).valueOrNull!.id;
    staffId = (await users.createStaff(
      fullName: 'Dr Who',
      email: 'dr@care.test',
      temporaryPassword: 'temp12345',
    )).valueOrNull!.id;
  });

  group('SickLeaveRepository', () {
    NewSickLeave note({DateTime? from, DateTime? to}) => NewSickLeave(
      patientId: patientId,
      issuedByStaffId: staffId,
      diagnosis: 'Influenza',
      fromDate: from ?? DateTime(2026, 3, 2),
      toDate: to ?? DateTime(2026, 3, 5),
    );

    test('issue then forPatient / issuedBy return it', () async {
      final issued = await sick.issue(note());
      expect(issued.isOk, isTrue);
      expect(issued.valueOrNull!.days, 4);

      expect(
        (await sick.forPatient(patientId)).valueOrNull, hasLength(1),
      );
      expect(
        (await sick.issuedBy(staffId)).valueOrNull, hasLength(1),
      );
    });

    test('rejects an end date before the start date', () async {
      final r = await sick.issue(
        note(from: DateTime(2026, 3, 5), to: DateTime(2026, 3, 2)),
      );
      expect(r.isErr, isTrue);
    });

    test('rejects an empty diagnosis', () async {
      final r = await sick.issue(
        NewSickLeave(
          patientId: patientId,
          issuedByStaffId: staffId,
          diagnosis: '   ',
          fromDate: DateTime(2026, 3, 2),
          toDate: DateTime(2026, 3, 3),
        ),
      );
      expect(r.isErr, isTrue);
    });
  });

  group('CareMessageRepository', () {
    test('send builds a thread; markRead clears the other side', () async {
      await messages.send(
        patientId: patientId,
        staffId: staffId,
        fromStaff: false,
        body: 'Quick question',
      );
      await messages.send(
        patientId: patientId,
        staffId: staffId,
        fromStaff: true,
        body: 'Here is the answer',
      );

      final thread = (await messages.thread(
        patientId: patientId,
        staffId: staffId,
      )).valueOrNull!;
      expect(thread, hasLength(2));
      expect(thread.first.body, 'Quick question'); // oldest first

      final forPatient = (await messages.threadsForPatient(
        patientId,
      )).valueOrNull!;
      expect(forPatient, hasLength(1));
      expect(forPatient.single.unreadForPatient, 1); // the doctor's reply
      expect(forPatient.single.counterpartName, contains('Dr'));

      await messages.markRead(
        patientId: patientId,
        staffId: staffId,
        readerIsStaff: false,
      );
      final after = (await messages.threadsForPatient(patientId)).valueOrNull!;
      expect(after.single.unreadForPatient, 0);
    });

    test('staff inbox shows the patient side, unread until read', () async {
      await messages.send(
        patientId: patientId,
        staffId: staffId,
        fromStaff: false,
        body: 'Hello doctor',
      );
      final inbox = (await messages.threadsForStaff(staffId)).valueOrNull!;
      expect(inbox, hasLength(1));
      expect(inbox.single.unreadForStaff, 1);

      await messages.markRead(
        patientId: patientId,
        staffId: staffId,
        readerIsStaff: true,
      );
      expect(
        (await messages.threadsForStaff(staffId)).valueOrNull!.single
            .unreadForStaff,
        0,
      );
    });

    test('rejects an empty message', () async {
      final r = await messages.send(
        patientId: patientId,
        staffId: staffId,
        fromStaff: false,
        body: '   ',
      );
      expect(r.isErr, isTrue);
    });
  });

  group('HomeVisitRepository', () {
    NewHomeVisitRequest req() => NewHomeVisitRequest(
      patientId: patientId,
      addressText: 'Building 1, Road 2, Block 3',
      preferredDate: DateTime(2026, 4, 2),
      reasonText: 'Cannot travel to the clinic',
    );

    test('create → queue → schedule → complete', () async {
      final created = await visits.create(req());
      expect(created.isOk, isTrue);
      expect(created.valueOrNull!.status, HomeVisitStatus.requested);

      expect(
        (await visits.all(status: HomeVisitStatus.requested)).valueOrNull,
        hasLength(1),
      );

      final scheduled = await visits.decide(
        id: created.valueOrNull!.id,
        status: HomeVisitStatus.scheduled,
        assignedStaffId: staffId,
        decisionNote: 'Nurse Tue 10:00',
      );
      expect(scheduled.valueOrNull!.status, HomeVisitStatus.scheduled);
      expect(scheduled.valueOrNull!.assignedStaffId, staffId);
      expect(scheduled.valueOrNull!.decidedAt, isNotNull);

      final done = await visits.decide(
        id: created.valueOrNull!.id,
        status: HomeVisitStatus.completed,
      );
      expect(done.valueOrNull!.status, HomeVisitStatus.completed);
      expect(
        (await visits.all(status: HomeVisitStatus.requested)).valueOrNull,
        isEmpty,
      );
    });

    test('patient can cancel an open request but not a closed one', () async {
      final created = (await visits.create(req())).valueOrNull!;
      final cancelled = await visits.cancel(
        id: created.id,
        patientId: patientId,
      );
      expect(cancelled.valueOrNull!.status, HomeVisitStatus.cancelled);

      final again = await visits.cancel(id: created.id, patientId: patientId);
      expect(again.isErr, isTrue);
    });

    test('rejects a blank address or reason', () async {
      final r = await visits.create(
        NewHomeVisitRequest(
          patientId: patientId,
          addressText: '  ',
          preferredDate: DateTime(2026, 4, 2),
          reasonText: 'x',
        ),
      );
      expect(r.isErr, isTrue);
    });
  });
}
