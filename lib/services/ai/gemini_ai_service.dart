/// Live LLM implementation of [AiService] — Google Gemini, free tier (P3-05).
///
/// The provider is a one-class swap behind [AiService]; the report frames it as
/// "provider-agnostic, demoed with Gemini Flash". On any failure this returns
/// an [Err] and the caller ([FallbackAiService]) drops to [MockAiService], so a
/// bad network can never sink a screen.
library;

import 'package:dio/dio.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import 'ai_models.dart';
import 'ai_service.dart';
import 'prompts/summarize_records.dart';
import 'summary_parser.dart';

class GeminiAiService implements AiService {
  GeminiAiService({required this.apiKey, this.model = defaultModel, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );

  final String apiKey;
  final String model;
  final Dio _dio;

  static const defaultModel = 'gemini-2.0-flash';

  @override
  Future<Result<HealthSummary>> summarizeRecords(PatientContext context) async {
    return Result.guardAsync(() async {
      final body = {
        'systemInstruction': {
          'parts': [
            {'text': summarizeSystemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': buildSummarizePrompt(context.contextText)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      };

      final text = await _callWithRetry(body);
      return parseHealthSummary(
        text,
        modelId: model,
        promptVersion: summarizePromptVersion,
      );
    });
  }

  Future<String> _callWithRetry(Map<String, Object?> body) async {
    DioException? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _dio.post<Map<String, dynamic>>(
          '/models/$model:generateContent',
          queryParameters: {'key': apiKey},
          data: body,
        );
        return _extractText(res.data);
      } on DioException catch (e) {
        last = e;
        // Retry once on transient errors only.
        final code = e.response?.statusCode ?? 0;
        if (code != 429 &&
            code < 500 &&
            e.type == DioExceptionType.badResponse) {
          break;
        }
      }
    }
    throw NetworkFailure(
      'The AI service is unavailable right now.',
      cause: last,
    );
  }

  String _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiFailure('The AI service returned no candidates.');
    }
    final content = (candidates.first as Map)['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const AiFailure('The AI service returned an empty response.');
    }
    final text = (parts.first as Map)['text'];
    if (text is! String || text.isEmpty) {
      throw const AiFailure('The AI service returned no text.');
    }
    return text;
  }
}

/// Tries [primary]; on any [Err] falls back to [fallback] (P3-05).
class FallbackAiService implements AiService {
  const FallbackAiService({required this.primary, required this.fallback});

  final AiService primary;
  final AiService fallback;

  @override
  Future<Result<HealthSummary>> summarizeRecords(PatientContext context) async {
    final result = await primary.summarizeRecords(context);
    if (result.isOk) return result;
    return fallback.summarizeRecords(context);
  }
}
