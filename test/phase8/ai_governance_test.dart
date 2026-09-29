import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/capabilities/capability_registry.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/services/ai/ai_governance.dart';
import 'package:myhealthcare/services/ai/ai_models.dart';
import 'package:myhealthcare/services/ai/ai_service.dart';

void main() {
  const context = PatientContext(
    patientId: 'patient',
    contextText: 'minimized context',
    hash: 'hash',
    approxTokens: 4,
  );

  test('live clinical AI remains release-gated', () {
    expect(phase8CapabilityEnabled('live-clinical-ai'), isFalse);
  });

  test('AI provenance starts as a non-committable draft', () {
    final provenance = AiProvenance(
      mode: aiModeForModel('mock-ai'),
      modelId: 'mock-ai',
      promptVersion: 'v1',
      inputHash: 'hash',
      generatedAt: DateTime(2026, 9, 29),
    );
    expect(provenance.mode, AiRuntimeMode.mock);
    expect(provenance.reviewState, AiReviewState.draft);
    expect(provenance.canCommitAsClinicalTruth, isFalse);
    expect(
      provenance.review(reviewerId: 'clinician').canCommitAsClinicalTruth,
      isTrue,
    );
  });

  test('AI outage is an ordinary failure, not an exception', () async {
    const service = UnavailableAiService();
    final result = await service.summarizeRecords(context);
    expect(result, isA<Err<HealthSummary>>());
  });
}
