/// Audit trail + app settings contracts (P1-11).
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

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

/// User feedback / issue reports (patient + staff submit; admin triages).
abstract interface class FeedbackRepository {
  Future<Result<void>> submit({
    required FeedbackCategory category,
    required String message,
    String? reporterId,
  });

  /// Newest first, optionally filtered to one [status]. Reporter name/email are
  /// joined in for the admin list.
  Future<Result<List<UserFeedback>>> all({FeedbackStatus? status});

  Future<Result<void>> setStatus({
    required String id,
    required FeedbackStatus status,
    String? adminId,
  });
}

/// Append-only AI usage log (admin "AI Logs").
abstract interface class AiUsageRepository {
  /// Fire-and-forget: a failure here must never break the AI surface.
  Future<Result<void>> log({
    required AiFeature feature,
    required bool usedLiveModel,
    String? userId,
    String? summary,
  });

  Future<Result<List<AiUsageEntry>>> recent({AiFeature? feature, int limit});
}
