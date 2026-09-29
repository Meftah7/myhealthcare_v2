/// Owned clinical review of an abnormal or unjudgeable result (Phase 4).
library;

import 'package:flutter/foundation.dart';

import '../enums.dart';

@immutable
class ResultReview {
  const ResultReview({
    required this.id,
    required this.recordId,
    required this.patientId,
    required this.recordTitle,
    required this.dueAt,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.ownerStaffId,
    this.coverageStaffId,
    this.escalationNote,
    this.resolvedAt,
    this.resolvedByStaffId,
    this.resolutionNote,
    this.version = 1,
  });

  final String id;
  final String recordId;
  final String patientId;
  final String recordTitle;
  final String? ownerStaffId;

  /// The clinician covering it (escalation target, or off-duty cover).
  final String? coverageStaffId;
  final DateTime dueAt;
  final WorkPriority priority;
  final ResultReviewStatus status;
  final String? escalationNote;
  final DateTime? resolvedAt;
  final String? resolvedByStaffId;
  final String? resolutionNote;
  final DateTime createdAt;
  final int version;

  bool get isOpen => status != ResultReviewStatus.resolved;

  bool isOverdueAt(DateTime now) => isOpen && dueAt.isBefore(now);

  /// Anyone who can act on it now.
  bool isHeldBy(String staffId) =>
      ownerStaffId == staffId || coverageStaffId == staffId;
}
