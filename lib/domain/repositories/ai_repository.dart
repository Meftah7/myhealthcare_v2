/// Persistence contract for cached AI summaries (P1-11).
///
/// The AI *service* (calling the model) is separate — services/ai/ (P3-01).
/// This is only the cache store keyed on the context hash (P3-08).
library;

import '../../core/result.dart';
import '../entities/entities.dart';

abstract interface class AiSummaryRepository {
  /// Cache hit for an identical patient context, or null.
  Future<Result<AiSummary?>> cachedFor(String inputHash);

  Future<Result<AiSummary?>> latestForPatient(String patientId);

  Future<Result<void>> save(AiSummary summary);
}
