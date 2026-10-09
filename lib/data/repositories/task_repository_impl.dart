/// Drift-backed [TaskRepository] + [RiskRepository] (P1-16).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/task_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'task_cover.dart';
import 'task_workflow.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  Future<void> _ownTasks(String staffId) async {
    await _access.requireStaffOrAdmin(entityType: 'task');
    await _access.selfOrAdmin(
      staffId,
      Permission.viewOperationalReports,
      entityType: 'task',
    );
  }

  Future<List<StaffTask>> _visibleTasks(List<StaffTaskRow> rows) async {
    final visible = await _access.clinicallyVisiblePatientIds();
    final principal = await _access.principal();
    final eligible = <StaffTaskRow>[];
    for (final row in rows) {
      if (principal?.isStaff == true &&
          row.staffId != principal!.accountId &&
          !await activeTaskCover(_db, row.id, principal.accountId)) {
        continue;
      }
      eligible.add(row);
    }
    return [
      for (final row in eligible)
        if (row.patientId == null ||
            visible == null ||
            visible.contains(row.patientId))
          row.toEntity()
        else if (principal?.isAdmin ?? false)
          row.toEntity().copyWith(
            patientId: null,
            title: 'Clinical task',
            kind: TaskKind.other,
            aiRationale: null,
            aiPriorityScore: null,
            ruleScore: 0,
          ),
    ];
  }

  SimpleSelectStatement<$StaffTasksTable, StaffTaskRow> _query(
    String staffId, {
    bool openOnly = false,
  }) {
    final q = _db.select(_db.staffTasks)
      ..where(
        (t) => t.staffId.equals(staffId) | t.coverageStaffId.equals(staffId),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.ruleScore),
        (t) => OrderingTerm(expression: t.dueAt),
      ]);
    if (openOnly) {
      q.where(
        (t) =>
            t.status.equalsValue(TaskStatus.open) |
            t.status.equalsValue(TaskStatus.inProgress) |
            t.status.equalsValue(TaskStatus.waiting) |
            t.status.equalsValue(TaskStatus.blocked),
      );
    }
    return q;
  }

  @override
  Future<Result<List<StaffTask>>> forStaff(
    String staffId, {
    bool openOnly = false,
  }) {
    return Result.guardAsync(() async {
      await _ownTasks(staffId);
      final rows = await _query(staffId, openOnly: openOnly).get();
      return _visibleTasks(rows);
    });
  }

  @override
  Stream<List<StaffTask>> watchForStaff(
    String staffId, {
    bool openOnly = false,
  }) {
    return authorizedStream(
      () => _ownTasks(staffId),
      () => _query(staffId, openOnly: openOnly).watch().asyncMap(_visibleTasks),
    );
  }

  @override
  Future<Result<void>> upsert(StaffTask task, {String? sourceId}) {
    return Result.guardAsync(() async {
      if (!task.ruleScore.isFinite ||
          task.ruleScore < 0 ||
          task.ruleScore > 1) {
        throw const ValidationFailure(
          'Task scores must be finite and between zero and one.',
        );
      }
      if (task.patientId != null) {
        await _access.clinicalWrite(
          staffId: task.staffId,
          patientId: task.patientId!,
          permission: Permission.manageTasks,
          entityType: 'task',
          entityId: task.id,
        );
      } else {
        await _access.actAsStaff(
          task.staffId,
          Permission.manageTasks,
          entityType: 'task',
          entityId: task.id,
        );
      }
      await _db.transaction(() async {
        if (sourceId != null) {
          final linked =
              await (_db.select(_db.taskSources)..where(
                    (s) =>
                        s.sourceType.equals('risk') &
                        s.sourceId.equals(sourceId),
                  ))
                  .get();
          if (linked.isNotEmpty) {
            final canonical = await (_db.select(
              _db.staffTasks,
            )..where((t) => t.id.equals(linked.first.taskId))).getSingle();
            if (canonical.id != task.id || canonical.staffId != task.staffId) {
              return;
            }
          }
        }
        final existing = await (_db.select(
          _db.staffTasks,
        )..where((t) => t.id.equals(task.id))).getSingleOrNull();
        if (existing != null) {
          if (existing.staffId != task.staffId ||
              existing.patientId != task.patientId) {
            throw const AccessDeniedFailure();
          }
          if (sourceId != null) {
            await _db
                .into(_db.taskSources)
                .insertOnConflictUpdate(
                  TaskSourcesCompanion.insert(
                    taskId: task.id,
                    sourceType: 'risk',
                    sourceId: sourceId,
                    episodeKey: sourceId,
                    recordedAt: DateTime.now(),
                  ),
                );
          }
          // Regeneration may refresh source fields, never clinician work.
          final priority = existing.priority.index >= task.priority.index
              ? existing.priority
              : task.priority;
          if (existing.title != task.title ||
              existing.kind != task.kind ||
              existing.ruleScore != task.ruleScore ||
              existing.priority != priority) {
            await (_db.update(
              _db.staffTasks,
            )..where((t) => t.id.equals(task.id))).write(
              StaffTasksCompanion(
                title: Value(task.title),
                kind: Value(task.kind),
                ruleScore: Value(task.ruleScore),
                priority: Value(priority),
              ),
            );
          }
          return;
        }
        if (task.status != TaskStatus.open) {
          throw const ValidationFailure(
            'New work must start open; record later decisions through a task transition.',
          );
        }
        await _db
            .into(_db.staffTasks)
            .insert(
              StaffTasksCompanion.insert(
                id: task.id,
                staffId: task.staffId,
                title: task.title,
                kind: task.kind,
                status: Value(task.status),
                ruleScore: Value(task.ruleScore),
                patientId: Value(task.patientId),
                dueAt: Value(task.dueAt),
                priority: Value(task.priority),
                coverageStaffId: Value(task.coverageStaffId),
                escalatedAt: Value(task.escalatedAt),
                aiPriorityScore: Value(task.aiPriorityScore),
                aiRationale: Value(task.aiRationale),
                createdAt: Value(task.createdAt),
              ),
            );
        if (sourceId != null) {
          await _db
              .into(_db.taskSources)
              .insert(
                TaskSourcesCompanion.insert(
                  taskId: task.id,
                  sourceType: 'risk',
                  sourceId: sourceId,
                  episodeKey: sourceId,
                  recordedAt: DateTime.now(),
                ),
              );
        }
      });
    });
  }

  @override
  Future<Result<void>> setStatus({
    required String id,
    required String staffId,
    required TaskStatus status,
    int? expectedVersion,
    String? outcome,
    DateTime? reviewAt,
  }) => Result.guardAsync(() async {
    await _access.actAsStaff(
      staffId,
      Permission.manageTasks,
      entityType: 'task',
      entityId: id,
    );
    await _db.transaction(() async {
      final task = await (_db.select(
        _db.staffTasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (task == null ||
          (task.staffId != staffId && task.coverageStaffId != staffId)) {
        throw const AccessDeniedFailure('Task ownership is required.');
      }
      if (task.staffId != staffId && !await activeTaskCover(_db, id, staffId)) {
        throw const AccessDeniedFailure('Cover has expired.');
      }
      if (task.patientId != null) {
        await _access.readPatient(
          task.patientId!,
          entityType: 'task',
          entityId: id,
        );
      }
      if (expectedVersion != null && expectedVersion != task.version) {
        throw ConflictFailure(
          'Task changed. Reload it.',
          currentVersion: task.version,
        );
      }
      if (task.status == status) return;
      if (task.status == TaskStatus.done ||
          task.status == TaskStatus.dismissed) {
        throw const ValidationFailure(
          'Closed work cannot be reopened. Create a new source episode.',
        );
      }
      final needsReason = {
        TaskStatus.done,
        TaskStatus.dismissed,
        TaskStatus.waiting,
        TaskStatus.blocked,
      }.contains(status);
      if (needsReason &&
          (outcome == null ||
              outcome.trim().isEmpty ||
              outcome.length > 2000)) {
        throw const ValidationFailure(
          'Record the outcome or reason (up to 2000 characters).',
        );
      }
      if ({TaskStatus.waiting, TaskStatus.blocked}.contains(status) &&
          (reviewAt == null || !reviewAt.isAfter(DateTime.now()))) {
        throw const ValidationFailure(
          'Waiting or blocked work needs a future review time and an accountable owner.',
        );
      }
      final changed =
          await (_db.update(
                _db.staffTasks,
              )..where((t) => t.id.equals(id) & t.version.equals(task.version)))
              .write(StaffTasksCompanion(status: Value(status)));
      if (changed != 1) throw const ConflictFailure('Task changed. Reload it.');
      final before = {
        'status': task.status.name,
        'owner': task.staffId,
        'cover': task.coverageStaffId,
      };
      final after = {
        ...before,
        'status': status.name,
        'reviewAt': {TaskStatus.waiting, TaskStatus.blocked}.contains(status)
            ? reviewAt!.toUtc().toIso8601String()
            : null,
      };
      await _db
          .into(_db.taskHistory)
          .insert(
            TaskHistoryCompanion.insert(
              id: const Uuid().v4(),
              taskId: id,
              actorAccountId: Value(
                (await _access.principal())?.accountId ?? staffId,
              ),
              action: 'task.transition',
              beforeJson: jsonEncode(before),
              afterJson: jsonEncode(after),
              outcome: Value(outcome?.trim()),
              at: DateTime.now(),
            ),
          );
      await _access.audit(
        'task.transition',
        entityType: 'staff_task',
        entityId: id,
        subjectPatientId: task.patientId,
        detail: jsonEncode({
          ...after,
          'outcomeRecorded': outcome?.trim().isNotEmpty ?? false,
        }),
      );
      if ({TaskStatus.done, TaskStatus.dismissed}.contains(status)) {
        // Only handover-specific care access is removed; pre-existing care is retained.
        final assignments = await _db.select(_db.careTeamAssignments).get();
        for (final assignment in assignments.where(
          (a) => a.id.startsWith('task-cover-$id-'),
        )) {
          await (_db.update(
            _db.careTeamAssignments,
          )..where((c) => c.id.equals(assignment.id))).write(
            CareTeamAssignmentsCompanion(endedAt: Value(DateTime.now())),
          );
        }
      }
    });
  });

  @override
  Future<Result<void>> applyAiPriority({
    required String id,
    required String staffId,
    required double score,
    required String rationale,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      if (!score.isFinite || score < 0 || score > 1) {
        throw const ValidationFailure(
          'Task scores must be finite and between zero and one.',
        );
      }
      await _access.actAsStaff(
        staffId,
        Permission.runConsultation,
        entityType: 'task',
        entityId: id,
      );
      final task =
          await (_db.select(_db.staffTasks)
                ..where((t) => t.id.equals(id) & t.staffId.equals(staffId)))
              .getSingleOrNull();
      if (task?.patientId != null) {
        await _access.readPatient(
          task!.patientId!,
          entityType: 'task',
          entityId: id,
        );
      }
      final updated =
          await (_db.update(_db.staffTasks)..where(
                (t) =>
                    t.id.equals(id) &
                    t.staffId.equals(staffId) &
                    (expectedVersion == null
                        ? const Constant(true)
                        : t.version.equals(expectedVersion)),
              ))
              .write(
                StaffTasksCompanion(
                  aiPriorityScore: Value(score),
                  aiRationale: Value(rationale),
                ),
              );
      if (updated != 1) {
        final current =
            await (_db.select(_db.staffTasks)
                  ..where((t) => t.id.equals(id) & t.staffId.equals(staffId)))
                .getSingleOrNull();
        if (current != null && expectedVersion != null) {
          throw ConflictFailure(
            'This task changed before its priority was saved.',
            currentVersion: current.version,
          );
        }
        throw const AuthFailure('This task is assigned to another clinician.');
      }
    });
  }

  @override
  Future<Result<void>> escalate({
    required String id,
    required String staffId,
    required String coverageStaffId,
    required WorkPriority priority,
    int? expectedVersion,
  }) => Result.guardAsync(() async {
    final row = await (_db.select(
      _db.staffTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Task not found.');
    await TaskWorkflow(_db, _access).offer(
      actor: staffId,
      tasks: {id: expectedVersion ?? row.version},
      recipient: coverageStaffId,
      reason: 'Escalation: clinical review requested',
      expires: DateTime.now().add(const Duration(hours: 24)),
      urgent: priority == WorkPriority.urgent,
    );
  });
}

class RiskRepositoryImpl implements RiskRepository {
  RiskRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<RiskFlag>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'risk_flag');
      final rows =
          await (_db.select(_db.riskFlags)
                ..where((f) => f.patientId.equals(patientId))
                ..orderBy([(f) => OrderingTerm.desc(f.detectedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  SimpleSelectStatement<$RiskFlagsTable, RiskFlagRow> _unackQuery() {
    return _db.select(_db.riskFlags)
      ..where((f) => f.acknowledgedBy.isNull())
      ..orderBy([(f) => OrderingTerm.desc(f.detectedAt)]);
  }

  @override
  Future<Result<List<RiskFlag>>> unacknowledged() {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'risk_flag');
      final visible = await _access.clinicallyVisiblePatientIds();
      final query = _unackQuery();
      if (visible != null) query.where((f) => f.patientId.isIn(visible));
      final rows = await query.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<RiskFlag>> watchUnacknowledged() {
    return authorizedStream(
      () => _access.requireStaffOrAdmin(entityType: 'risk_flag'),
      _watchUnacknowledged,
    );
  }

  Stream<List<RiskFlag>> _watchUnacknowledged() {
    return _unackQuery().watch().asyncMap((rows) async {
      final visible = await _access.clinicallyVisiblePatientIds();
      return rows
          .where((r) => visible == null || visible.contains(r.patientId))
          .map((r) => r.toEntity())
          .toList();
    });
  }

  @override
  Future<Result<void>> upsertByDedupeKey(RiskFlag incoming) {
    return Result.guardAsync(() async {
      await _access.readPatient(incoming.patientId, entityType: 'risk_flag');
      await _db.transaction(() async {
        final alias =
            await (_db.select(_db.riskSourceAliases)..where(
                  (a) =>
                      a.sourceKey.equals(incoming.dedupeKey) &
                      a.patientId.equals(incoming.patientId),
                ))
                .getSingleOrNull();
        final flag = incoming.copyWith(
          dedupeKey: alias?.canonicalKey ?? incoming.dedupeKey,
        );
        final existing = await (_db.select(
          _db.riskFlags,
        )..where((f) => f.dedupeKey.equals(flag.dedupeKey))).getSingleOrNull();
        if (existing != null) {
          // An old aggregate may alias several reports. Preserve its exact
          // history rather than replacing its rationale once per source.
          if (alias != null) return;
          await (_db.update(
            _db.riskFlags,
          )..where((f) => f.id.equals(existing.id))).write(
            RiskFlagsCompanion(
              severity: Value(flag.severity),
              rationale: Value(flag.rationale),
            ),
          );
          return;
        }
        await _db
            .into(_db.riskFlags)
            .insert(
              RiskFlagsCompanion.insert(
                id: flag.id,
                patientId: flag.patientId,
                kind: flag.kind,
                severity: flag.severity,
                rationale: flag.rationale,
                dedupeKey: flag.dedupeKey,
                detectedAt: Value(flag.detectedAt),
                source: Value(flag.source),
              ),
            );
      });
    });
  }

  @override
  Future<Result<void>> acknowledge({
    required String id,
    required String staffId,
  }) {
    return Result.guardAsync(() async {
      final flag = await (_db.select(
        _db.riskFlags,
      )..where((f) => f.id.equals(id))).getSingleOrNull();
      if (flag == null) throw const NotFoundFailure('Risk flag not found.');
      await _access.clinicalWrite(
        staffId: staffId,
        patientId: flag.patientId,
        permission: Permission.acknowledgeRiskFlags,
        entityType: 'risk_flag',
        entityId: id,
      );
      final updated =
          await (_db.update(
            _db.riskFlags,
          )..where((f) => f.id.equals(id) & f.acknowledgedBy.isNull())).write(
            RiskFlagsCompanion(
              acknowledgedBy: Value(staffId),
              acknowledgedAt: Value(DateTime.now()),
            ),
          );
      if (updated != 1) {
        throw const ValidationFailure(
          'This risk flag was already acknowledged.',
        );
      }
    });
  }
}
