/// Staff-facing AI patient summary (Tier B) — the same summariser the patient
/// sees on their own record (P3-09), but keyed by an explicit patient id so a
/// clinician can run it from the chart. Cache-or-generate, Gemini when a key is
/// configured, deterministic mock otherwise.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/ai/gemini_ai_service.dart';
import '../../../services/ai/mock_ai_service.dart';
import '../../../services/ai/patient_context_builder.dart';
import '../../admin/application/settings_providers.dart';
import 'chart_providers.dart';

/// The [AiService] for a chart summary of [patientId] — live when a key is
/// configured and AI is on, always wrapped so a failure drops to the mock.
final _chartAiServiceProvider = FutureProvider.family<AiService, String>((
  ref,
  patientId,
) async {
  final patient = await ref.watch(chartPatientProvider(patientId).future);
  final records = await ref.watch(chartTimelineProvider(patientId).future);
  final vitals = await ref.watch(chartVitalsProvider(patientId).future);
  final meds = await ref.watch(chartMedicationsProvider(patientId).future);

  final mock = MockAiService(
    patient: patient,
    records: records,
    vitals: vitals,
    medications: meds,
  );

  final settings = await ref.watch(appSettingsProvider.future);
  final key = await ref.watch(aiKeyStoreProvider).read();
  if (settings.usesRealAi && key != null && key.isNotEmpty) {
    return FallbackAiService(
      primary: GeminiAiService(apiKey: key, model: settings.modelId),
      fallback: mock,
    );
  }
  return mock;
});

/// The cached-or-generated AI summary for a patient, from the staff chart.
final chartPatientSummaryProvider = FutureProvider.family<AiSummary, String>((
  ref,
  patientId,
) async {
  final patient = await ref.watch(chartPatientProvider(patientId).future);
  final records = await ref.watch(chartTimelineProvider(patientId).future);
  final vitals = await ref.watch(chartVitalsProvider(patientId).future);
  final meds = await ref.watch(chartMedicationsProvider(patientId).future);

  final ctx = const PatientContextBuilder().build(
    patient: patient,
    records: records,
    vitals: vitals,
    medications: meds,
  );

  final cache = ref.read(aiSummaryRepositoryProvider);
  final hit = await cache.cachedFor(ctx.hash);
  if (hit case Ok(value: final AiSummary cached)) return cached;

  final service = await ref.watch(_chartAiServiceProvider(patientId).future);
  final result = await service.summarizeRecords(ctx);
  final summary = switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };

  unawaited(
    ref
        .read(aiUsageRepositoryProvider)
        .log(
          feature: AiFeature.patientSummary,
          usedLiveModel: summary.modelId != 'mock-ai',
          summary: 'Chart summary for ${patient.fullName}',
        ),
  );

  final entity = AiSummary(
    id: newId('sum'),
    patientId: ctx.patientId,
    generatedAt: DateTime.now(),
    modelId: summary.modelId,
    promptVersion: summary.promptVersion,
    summaryMarkdown: summary.summaryMarkdown,
    inputHash: ctx.hash,
    keyEvents: summary.keyEvents,
    trends: summary.trends,
    redFlags: summary.redFlags,
  );
  await cache.save(entity);
  return entity;
});
