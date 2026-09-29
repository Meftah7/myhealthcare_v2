/// The AI abstraction — three methods, one per research question, so the code
/// maps 1:1 onto the report (P3-01).
///
/// Two implementations, chosen by a Riverpod provider from app settings
/// (P3-07): [MockAiService] (deterministic, offline) and `ClaudeAiService`
/// (Anthropic Messages API, P3-05). Every method returns [Result] and never
/// throws across the boundary.
library;

import '../../core/failures.dart';
import '../../core/result.dart';
import 'ai_models.dart';

abstract interface class AiService {
  /// RQ1 — unify the record into a timeline summary with key events + trends.
  Future<Result<HealthSummary>> summarizeRecords(PatientContext context);

  // RQ2 (rankSlots) and RQ3 (prioritizeTasks) are added in Phase 4 / Phase 5.
}

/// Used in production when no live AI provider is configured.
class UnavailableAiService implements AiService {
  const UnavailableAiService();

  @override
  Future<Result<HealthSummary>> summarizeRecords(PatientContext context) async {
    return const Err(
      AiFailure('AI is unavailable until a live provider is configured.'),
    );
  }
}
