import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/task_workflow.dart';
import 'package:myhealthcare/domain/enums.dart';
import '../support/sessions.dart';

void main() {
  test('handover rejects mismatched source patients atomically', () async {
    final (c, db) = await seededContainer();
    await signInAs(c, 'staff1@myhealth.demo');
    await db
        .into(db.staffTasks)
        .insert(
          StaffTasksCompanion.insert(
            id: 'wrong-source',
            staffId: 'staff_01',
            patientId: const Value('patient_050'),
            title: 'Reply',
            kind: TaskKind.unreviewedAbnormalLab,
          ),
        );
    await db
        .into(db.careMessages)
        .insert(
          CareMessagesCompanion.insert(
            id: 'wrong-patient-message',
            patientId: 'patient_051',
            staffId: 'staff_01',
            fromStaff: false,
            body: 'Private message',
          ),
        );
    await db
        .into(db.taskSources)
        .insert(
          TaskSourcesCompanion.insert(
            taskId: 'wrong-source',
            sourceType: 'reply',
            sourceId: 'wrong-patient-message',
            episodeKey: 'wrong-source',
            recordedAt: DateTime.now(),
          ),
        );
    final workflow = c.read(taskWorkflowProvider);
    await workflow.offer(
      actor: 'staff_01',
      tasks: {'wrong-source': 1},
      recipient: 'staff_02',
      reason: 'Shift change',
      expires: DateTime.now().add(const Duration(hours: 4)),
    );
    await signInAs(c, 'staff2@myhealth.demo');
    final bundle = (await workflow.pending('staff_02')).single.bundle;
    await expectLater(
      workflow.decide('staff_02', bundle, accept: true),
      throwsA(isA<AccessDeniedFailure>()),
    );
    expect(
      (await (db.select(
            db.staffTasks,
          )..where((t) => t.id.equals('wrong-source'))).getSingle())
          .coverageStaffId,
      isNull,
    );
    expect(
      (await db.select(db.careTeamAssignments).get()).where(
        (a) => a.id.startsWith('task-cover-wrong-source-'),
      ),
      isEmpty,
    );
    expect(
      (await (db.select(
            db.careMessages,
          )..where((m) => m.id.equals('wrong-patient-message'))).getSingle())
          .coverageStaffId,
      isNull,
    );
  });
  Future<void> work(AppDatabase db, String id) => db
      .into(db.staffTasks)
      .insert(
        StaffTasksCompanion.insert(
          id: id,
          staffId: 'staff_01',
          patientId: const Value('patient_050'),
          title: 'Review result',
          kind: TaskKind.unreviewedAbnormalLab,
        ),
      )
      .then((_) {});

  test(
    'outcomes and paused work require reasons and future review; history is retained',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await work(db, 'outcome');
      final repo = c.read(taskRepositoryProvider);
      expect(
        (await repo.setStatus(
          id: 'outcome',
          staffId: 'staff_01',
          status: TaskStatus.done,
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await repo.setStatus(
          id: 'outcome',
          staffId: 'staff_01',
          status: TaskStatus.blocked,
          outcome: 'Awaiting report',
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await repo.setStatus(
          id: 'outcome',
          staffId: 'staff_01',
          status: TaskStatus.waiting,
          outcome: 'Awaiting report',
          reviewAt: DateTime.now().add(const Duration(hours: 4)),
        )).isOk,
        true,
      );
      expect(
        (await repo.forStaff(
          'staff_01',
          openOnly: true,
        )).valueOrNull!.any((t) => t.id == 'outcome'),
        true,
      );
      expect(
        (await repo.setStatus(
          id: 'outcome',
          staffId: 'staff_01',
          status: TaskStatus.done,
          outcome: 'Discussed result and plan with patient',
        )).isOk,
        true,
      );
      final history = await (db.select(
        db.taskHistory,
      )..where((h) => h.taskId.equals('outcome'))).get();
      expect(history.length, 2);
      expect(history.last.outcome, 'Discussed result and plan with patient');
      final audit =
          await (db.select(db.auditLog)..where(
                (a) =>
                    a.entityId.equals('outcome') &
                    a.action.equals('task.transition'),
              ))
              .get();
      expect(
        audit.any(
          (a) =>
              a.detail?.contains('Discussed result and plan with patient') ??
              false,
        ),
        false,
      );
      expect(
        (await repo.setStatus(
          id: 'outcome',
          staffId: 'staff_01',
          status: TaskStatus.open,
        )).isErr,
        true,
      );
    },
  );

  test(
    'bundle acceptance grants temporary access and closes only handover grants',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await work(db, 'cover-one');
      await work(db, 'cover-two');
      final workflow = c.read(taskWorkflowProvider);
      await workflow.offer(
        actor: 'staff_01',
        tasks: {'cover-one': 1, 'cover-two': 1},
        recipient: 'staff_02',
        reason: 'Please review urgent results during my shift change',
        expires: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(
        (await (db.select(
          db.staffTasks,
        )..where((t) => t.id.equals('cover-one'))).getSingle()).coverageStaffId,
        isNull,
      );
      expect(
        (await db.select(db.careTeamAssignments).get()).where(
          (a) => a.id.startsWith('task-cover-cover-one-'),
        ),
        isEmpty,
      );
      await signInAs(c, 'staff2@myhealth.demo');
      final offers = await workflow.pending('staff_02');
      expect(offers.single.count, 2);
      await workflow.decide('staff_02', offers.single.bundle, accept: true);
      expect(await workflow.pending('staff_02'), isEmpty);
      expect(
        (await c.read(taskRepositoryProvider).forStaff('staff_02')).valueOrNull!
            .where((t) => t.id.startsWith('cover-'))
            .length,
        2,
      );
      expect(
        (await c
                .read(taskRepositoryProvider)
                .setStatus(
                  id: 'cover-one',
                  staffId: 'staff_02',
                  status: TaskStatus.done,
                  outcome: 'Reviewed and recorded plan',
                ))
            .isOk,
        true,
      );
      final grants = await db.select(db.careTeamAssignments).get();
      expect(
        grants
            .singleWhere((a) => a.id.startsWith('task-cover-cover-one-'))
            .endedAt!
            .isAfter(DateTime.now()),
        false,
      );
      expect(
        grants
            .singleWhere((a) => a.id.startsWith('task-cover-cover-two-'))
            .endedAt!
            .isAfter(DateTime.now()),
        true,
      );
      await expectLater(
        workflow.decide('staff_02', offers.single.bundle, accept: true),
        throwsA(isA<ConflictFailure>()),
      );
    },
  );

  test(
    'changed work refuses the entire handover without partial grants',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await work(db, 'atomic-one');
      await work(db, 'atomic-two');
      final flow = c.read(taskWorkflowProvider);
      await flow.offer(
        actor: 'staff_01',
        tasks: {'atomic-one': 1, 'atomic-two': 1},
        recipient: 'staff_02',
        reason: 'Shift change',
        expires: DateTime.now().add(const Duration(hours: 4)),
      );
      await c
          .read(taskRepositoryProvider)
          .setStatus(
            id: 'atomic-two',
            staffId: 'staff_01',
            status: TaskStatus.inProgress,
          );
      await signInAs(c, 'staff2@myhealth.demo');
      final offer = (await flow.pending('staff_02')).single;
      await expectLater(
        flow.decide('staff_02', offer.bundle, accept: true),
        throwsA(isA<ConflictFailure>()),
      );
      expect(
        (await db.select(db.careTeamAssignments).get()).where(
          (a) => a.id.startsWith('task-cover-atomic-'),
        ),
        isEmpty,
      );
      expect(
        (await (db.select(
              db.staffTasks,
            )..where((t) => t.id.equals('atomic-one'))).getSingle())
            .coverageStaffId,
        isNull,
      );
    },
  );

  test(
    'expired cover cannot act even when another care relationship remains',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await work(db, 'expiry');
      await db
          .into(db.medicalRecords)
          .insert(
            MedicalRecordsCompanion.insert(
              id: 'expiry-result',
              patientId: 'patient_050',
              authorStaffId: const Value('staff_01'),
              recordType: RecordType.labResult,
              title: 'Cover review',
              occurredAt: DateTime.now(),
            ),
          );
      await db
          .into(db.resultReviews)
          .insert(
            ResultReviewsCompanion.insert(
              id: 'expiry-review',
              recordId: 'expiry-result',
              ownerStaffId: const Value('staff_01'),
              status: const Value(ResultReviewStatus.assigned),
              dueAt: DateTime.now(),
            ),
          );
      await db
          .into(db.taskSources)
          .insert(
            TaskSourcesCompanion.insert(
              taskId: 'expiry',
              sourceType: 'result',
              sourceId: 'expiry-review',
              episodeKey: 'expiry',
              recordedAt: DateTime.now(),
            ),
          );
      final flow = c.read(taskWorkflowProvider);
      await flow.offer(
        actor: 'staff_01',
        tasks: {'expiry': 1},
        recipient: 'staff_02',
        reason: 'Cover review',
        expires: DateTime.now().add(const Duration(hours: 4)),
      );
      await signInAs(c, 'staff2@myhealth.demo');
      await flow.decide(
        'staff_02',
        (await flow.pending('staff_02')).single.bundle,
        accept: true,
      );
      final grant = (await db.select(db.careTeamAssignments).get()).singleWhere(
        (a) => a.id.startsWith('task-cover-expiry-'),
      );
      await (db.update(
        db.careTeamAssignments,
      )..where((a) => a.id.equals(grant.id))).write(
        CareTeamAssignmentsCompanion(
          endedAt: Value(DateTime.now().subtract(const Duration(seconds: 1))),
        ),
      );
      expect(
        (await c
                .read(taskRepositoryProvider)
                .setStatus(
                  id: 'expiry',
                  staffId: 'staff_02',
                  status: TaskStatus.done,
                  outcome: 'Attempt after expiry',
                ))
            .failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      await expectLater(
        flow.context('expiry', 'staff_02'),
        throwsA(isA<AccessDeniedFailure>()),
      );
      expect(
        (await c
                .read(resultReviewRepositoryProvider)
                .startReview(id: 'expiry-review', staffId: 'staff_02'))
            .failureOrNull,
        isA<AccessDeniedFailure>(),
      );
    },
  );

  test(
    'source generation and reply conversion retain final outcomes and deadlines',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await db
          .into(db.careMessages)
          .insert(
            CareMessagesCompanion.insert(
              id: 'reply-episode',
              patientId: 'patient_050',
              staffId: 'staff_01',
              fromStaff: false,
              body: 'Please review my results',
              queueOwnerStaffId: const Value('staff_01'),
              responseDueAt: Value(
                DateTime.now().subtract(const Duration(hours: 1)),
              ),
            ),
          );
      final flow = c.read(taskWorkflowProvider);
      final id = await flow.replyTask('staff_01', 'reply-episode');
      final before = await (db.select(
        db.staffTasks,
      )..where((t) => t.id.equals(id))).getSingle();
      await c
          .read(taskRepositoryProvider)
          .setStatus(
            id: id,
            staffId: 'staff_01',
            status: TaskStatus.dismissed,
            outcome: 'Duplicate channel; discussion recorded in consultation',
          );
      await flow.generate('staff_01');
      expect(await flow.replyTask('staff_01', 'reply-episode'), id);
      final after = await (db.select(
        db.staffTasks,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(after.status, TaskStatus.dismissed);
      expect(after.dueAt, before.dueAt);
      expect(
        (await (db.select(
          db.taskSources,
        )..where((s) => s.sourceId.equals('reply-episode'))).get()).length,
        1,
      );
    },
  );

  test('time off enforces ownership and delivers notices atomically', () async {
    final (c, db) = await seededContainer();
    await signInAs(c, 'staff1@myhealth.demo');
    final visit =
        (await (db.select(db.appointments)..where(
                  (a) =>
                      a.staffId.equals('staff_01') &
                      a.status.isNotIn(['completed', 'cancelled', 'noShow']),
                ))
                .get())
            .first;
    final repo = c.read(appointmentRepositoryProvider);
    final denied = await repo.addAvailabilityException(
      staffId: 'staff_02',
      start: visit.slotStart,
      end: visit.slotEnd,
      reason: 'Test',
    );
    expect(denied.failureOrNull, isA<AccessDeniedFailure>());
    final saved = await repo.addAvailabilityException(
      staffId: 'staff_01',
      start: visit.slotStart,
      end: visit.slotEnd,
      reason: 'Time off',
    );
    expect(saved.isOk, true);
    final notices =
        await (db.select(db.notifications)..where(
              (n) => n.sourceEventId.equals(
                'availability:${saved.valueOrNull!.id}:${visit.id}',
              ),
            ))
            .get();
    expect(notices.length, 1);
    expect(
      (await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(visit.id))).getSingle()).staffId,
      'staff_01',
    );
  });

  test(
    'results, drafts, referrals and document approvals generate once and preserve reassigned ownership',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final visit =
          (await (db.select(db.appointments)..where(
                    (a) =>
                        a.staffId.equals('staff_01') &
                        a.patientId.equals('patient_050'),
                  ))
                  .get())
              .first;
      await db
          .into(db.medicalRecords)
          .insert(
            MedicalRecordsCompanion.insert(
              id: 'generation-result',
              patientId: visit.patientId,
              appointmentId: Value(visit.id),
              authorStaffId: const Value('staff_01'),
              recordType: RecordType.labResult,
              title: 'Result for clinician review',
              occurredAt: DateTime.now(),
            ),
          );
      await db
          .into(db.resultReviews)
          .insert(
            ResultReviewsCompanion.insert(
              id: 'generation-review',
              recordId: 'generation-result',
              ownerStaffId: const Value('staff_01'),
              dueAt: DateTime.now(),
              priority: const Value(WorkPriority.urgent),
            ),
          );
      await db
          .into(db.encounterDrafts)
          .insertOnConflictUpdate(
            EncounterDraftsCompanion.insert(
              appointmentId: visit.id,
              patientId: visit.patientId,
              authorStaffId: 'staff_01',
              note: const Value('Unsaved signature; clinical draft preserved'),
            ),
          );
      await db
          .into(db.referralRequests)
          .insert(
            ReferralRequestsCompanion.insert(
              id: 'generation-referral',
              patientId: visit.patientId,
              requestedByStaffId: 'staff_01',
              reason: 'Coordinate referral review',
            ),
          );
      await db
          .into(db.documentTemplates)
          .insert(
            DocumentTemplatesCompanion.insert(
              id: 'generation-template',
              documentType: 'attendanceConfirmation',
              version: 1,
              language: 'en',
              disclosureProfile: 'employer',
              wording: 'Proposed wording',
              clinicalSignatureRequired: false,
            ),
          );
      await db
          .into(db.documentRequests)
          .insert(
            DocumentRequestsCompanion.insert(
              id: 'generation-document',
              patientId: visit.patientId,
              appointmentId: Value(visit.id),
              templateId: 'generation-template',
              requestedBy: 'staff_01',
              status: const Value('submitted'),
              contentJson: '{}',
              idempotencyKey: 'generation-document',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      final flow = c.read(taskWorkflowProvider);
      await flow.generate('staff_01');
      final links = await db.select(db.taskSources).get();
      for (final source in [
        'generation-review',
        visit.id,
        'generation-referral',
        'generation-document',
      ]) {
        expect(links.where((s) => s.sourceId == source).length, 1);
      }
      final link = links.singleWhere((s) => s.sourceId == 'generation-review');
      final original = await (db.select(
        db.staffTasks,
      )..where((t) => t.id.equals(link.taskId))).getSingle();
      await (db.update(db.staffTasks)..where((t) => t.id.equals(link.taskId)))
          .write(const StaffTasksCompanion(staffId: Value('staff_02')));
      await flow.generate('staff_01');
      final after = await (db.select(
        db.staffTasks,
      )..where((t) => t.id.equals(link.taskId))).getSingle();
      expect(after.staffId, 'staff_02');
      expect(after.dueAt, original.dueAt);
      expect(
        (await (db.select(
          db.taskSources,
        )..where((s) => s.sourceId.equals('generation-review'))).get()).length,
        1,
      );
    },
  );

  test(
    'team reassignment requires a live grant and clinical access, including at acceptance',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await db
          .into(db.staffTasks)
          .insert(
            StaffTasksCompanion.insert(
              id: 'team-work',
              staffId: 'staff_02',
              patientId: const Value('patient_050'),
              title: 'Assigned clinical review',
              kind: TaskKind.other,
            ),
          );
      final flow = c.read(taskWorkflowProvider);
      expect(await flow.team('staff_01'), isEmpty);
      final admin = (await (db.select(
        db.users,
      )..where((u) => u.role.equalsValue(UserRole.admin))).get()).first;
      await db
          .into(db.scopedGrants)
          .insert(
            ScopedGrantsCompanion.insert(
              id: 'assign-team-test',
              accountId: 'staff_01',
              permission: 'assignOperationalWork',
              scope: 'patient',
              scopeId: 'patient_050',
              grantedBy: admin.id,
              startsAt: DateTime.now().subtract(const Duration(minutes: 1)),
              reason: 'Test explicit coordinator grant',
            ),
          );
      expect(
        (await flow.team('staff_01')).any((t) => t.id == 'team-work'),
        true,
      );
      await flow.offer(
        actor: 'staff_01',
        tasks: {'team-work': 1},
        recipient: 'staff_03',
        reason: 'Coordinator reassignment',
        expires: DateTime.now().add(const Duration(hours: 4)),
        reassign: true,
      );
      await (db.update(db.scopedGrants)
            ..where((g) => g.id.equals('assign-team-test')))
          .write(ScopedGrantsCompanion(revokedAt: Value(DateTime.now())));
      await signInAs(c, 'staff3@myhealth.demo');
      final offer = (await flow.pending('staff_03')).single;
      await expectLater(
        flow.decide('staff_03', offer.bundle, accept: true),
        throwsA(isA<AccessDeniedFailure>()),
      );
      expect(
        (await (db.select(
          db.staffTasks,
        )..where((t) => t.id.equals('team-work'))).getSingle()).staffId,
        'staff_02',
      );
      expect(
        (await db.select(db.careTeamAssignments).get()).where(
          (a) => a.id.startsWith('task-cover-team-work-'),
        ),
        isEmpty,
      );
    },
  );
}
