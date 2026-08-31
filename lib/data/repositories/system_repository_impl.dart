/// Drift-backed [AuditRepository] + [SettingsRepository] (P1-17).
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
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
