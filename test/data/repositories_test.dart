// Repository behaviour against an in-memory database (P1-12…P1-18, P6-02).

import 'package:drift/drift.dart' hide isNull;
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

    // Every test time below is constructed as an exact hour-of-day (always a
    // multiple of the 20-minute grid) offset by whole days, so one
    // full-day, every-weekday template makes any such time land on a real
    // slot boundary regardless of which weekday it falls on.
    Future<String> makeStaff(String id) async {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              role: UserRole.staff,
              fullName: 'Dr Staff',
              email: '$id@example.com',
              passwordHash: 'x',
              passwordSalt: 'y',
            ),
          );
      for (var weekday = 1; weekday <= 7; weekday++) {
        await db
            .into(db.scheduleTemplates)
            .insert(
              ScheduleTemplatesCompanion.insert(
                id: 'tmpl-$id-$weekday',
                staffId: id,
                weekday: weekday,
                startMinutes: 0,
                endMinutes: 24 * 60,
                slotMinutes: const Value(20),
              ),
            );
      }
      return id;
    }

    test(
      'book rejects an interval overlap even with a different start time',
      () async {
        final patient = await registerPatient(email: 'ov1@example.com');
        final staffId = await makeStaff('staff-ov1');
        final appts = AppointmentRepositoryImpl(db);
        final start = _nextWeekday(
          DateTime.monday,
        ).add(const Duration(hours: 9));

        final first = await appts.book(
          BookingRequest(
            patientId: patient.id,
            staffId: staffId,
            start: start,
            end: start.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        );
        expect(first.isOk, isTrue);

        // Starts 10 minutes into the first appointment — not an exact-start
        // match, but the intervals overlap.
        final overlapping = await appts.book(
          BookingRequest(
            patientId: patient.id,
            staffId: staffId,
            start: start.add(const Duration(minutes: 10)),
            end: start.add(const Duration(minutes: 30)),
            visitType: VisitType.followUp,
          ),
        );
        expect(overlapping.isErr, isTrue);
      },
    );

    test('book rejects a past start time', () async {
      final patient = await registerPatient(email: 'past1@example.com');
      final staffId = await makeStaff('staff-past1');
      final appts = AppointmentRepositoryImpl(db);
      final past = DateTime.now().subtract(const Duration(days: 1));

      final result = await appts.book(
        BookingRequest(
          patientId: patient.id,
          staffId: staffId,
          start: past,
          end: past.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
        ),
      );
      expect(result.isErr, isTrue);
    });

    test(
      "book rejects a time that isn't on the clinician's schedule grid",
      () async {
        final patient = await registerPatient(email: 'grid1@example.com');
        final staffId = await makeStaff('staff-grid1');
        final appts = AppointmentRepositoryImpl(db);
        // makeStaff's template is on a 20-minute grid; 5 minutes past the
        // hour never lands on one of its boundaries.
        final offGrid = _nextWeekday(
          DateTime.monday,
        ).add(const Duration(hours: 9, minutes: 5));

        final result = await appts.book(
          BookingRequest(
            patientId: patient.id,
            staffId: staffId,
            start: offGrid,
            end: offGrid.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        );
        expect(result.isErr, isTrue);
      },
    );

    test("reschedule rejects a time that isn't on the clinician's schedule "
        'grid', () async {
      final patient = await registerPatient(email: 'grid2@example.com');
      final staffId = await makeStaff('staff-grid2');
      final appts = AppointmentRepositoryImpl(db);
      final start = _nextWeekday(DateTime.monday).add(const Duration(hours: 9));

      final booked = (await appts.book(
        BookingRequest(
          patientId: patient.id,
          staffId: staffId,
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
        ),
      )).valueOrNull!;

      final offGrid = start.add(const Duration(days: 1, minutes: 5));
      final result = await appts.reschedule(
        id: booked.id,
        patientId: patient.id,
        newStart: offGrid,
        newEnd: offGrid.add(const Duration(minutes: 20)),
      );
      expect(result.isErr, isTrue);
    });

    test(
      'reschedule rejects a caller who does not own the appointment',
      () async {
        final owner = await registerPatient(email: 'owner1@example.com');
        final stranger = await registerPatient(email: 'stranger1@example.com');
        final staffId = await makeStaff('staff-auth1');
        final appts = AppointmentRepositoryImpl(db);
        final start = _nextWeekday(
          DateTime.monday,
        ).add(const Duration(hours: 9));

        final booked = (await appts.book(
          BookingRequest(
            patientId: owner.id,
            staffId: staffId,
            start: start,
            end: start.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        )).valueOrNull!;

        final result = await appts.reschedule(
          id: booked.id,
          patientId: stranger.id,
          newStart: start.add(const Duration(days: 1)),
          newEnd: start.add(const Duration(days: 1, minutes: 20)),
        );
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<AuthFailure>());

        // Untouched — still at its original time.
        final unchanged = (await appts.byId(booked.id)).valueOrNull!;
        expect(unchanged.slotStart, start);
      },
    );

    test(
      'reschedule rejects an interval that overlaps another appointment',
      () async {
        final patient = await registerPatient(email: 'resched1@example.com');
        final staffId = await makeStaff('staff-resched1');
        final appts = AppointmentRepositoryImpl(db);
        final start = _nextWeekday(
          DateTime.monday,
        ).add(const Duration(hours: 9));

        final first = (await appts.book(
          BookingRequest(
            patientId: patient.id,
            staffId: staffId,
            start: start,
            end: start.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        )).valueOrNull!;
        final second = (await appts.book(
          BookingRequest(
            patientId: patient.id,
            staffId: staffId,
            start: start.add(const Duration(days: 1)),
            end: start.add(const Duration(days: 1, minutes: 20)),
            visitType: VisitType.followUp,
          ),
        )).valueOrNull!;

        // Try to move the second appointment onto the first's time.
        final result = await appts.reschedule(
          id: second.id,
          patientId: patient.id,
          newStart: first.slotStart,
          newEnd: first.slotEnd,
        );
        expect(result.isErr, isTrue);
        final unchanged = (await appts.byId(second.id)).valueOrNull!;
        expect(unchanged.slotStart, second.slotStart);
        expect(unchanged.slotEnd, second.slotEnd);
      },
    );

    test('reschedule rejects a completed appointment and rebuilds reminders '
        'on success', () async {
      final patient = await registerPatient(email: 'resched2@example.com');
      final staffId = await makeStaff('staff-resched2');
      final appts = AppointmentRepositoryImpl(db);
      final start = _nextWeekday(DateTime.monday).add(const Duration(hours: 9));

      final booked = (await appts.book(
        BookingRequest(
          patientId: patient.id,
          staffId: staffId,
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
          riskBand: RiskBand.low,
        ),
      )).valueOrNull!;

      final newStart = start.add(const Duration(days: 1));
      final rescheduled = await appts.reschedule(
        id: booked.id,
        patientId: patient.id,
        newStart: newStart,
        newEnd: newStart.add(const Duration(minutes: 20)),
      );
      expect(rescheduled.isOk, isTrue);

      final reminders = await (db.select(
        db.reminders,
      )..where((r) => r.appointmentId.equals(booked.id))).get();
      expect(reminders, isNotEmpty);
      expect(reminders.every((r) => r.scheduledFor.isBefore(newStart)), isTrue);

      await appts.updateStatus(
        id: booked.id,
        staffId: staffId,
        status: AppointmentStatus.confirmed,
      );
      await appts.markArrived(booked.id, staffId: staffId, at: DateTime.now());
      await appts.completeVisit(id: booked.id, staffId: staffId);
      final afterCompletion = await appts.reschedule(
        id: booked.id,
        patientId: patient.id,
        newStart: newStart.add(const Duration(days: 1)),
        newEnd: newStart.add(const Duration(days: 1, minutes: 20)),
      );
      expect(afterCompletion.isErr, isTrue);
    });

    test('cancel rejects a non-owner, is not repeatable, and suppresses '
        'queued reminders', () async {
      final owner = await registerPatient(email: 'owner2@example.com');
      final stranger = await registerPatient(email: 'stranger2@example.com');
      final staffId = await makeStaff('staff-cancel1');
      final appts = AppointmentRepositoryImpl(db);
      final start = _nextWeekday(DateTime.monday).add(const Duration(hours: 9));

      final booked = (await appts.book(
        BookingRequest(
          patientId: owner.id,
          staffId: staffId,
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
          riskBand: RiskBand.low,
        ),
      )).valueOrNull!;
      // Add another reminder so both repository-created and legacy rows
      // are retained as suppressed evidence.
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'rem-cancel1',
              appointmentId: booked.id,
              scheduledFor: start.subtract(const Duration(hours: 24)),
              channel: ReminderChannel.push,
            ),
          );

      final wrongOwner = await appts.cancel(booked.id, patientId: stranger.id);
      expect(wrongOwner.isErr, isTrue);

      final firstCancel = await appts.cancel(booked.id, patientId: owner.id);
      expect(firstCancel.isOk, isTrue);

      final secondCancel = await appts.cancel(booked.id, patientId: owner.id);
      expect(secondCancel.isErr, isTrue);

      final remaining = await (db.select(
        db.reminders,
      )..where((r) => r.appointmentId.equals(booked.id))).get();
      expect(remaining, isNotEmpty);
      expect(
        remaining.every(
          (row) => row.deliveryStatus == ReminderDeliveryStatus.suppressed,
        ),
        isTrue,
      );
    });

    test(
      'setTemplates rejects two overlapping templates on the same weekday',
      () async {
        final staffId = await makeStaff('staff-tmpl1');
        final appts = AppointmentRepositoryImpl(db);
        final result = await appts.setTemplates(
          staffId: staffId,
          templates: [
            const NewScheduleTemplate(
              weekday: DateTime.monday,
              startMinutes: 9 * 60,
              endMinutes: 11 * 60,
            ),
            const NewScheduleTemplate(
              weekday: DateTime.monday,
              startMinutes: 10 * 60,
              endMinutes: 12 * 60,
            ),
          ],
        );
        expect(result.isErr, isTrue);
      },
    );

    test('a clinician cannot mutate an appointment assigned to another '
        'clinician', () async {
      final patient = await registerPatient(email: 'staffauth1@example.com');
      final ownerStaffId = await makeStaff('staff-owner1');
      final otherStaffId = await makeStaff('staff-other1');
      final appts = AppointmentRepositoryImpl(db);
      final start = _nextWeekday(DateTime.monday).add(const Duration(hours: 9));

      final booked = (await appts.book(
        BookingRequest(
          patientId: patient.id,
          staffId: ownerStaffId,
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
        ),
      )).valueOrNull!;

      expect(
        (await appts.updateStatus(
          id: booked.id,
          staffId: otherStaffId,
          status: AppointmentStatus.noShow,
        )).isErr,
        isTrue,
      );
      expect(
        (await appts.markCalledIn(
          booked.id,
          staffId: otherStaffId,
          at: DateTime.now(),
        )).isErr,
        isTrue,
      );
      expect(
        (await appts.markArrived(
          booked.id,
          staffId: otherStaffId,
          at: DateTime.now(),
        )).isErr,
        isTrue,
      );
      expect(
        (await appts.completeVisit(id: booked.id, staffId: otherStaffId)).isErr,
        isTrue,
      );
      expect(
        (await appts.transfer(
          id: booked.id,
          fromStaffId: otherStaffId,
          toStaffId: ownerStaffId,
        )).isErr,
        isTrue,
      );

      // Untouched by any of the rejected attempts.
      final unchanged = (await appts.byId(booked.id)).valueOrNull!;
      expect(unchanged.status, AppointmentStatus.booked);
      expect(unchanged.staffId, ownerStaffId);

      // The actual owner can, though.
      expect(
        (await appts.markCalledIn(
          booked.id,
          staffId: ownerStaffId,
          at: DateTime.now(),
        )).isOk,
        isTrue,
      );
    });

    test('terminal appointment states cannot be reopened', () async {
      final patient = await registerPatient(email: 'terminal@example.com');
      final staffId = await makeStaff('staff-terminal');
      final appts = AppointmentRepositoryImpl(db);
      final start = _nextWeekday(DateTime.monday).add(const Duration(hours: 9));
      final booked = (await appts.book(
        BookingRequest(
          patientId: patient.id,
          staffId: staffId,
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
        ),
      )).valueOrNull!;

      expect(
        (await appts.updateStatus(
          id: booked.id,
          staffId: staffId,
          status: AppointmentStatus.noShow,
        )).isOk,
        isTrue,
      );
      expect(
        (await appts.markArrived(
          booked.id,
          staffId: staffId,
          at: DateTime.now(),
        )).isErr,
        isTrue,
      );
      expect(
        (await appts.completeVisit(id: booked.id, staffId: staffId)).isErr,
        isTrue,
      );
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

    test(
      'an imported PDF round-trips its filename and extracted text',
      () async {
        final patient = await registerPatient(email: 'import@example.com');
        final repo = RecordRepositoryImpl(db);

        final saved = (await repo.add(
          NewRecord(
            patientId: patient.id,
            recordType: RecordType.labResult,
            title: 'Outside lab result',
            occurredAt: DateTime(2026, 3),
            attachmentPath: 'lab_report.pdf',
            extractedText: 'Hemoglobin 13.2 g/dL — within range',
          ),
        )).valueOrNull!;

        expect(saved.hasAttachment, isTrue);
        expect(saved.attachmentPath, 'lab_report.pdf');
        expect(saved.extractedText, contains('Hemoglobin'));

        // It shows up in the patient's timeline like any other record.
        final timeline = (await repo.timeline(patient.id)).valueOrNull!;
        expect(timeline.any((r) => r.id == saved.id), isTrue);
      },
    );

    test(
      'a patient upload stays marked as unreviewed; clinic records do not',
      () async {
        final patient = await registerPatient(email: 'upload@example.com');
        final repo = RecordRepositoryImpl(db);

        final upload = (await repo.add(
          NewRecord(
            patientId: patient.id,
            recordType: RecordType.labResult,
            title: 'My outside lab',
            occurredAt: DateTime(2026, 3),
            attachmentPath: 'lab.pdf',
            sourceFacility: 'Outside Lab Co.',
            uploadedByPatient: true,
          ),
        )).valueOrNull!;
        final clinic = (await repo.add(
          NewRecord(
            patientId: patient.id,
            recordType: RecordType.labResult,
            title: 'Clinic CBC',
            occurredAt: DateTime(2026, 3),
          ),
        )).valueOrNull!;

        final timeline = (await repo.timeline(patient.id)).valueOrNull!;
        expect(
          timeline.firstWhere((r) => r.id == upload.id).uploadedByPatient,
          isTrue,
        );
        expect(
          timeline.firstWhere((r) => r.id == clinic.id).uploadedByPatient,
          isFalse,
        );
      },
    );
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
