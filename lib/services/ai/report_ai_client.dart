/// Client for live report explanations and grounded follow-up questions.
///
/// The provider key never lives on the device: the app talks to the MyHealth
/// report AI gateway (services/report_ai), configured at build time with
///   --dart-define=REPORT_AI_ORIGIN=https://…   (gateway origin)
///   --dart-define=REPORT_AI_CLIENT_TOKEN=…     (client installation token,
///                                               not a provider credential)
/// Without both, [UnconfiguredReportAiClient] reports the capability as
/// unavailable and the app shows its labelled on-device summary instead.
///
/// Real patient documents: a production build (APP_MODE=production) sends
/// nothing unless it is also built with
///   --dart-define=REPORT_AI_REAL_DOCUMENTS_APPROVED=true
/// — set only once the provider and deployment are approved for that use.
/// Demo builds hold synthetic data.
///
/// Patient/report authorization happens before any call: callers re-read
/// the record through the access-checked repository and send only that
/// report's text. Nothing here logs report text or questions.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';

/// Why a live request did not produce an answer.
enum ReportAiFailureKind {
  /// The gateway or its provider is not configured.
  unavailable,
  timeout,

  /// The AI provider failed or returned an unreadable answer.
  provider,
  rateLimited,

  /// The request was rejected (too large, invalid).
  rejected,

  /// The gateway could not be reached.
  network,
}

class ReportAiException implements Exception {
  const ReportAiException(this.kind);
  final ReportAiFailureKind kind;

  @override
  String toString() => 'ReportAiException($kind)';
}

/// How much of the report the model was given.
class ReportCoverage {
  const ReportCoverage({
    required this.explainedChars,
    required this.totalChars,
    required this.complete,
  });

  factory ReportCoverage.fromJson(Map<String, dynamic>? json) => ReportCoverage(
    explainedChars: (json?['explainedChars'] as num?)?.toInt() ?? 0,
    totalChars: (json?['totalChars'] as num?)?.toInt() ?? 0,
    complete: json?['complete'] == true,
  );

  final int explainedChars;
  final int totalChars;
  final bool complete;
}

class ReportExplanation {
  const ReportExplanation({
    required this.answer,
    required this.coverage,
    this.quotes = const [],
    this.readable = true,
  });

  /// A few short bullets, or the server's fixed "couldn't read" message.
  final String answer;
  final ReportCoverage coverage;

  /// Excerpts verified on the server to appear verbatim in the report.
  final List<String> quotes;

  /// False when the text was not readable report content.
  final bool readable;
}

/// A grounded answer: [quotes] were verified on the server to appear
/// verbatim in the report; [supported] is false when the report does not
/// answer the question (or the model's support could not be verified).
class ReportAnswer {
  const ReportAnswer({
    required this.answer,
    required this.supported,
    required this.quotes,
    required this.coverage,
    this.action,
    this.refusal = false,
  });

  final String answer;
  final bool supported;
  final List<String> quotes;
  final ReportCoverage coverage;

  /// A navigation action id the assistant suggests (or null). Only an id —
  /// the app maps it to a screen and checks access (AssistantAction).
  final String? action;

  /// The question asked for a diagnosis, advice or a medicine change, and
  /// [answer] is the fixed decline.
  final bool refusal;
}

/// One earlier turn of the report conversation.
class ReportTurn {
  const ReportTurn({required this.fromPatient, required this.text});
  final bool fromPatient;
  final String text;

  Map<String, String> toJson() => {
    'role': fromPatient ? 'user' : 'assistant',
    'text': text,
  };
}

/// Request bounds mirrored from the server (services/shared_api/ai.mjs).
abstract final class ReportAiLimits {
  static const maxTextChars = 50000;
  static const maxQuestionChars = 1000;
  static const maxHistoryTurns = 12;
  static const maxHistoryChars = 2000;
}

abstract interface class ReportAiClient {
  bool get isConfigured;

  /// A short summary; [arabic] picks the language of its wording.
  Future<ReportExplanation> explain(String reportText, {bool arabic = false});

  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
  });
}

class UnconfiguredReportAiClient implements ReportAiClient {
  const UnconfiguredReportAiClient();

  @override
  bool get isConfigured => false;

