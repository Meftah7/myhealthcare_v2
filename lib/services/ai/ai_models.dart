/// AI request/response models (P3-01).
///
/// [KeyEvent] / [Trend] / [RedFlag] are the shared value types from
/// lib/domain/entities/ai_summary.dart. [HealthSummary] is the live response;
/// it is persisted as an [AiSummary] cache row (P3-08, P3-14).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/ai_summary.dart';

part 'ai_models.freezed.dart';

/// The compact, token-budgeted view of a patient's record handed to the model
/// (P3-02). [hash] is the cache key (P3-08).
@freezed
abstract class PatientContext with _$PatientContext {
  const factory PatientContext({
    required String patientId,
    required String contextText,
    required String hash,
    required int approxTokens,
  }) = _PatientContext;
}

@freezed
abstract class HealthSummary with _$HealthSummary {
  const factory HealthSummary({
    required String summaryMarkdown,
    required String modelId,
    required String promptVersion,
    @Default([]) List<KeyEvent> keyEvents,
    @Default([]) List<Trend> trends,
    @Default([]) List<RedFlag> redFlags,
  }) = _HealthSummary;
}
