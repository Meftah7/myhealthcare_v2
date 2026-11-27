/// Client for the MyHealth report AI gateway (services/report_ai): readiness,
/// ordinary conversation, document summaries and factual document lookup.
///
/// The provider key never lives on the device: the app talks to the gateway,
/// configured at build time with
///   --dart-define=REPORT_AI_ORIGIN=https://…   (gateway origin)
///   --dart-define=REPORT_AI_CLIENT_TOKEN=…     (client installation token —
///                                               not a provider credential,
///                                               not secret in a web build)
/// Without both, [UnconfiguredReportAiClient] reports the capability as
/// unconfigured and the app labels its on-device guide and summaries.
/// Being configured is not being connected: [ReportAiClient.checkReadiness]
/// asks the gateway (authenticated, with a time limit).
///
/// Real patient documents: a production build (APP_MODE=production) sends
/// nothing unless it is also built with
///   --dart-define=REPORT_AI_REAL_DOCUMENTS_APPROVED=true
/// — set only once the provider and deployment are approved for that use.
/// Demo builds hold synthetic data.
///
/// Documents: the app reads the file on the device and uploads only its
/// extracted text (with real byte progress); the original stays on the
/// device. Patient/document authorization happens before any call. Nothing
/// here logs documents, questions or replies.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';

/// Why a live request did not produce an answer.
enum ReportAiFailureKind {
  /// This build has no gateway configured.
  unavailable,

  /// The gateway is up but has no provider configured, or the provider
  /// account cannot be used (key / balance) — not the patient's doing.
  providerUnavailable,

  /// The gateway does not recognise this app (client token).
  unauthorized,
  timeout,

  /// The AI provider failed or returned an unusable answer.
  provider,

  /// The gateway answered something this app cannot read.
  invalidResponse,
  rateLimited,

  /// The request was rejected (too large, invalid).
  rejected,

  /// The gateway could not be reached (offline, DNS, blocked by CORS).
  network,

  /// The request was cancelled by the app.
  cancelled,
}

class ReportAiException implements Exception {
  const ReportAiException(this.kind);
  final ReportAiFailureKind kind;

  @override
  String toString() => 'ReportAiException($kind)';
}

/// What the readiness check found.
enum GatewayReadiness {
  /// No gateway in this build.
  unconfigured,
  checking,

  /// The gateway answered and has a provider configured. (Not proof that a
  /// provider call will succeed.)
  available,
  unreachable,
  unauthorized,

  /// The gateway answered but cannot reach a provider.
  providerUnavailable,
}

/// How much of a report the model was given.
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

  final String answer;
  final ReportCoverage coverage;
  final List<String> quotes;
  final bool readable;
}

/// A factual answer from the attached document.
class ReportAnswer {
  const ReportAnswer({
    required this.answer,
    required this.supported,
    required this.quotes,
    required this.coverage,
    this.action,
    this.actions = const [],
    this.refusal = false,
  });

  final String answer;
  final bool supported;
  final List<String> quotes;
  final ReportCoverage coverage;

  /// A navigation action id (or null). Only an id — the app maps it to a
  /// screen and checks access.
  final String? action;
  final List<String> actions;

  /// The question was a medical one and [answer] is the fixed refusal.
  final bool refusal;
}

/// One reply in ordinary conversation.
class ChatReply {
  const ChatReply({
    required this.reply,
    this.actions = const [],
    this.medical = false,
    this.emergency = false,
  });

  final String reply;

  /// Navigation action ids for buttons under the reply.
  final List<String> actions;

  /// The message was a medical question; [reply] is the fixed refusal.
  final bool medical;
  final bool emergency;
}

/// How much of a document the summary covers, as the gateway processed it.
class SummaryCoverage {
  const SummaryCoverage({
    required this.sourceChars,
    required this.processedChars,
    required this.complete,
  });

  factory SummaryCoverage.fromJson(Map<String, dynamic>? json) =>
      SummaryCoverage(
        sourceChars: (json?['sourceChars'] as num?)?.toInt() ?? 0,
        processedChars: (json?['processedChars'] as num?)?.toInt() ?? 0,
        complete: json?['complete'] == true,
      );

  final int sourceChars;
  final int processedChars;
  final bool complete;
}

/// A short overview and the main points of one document.
class DocumentSummary {
  const DocumentSummary({
    required this.overview,
    required this.points,
    required this.coverage,
    this.quotes = const [],
    this.readable = true,
  });

  final String overview;
  final List<String> points;
  final List<String> quotes;
  final bool readable;
  final SummaryCoverage coverage;
}

