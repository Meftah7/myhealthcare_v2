/// Audit trail + app settings contracts (P1-11).
library;

import '../../core/result.dart';
import '../entities/entities.dart';

class AuditQuery {
  const AuditQuery({
    this.actorUserId,
    this.entityType,
    this.entityId,
    this.from,
    this.to,
    this.limit = 100,
  });

  final String? actorUserId;
  final String? entityType;
  final String? entityId;
  final DateTime? from;
  final DateTime? to;
  final int limit;
}

abstract interface class AuditRepository {
  /// Append an entry. Any write path can call this; failures here must never
  /// break the originating operation.
  Future<Result<void>> record({
    required String action,
    required String entityType,
    String? entityId,
    String? actorUserId,
    String? detail,
  });

  Future<Result<List<AuditEntry>>> query(AuditQuery query);
}

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> get();

  Stream<AppSettings> watch();

  Future<Result<void>> update(AppSettings settings);
}
