// Phase 4 gate: clinical work is durable, attributable, recoverable and owned.
//
// * a force-closed consultation resumes the saved draft;
// * a partial completion plus retry finalizes once — no duplicate orders or
//   notices;
// * critical and unjudgeable results stay visible, owned and escalatable;
// * a referral survives an owner/shift change without becoming unowned;
// * tasks and patient messages are owned work with cover.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/consultation_repository_impl.dart';
import 'package:myhealthcare/data/repositories/task_workflow.dart';
import 'package:myhealthcare/data/sync/outbox.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sessions.dart';

const _doctor = 'staff1@myhealth.demo';
const _doctorId = 'staff_01';
const _colleagueId = 'staff_02';
const _patientId = 'patient_050';

Matcher get _denied => isA<Err<dynamic>>().having(
  (e) => e.failure,
  'failure',
  isA<AccessDeniedFailure>(),
);

Matcher _fails<T extends Failure>() =>
    isA<Err<dynamic>>().having((e) => e.failure, 'failure', isA<T>());

/// A second app instance over the same database — a restarted app, or a
/// second device on the same store.
Future<ProviderContainer> _reopen(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// An in-progress visit for [_doctorId] with [_patientId].
Future<Appointment> _visit(ProviderContainer c, AppDatabase db) async {
  final dept = await (db.select(
    db.staffProfiles,
  )..where((s) => s.userId.equals(_doctorId))).getSingle();
  final r = await c
      .read(appointmentRepositoryProvider)
      .openWalkInVisit(
        patientId: _patientId,
        staffId: _doctorId,
        departmentId: dept.departmentId!,
        ticketTag: 'T-${DateTime.now().microsecondsSinceEpoch % 100000}',
      );
  return r.valueOrNull!;
}

Future<int> _prescriptionNotices(AppDatabase db) async {
  final events = await (db.select(
    db.outboxEvents,
  )..where((e) => e.type.equals(OutboxTypes.deliverNotification))).get();
  return events.where((e) {
    final p = jsonDecode(e.payload) as Map<String, Object?>;
    return p['category'] == NotificationCategory.prescription.name &&
        p['recipientId'] == _patientId;
  }).length;
}

/// Walk-in repository whose first "close the ticket" call fails — a crash
/// part-way through finalizing.
class _FlakyWalkIns implements WalkInTicketRepository {
  _FlakyWalkIns(this._inner);
  final WalkInTicketRepository _inner;
  var failNext = true;

  @override
  Future<Result<void>> resolveByAppointment(String appointmentId) async {
    if (failNext) {
      failNext = false;
      return const Err(DatabaseFailure('Storage interrupted'));
    }
    return _inner.resolveByAppointment(appointmentId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('encounter drafts survive a forced close', () {
    test('a restarted app resumes the saved draft', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
      final saved = await c
          .read(encounterDraftRepositoryProvider)
          .save(
            EncounterDraftData(
              appointmentId: appt.id,
              patientId: _patientId,
              authorStaffId: _doctorId,
              note: 'Cough for 3 days, chest clear.',
              medications: const [
                DraftMedicationData(name: 'Paracetamol', dose: '500 mg'),
              ],
            ),
          );
      expect(saved.isOk, isTrue);

      // The first instance is gone (tab closed, crash); a new one signs in.
      c.dispose();
      final reopened = await _reopen(db);
      await signInAs(reopened, _doctor);
      final draft =
          (await reopened
                  .read(encounterDraftRepositoryProvider)
                  .forAppointment(appt.id))
              .valueOrNull;
      expect(draft, isNotNull);
      expect(draft!.note, 'Cough for 3 days, chest clear.');
      expect(draft.medications.single.name, 'Paracetamol');
    });

    test('a stale save conflicts instead of overwriting', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
      final repo = c.read(encounterDraftRepositoryProvider);
      final first = (await repo.save(
        EncounterDraftData(
          appointmentId: appt.id,
          patientId: _patientId,
          authorStaffId: _doctorId,
          note: 'v1',
        ),
      )).valueOrNull!;
      await repo.save(
        EncounterDraftData(
          appointmentId: appt.id,
          patientId: _patientId,
          authorStaffId: _doctorId,
          note: 'v2 from another tab',
        ),
        expectedVersion: first.version,
      );
      expect(
        await repo.save(
          EncounterDraftData(
            appointmentId: appt.id,
            patientId: _patientId,
            authorStaffId: _doctorId,
            note: 'v2 from this tab',
          ),
          expectedVersion: first.version,
        ),
        _fails<ConflictFailure>(),
      );
      final kept = (await repo.forAppointment(appt.id)).valueOrNull!;
      expect(kept.note, 'v2 from another tab');
    });

    test("another clinician cannot write someone else's draft", () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
      await signInAs(c, 'staff2@myhealth.demo');
      expect(
        await c
            .read(encounterDraftRepositoryProvider)
            .save(
              EncounterDraftData(
                appointmentId: appt.id,
                patientId: _patientId,
                authorStaffId: _colleagueId,
                note: 'not my patient',
              ),
            ),
        _denied,
      );
    });
  });

  group('finalizing an encounter happens once', () {
    test('partial completion then retry: one note, no duplicate orders or '
        'notices', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
      final noticesBefore = await _prescriptionNotices(db);
      final flaky = _FlakyWalkIns(c.read(walkInTicketRepositoryProvider));
      final repo = EncounterRepositoryImpl(
        db,
        access: c.read(accessPolicyProvider),
        appointments: c.read(appointmentRepositoryProvider),
        walkIns: flaky,
      );
      final request = FinalizeEncounter(
        appointmentId: appt.id,
        staffId: _doctorId,
        note: 'Viral URTI. Supportive care.',
        medications: const [
          DraftMedicationData(name: 'Paracetamol', dose: '500 mg'),
          DraftMedicationData(name: 'Saline spray'),
        ],
      );
      final key = IdempotencyKey.generate();

      // The walk-in step fails: nothing may be left half-written.
      expect(
        await repo.finalize(request, idempotencyKey: key),
        _fails<DatabaseFailure>(),
      );
      expect(await db.select(db.signedNotes).get(), isEmpty);
      final orders = db.select(db.medications)
        ..where((m) => m.appointmentId.equals(appt.id));
      expect(await orders.get(), isEmpty);
      expect(await _prescriptionNotices(db), noticesBefore);
      final still = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(appt.id))).getSingle();
      expect(still.status, AppointmentStatus.inProgress);

      // Retry: finalizes exactly once.
      final signed = await repo.finalize(request, idempotencyKey: key);
      expect(signed.isOk, isTrue);
      expect(await orders.get(), hasLength(2));
      expect(await _prescriptionNotices(db), noticesBefore + 2);

      // A second tap, or a retry with a fresh key after a restart, is a
      // no-op returning the same note.
      final again = await repo.finalize(
        request,
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(again.valueOrNull!.id, signed.valueOrNull!.id);
      expect(await db.select(db.signedNotes).get(), hasLength(1));
      expect(await orders.get(), hasLength(2));
      expect(await _prescriptionNotices(db), noticesBefore + 2);
      final done = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(appt.id))).getSingle();
      expect(done.status, AppointmentStatus.completed);
    });

    test('a signed note never changes; corrections are amendments', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
      final repo = c.read(encounterRepositoryProvider);
      final note = (await repo.finalize(
        FinalizeEncounter(
          appointmentId: appt.id,
          staffId: _doctorId,
          note: 'Original note',
        ),
      )).valueOrNull!;
      await expectLater(
        db.customStatement(
          "UPDATE signed_notes SET body = 'edited' WHERE id = '${note.id}'",
        ),
        throwsA(anything),
      );
      final amendment = await repo.amend(
        signedNoteId: note.id,
        staffId: _doctorId,
        body: 'Correction: allergy to penicillin noted.',
      );
      expect(amendment.isOk, isTrue);
      final reloaded = (await repo.signedNoteFor(appt.id)).valueOrNull!;
      expect(reloaded.body, 'Original note');
      expect(reloaded.amendments.single.body, contains('penicillin'));
    });

    test('a nurse drafts but cannot sign', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      final appt = await _visit(c, db);
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
      await c.read(sessionProvider.notifier).logout();
      await c
          .read(sessionProvider.notifier)
          .login(email: 'nora@clinic.test', password: 'password123');
      expect(
        await c
            .read(encounterRepositoryProvider)
            .finalize(
              FinalizeEncounter(
                appointmentId: appt.id,
                staffId: nurse.id,
                note: 'x',
              ),
            ),
        _denied,
      );
    });
  });

  group('critical and unknown results are owned work', () {
    Future<MedicalRecord> fileLab(ProviderContainer c) async {
      final r = await c
          .read(recordRepositoryProvider)
          .add(
            NewRecord(
              patientId: _patientId,
              recordType: RecordType.labResult,
              title: 'Electrolytes',
              occurredAt: DateTime(2026, 9, 2),
              authorStaffId: _doctorId,
              labValues: const [
                NewLabValue(
                  analyte: 'Potassium',
                  value: 7.9,
                  unit: 'mmol/L',
                  refLow: 3.5,
                  refHigh: 5.0,
                ),
                // No range supplied: must not read as normal.
                NewLabValue(analyte: 'Novel marker', value: 12, unit: 'U'),
              ],
            ),
          );
      return r.valueOrNull!;
    }

    test(
      'a critical and a range-less value open an urgent, owned review',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, _doctor);
        await _visit(c, db); // care relationship
        final record = await fileLab(c);
        final flags = {
          for (final v in record.labValues) v.analyte: v.abnormalFlag,
        };
        expect(flags['Potassium'], AbnormalFlag.critical);
        expect(flags['Novel marker'], AbnormalFlag.unknown);
        expect(record.labValues.every((v) => v.provenance != null), isTrue);

        final review =
            (await c.read(resultReviewRepositoryProvider).forRecord(record.id))
                .valueOrNull!;
        expect(review.ownerStaffId, _doctorId);
        expect(review.priority, WorkPriority.urgent);
        expect(review.status, ResultReviewStatus.assigned);
        expect(
          review.dueAt.difference(review.createdAt),
          const Duration(hours: 1),
        );
        final queue =
            (await c.read(resultReviewRepositoryProvider).queueFor(_doctorId))
                .valueOrNull!;
        expect(queue.map((r) => r.id), contains(review.id));
      },
    );

    test('escalation hands it to cover; only a holder resolves; resolving '
        'verifies the values', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      await _visit(c, db);
      final record = await fileLab(c);
      final reviews = c.read(resultReviewRepositoryProvider);
      final review = (await reviews.forRecord(record.id)).valueOrNull!;

      expect(
        await reviews.escalate(
          id: review.id,
          staffId: _doctorId,
          coverageStaffId: _colleagueId,
          note: '',
        ),
        _fails<ValidationFailure>(),
      );
      final escalated = (await reviews.escalate(
        id: review.id,
        staffId: _doctorId,
        coverageStaffId: _colleagueId,
        note: 'K 7.9 — I am in theatre, please call the patient now.',
      )).valueOrNull!;
      expect(escalated.status, ResultReviewStatus.escalated);
      expect(escalated.ownerStaffId, _doctorId);
      expect(escalated.coverageStaffId, _colleagueId);

      await signInAs(c, 'staff3@myhealth.demo');
      expect(
        await reviews.resolve(
          id: review.id,
          staffId: 'staff_03',
          note: 'not mine',
        ),
        _denied,
      );

      await signInAs(c, 'staff2@myhealth.demo');
      final cover = (await reviews.queueFor(_colleagueId)).valueOrNull!;
      expect(cover.map((r) => r.id), contains(review.id));
      await reviews.startReview(id: review.id, staffId: _colleagueId);
      final resolved = (await reviews.resolve(
        id: review.id,
        staffId: _colleagueId,
        note: 'Patient contacted, sent to ED for repeat and ECG.',
      )).valueOrNull!;
      expect(resolved.status, ResultReviewStatus.resolved);
      expect(resolved.resolvedByStaffId, _colleagueId);
      final values = await (db.select(
        db.labValues,
      )..where((l) => l.recordId.equals(record.id))).get();
      expect(
        values.every(
          (v) =>
              v.verificationStatus == VerificationStatus.verified &&
              v.verifiedByStaffId == _colleagueId,
        ),
        isTrue,
      );
      expect(
        await reviews.resolve(id: review.id, staffId: _colleagueId, note: 'x'),
        _fails<ValidationFailure>(),
      );
    });

    test('a review can change owner but never lose one', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, _doctor);
      await _visit(c, db);
      final record = await fileLab(c);
      final reviews = c.read(resultReviewRepositoryProvider);
      final review = (await reviews.forRecord(record.id)).valueOrNull!;
      expect(
        await reviews.assign(id: review.id, ownerStaffId: ''),
        _fails<ValidationFailure>(),
      );
      // The owner hands over at shift change — a note is required.
      expect(
        await reviews.assign(id: review.id, ownerStaffId: _colleagueId),
        _fails<ValidationFailure>(),
      );
      final handed = (await reviews.assign(
        id: review.id,
        ownerStaffId: _colleagueId,
        note: 'Going off shift; repeat K pending.',
      )).valueOrNull!;
      expect(handed.ownerStaffId, _colleagueId);
      final audit = await (db.select(
        db.auditLog,
      )..where((a) => a.action.equals('result_review.handover'))).get();
      expect(audit, isNotEmpty);
    });

    test('an unowned patient import shows up for administrators', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final record =
          (await c
                  .read(recordRepositoryProvider)
                  .add(
                    NewRecord(
                      patientId: 'patient_001',
                      recordType: RecordType.labResult,
                      title: 'Outside lab',
                      occurredAt: DateTime(2026, 9, 2),
                      sourceFacility: 'Outside Lab Co.',
                      uploadedByPatient: true,
                      labValues: const [
                        NewLabValue(analyte: 'Ferritin', value: 9),
                      ],
                    ),
                  ))
              .valueOrNull!;
      expect(record.reviewStatus, ImportReviewStatus.pendingReview);
      await signInAs(c, 'admin@myhealth.demo');
      final attention =
          (await c
                  .read(resultReviewRepositoryProvider)
                  .openReviews(needsAttentionOnly: true))
              .valueOrNull!;
      final mine = attention.firstWhere((r) => r.recordId == record.id);
      expect(mine.status, ResultReviewStatus.unassigned);
    });
  });

  group('referrals keep an owner through handover', () {
    Future<ReferralRequest> pendingReferral(AppDatabase db) async {
      final row =
          await (db.select(db.referralRequests)
                ..where(
                  (r) => r.status.equalsValue(ReferralRequestStatus.pending),
                )
                ..limit(1))
              .getSingle();
      return ReferralRequest(
        id: row.id,
        patientId: row.patientId,
        requestedByStaffId: row.requestedByStaffId,
        reason: row.reason,
        status: row.status,
        createdAt: row.createdAt,
        version: row.version,
      );
    }

    test(
      'send → clarify → accept → arrange → close, with a shift change',
      () async {
        final (c, db) = await seededContainer();
        final referral = await pendingReferral(db);
        await signInAs(c, 'admin@myhealth.demo');
        final repo = c.read(referralRequestRepositoryProvider);

        expect(
          await repo.transition(
            id: referral.id,
            status: ReferralRequestStatus.closed,
            actorId: 'admin_01',
            ownerStaffId: 'admin_01',
          ),
          _fails<ValidationFailure>(),
        );
        expect(
          await repo.transition(
            id: referral.id,
            status: ReferralRequestStatus.accepted,
            actorId: 'admin_01',
            ownerStaffId: '',
          ),
          _fails<ValidationFailure>(),
        );

        final outboxBefore = await db.select(db.outboxEvents).get();
        await repo.transition(
          id: referral.id,
          status: ReferralRequestStatus.clarificationRequested,
          actorId: 'admin_01',
          ownerStaffId: 'admin_01',
          handoverNote: 'Which cardiology service — ECHO or EP?',
        );
        final outboxAfter = await db.select(db.outboxEvents).get();
        expect(outboxAfter.length, outboxBefore.length + 1);
        final notice =
            jsonDecode(outboxAfter.last.payload) as Map<String, Object?>;
        expect(notice['recipientId'], referral.requestedByStaffId);

        await repo.transition(
          id: referral.id,
          status: ReferralRequestStatus.accepted,
          actorId: 'admin_01',
          ownerStaffId: 'admin_01',
        );
        // Shift change: needs a note, and the owner can't be cleared.
        expect(
          await repo.handover(
            id: referral.id,
            actorId: 'admin_01',
            newOwnerId: _colleagueId,
            note: ' ',
          ),
          _fails<ValidationFailure>(),
        );
        expect(
          await repo.handover(
            id: referral.id,
            actorId: 'admin_01',
            newOwnerId: '',
            note: 'x',
          ),
          _fails<ValidationFailure>(),
        );
        final handed = (await repo.handover(
          id: referral.id,
          actorId: 'admin_01',
          newOwnerId: _colleagueId,
          note: 'Booking with the ECHO lab pending their callback.',
        )).valueOrNull!;
        expect(handed.ownerStaffId, _colleagueId);

        // Moving on with a different owner also needs a note.
        expect(
          await repo.transition(
            id: referral.id,
            status: ReferralRequestStatus.arranged,
            actorId: 'admin_01',
            ownerStaffId: 'admin_01',
          ),
          _fails<ValidationFailure>(),
        );
        final arranged = (await repo.transition(
          id: referral.id,
          status: ReferralRequestStatus.arranged,
          actorId: 'admin_01',
          ownerStaffId: _colleagueId,
        )).valueOrNull!;
        expect(arranged.ownerStaffId, _colleagueId);
        final closed = (await repo.transition(
          id: referral.id,
          status: ReferralRequestStatus.closed,
          actorId: 'admin_01',
          ownerStaffId: _colleagueId,
        )).valueOrNull!;
        expect(closed.status, ReferralRequestStatus.closed);
        expect(closed.ownerStaffId, isNotNull);
      },
    );
  });

  group('tasks and messages are owned work with cover', () {
    test(
      'a task escalates to a real colleague and closed tasks stay closed',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, _doctor);
        await db
            .into(db.staffTasks)
            .insert(
              StaffTasksCompanion.insert(
                id: 'task_p4',
                staffId: _doctorId,
                title: 'Chase repeat potassium',
                kind: TaskKind.followUpDue,
                patientId: const Value(_patientId),
              ),
            );
        final tasks = c.read(taskRepositoryProvider);
        expect(
          await tasks.escalate(
            id: 'task_p4',
            staffId: _doctorId,
            coverageStaffId: _doctorId,
            priority: WorkPriority.urgent,
          ),
          _fails<ValidationFailure>(),
        );
        expect(
          (await tasks.escalate(
            id: 'task_p4',
            staffId: _doctorId,
            coverageStaffId: _colleagueId,
            priority: WorkPriority.urgent,
          )).isOk,
          isTrue,
        );
        await signInAs(c, 'staff2@myhealth.demo');
        final workflow = c.read(taskWorkflowProvider);
        final pending = await workflow.pending(_colleagueId);
        await workflow.decide(
          _colleagueId,
          pending.single.bundle,
          accept: true,
        );
        final covered = (await tasks.forStaff(_colleagueId)).valueOrNull!;
        final task = covered.firstWhere((t) => t.id == 'task_p4');
        expect(task.coverageStaffId, _colleagueId);
        expect(task.priority, WorkPriority.urgent);
        await tasks.setStatus(
          id: 'task_p4',
          staffId: _colleagueId,
          status: TaskStatus.done,
          outcome: 'Reviewed source; recorded clinical decision in chart.',
        );
        expect(
          await tasks.setStatus(
            id: 'task_p4',
            staffId: _colleagueId,
            status: TaskStatus.open,
          ),
          _fails<AccessDeniedFailure>(),
        );
        await signInAs(c, _doctor);
        expect(
          await tasks.setStatus(
            id: 'task_p4',
            staffId: _doctorId,
            status: TaskStatus.open,
          ),
          _fails<ValidationFailure>(),
        );
      },
    );

    test('a message to an off-duty doctor gets cover and a reply-by time; '
        'the cover can answer it', () async {
      final (c, db) = await seededContainer();
      // Find a patient thread whose doctor we can send off shift.
      final thread = await (db.select(db.careMessages)..limit(1)).getSingle();
      final owner = thread.staffId;
      final ownerProfile = await (db.select(
        db.staffProfiles,
      )..where((s) => s.userId.equals(owner))).getSingle();
      await (db.update(
        db.staffProfiles,
      )..where((s) => s.userId.equals(owner))).write(
        const StaffProfilesCompanion(presence: Value(PresenceStatus.offShift)),
      );
      final colleague =
          await (db.select(db.staffProfiles)
                ..where(
                  (s) =>
                      s.departmentId.equalsNullable(ownerProfile.departmentId) &
                      s.userId.equals(owner).not(),
                )
                ..limit(1))
              .getSingle();
      await (db.update(
        db.staffProfiles,
      )..where((s) => s.userId.equals(colleague.userId))).write(
        const StaffProfilesCompanion(presence: Value(PresenceStatus.onDuty)),
      );
      final patient = await (db.select(
        db.users,
      )..where((u) => u.id.equals(thread.patientId))).getSingle();
      await signInAs(c, patient.email);
      final sent =
          (await c
                  .read(careMessageRepositoryProvider)
                  .send(
                    patientId: thread.patientId,
                    staffId: owner,
                    fromStaff: false,
                    body: 'Is it OK to take ibuprofen with my new tablets?',
                  ))
              .valueOrNull!;
      expect(sent.queueOwnerStaffId, owner);
      expect(sent.coverageStaffId, colleague.userId);
      expect(
        sent.responseDueAt!.difference(sent.sentAt),
        CareMessageQueue.responseWindow,
      );

      final coverEmail = (await (db.select(
        db.users,
      )..where((u) => u.id.equals(colleague.userId))).getSingle()).email;
      await signInAs(c, coverEmail);
      final messages = c.read(careMessageRepositoryProvider);
      final waiting = (await messages.awaitingReply(
        staffId: colleague.userId,
      )).valueOrNull!;
      expect(waiting.map((m) => m.id), contains(sent.id));
      final reply = await messages.send(
        patientId: thread.patientId,
        staffId: owner,
        fromStaff: true,
        body: 'Please avoid ibuprofen for now; paracetamol is fine.',
      );
      expect(reply.isOk, isTrue);
      final after = (await messages.awaitingReply(
        staffId: colleague.userId,
      )).valueOrNull!;
      expect(after.map((m) => m.id), isNot(contains(sent.id)));
    });
  });
}
