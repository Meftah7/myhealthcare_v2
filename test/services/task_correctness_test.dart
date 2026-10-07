import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/presentation/feedback.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';
import 'package:myhealthcare/domain/repositories/task_repository.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/l10n/app_localizations_ar.dart';
import 'package:myhealthcare/l10n/app_localizations_en.dart';
import 'package:myhealthcare/services/auth/access_policy.dart';
import 'package:myhealthcare/services/rules/task_generator.dart';

import '../support/sessions.dart';

RiskFlag flag(String patientId, {String key = 'episode-1'}) => RiskFlag(
  id: 'flag_$key',
  patientId: patientId,
  kind: RiskFlagKind.abnormalLab,
  severity: Severity.urgent,
  rationale: 'Private clinical reason',
  detectedAt: DateTime(2026),
  source: FlagSource.rule,
  dedupeKey: '$patientId:$key',
);

StaffTask task(
  String id, {
  String staffId = 'staff_01',
  String? patientId,
  WorkPriority priority = WorkPriority.routine,
  DateTime? dueAt,
  double score = 0,
}) => StaffTask(
  id: id,
  staffId: staffId,
  patientId: patientId,
  title: 'Review private result',
  kind: TaskKind.unreviewedAbnormalLab,
  status: TaskStatus.open,
  ruleScore: score,
  createdAt: DateTime(2026),
  priority: priority,
  dueAt: dueAt,
);

/// Inject a failed second write while retaining real persistence for the first.
class FailingTasks implements TaskRepository {
  FailingTasks(this.delegate, {this.failAt = 2});
  final TaskRepository delegate;
  final int failAt;
  int writes = 0;
  static const failure = ConflictFailure('Task changed. Reload.');

  @override
  Future<Result<void>> upsert(StaffTask task) async =>
      ++writes == failAt ? const Err(failure) : delegate.upsert(task);

  @override
  Future<Result<List<StaffTask>>> forStaff(
    String staffId, {
    bool openOnly = false,
  }) => delegate.forStaff(staffId, openOnly: openOnly);

