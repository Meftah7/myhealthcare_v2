/// AI health summary: build context → cache lookup → generate → persist
/// (P3-02, P3-07, P3-08, P3-14).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../services/ai/ai_models.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/ai/mock_ai_service.dart';
import '../../../services/ai/patient_context_builder.dart';
import '../../patient/application/patient_data_providers.dart';

/// The [AiService] for the current patient. Reads app settings to pick mock vs
/// real (P3-07); until P3-05 the real client isn't wired, so this is always the
/// deterministic mock.
final aiServiceProvider = FutureProvider<AiService>((ref) async {
  final patient = await ref.watch(patientProfileProvider.future);
  final records = await ref.watch(patientTimelineProvider.future);
  final vitals = await ref.watch(patientVitalsProvider.future);
  final meds = await ref.watch(patientMedicationsProvider.future);

  // final settings = await ref.watch(settingsProvider.future);
  // if (settings.usesRealAi) return ClaudeAiService(...);  // P3-05

  return MockAiService(
    patient: patient,
    records: records,
    vitals: vitals,
    medications: meds,
  );
});

/// Whether the last generation went through the network (always false for now).
final aiUsingRealServiceProvider = Provider<bool>((_) => false);

class AiSummaryController {
  AiSummaryController(this._ref);
  final Ref _ref;

  Future<PatientContext> _context() async {
    final patient = await _ref.read(patientProfileProvider.future);
    final records = await _ref.read(patientTimelineProvider.future);
    final vitals = await _ref.read(patientVitalsProvider.future);
    final meds = await _ref.read(patientMedicationsProvider.future);
    return const PatientContextBuilder().build(
      patient: patient,
      records: records,
      vitals: vitals,
      medications: meds,
    );
  }

  Future<AiSummary> load({bool forceRegenerate = false}) async {
    final ctx = await _context();
    final cache = _ref.read(aiSummaryRepositoryProvider);

    if (!forceRegenerate) {
      final hit = await cache.cachedFor(ctx.hash);
      if (hit case Ok(value: final AiSummary cached)) return cached;
    }

    final service = await _ref.read(aiServiceProvider.future);
    final result = await service.summarizeRecords(ctx);
    final summary = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

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
  }
}

final aiSummaryControllerProvider = Provider<AiSummaryController>(
  AiSummaryController.new,
);

/// The current patient's AI summary (cached-or-generated).
final patientAiSummaryProvider = FutureProvider<AiSummary>((ref) {
  return ref.watch(aiSummaryControllerProvider).load();
});