/// One earlier turn of a conversation.
class ReportTurn {
  const ReportTurn({required this.fromPatient, required this.text});
  final bool fromPatient;
  final String text;

  Map<String, String> toJson() => {
    'role': fromPatient ? 'user' : 'assistant',
    'text': text,
  };
}

/// Request bounds mirrored from the gateway.
abstract final class ReportAiLimits {
  static const maxTextChars = 50000;
  static const maxQuestionChars = 1000;
  static const maxHistoryTurns = 12;
  static const maxHistoryChars = 2000;

  /// The most document text one summary request carries (the gateway
  /// processes it in chunks).
  static const maxSummaryChars = 120000;
}

/// Byte progress of an upload: [sent] of [total] bytes.
typedef UploadProgress = void Function(int sent, int total);

abstract interface class ReportAiClient {
  bool get isConfigured;

  /// Asks the gateway whether it is reachable, recognises this app and has
  /// a provider configured.
  Future<GatewayReadiness> checkReadiness();

  /// One turn of ordinary conversation (no document).
  Future<ChatReply> chat({
    required String message,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  });

  /// Uploads a document's extracted text and returns its summary.
  /// [onSendProgress] reports the real bytes sent; [idempotencyKey] makes a
  /// retry of the same summary return the first result.
  Future<DocumentSummary> summarizeDocument({
    required String text,
    required String fileName,
    required bool arabic,
    required int sourceChars,
    required bool extractionComplete,
    required String idempotencyKey,
    UploadProgress? onSendProgress,
    CancelToken? cancelToken,
  });

  /// The earlier explain contract (a summary as one text).
  Future<ReportExplanation> explain(String reportText, {bool arabic = false});

  /// A factual question about the attached document.
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  });
}

class UnconfiguredReportAiClient implements ReportAiClient {
  const UnconfiguredReportAiClient();

  static Future<T> _no<T>() =>
      Future.error(const ReportAiException(ReportAiFailureKind.unavailable));

  @override
  bool get isConfigured => false;

  @override
  Future<GatewayReadiness> checkReadiness() async =>
      GatewayReadiness.unconfigured;

  @override
  Future<ChatReply> chat({
    required String message,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  }) => _no();

  @override
  Future<DocumentSummary> summarizeDocument({
    required String text,
    required String fileName,
    required bool arabic,
    required int sourceChars,
    required bool extractionComplete,
    required String idempotencyKey,
    UploadProgress? onSendProgress,
    CancelToken? cancelToken,
  }) => _no();

  @override
  Future<ReportExplanation> explain(String reportText, {bool arabic = false}) =>
      _no();

  @override
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  }) => _no();
}

class GatewayReportAiClient implements ReportAiClient {
  GatewayReportAiClient({
    required String origin,
    required String token,
    Dio? dio,
    this.readinessTimeout = const Duration(seconds: 6),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: origin,
               connectTimeout: const Duration(seconds: 10),
               // Long documents are summarized in several provider calls.
               receiveTimeout: const Duration(seconds: 150),
               headers: {'Authorization': 'Bearer $token'},
               // Status codes are mapped below, never thrown as text.
               validateStatus: (_) => true,
             ),
           );

  final Dio _dio;
  final Duration readinessTimeout;

  @override
  bool get isConfigured => true;

  static String _bounded(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;

  static ReportAiFailureKind _forDio(DioException e) => switch (e.type) {
    DioExceptionType.cancel => ReportAiFailureKind.cancelled,
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => ReportAiFailureKind.timeout,
    // Offline, DNS, refused, TLS, or a browser CORS block (which the web
    // reports as a connection error).
    _ => ReportAiFailureKind.network,
  };

  /// The failure for a non-200 reply: the gateway's `code` when present,
  /// else the status.
  static ReportAiFailureKind _forStatus(int status, Object? body) {
    final code = body is Map ? body['code'] : null;
    switch (code) {
      case 'unauthorized' || 'origin_not_allowed':
        return ReportAiFailureKind.unauthorized;
      case 'not_configured' || 'provider_unavailable':
        return ReportAiFailureKind.providerUnavailable;
      case 'rate_limited' || 'provider_busy':
        return ReportAiFailureKind.rateLimited;
      case 'provider_timeout':
        return ReportAiFailureKind.timeout;
      case 'invalid' || 'too_large':
        return ReportAiFailureKind.rejected;
      case 'provider_failed' || 'invalid_reply':
        return ReportAiFailureKind.provider;
    }
    return switch (status) {
      401 || 403 => ReportAiFailureKind.unauthorized,
      503 => ReportAiFailureKind.providerUnavailable,
      404 => ReportAiFailureKind.unavailable,
      429 => ReportAiFailureKind.rateLimited,
      400 || 413 || 415 => ReportAiFailureKind.rejected,
      504 => ReportAiFailureKind.timeout,
      _ => ReportAiFailureKind.provider,
    };
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Options? options,
    UploadProgress? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        options: (options ?? Options()).copyWith(method: method),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ReportAiException(_forDio(e));
    }
    final status = response.statusCode ?? 0;
    if (status == 200) {
      if (response.data is Map) {
        return (response.data as Map).cast<String, dynamic>();
      }
      throw const ReportAiException(ReportAiFailureKind.invalidResponse);
    }
    throw ReportAiException(_forStatus(status, response.data));
  }

