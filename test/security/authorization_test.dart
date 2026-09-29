// Gate 1 — object-level authorization, enforced in the repositories: the
// acting identity comes from the signed-in principal, and caller-supplied
// patient/staff IDs are only ever the *target*. Negative tests for
// cross-patient, cross-clinician, revoked-proxy and insufficient-role
// access, plus the dependent (proxy) workflow keeping both identities.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';

import '../support/sessions.dart';

Matcher get _denied => isA<Err<dynamic>>().having(
  (r) => r.failure,
  'failure',
  isA<AccessDeniedFailure>(),
);

/// A seeded appointment's (patient, staff) pair — a real care relationship.
Future<AppointmentRow> _someAppointment(AppDatabase db, {String? patientId}) {
  final q = db.select(db.appointments)..limit(1);
  if (patientId != null) q.where((a) => a.patientId.equals(patientId));
  return q.getSingle();
}

/// A patient [staffId] has never seen.
Future<String> _unrelatedPatient(AppDatabase db, String staffId) async {
  final related = (await (db.select(
    db.appointments,
  )..where((a) => a.staffId.equals(staffId))).get()).map((a) => a.patientId);
  final patients = await (db.select(
    db.users,
  )..where((u) => u.role.equalsValue(UserRole.patient))).get();
  return patients.firstWhere((p) => !related.contains(p.id)).id;
}

String _staffEmail(String staffId) =>
    'staff${int.parse(staffId.substring('staff_'.length))}@myhealth.demo';

String _patientEmail(String patientId) =>
    'patient${int.parse(patientId.substring('patient_'.length))}@myhealth.demo';