  @override
  Future<Result<void>> applyAiPriority({
    required String id,
    required String staffId,
    required double score,
    required String rationale,
    int? expectedVersion,
  }) async => ++writes == failAt
      ? const Err(failure)
      : delegate.applyAiPriority(
          id: id,
          staffId: staffId,
          score: score,
          rationale: rationale,
          expectedVersion: expectedVersion,
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('partial completion feedback keeps Reload in English and Arabic', () {
    final failure = PartialOperationFailure(
      completed: 1,
      total: 2,
      failure: FailingTasks.failure,
    );
    for (final locale in [AppLocalizationsEn(), AppLocalizationsAr()]) {
      final feedback = describeFailure(locale, failure);
      expect(feedback.action, RecoveryAction.reload);
      expect(feedback.message, contains(locale.partialOperationProgress(1, 2)));
    }
  });

  for (final status in [TaskStatus.done, TaskStatus.dismissed]) {
    test(
      'regeneration preserves $status, deadline, AI, owner and cover',
      () async {
        final (c, db) = await seededContainer();
        final repo = TaskRepositoryImpl(db);
        final generator = TaskGenerator(
          tasks: repo,
          risk: RiskRepositoryImpl(db),
        );
        final source = flag('patient_001');
        expect(
          (await generator.generateFor(
            staffId: 'staff_01',
            flags: [source],
          )).isOk,
          true,
        );
        final original = (await repo.forStaff(
          'staff_01',
        )).valueOrNull!.firstWhere((t) => t.id.startsWith('task_staff_01_'));
        expect(original.priority, WorkPriority.urgent);
        expect(
          (await repo.applyAiPriority(
            id: original.id,
            staffId: original.staffId,
            score: 0.7,
            rationale: 'Retain this rationale',
          )).isOk,
          true,
        );
        expect(
          (await repo.escalate(
            id: original.id,
            staffId: original.staffId,
            coverageStaffId: 'staff_02',
            priority: WorkPriority.urgent,
          )).isOk,
          true,
        );
        expect(
          (await repo.setStatus(
            id: original.id,
            staffId: original.staffId,
            status: status,
          )).isOk,
          true,
        );
        final before = (await repo.forStaff(
          'staff_01',
        )).valueOrNull!.firstWhere((t) => t.id == original.id);
        expect(
          (await generator.generateFor(
            staffId: 'staff_01',
            flags: [
              source.copyWith(
                detectedAt: DateTime(2026, 9),
                severity: Severity.warning,
              ),
            ],
          )).isOk,
          true,
        );
        final after = (await repo.forStaff(
          'staff_01',
        )).valueOrNull!.firstWhere((t) => t.id == original.id);
        expect(after.status, status);
        expect(after.dueAt, before.dueAt);
        expect(after.createdAt, before.createdAt);
        expect(after.staffId, before.staffId);
        expect(after.coverageStaffId, before.coverageStaffId);
        expect(after.escalatedAt, before.escalatedAt);
        expect(after.priority, WorkPriority.urgent);
        expect(after.aiPriorityScore, before.aiPriorityScore);
        expect(after.aiRationale, before.aiRationale);
        expect(after.ruleScore, 0.6);
        await generator.generateFor(
          staffId: 'staff_01',
          flags: [flag('patient_001', key: 'episode-2')],
        );
        expect(
          (await repo.forStaff(
            'staff_01',
          )).valueOrNull!.where((t) => t.id.startsWith('task_staff_01_')),
          hasLength(2),
        );
      },
    );
  }

  test('urgency precedes deadline and AI; ties have stable IDs', () {
    final items = [
      task('z', score: 1),
      task('b', score: 1),
      task('overdue', dueAt: DateTime(2025)),
      task('urgent', priority: WorkPriority.urgent, dueAt: DateTime(2030)),
      task('priority', priority: WorkPriority.priority),
    ]..sort((a, b) => compareStaffTasks(a, b, aiWeight: 1));
    expect(items.map((t) => t.id), ['urgent', 'priority', 'overdue', 'b', 'z']);
  });

  test(
    'generation returns original failure or explicit partial completion',
    () async {
      final (c, db) = await seededContainer();
      final repo = TaskRepositoryImpl(db);
      final failing = FailingTasks(repo);
      final result =
          await TaskGenerator(
            tasks: failing,
            risk: RiskRepositoryImpl(db),
          ).generateFor(
            staffId: 'staff_01',
            flags: [
              flag('patient_001'),
              flag('patient_001', key: 'episode-2'),
            ],
          );
      final failure = result.failureOrNull as PartialOperationFailure;
      expect(failure.completed, 1);
      expect(failure.total, 2);
      expect(failure.failure, same(FailingTasks.failure));
      final firstFailure = await TaskGenerator(
        tasks: FailingTasks(repo, failAt: 1),
        risk: RiskRepositoryImpl(db),
      ).generateFor(staffId: 'staff_01', flags: [flag('patient_001')]);
      expect(firstFailure.failureOrNull, same(FailingTasks.failure));
    },
  );

  test(
    'panel/flags/generation exclude unrelated patients; persistence rejects bypass',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final visible = (await c
          .read(accessPolicyProvider)
          .clinicallyVisiblePatientIds())!;
      final patients = await (db.select(
        db.users,
      )..where((u) => u.role.equalsValue(UserRole.patient))).get();
      final related = visible.first;
      final unrelated = patients.firstWhere((p) => !visible.contains(p.id)).id;
      final rawRisk = RiskRepositoryImpl(db);
      await rawRisk.upsertByDedupeKey(flag(related));
      await rawRisk.upsertByDedupeKey(flag(unrelated, key: 'other-panel'));
      final scoped =
          (await c.read(riskRepositoryProvider).unacknowledged()).valueOrNull!;
      expect(scoped.every((f) => visible.contains(f.patientId)), true);
      expect(scoped.any((f) => f.patientId == unrelated), false);
      final panel = await c.read(staffPanelProvider.future);
      expect(panel.every((p) => visible.contains(p.id)), true);
      final denied = await c
          .read(taskRepositoryProvider)
          .upsert(task('bypass', patientId: unrelated));
      expect(denied.failureOrNull, isA<AccessDeniedFailure>());
      final generator = c.read(taskGeneratorProvider);
      expect(
        (await generator.generateFor(staffId: 'staff_01', flags: scoped)).isOk,
        true,
      );
      final tasks = (await c.read(taskRepositoryProvider).forStaff('staff_01'))
          .valueOrNull!;
      expect(
        tasks
            .where((t) => t.patientId != null)
            .every((t) => visible.contains(t.patientId)),
        true,
      );
    },
  );

