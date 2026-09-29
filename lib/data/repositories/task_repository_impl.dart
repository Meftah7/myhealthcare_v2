/// Drift-backed [TaskRepository] + [RiskRepository] (P1-16).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/task_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  Future<void> _ownTasks(String staffId) => _access.selfOrAdmin(
    staffId,
    Permission.viewOperationalReports,
    entityType: 'task',
  );

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
            t.status.equalsValue(TaskStatus.inProgress),
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
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<StaffTask>> watchForStaff(
    String staffId, {
    bool openOnly = false,
  }) {
    return authorizedStream(
      () => _ownTasks(staffId),
      () => _query(
        staffId,
        openOnly: openOnly,
      ).watch().map((rows) => rows.map((r) => r.toEntity()).toList()),
    );
  }

  @override
  Future<Result<void>> upsert(StaffTask task) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        task.staffId,
        Permission.manageUsers,
        entityType: 'task',
        entityId: task.id,
      );
      await _db
          .into(_db.staffTasks)
          .insertOnConflictUpdate(
            StaffTasksCompanion.insert(
              id: task.id,
              staffId: task.staffId,
              title: task.title,
              kind: task.kind,
              status: Value(task.status),
              ruleScore: Value(task.ruleScore),
              patientId: Value(task.patientId),
              dueAt: Value(task.dueAt),
              aiPriorityScore: Value(task.aiPriorityScore),
              aiRationale: Value(task.aiRationale),
              createdAt: Value(task.createdAt),
            ),
          );
    });
  }

  @override
  Future<Result<void>> setStatus({
    required String id,
    required String staffId,
    required TaskStatus status,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.manageTasks,
        entityType: 'task',
        entityId: id,
      );
      final task =
          await (_db.select(_db.staffTasks)..where(
                (t) =>
                    t.id.equals(id) &
                    (t.staffId.equals(staffId) |
                        t.coverageStaffId.equals(staffId)),
              ))
              .getSingleOrNull();
      if (task != null &&
          task.status != status &&
          !(_taskSteps[task.status]?.contains(status) ?? false)) {
        throw ValidationFailure(
          'A ${task.status.name} task cannot become ${status.name}.',
        );
      }
      final updated =
          await (_db.update(_db.staffTasks)..where(
                (t) =>
                    t.id.equals(id) &
                    (t.staffId.equals(staffId) |
                        t.coverageStaffId.equals(staffId)) &
                    (expectedVersion == null
                        ? const Constant(true)
                        : t.version.equals(expectedVersion)),
              ))
              .write(StaffTasksCompanion(status: Value(status)));
      if (updated != 1) {
        if (task != null && expectedVersion != null) {
          throw ConflictFailure(
            'This task changed before your update was saved.',
            currentVersion: task.version,
          );
        }
        throw const AuthFailure('This task is assigned to another clinician.');
      }
    });
  }

  /// Open work moves forward; done and dismissed are final.
  static const _taskSteps = <TaskStatus, Set<TaskStatus>>{
    TaskStatus.open: {
      TaskStatus.inProgress,
      TaskStatus.done,
      TaskStatus.dismissed,
    },
    TaskStatus.inProgress: {
      TaskStatus.open,
      TaskStatus.done,
      TaskStatus.dismissed,
    },
  };

  @override
  Future<Result<void>> applyAiPriority({
    required String id,
    required String staffId,
    required double score,
    required String rationale,
    int? expectedVersion,
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.runConsultation,
        entityType: 'task',
        entityId: id,
      );
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
  }) {
    return Result.guardAsync(() async {
      await _access.actAsStaff(
        staffId,
        Permission.manageTasks,
        entityType: 'staff_task',
        entityId: id,
      );
      if (coverageStaffId == staffId) {
        throw const ValidationFailure('Escalate to a different clinician.');
      }
      final cover = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(coverageStaffId))).getSingleOrNull();
      if (cover == null || !cover.isActive || cover.role != UserRole.staff) {
        throw const ValidationFailure('Choose an active clinician to cover.');
      }
      final task = await (_db.select(
        _db.staffTasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (task == null) throw const NotFoundFailure('Task not found.');
      if (task.status == TaskStatus.done ||
          task.status == TaskStatus.dismissed) {
        throw const ValidationFailure('A closed task cannot be escalated.');
      }
      final updated =
          await (_db.update(_db.staffTasks)..where(
                (task) =>
                    task.id.equals(id) &
                    task.staffId.equals(staffId) &
                    (expectedVersion == null
                        ? const Constant(true)
                        : task.version.equals(expectedVersion)),
              ))
              .write(
                StaffTasksCompanion(
                  priority: Value(priority),
                  coverageStaffId: Value(coverageStaffId),
                  escalatedAt: Value(DateTime.now()),
                ),
              );
      if (updated != 1) {
        throw ConflictFailure(
          'This task changed. Reload before escalating it.',
          currentVersion: task.version,
        );
      }
      await _access.audit(
        'task.escalate',
        entityType: 'staff_task',
        entityId: id,
        subjectPatientId: task.patientId,
        detail: 'to $coverageStaffId (${priority.name})',
      );
    });
  }
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
      final rows = await _unackQuery().get();
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
    return _unackQuery().watch().map(
      (rows) => rows.map((r) => r.toEntity()).toList(),
    );
  }

  @override
  Future<Result<void>> upsertByDedupeKey(RiskFlag flag) {
    return Result.guardAsync(() async {
      // Flags are derived from data the caller can already read.
      await _access.readPatient(flag.patientId, entityType: 'risk_flag');
      final existing = await (_db.select(
        _db.riskFlags,
      )..where((f) => f.dedupeKey.equals(flag.dedupeKey))).getSingleOrNull();
      if (existing != null) {
        await (_db.update(
          _db.riskFlags,
        )..where((f) => f.id.equals(existing.id))).write(
          RiskFlagsCompanion(
            severity: Value(flag.severity),
            rationale: Value(flag.rationale),
            detectedAt: Value(flag.detectedAt),
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
      final relationship =
          await (_db.select(_db.appointments)
                ..where(
                  (a) =>
                      a.staffId.equals(staffId) &
                      a.patientId.equals(flag.patientId),
                )
                ..limit(1))
              .getSingleOrNull();
      if (relationship == null) {
        throw const AuthFailure('You are not assigned to this patient.');
      }
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
