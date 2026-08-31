/// A patient risk flag from the rule engine or the AI layer (P1-10).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'risk_flag.freezed.dart';

@freezed
abstract class RiskFlag with _$RiskFlag {
  const factory RiskFlag({
    required String id,
    required String patientId,
    required RiskFlagKind kind,
    required Severity severity,
    required String rationale,
    required DateTime detectedAt,
    required FlagSource source,
    required String dedupeKey,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
  }) = _RiskFlag;

  const RiskFlag._();

  bool get isAcknowledged => acknowledgedBy != null;
}
