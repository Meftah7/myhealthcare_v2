/// One row of the audit trail (P1-10/P1-11).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_entry.freezed.dart';

@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required String id,
    required String action,
    required String entityType,
    required DateTime at,
    String? actorUserId,
    String? entityId,
    String? detail,
  }) = _AuditEntry;
}