  @override
  Future<ReportExplanation> explain(String reportText, {bool arabic = false}) =>
      Future.error(const ReportAiException(ReportAiFailureKind.unavailable));

  @override
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
  }) => Future.error(const ReportAiException(ReportAiFailureKind.unavailable));
}

class GatewayReportAiClient implements ReportAiClient {
  GatewayReportAiClient({
    required String origin,
    required String token,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: origin,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 45),
               headers: {'Authorization': 'Bearer $token'},
               // Status codes are mapped below, never thrown as text.
               validateStatus: (_) => true,
             ),
           );

  final Dio _dio;

  @override
  bool get isConfigured => true;

  /// Bounds the text locally too, so nothing oversized leaves the device.
  static String _bounded(String text) =>
      text.length > ReportAiLimits.maxTextChars
      ? text.substring(0, ReportAiLimits.maxTextChars)
      : text;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(path, data: body);
    } on DioException catch (e) {
      throw ReportAiException(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => ReportAiFailureKind.timeout,
        _ => ReportAiFailureKind.network,
      });
    }
    final status = response.statusCode ?? 0;
    if (status == 200 && response.data is Map) {
      return (response.data as Map).cast<String, dynamic>();
    }
    throw ReportAiException(switch (status) {
      503 || 401 || 404 => ReportAiFailureKind.unavailable,
      429 => ReportAiFailureKind.rateLimited,
      400 || 413 || 415 => ReportAiFailureKind.rejected,
      504 => ReportAiFailureKind.timeout,
      _ => ReportAiFailureKind.provider,
    });
  }

  static List<String> _quotes(Object? raw) => [
    for (final q in (raw is List ? raw : const []))
      if (q is String) q,
  ];

  @override
  Future<ReportExplanation> explain(
    String reportText, {
    bool arabic = false,
  }) async {
    final data = await _post('/v1/reports/explain', {
      'text': _bounded(reportText),
      'lang': arabic ? 'ar' : 'en',
    });
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.provider);
    }
    return ReportExplanation(
      answer: answer.trim(),
      quotes: _quotes(data['quotes']),
      readable: data['readable'] != false,
      coverage: ReportCoverage.fromJson(
        (data['coverage'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  @override
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
  }) async {
    final turns = history
        .where((t) => t.text.trim().isNotEmpty)
        .toList()
        .reversed
        .take(ReportAiLimits.maxHistoryTurns)
        .toList()
        .reversed
        .map(
          (t) => ReportTurn(
            fromPatient: t.fromPatient,
            text: t.text.length > ReportAiLimits.maxHistoryChars
                ? t.text.substring(0, ReportAiLimits.maxHistoryChars)
                : t.text,
          ),
        );
    final data = await _post('/v1/reports/chat', {
      'text': _bounded(reportText),
      'question': question,
      'history': [for (final t in turns) t.toJson()],
    });
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.provider);
    }
    final action = data['action'];
    return ReportAnswer(
      answer: answer.trim(),
      supported: data['supported'] == true,
      quotes: _quotes(data['quotes']),
      action: action is String ? action : null,
      refusal: data['refusal'] == true,
      coverage: ReportCoverage.fromJson(
        (data['coverage'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }
}

const _origin = String.fromEnvironment('REPORT_AI_ORIGIN');
const _token = String.fromEnvironment('REPORT_AI_CLIENT_TOKEN');
const _realDocumentsApproved = bool.fromEnvironment(
  'REPORT_AI_REAL_DOCUMENTS_APPROVED',
);

/// The configured client, or [UnconfiguredReportAiClient]. Overridable in
/// tests.
final reportAiClientProvider = Provider<ReportAiClient>((ref) {
  // Real patient documents stay on the device until external processing is
  // approved; demo builds hold synthetic data.
  if (!ref.watch(appModeProvider).isDemo && !_realDocumentsApproved) {
    return const UnconfiguredReportAiClient();
  }
  final origin = Uri.tryParse(_origin);
  final valid =
      origin != null &&
      origin.hasScheme &&
      (origin.scheme == 'https' ||
          origin.host == 'localhost' ||
          origin.host == '127.0.0.1') &&
      _token.length >= 32;
  return valid
      ? GatewayReportAiClient(origin: _origin, token: _token)
      : const UnconfiguredReportAiClient();
});
