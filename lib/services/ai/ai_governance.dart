enum AiRuntimeMode { unavailable, offline, mock, live }

enum AiReviewState { draft, reviewed, rejected }

class AiProvenance {
  const AiProvenance({
    required this.mode,
    required this.modelId,
    required this.promptVersion,
    required this.inputHash,
    required this.generatedAt,
    this.reviewState = AiReviewState.draft,
    this.reviewedBy,
    this.reviewedAt,
  });

  final AiRuntimeMode mode;
  final String modelId;
  final String promptVersion;
  final String inputHash;
  final DateTime generatedAt;
  final AiReviewState reviewState;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get canCommitAsClinicalTruth =>
      reviewState == AiReviewState.reviewed &&
      reviewedBy != null &&
      reviewedAt != null;

  AiProvenance review({required String reviewerId, DateTime? at}) =>
      AiProvenance(
        mode: mode,
        modelId: modelId,
        promptVersion: promptVersion,
        inputHash: inputHash,
        generatedAt: generatedAt,
        reviewState: AiReviewState.reviewed,
        reviewedBy: reviewerId,
        reviewedAt: at ?? DateTime.now(),
      );
}

AiRuntimeMode aiModeForModel(String modelId) => switch (modelId) {
  'mock-ai' => AiRuntimeMode.mock,
  'offline' => AiRuntimeMode.offline,
  _ => AiRuntimeMode.live,
};