  static List<String> _strings(Object? raw) => [
    for (final q in (raw is List ? raw : const []))
      if (q is String) q,
  ];

  static List<Map<String, String>> _turns(List<ReportTurn> history) {
    final kept = history
        .where((t) => t.text.trim().isNotEmpty)
        .toList()
        .reversed
        .take(ReportAiLimits.maxHistoryTurns)
        .toList()
        .reversed;
    return [
      for (final t in kept)
        ReportTurn(
          fromPatient: t.fromPatient,
          text: _bounded(t.text, ReportAiLimits.maxHistoryChars),
        ).toJson(),
    ];
  }

  @override
  Future<GatewayReadiness> checkReadiness() async {
    try {
      final data = await _send(
        'GET',
        '/v1/health',
        options: Options(
          sendTimeout: readinessTimeout,
          receiveTimeout: readinessTimeout,
        ),
      ).timeout(readinessTimeout);
      return data['chat'] == true && data['summarize'] == true
          ? GatewayReadiness.available
          : GatewayReadiness.providerUnavailable;
    } on ReportAiException catch (e) {
      return switch (e.kind) {
        ReportAiFailureKind.unauthorized => GatewayReadiness.unauthorized,
        ReportAiFailureKind.providerUnavailable =>
          GatewayReadiness.providerUnavailable,
        _ => GatewayReadiness.unreachable,
      };
    } on Object {
      return GatewayReadiness.unreachable;
    }
  }

  @override
  Future<ChatReply> chat({
    required String message,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      'POST',
      '/v1/chat',
      body: {'message': message, 'history': _turns(history)},
      cancelToken: cancelToken,
    );
    final reply = data['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.invalidResponse);
    }
    return ChatReply(
      reply: reply.trim(),
      actions: _strings(data['actions']),
      medical: data['medical'] == true,
      emergency: data['emergency'] == true,
    );
  }

  @override
  Future<DocumentSummary> summarizeDocument({
    required String text,
    required String fileName,
    required bool arabic,
    required int sourceChars,
    required bool extractionComplete,
    required String idempotencyKey,
    UploadProgress? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final sent = _bounded(text, ReportAiLimits.maxSummaryChars);
    final data = await _send(
      'POST',
      '/v1/documents/summarize',
      body: {
        'text': sent,
        'lang': arabic ? 'ar' : 'en',
        'fileName': fileName,
        'sourceChars': sourceChars < sent.length ? sent.length : sourceChars,
        'extractionComplete': extractionComplete && sent.length == text.length,
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    final overview = data['overview'];
    if (overview is! String || overview.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.invalidResponse);
    }
    return DocumentSummary(
      overview: overview.trim(),
      points: _strings(data['points']),
      quotes: _strings(data['quotes']),
      readable: data['readable'] != false,
      coverage: SummaryCoverage.fromJson(
        (data['coverage'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  @override
  Future<ReportExplanation> explain(
    String reportText, {
    bool arabic = false,
  }) async {
    final data = await _send(
      'POST',
      '/v1/reports/explain',
      body: {
        'text': _bounded(reportText, ReportAiLimits.maxSummaryChars),
        'lang': arabic ? 'ar' : 'en',
      },
    );
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.invalidResponse);
    }
    return ReportExplanation(
      answer: answer.trim(),
      quotes: _strings(data['quotes']),
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
    CancelToken? cancelToken,
  }) async {
    final data = await _send(
      'POST',
      '/v1/reports/chat',
      body: {
        'text': _bounded(reportText, ReportAiLimits.maxTextChars),
        'question': question,
        'history': _turns(history),
      },
      cancelToken: cancelToken,
    );
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const ReportAiException(ReportAiFailureKind.invalidResponse);
    }
    final action = data['action'];
    return ReportAnswer(
      answer: answer.trim(),
      supported: data['supported'] == true,
      quotes: _strings(data['quotes']),
      action: action is String ? action : null,
      actions: _strings(data['actions']),
      refusal: data['refusal'] == true || data['medical'] == true,
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
