/// Parses the model's JSON summary contract into a [HealthSummary] (P3-04).
///
/// Tolerates the model wrapping the JSON in prose or ```json fences. Throws
/// [AiFailure] on anything it cannot make sense of — callers fall back to mock.
library;

import 'dart:convert';

import '../../core/failures.dart';
import '../../domain/entities/ai_summary.dart';
import '../../domain/enums.dart';
import 'ai_models.dart';

HealthSummary parseHealthSummary(
  String raw, {
  required String modelId,
  required String promptVersion,
}) {
  final json = _extractJsonObject(raw);
  final Map<String, dynamic> map;
  try {
    map = jsonDecode(json) as Map<String, dynamic>;
  } catch (e) {
    throw AiFailure('The AI response was not valid JSON.', cause: e);
  }

  final summary = (map['summary'] as String?)?.trim();
  if (summary == null || summary.isEmpty) {
    throw const AiFailure('The AI response had no summary.');
  }

  return HealthSummary(
    summaryMarkdown: summary,
    modelId: modelId,
    promptVersion: promptVersion,
    keyEvents: _list(map['keyEvents'], _keyEvent),
    trends: _list(map['trends'], _trend),
    redFlags: _list(map['redFlags'], _redFlag),
  );
}

String _extractJsonObject(String raw) {
  var s = raw.trim();
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(s);
  if (fence != null) s = fence.group(1)!.trim();
  final start = s.indexOf('{');
  final end = s.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw const AiFailure('No JSON object found in the AI response.');
  }
  return s.substring(start, end + 1);
}

List<T> _list<T>(Object? node, T Function(Map<String, dynamic>) fromMap) {
  if (node is! List) return const [];
  final out = <T>[];
  for (final item in node) {
    if (item is Map<String, dynamic>) {
      try {
        out.add(fromMap(item));
      } catch (_) {
        // Skip malformed entries rather than fail the whole parse.
      }
    }
  }
  return out;
}

KeyEvent _keyEvent(Map<String, dynamic> m) => KeyEvent(
  date: DateTime.parse(m['date'] as String),
  title: (m['title'] as String).trim(),
  description: (m['description'] as String?)?.trim(),
  category: (m['category'] as String?)?.trim(),
);

Trend _trend(Map<String, dynamic> m) => Trend(
  metric: (m['metric'] as String).trim(),
  direction: (m['direction'] as String?)?.trim() ?? 'stable',
  summary: (m['summary'] as String).trim(),
);

RedFlag _redFlag(Map<String, dynamic> m) => RedFlag(
  severity: _severity(m['severity'] as String?),
  description: (m['description'] as String).trim(),
);

Severity _severity(String? s) => switch (s) {
  'urgent' => Severity.urgent,
  'warning' => Severity.warning,
  _ => Severity.info,
};
