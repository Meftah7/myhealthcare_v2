/// AI Clinical Scribe — turns a clinician's free-text dictation into a
/// structured visit note (chief complaint / HPI / assessment / plan + suggested
/// ICD-10 codes).
///
/// Ported from the FirstSemMyHealth `Ai/clinical_scribe.php`: same output shape,
/// same "ICD codes are suggestions the doctor must confirm" rule, same
/// graceful-degradation contract — with no key, or with AI switched off, it
/// still returns a usable draft (everything in the HPI field) so the screen
/// never dead-ends.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../admin/application/settings_providers.dart';

/// A structured note draft. Every field is editable on screen before saving —
/// nothing here is committed to the record until the clinician says so.
class ScribeDraft {
  const ScribeDraft({
    this.chiefComplaint = '',
    this.hpi = '',
    this.assessment = '',
    this.plan = '',
    this.icdCodes = const [],
    this.usedAi = false,
  });

  final String chiefComplaint;
  final String hpi;
  final String assessment;
  final String plan;

  /// Suggested ICD-10 codes — always shown as "suggested, confirm".
  final List<String> icdCodes;

  /// True when a live model produced this draft (drives the disclaimer banner).
  final bool usedAi;

  /// Everything the clinician typed, laid out as a note body.
  static ScribeDraft offline(String freeText) => ScribeDraft(
    hpi: freeText.trim(),
  );

  /// The draft rendered as a single note body for [MedicalRecord.body].
  String toNoteBody() {
    final b = StringBuffer();
    void section(String label, String value) {
      if (value.trim().isEmpty) return;
      b.writeln(label);
      b.writeln(value.trim());
      b.writeln();
    }

    section('Chief complaint:', chiefComplaint);
    section('History of present illness:', hpi);
    section('Assessment:', assessment);
    section('Plan:', plan);
    if (icdCodes.isNotEmpty) {
      b.writeln('Suggested ICD-10 (confirm before coding):');
      for (final c in icdCodes) {
        b.writeln('- $c');
      }
    }
    return b.toString().trim();
  }
}

class ClinicalScribe {
  ClinicalScribe(this._ref);
  final Ref _ref;

  static const _systemPrompt = '''
You are an expert clinical scribe assisting a doctor. Convert the doctor's
unstructured free-text dictation from a patient visit into a structured
clinical note.

Return ONLY a JSON object (no markdown fences) with exactly these fields:
- "chief_complaint": one concise sentence.
- "hpi": History of Present Illness, a short narrative paragraph.
- "assessment": the clinical impression / working diagnosis.
- "plan": treatment, prescriptions and follow-up.
- "icd_codes": an array of strings, each "CODE - description" (e.g.
  "J20.9 - Acute bronchitis, unspecified"). May be empty.

Rules: professional clinical tone; never invent findings — if a section is not
covered in the dictation, use "Not provided."; output valid JSON only.''';

  /// Structure [freeText]. Never throws — returns an offline draft on any
  /// failure or when AI is unavailable.
  Future<Result<ScribeDraft>> structure(String freeText) async {
    final text = freeText.trim();
    if (text.isEmpty) {
      return const Err(ValidationFailure('Enter some notes to structure.'));
    }

    try {
      final settings = await _ref.read(appSettingsProvider.future);
      final key = await _ref.read(aiKeyStoreProvider).read();
      if (!settings.usesRealAi || key == null || key.isEmpty) {
        return Ok(ScribeDraft.offline(text));
      }
      return Ok(await _ask(text, apiKey: key, model: settings.modelId));
    } catch (_) {
      return Ok(ScribeDraft.offline(text));
    }
  }

  Future<ScribeDraft> _ask(
    String text, {
    required String apiKey,
    required String model,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    final res = await dio.post<Map<String, dynamic>>(
      '/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': "Doctor's dictation:\n$text"},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      },
    );

    final candidates = res.data?['candidates'];
    final first = (candidates is List && candidates.isNotEmpty)
        ? candidates.first
        : null;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    final part = (parts is List && parts.isNotEmpty) ? parts.first : null;
    final raw = part is Map ? part['text'] : null;
    if (raw is! String || raw.trim().isEmpty) {
      return ScribeDraft.offline(text);
    }
    return _parse(raw, fallback: text);
  }

  ScribeDraft _parse(String raw, {required String fallback}) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return ScribeDraft.offline(fallback);
    Object? decoded;
    try {
      decoded = jsonDecode(raw.substring(start, end + 1));
    } catch (_) {
      return ScribeDraft.offline(fallback);
    }
    if (decoded is! Map) return ScribeDraft.offline(fallback);

    String str(String k) {
      final v = decoded is Map ? decoded[k] : null;
      return v is String ? v.trim() : '';
    }

    final codesRaw = decoded['icd_codes'];
    final codes = codesRaw is List
        ? codesRaw.whereType<String>().map((s) => s.trim()).toList()
        : <String>[];

    return ScribeDraft(
      chiefComplaint: str('chief_complaint'),
      hpi: str('hpi'),
      assessment: str('assessment'),
      plan: str('plan'),
      icdCodes: codes,
      usedAi: true,
    );
  }
}

final clinicalScribeProvider = Provider<ClinicalScribe>(ClinicalScribe.new);
