/// Cached AI health summary and its parts (P1-10).
///
/// This is the *persisted* record (metadata + cached output). P3-01 defines the
/// live AI *response* models; [KeyEvent] / [Trend] / [RedFlag] are shared.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'ai_summary.freezed.dart';

@freezed
abstract class KeyEvent with _$KeyEvent {
  const factory KeyEvent({
    required DateTime date,
    required String title,
    String? description,
    String? category,
    String? recordId,
  }) = _KeyEvent;
}

@freezed
abstract class Trend with _$Trend {
  const factory Trend({
    required String metric,
    required String direction, // 'up' | 'down' | 'stable'
    required String summary,
  }) = _Trend;
}

@freezed
abstract class RedFlag with _$RedFlag {
  const factory RedFlag({
    required Severity severity,
    required String description,
  }) = _RedFlag;
}

@freezed
abstract class AiSummary with _$AiSummary {
  const factory AiSummary({
    required String id,
    required String patientId,
    required DateTime generatedAt,
    required String modelId,
    required String promptVersion,
    required String summaryMarkdown,
    required String inputHash,
    @Default([]) List<KeyEvent> keyEvents,
    @Default([]) List<Trend> trends,
    @Default([]) List<RedFlag> redFlags,
  }) = _AiSummary;
}
