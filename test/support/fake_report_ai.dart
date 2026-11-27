/// A scriptable [ReportAiClient] for tests: records every call, returns
/// configured replies, fails on demand, reports upload progress the way Dio
/// does, and can hold a request open (to test cancellation and stale
/// replies). A mocked contract — not a live-provider test.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:myhealthcare/services/ai/report_ai_client.dart';

class FakeReportAiClient implements ReportAiClient {
  FakeReportAiClient({this.readiness = GatewayReadiness.available});

  GatewayReadiness readiness;
  int readinessChecks = 0;

  final chats = <({String message, List<ReportTurn> history})>[];
  final asked = <({String question, List<ReportTurn> history})>[];
  final summaries =
      <
        ({String text, String key, int sourceChars, bool complete, bool arabic})
      >[];
  final explained = <String>[];

  /// Thrown (once) by the next call.
  ReportAiException? failNext;

  /// When set, requests wait for it before answering.
  Completer<void>? hold;

  ChatReply chatReply = const ChatReply(
    reply: 'Open Appointments to choose a time.',
    actions: ['open_appointments'],
  );

  ReportAnswer answer = const ReportAnswer(
    answer: 'The document labels HbA1c 7.9 % as High (4.0–5.6).',
    supported: true,
    quotes: ['HbA1c 7.9 % H (4.0–5.6)'],
    coverage: ReportCoverage(
      explainedChars: 60,
      totalChars: 60,
      complete: true,
    ),
  );

  DocumentSummary summary = const DocumentSummary(
    overview: 'A synthetic laboratory report.',
    points: ['The document labels HbA1c 7.9 % as High.'],
    quotes: ['HbA1c 7.9 % H (4.0–5.6)'],
    coverage: SummaryCoverage(
      sourceChars: 60,
      processedChars: 60,
      complete: true,
    ),
  );

  ReportExplanation explanation = const ReportExplanation(
    answer:
        'A synthetic laboratory report.\n• The document labels HbA1c 7.9 % as High.',
    coverage: ReportCoverage(
      explainedChars: 60,
      totalChars: 60,
      complete: true,
    ),
  );

  /// Upload progress events to report, as (sent, total) pairs.
  List<(int, int)> progress = const [(0, 1000), (400, 1000), (1000, 1000)];

  @override
  bool get isConfigured => true;

  Future<void> _gate(CancelToken? token) async {
    if (failNext case final e?) {
      failNext = null;
      throw e;
    }
    if (hold case final h?) {
      await Future.any([
        h.future,
        if (token != null)
          token.whenCancel.then(
            (_) => throw const ReportAiException(ReportAiFailureKind.cancelled),
          ),
      ]);
    }
    if (token?.isCancelled ?? false) {
      throw const ReportAiException(ReportAiFailureKind.cancelled);
    }
  }

  @override
  Future<GatewayReadiness> checkReadiness() async {
    readinessChecks++;
    return readiness;
  }

  @override
  Future<ChatReply> chat({
    required String message,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  }) async {
    chats.add((message: message, history: history));
    await _gate(cancelToken);
    return chatReply;
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
    summaries.add((
      text: text,
      key: idempotencyKey,
      sourceChars: sourceChars,
      complete: extractionComplete,
      arabic: arabic,
    ));
    for (final (sent, total) in progress) {
      onSendProgress?.call(sent, total);
      await Future<void>.delayed(Duration.zero);
    }
    await _gate(cancelToken);
    return summary;
  }

  @override
  Future<ReportExplanation> explain(
    String reportText, {
    bool arabic = false,
  }) async {
    explained.add(reportText);
    await _gate(null);
    return explanation;
  }

  @override
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
    CancelToken? cancelToken,
  }) async {
    asked.add((question: question, history: history));
    await _gate(cancelToken);
    return answer;
  }
}
