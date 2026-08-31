/// Drift-backed [TaskRepository] + [RiskRepository] (P1-16).
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$StaffTasksTable, StaffTaskRow> _query(
    String staffId, {
    bool openOnly = false,
  }) {
    final q = _db.select(_db.staffTasks)
      ..where((t) => t.staffId.equals(staffId))
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
      final rows = await _query(staffId, openOnly: openOnly).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<StaffTask>> watchForStaff(
    String staffId, {
    bool openOnly = false,
  }) {
    return _query(
      staffId,
      openOnly: openOnly,
    ).watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<void>> upsert(StaffTask task) {
    return Result.guardAsync(() async {
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
  Future<Result<void>> setStatus(String id, TaskStatus status) {
    return Result.guardAsync(() async {
      await (_db.update(_db.staffTasks)..where((t) => t.id.equals(id))).write(
        StaffTasksCompanion(status: Value(status)),
      );
    });
  }

  @override
  Future<Result<void>> applyAiPriority({
    required String id,
    required double score,
    required String rationale,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.staffTasks)..where((t) => t.id.equals(id))).write(
        StaffTasksCompanion(
          aiPriorityScore: Value(score),
          aiRationale: Value(rationale),
        ),
      );
    });
  }
}

class RiskRepositoryImpl implements RiskRepository {
  RiskRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<RiskFlag>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
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
      final rows = await _unackQuery().get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<RiskFlag>> watchUnacknowledged() {
    return _unackQuery().watch().map(
      (rows) => rows.map((r) => r.toEntity()).toList(),
    );
  }

  @override
  Future<Result<void>> upsertByDedupeKey(RiskFlag flag) {
    return Result.guardAsync(() async {
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
      await (_db.update(_db.riskFlags)..where((f) => f.id.equals(id))).write(
        RiskFlagsCompanion(
          acknowledgedBy: Value(staffId),
          acknowledgedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}