  test(
    'assignment-only care permits acknowledgement and expiry blocks later access',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final visible = (await c
          .read(accessPolicyProvider)
          .clinicallyVisiblePatientIds())!;
      final patients = await (db.select(
        db.users,
      )..where((u) => u.role.equalsValue(UserRole.patient))).get();
      final patientId = patients.firstWhere((p) => !visible.contains(p.id)).id;
      await db
          .into(db.careTeamAssignments)
          .insert(
            CareTeamAssignmentsCompanion.insert(
              id: 'temporary',
              patientId: patientId,
              staffId: 'staff_01',
              role: CareTeamRole.primaryClinician,
              assignedAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          );
      await RiskRepositoryImpl(db).upsertByDedupeKey(flag(patientId));
      expect(
        (await c
                .read(riskRepositoryProvider)
                .acknowledge(id: 'flag_episode-1', staffId: 'staff_01'))
            .isOk,
        true,
      );
      expect(
        (await c
                .read(taskRepositoryProvider)
                .upsert(task('temporary-task', patientId: patientId)))
            .isOk,
        true,
      );
      await (db.update(
        db.careTeamAssignments,
      )..where((a) => a.id.equals('temporary'))).write(
        CareTeamAssignmentsCompanion(
          endedAt: Value(DateTime.now().subtract(const Duration(seconds: 1))),
        ),
      );
      switch (await c.read(taskRepositoryProvider).forStaff('staff_01')) {
        case Ok(:final value):
          expect(value.any((t) => t.id == 'temporary-task'), false);
        case Err(:final failure):
          expect(failure, isA<AuthFailure>());
      }
      expect(
        (await c
                .read(taskRepositoryProvider)
                .setStatus(
                  id: 'temporary-task',
                  staffId: 'staff_01',
                  status: TaskStatus.done,
                ))
            .failureOrNull,
        isA<AuthFailure>(),
      );
    },
  );

  test(
    'admin sees operational tasks without clinical details or flag rationale',
    () async {
      final (c, db) = await seededContainer();
      await TaskRepositoryImpl(
        db,
      ).upsert(task('private', patientId: 'patient_001'));
      await RiskRepositoryImpl(db).upsertByDedupeKey(flag('patient_001'));
      await signInAs(c, 'admin@myhealth.demo');
      final metadata =
          (await c.read(taskRepositoryProvider).forStaff('staff_01'))
              .valueOrNull!
              .firstWhere((t) => t.id == 'private');
      expect(metadata.patientId, isNull);
      expect(metadata.title, 'Clinical task');
      expect(metadata.aiRationale, isNull);
      expect(metadata.staffId, 'staff_01');
      expect(
        (await c.read(riskRepositoryProvider).unacknowledged()).valueOrNull,
        isEmpty,
      );
    },
  );

  test(
    'ranker propagates conflict and does not report a completed batch',
    () async {
      final (c, db) = await seededContainer(
        overrides: [
          taskRepositoryProvider.overrideWith(
            (ref) => FailingTasks(
              TaskRepositoryImpl(
                ref.watch(appDatabaseProvider),
                access: ref.watch(accessPolicyProvider),
              ),
            ),
          ),
        ],
      );
      await signInAs(c, 'staff1@myhealth.demo');
      final repo = TaskRepositoryImpl(db, access: c.read(accessPolicyProvider));
      await repo.upsert(task('rank-a'));
      await repo.upsert(task('rank-b'));
      await expectLater(
        c.read(staffOpsProvider).prioritiseWithAi(),
        throwsA(
          isA<PartialOperationFailure>().having(
            (f) => f.failure,
            'cause',
            isA<ConflictFailure>(),
          ),
        ),
      );
    },
  );

  test(
    'profile demotion narrows permissions without another sign-in',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      expect(
        (await c.read(accessPolicyProvider).principal())!.can(
          Permission.prescribe,
        ),
        true,
      );
      await (db.update(db.staffProfiles)
            ..where((p) => p.userId.equals('staff_01')))
          .write(const StaffProfilesCompanion(jobTitle: Value(kNurseJobTitle)));
      final denied = await Result.guardAsync(
        () => c.read(accessPolicyProvider).require(Permission.prescribe),
      );
      expect(denied.failureOrNull, isA<AuthFailure>());
    },
  );

  test(
    'live queries reauthorize each emission and close after denial',
    () async {
      final source = StreamController<int>.broadcast();
      addTearDown(source.close);
      var allowed = true;
      final first = Completer<void>();
      final done = Completer<void>();
      final events = <int>[];
      final errors = <Object>[];
      final subscription =
          authorizedStream(() async {
            if (!allowed) throw const AccessDeniedFailure();
          }, () => source.stream).listen(
            (value) {
              events.add(value);
              if (!first.isCompleted) first.complete();
            },
            onError: errors.add,
            onDone: done.complete,
          );
      addTearDown(subscription.cancel);
      source.add(1);
      await first.future.timeout(const Duration(seconds: 5));
      allowed = false;
      source.add(2);
      await done.future.timeout(const Duration(seconds: 5));
      expect(events, [1]);
      expect(errors.single, isA<AccessDeniedFailure>());
    },
  );
}
