/// Drift-backed [AuditRepository] + [SettingsRepository] + [FeedbackRepository]
/// + [AiUsageRepository] (P1-17).
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/system_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<void>> record({
    required String action,
    required String entityType,
    String? entityId,
    String? actorUserId,
    String? detail,
  }) {
    return Result.guardAsync(() async {
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: newId('aud'),
              action: action,
              entityType: entityType,
              entityId: Value(entityId),
              actorUserId: Value(actorUserId),
              detail: Value(detail),
            ),
          );
    });
  }

  @override
  Future<Result<List<AuditEntry>>> query(AuditQuery query) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.auditLog)
        ..orderBy([(a) => OrderingTerm.desc(a.at)])
        ..limit(query.limit);
      if (query.actorUserId != null) {
        q.where((a) => a.actorUserId.equals(query.actorUserId!));
      }
      if (query.entityType != null) {
        q.where((a) => a.entityType.equals(query.entityType!));
      }
      if (query.entityId != null) {
        q.where((a) => a.entityId.equals(query.entityId!));
      }
      if (query.from != null) {
        q.where((a) => a.at.isBiggerOrEqualValue(query.from!));
      }
      if (query.to != null) {
        q.where((a) => a.at.isSmallerOrEqualValue(query.to!));
      }
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  static const _defaults = AppSettingsCompanion(id: Value(1));

  Future<AppSettingsRow> _ensureRow() async {
    final existing = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await _db.into(_db.appSettings).insert(_defaults);
    return (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingle();
  }

  @override
  Future<Result<AppSettings>> get() {
    return Result.guardAsync(() async => (await _ensureRow()).toEntity());
  }

  @override
  Stream<AppSettings> watch() {
    return (_db.select(_db.appSettings)..where((s) => s.id.equals(1)))
        .watchSingleOrNull()
        .asyncMap((row) async => (row ?? await _ensureRow()).toEntity());
  }

  @override
  Future<Result<void>> update(AppSettings s) {
    return Result.guardAsync(() async {
      await _ensureRow();
      await (_db.update(_db.appSettings)..where((r) => r.id.equals(1))).write(
        AppSettingsCompanion(
          aiEnabled: Value(s.aiEnabled),
          mockMode: Value(s.mockMode),
          modelId: Value(s.modelId),
          aiTaskWeight: Value(s.aiTaskWeight),
          seedVersion: Value(s.seedVersion),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<void>> submit({
    required FeedbackCategory category,
    required String message,
    String? reporterId,
  }) {
    return Result.guardAsync(() async {
      await _db
          .into(_db.feedbacks)
          .insert(
            FeedbacksCompanion.insert(
              id: newId('fbk'),
              category: category,
              message: message.trim(),
              reporterId: Value(reporterId),
            ),
          );
    });
  }

  @override
  Future<Result<List<UserFeedback>>> all({FeedbackStatus? status}) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.feedbacks)
        ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]);
      if (status != null) q.where((f) => f.status.equalsValue(status));
      final rows = await q.get();
      if (rows.isEmpty) return const <UserFeedback>[];

      final ids = rows.map((r) => r.reporterId).whereType<String>().toSet();
      final users = ids.isEmpty
          ? const <UserRow>[]
          : await (_db.select(_db.users)..where((u) => u.id.isIn(ids))).get();
      final byId = {for (final u in users) u.id: u};

      return rows
          .map(
            (r) => feedbackFrom(
              r,
              name: byId[r.reporterId]?.fullName,
              email: byId[r.reporterId]?.email,
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<void>> setStatus({
    required String id,
    required FeedbackStatus status,
    String? adminId,
  }) {
    return Result.guardAsync(() async {
      final resolving = status == FeedbackStatus.resolved;
      await (_db.update(_db.feedbacks)..where((f) => f.id.equals(id))).write(
        FeedbacksCompanion(
          status: Value(status),
          handledByAdminId: Value(resolving ? adminId : null),
          handledAt: Value(resolving ? DateTime.now() : null),
        ),
      );
    });
  }
}

class AiUsageRepositoryImpl implements AiUsageRepository {
  AiUsageRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<void>> log({
    required AiFeature feature,
    required bool usedLiveModel,
    String? userId,
    String? summary,
  }) {
    return Result.guardAsync(() async {
      await _db
          .into(_db.aiUsageLog)
          .insert(
            AiUsageLogCompanion.insert(
              id: newId('ail'),
              feature: feature,
              usedLiveModel: Value(usedLiveModel),
              userId: Value(userId),
              summary: Value(summary),
            ),
          );
    });
  }

  @override
  Future<Result<List<AiUsageEntry>>> recent({
    AiFeature? feature,
    int limit = 100,
  }) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.aiUsageLog)
        ..orderBy([(l) => OrderingTerm.desc(l.at)])
        ..limit(limit);
      if (feature != null) q.where((l) => l.feature.equalsValue(feature));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }
}