Future<DateTime> _openWeekdaySlot() async {
  final now = DateTime.now();
  var start = DateTime(now.year, now.month, now.day + 3, 10);
  while (start.weekday == DateTime.friday ||
      start.weekday == DateTime.saturday) {
    start = start.add(const Duration(days: 1));
  }
  return start;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cross-patient', () {
    test('a patient cannot read another patient\'s records, visits, vitals, '
        'medications, bills or inbox', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      const other = 'patient_002';

      expect(await c.read(recordRepositoryProvider).timeline(other), _denied);
      expect(
        await c.read(appointmentRepositoryProvider).forPatient(other),
        _denied,
      );
      expect(await c.read(vitalsRepositoryProvider).forPatient(other), _denied);
      expect(
        await c.read(medicationRepositoryProvider).forPatient(other),
        _denied,
      );
      expect(
        await c.read(billingRepositoryProvider).forPatient(other),
        _denied,
      );
      expect(
        await c.read(billingRepositoryProvider).walletBalance(other),
        _denied,
      );
      expect(
        await c.read(sickLeaveRepositoryProvider).forPatient(other),
        _denied,
      );
      expect(await c.read(patientRepositoryProvider).byId(other), _denied);
      expect(
        await c.read(notificationRepositoryProvider).forRecipient(other),
        _denied,
      );
      expect(
        await c.read(aiSummaryRepositoryProvider).latestForPatient(other),
        _denied,
      );
    });

    test(
      'a patient cannot open another patient\'s record or invoice by id',
      () async {
        final (c, db) = await seededContainer();
        final record =
            await (db.select(db.medicalRecords)
                  ..where((r) => r.patientId.equals('patient_002'))
                  ..limit(1))
                .getSingle();
        final invoice =
            await (db.select(db.invoices)
                  ..where((i) => i.patientId.equals('patient_002'))
                  ..limit(1))
                .getSingleOrNull();
        await signInAs(c, 'patient1@myhealth.demo');

        expect(await c.read(recordRepositoryProvider).byId(record.id), _denied);
        if (invoice != null) {
          expect(
            await c.read(billingRepositoryProvider).byId(invoice.id),
            _denied,
          );
        }
      },
    );

    test('mutations on another patient are refused, whatever patient id the '
        'caller passes', () async {
      final (c, db) = await seededContainer();
      final theirs = await _someAppointment(db, patientId: 'patient_002');
      await signInAs(c, 'patient1@myhealth.demo');
      final appts = c.read(appointmentRepositoryProvider);

      // Naming the real owner: no grant.
      expect(await appts.cancel(theirs.id, patientId: 'patient_002'), _denied);
      // Naming themself: the stored owner still decides.
      final spoofed = await appts.cancel(theirs.id, patientId: 'patient_001');
      expect(spoofed.failureOrNull, isA<AccessDeniedFailure>());

      final start = await _openWeekdaySlot();
      expect(
        await appts.book(
          BookingRequest(
            patientId: 'patient_002',
            staffId: theirs.staffId,
            start: start,
            end: start.add(const Duration(minutes: 20)),
            visitType: VisitType.followUp,
          ),
        ),
        _denied,
      );
      expect(
        await c
            .read(recordRepositoryProvider)
            .add(
              NewRecord(
                patientId: 'patient_002',
                recordType: RecordType.labResult,
                title: 'Planted',
                occurredAt: DateTime.now(),
                uploadedByPatient: true,
              ),
            ),
        _denied,
      );
      expect(
        await c
            .read(billingRepositoryProvider)
            .topUpWallet(
              patientId: 'patient_002',
              amount: 5,
              card: const CardPayment(
                cardNumber: '4242424242424242',
                cardHolder: 'X',
                expiryMonth: 12,
                expiryYear: 2099,
                cvc: '123',
              ),
            ),
        _denied,
      );
      expect(
        await c
            .read(careMessageRepositoryProvider)
            .send(
              patientId: 'patient_002',
              staffId: theirs.staffId,
              fromStaff: false,
              body: 'hi',
            ),
        _denied,
      );

      // Nothing was written.
      final row = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(theirs.id))).getSingle();
      expect(row.status, theirs.status);
    });

    test('every denial leaves an access.denied audit entry naming the actor '
        'and the patient', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      await c.read(recordRepositoryProvider).timeline('patient_002');
      final denials = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('access.denied'))).get();
      expect(denials, isNotEmpty);
      expect(denials.last.actorUserId, 'patient_001');
      expect(denials.last.subjectPatientId, 'patient_002');
    });
  });

  group('cross-clinician', () {
    test(
      'a clinician cannot act as, or on the visits of, another clinician',
      () async {
        final (c, db) = await seededContainer();
        final appt =
            await (db.select(db.appointments)
                  ..where(
                    (a) => a.status.isInValues([
                      AppointmentStatus.booked,
                      AppointmentStatus.confirmed,
                    ]),
                  )
                  ..limit(1))
                .getSingle();
        final owner = appt.staffId;
        final staff = await (db.select(
          db.users,
        )..where((u) => u.role.equalsValue(UserRole.staff))).get();
        final colleague = staff.firstWhere((s) => s.id != owner).id;
        await signInAs(c, _staffEmail(colleague));
        final appts = c.read(appointmentRepositoryProvider);

        // Claiming to be the owning clinician.
        expect(
          await appts.updateStatus(
            id: appt.id,
            staffId: owner,
            status: AppointmentStatus.confirmed,
          ),
          _denied,
        );
        // As themself, on a colleague's visit.
        expect(
          (await appts.updateStatus(
            id: appt.id,
            staffId: colleague,
            status: AppointmentStatus.confirmed,
          )).failureOrNull,
          isA<AuthFailure>(),
        );
        expect(await c.read(taskRepositoryProvider).forStaff(owner), _denied);
        expect(
          await c
              .read(medicationRepositoryProvider)
              .prescribe(
                Medication(
                  id: '',
                  patientId: appt.patientId,
                  name: 'X',
                  prescriberId: owner,
                  startDate: DateTime.now(),
                  isActive: true,
                ),
              ),
          _denied,
        );
      },
    );

    test(
      'clinical access needs a care relationship; demographics do not',
      () async {
        final (c, db) = await seededContainer();
        final appt = await _someAppointment(db);
        final stranger = await _unrelatedPatient(db, appt.staffId);
        await signInAs(c, _staffEmail(appt.staffId));

        // Their own patient: full chart.
        expect(
          await c.read(recordRepositoryProvider).timeline(appt.patientId),
          isA<Ok<dynamic>>(),
        );
        // Someone else's: no chart, no notes, no prescriptions.
        expect(
          await c.read(recordRepositoryProvider).timeline(stranger),
          _denied,
        );
        expect(
          await c.read(vitalsRepositoryProvider).forPatient(stranger),
          _denied,
        );
        expect(
          await c
              .read(recordRepositoryProvider)
              .add(
                NewRecord(
                  patientId: stranger,
                  recordType: RecordType.visitNote,
                  title: 'Note',
                  occurredAt: DateTime.now(),
                  authorStaffId: appt.staffId,
                ),
              ),
          _denied,
        );
        // Demographics stay available (queues, search), clinical fields empty.
        final profile = (await c.read(patientRepositoryProvider).byId(stranger))
            .valueOrNull!;
        expect(profile.allergies, isEmpty);
        expect(profile.chronicConditions, isEmpty);
        expect(profile.bloodType, isNull);
      },
    );

    test(
      'an active care-team assignment grants access; ending it removes it',
      () async {
        final (c, db) = await seededContainer();
        final appt = await _someAppointment(db);
        final stranger = await _unrelatedPatient(db, appt.staffId);

        await signInAs(c, 'admin@myhealth.demo');
        final assigned =
            (await c
                    .read(careTeamRepositoryProvider)
                    .assign(
                      patientId: stranger,
                      staffId: appt.staffId,
                      role: CareTeamRole.consultant,
                    ))
                .valueOrNull!;

        await signInAs(c, _staffEmail(appt.staffId));
        expect(
          await c.read(recordRepositoryProvider).timeline(stranger),
          isA<Ok<dynamic>>(),
        );

        await signInAs(c, 'admin@myhealth.demo');
        await c.read(careTeamRepositoryProvider).end(assigned.id);

        await signInAs(c, _staffEmail(appt.staffId));
        expect(
          await c.read(recordRepositoryProvider).timeline(stranger),
          _denied,
        );
      },
    );
  });

  group('insufficient role', () {
    test('patients cannot administer', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      expect(
        await c
            .read(userRepositoryProvider)
            .setActive(id: 'patient_002', active: false),
        _denied,
      );
      expect(
        await c
            .read(userRepositoryProvider)
            .createStaff(
              fullName: 'Mallory',
              email: 'mallory@x.test',
              temporaryPassword: 'password123',
            ),
        _denied,
      );
      expect(await c.read(billingRepositoryProvider).all(), _denied);
      expect(
        await c.read(auditRepositoryProvider).query(const AuditQuery()),
        _denied,
      );
      expect(
        await c
            .read(notificationRepositoryProvider)
            .broadcast(
              audience: NotificationAudience.everyone,
              category: NotificationCategory.system,
              title: 'x',
              body: 'y',
            ),
        _denied,
      );
      expect(await c.read(patientRepositoryProvider).search('a'), _denied);
      expect(await c.read(homeVisitRepositoryProvider).all(), _denied);
      expect(
        await c.read(referralRequestRepositoryProvider).pending(),
        _denied,
      );
    });

    test('clinicians cannot run billing or departments', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      expect(await c.read(billingRepositoryProvider).all(), _denied);
      expect(
        await c.read(departmentRepositoryProvider).delete('dept_x'),
        _denied,
      );
      expect(
        await c.read(billingRepositoryProvider).forPatient('patient_001'),
        _denied,
      );
    });

    test('administrators have no clinical access', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_001'),
        _denied,
      );
      expect(
        await c.read(vitalsRepositoryProvider).forPatient('patient_001'),
        _denied,
      );
      // …but do see bookings and bills.
      expect(
        await c.read(appointmentRepositoryProvider).forPatient('patient_001'),
        isA<Ok<dynamic>>(),
      );
      expect(
        await c.read(billingRepositoryProvider).forPatient('patient_001'),
        isA<Ok<dynamic>>(),
      );
    });

    test('a nurse cannot prescribe', () async {
      final (c, db) = await seededContainer();
      final appt = await _someAppointment(db);
      await signInAs(c, 'admin@myhealth.demo');
      final nurse =
          (await c
                  .read(userRepositoryProvider)
                  .createStaff(
                    fullName: 'Nora Nurse',
                    email: 'nora@clinic.test',
                    temporaryPassword: 'password123',
                    jobTitle: kNurseJobTitle,
                  ))
              .valueOrNull!;
      // Give the nurse a care relationship so only the role is missing.
      await c
          .read(careTeamRepositoryProvider)
          .assign(
            patientId: appt.patientId,
            staffId: nurse.id,
            role: CareTeamRole.nurse,
          );
      await c.read(sessionProvider.notifier).logout();
      await c
          .read(sessionProvider.notifier)
          .login(email: 'nora@clinic.test', password: 'password123');

      expect(
        await c
            .read(medicationRepositoryProvider)
            .prescribe(
              Medication(
                id: '',
                patientId: appt.patientId,
                name: 'X',
                prescriberId: nurse.id,
                startDate: DateTime.now(),
                isActive: true,
              ),
            ),
        _denied,
      );
      // Charting is within a nurse's role.
      expect(
        await c.read(recordRepositoryProvider).timeline(appt.patientId),
        isA<Ok<dynamic>>(),
      );
    });

    test('caller-named actors are checked, not trusted', () async {
      final (c, db) = await seededContainer();
      final pending = await (db.select(
        db.referralRequests,
      )..limit(1)).getSingleOrNull();
      await signInAs(c, 'admin@myhealth.demo');
      if (pending != null) {
        expect(
          await c
              .read(referralRequestRepositoryProvider)
              .decide(
                id: pending.id,
                status: ReferralRequestStatus.rejected,
                adminId: 'staff_01',
              ),
          _denied,
        );
      }
      // The audit trail records the signed-in actor, not a claimed one.
      await c
          .read(auditRepositoryProvider)
          .record(
            action: 'test.event',
            entityType: 'test',
            actorUserId: 'patient_009',
          );
      final row = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('test.event'))).getSingle();
      expect(row.actorUserId, isNot('patient_009'));
      expect(row.detail, contains('claimed actor: patient_009'));
    });
  });

  group('proxies', () {
    Future<String> link(
      ProviderContainer c, {
      required String viewer,
      required String owner,
      required FamilyLinkPermission permission,
    }) async {
      await signInAs(c, _patientEmail(viewer));
      final req = await c
          .read(familyLinkRepositoryProvider)
          .request(
            ownerPatientId: owner,
            viewerPatientId: viewer,
            permission: permission,
          );
      await signInAs(c, _patientEmail(owner));
      await c
          .read(familyLinkRepositoryProvider)
          .accept(linkId: req.valueOrNull!.id, actingPatientId: owner);
      return req.valueOrNull!.id;
    }

    test('a view-only proxy can read but not act', () async {
      final (c, db) = await seededContainer();
      await link(
        c,
        viewer: 'patient_010',
        owner: 'patient_011',
        permission: FamilyLinkPermission.viewOnly,
      );
      final theirs = await _someAppointment(db, patientId: 'patient_011');
      await signInAs(c, 'patient10@myhealth.demo');
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_011'),
        isA<Ok<dynamic>>(),
      );
      expect(
        await c
            .read(appointmentRepositoryProvider)
            .cancel(theirs.id, patientId: 'patient_011'),
        _denied,
      );
    });

    test('a revoked proxy loses access on the very next call', () async {
      final (c, db) = await seededContainer();
      final linkId = await link(
        c,
        viewer: 'patient_010',
        owner: 'patient_011',
        permission: FamilyLinkPermission.manage,
      );
      await signInAs(c, 'patient10@myhealth.demo');
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_011'),
        isA<Ok<dynamic>>(),
      );

      // The owner revokes.
      await signInAs(c, 'patient11@myhealth.demo');
      await c
          .read(familyLinkRepositoryProvider)
          .unlink(linkId: linkId, actingPatientId: 'patient_011');

      await signInAs(c, 'patient10@myhealth.demo');
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_011'),
        _denied,
      );
      expect(
        await c.read(billingRepositoryProvider).forPatient('patient_011'),
        _denied,
      );
      final audit = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('proxy.grant.revoked'))).get();
      expect(audit, isNotEmpty);
    });

    test('a proxy cannot manage family links on the owner\'s behalf', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'patient10@myhealth.demo');
      expect(
        await c.read(familyLinkRepositoryProvider).viewersOfMe('patient_011'),
        _denied,
      );
    });
  });

  group('dependents keep both identities', () {
    test('a visit booked for a household member lands on the member\'s own '
        'record, stamped with the account that booked it', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient3@myhealth.demo');
      final guardian = c.read(currentUserProvider)!.id;
      final add = await c
          .read(familyMemberControllerProvider)
          .add(
            const FamilyMember(
              id: 'fm_sara',
              relationship: FamilyRelationship.child,
              firstName: 'Sara',
              lastName: 'Ali',
            ),
          );
      expect(add.isOk, isTrue);
      final member = (await c.read(
        patientFamilyMembersProvider.future,
      )).firstWhere((m) => m.id == 'fm_sara');

      final dependentId =
          (await c.read(bookingSubjectSelectorProvider).selectMember(member))
              .valueOrNull!;
      expect(dependentId, isNot(guardian));

      final depts = await c.read(departmentsProvider.future);
      final staff = await c.read(
        departmentStaffProvider(depts.first.id).future,
      );
      final start = await _openWeekdaySlot();
      final draft = c.read(bookingDraftProvider);
      c.read(bookingDraftProvider.notifier).state = draft.copyWith(
        departmentId: depts.first.id,
        staffId: staff.first.id,
        date: DateTime(start.year, start.month, start.day),
      );
      final ranked = await c.read(rankedSlotsProvider.future);
      final booked = await c
          .read(bookingControllerProvider)
          .confirm(ranked.first);
      expect(booked.isOk, isTrue, reason: '$booked');
      final appt = booked.valueOrNull!;

      // The patient is the member; the actor is the guardian.
      expect(appt.patientId, dependentId);
      expect(appt.bookedForName, 'Sara Ali');
      final row = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(appt.id))).getSingle();
      expect(row.bookedByAccountId, guardian);
      final audit = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('proxy.appointment.book'))).get();
      expect(audit.single.actorUserId, guardian);
      expect(audit.single.subjectPatientId, dependentId);

      // The guardian's own record is untouched; their list shows both.
      final own =
          (await c.read(appointmentRepositoryProvider).forPatient(guardian))
              .valueOrNull!;
      expect(own.where((a) => a.id == appt.id), isEmpty);
      final listed = await c.read(patientAppointmentsProvider.future);
      expect(listed.where((a) => a.id == appt.id), isNotEmpty);

      // The dependent has no login of their own.
      final dependent = await (db.select(
        db.users,
      )..where((u) => u.id.equals(dependentId))).getSingle();
      expect(dependent.hasLogin, isFalse);
    });

    test('a name stamped on the booker\'s own record is refused', () async {
      final (c, db) = await seededContainer();
      final appt = await _someAppointment(db);
      await signInAs(c, 'patient1@myhealth.demo');
      final start = await _openWeekdaySlot();
      final r = await c
          .read(appointmentRepositoryProvider)
          .book(
            BookingRequest(
              patientId: 'patient_001',
              staffId: appt.staffId,
              start: start,
              end: start.add(const Duration(minutes: 20)),
              visitType: VisitType.followUp,
              bookedForName: 'Somebody Else',
            ),
          );
      expect(r.failureOrNull, isA<ValidationFailure>());
    });

    test('documents and payments for a dependent record who acted', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient3@myhealth.demo');
      final guardian = c.read(currentUserProvider)!.id;
      await c
          .read(familyMemberControllerProvider)
          .add(
            const FamilyMember(
              id: 'fm_omar',
              relationship: FamilyRelationship.parent,
              firstName: 'Omar',
              lastName: 'Ali',
            ),
          );
      final dependentId =
          (await c
                  .read(patientRepositoryProvider)
                  .ensureDependentRecord(
                    guardianId: guardian,
                    memberId: 'fm_omar',
                  ))
              .valueOrNull!;

      final upload = await c
          .read(recordRepositoryProvider)
          .add(
            NewRecord(
              patientId: dependentId,
              recordType: RecordType.labResult,
              title: 'Outside lab',
              occurredAt: DateTime.now(),
              sourceFacility: 'Outside Lab Co.',
              uploadedByPatient: true,
            ),
          );
      expect(upload.isOk, isTrue);
      final record = await (db.select(
        db.medicalRecords,
      )..where((r) => r.id.equals(upload.valueOrNull!.id))).getSingle();
      expect(record.patientId, dependentId);
      expect(record.createdByAccountId, guardian);

      await signInAs(c, 'admin@myhealth.demo');
      final invoice =
          (await c
                  .read(billingRepositoryProvider)
                  .issue(NewInvoice(patientId: dependentId, subtotal: 10)))
              .valueOrNull!;

      await signInAs(c, 'patient3@myhealth.demo');
      final paid = await c
          .read(billingRepositoryProvider)
          .pay(
            invoiceId: invoice.id,
            patientId: dependentId,
            payment: const CardPayment(
              cardNumber: '4242424242424242',
              cardHolder: 'Guardian',
              expiryMonth: 12,
              expiryYear: 2099,
              cvc: '123',
            ),
          );
      expect(paid.isOk, isTrue, reason: '$paid');
      final row = await (db.select(
        db.invoices,
      )..where((i) => i.id.equals(invoice.id))).getSingle();
      expect(row.patientId, dependentId);
      expect(row.paidByAccountId, guardian);
    });
  });
}
