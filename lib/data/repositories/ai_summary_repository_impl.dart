/// Drift-backed [AiSummaryRepository] — the cache store (P1-17, P3-08).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/ai_repository.dart';
import '../db/app_database.dart';

class AiSummaryRepositoryImpl implements AiSummaryRepository {
  AiSummaryRepositoryImpl(this._db);

  final AppDatabase _db;

  AiSummary _toEntity(AiSummaryRow r) => AiSummary(
    id: r.id,
    patientId: r.patientId,
    generatedAt: r.generatedAt,
    modelId: r.modelId,
    promptVersion: r.promptVersion,
    summaryMarkdown: r.summaryMarkdown,
    inputHash: r.inputHash,
    keyEvents: _decodeKeyEvents(r.keyEventsJson),
    trends: _decodeTrends(r.trendsJson),
    redFlags: _decodeRedFlags(r.redFlagsJson),
  );

  @override
  Future<Result<AiSummary?>> cachedFor(String inputHash) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.aiSummaries)
                ..where((s) => s.inputHash.equals(inputHash))
                ..orderBy([(s) => OrderingTerm.desc(s.generatedAt)])
                ..limit(1))
              .getSingleOrNull();
      return row == null ? null : _toEntity(row);
    });
  }

  @override
  Future<Result<AiSummary?>> latestForPatient(String patientId) {
    return Result.guardAsync(() async {
      final row =
          await (_db.select(_db.aiSummaries)
                ..where((s) => s.patientId.equals(patientId))
                ..orderBy([(s) => OrderingTerm.desc(s.generatedAt)])
                ..limit(1))
              .getSingleOrNull();
      return row == null ? null : _toEntity(row);
    });
  }

  @override
  Future<Result<void>> save(AiSummary s) {
    return Result.guardAsync(() async {
      await _db
          .into(_db.aiSummaries)
          .insertOnConflictUpdate(
            AiSummariesCompanion.insert(
              id: s.id,
              patientId: s.patientId,
              modelId: s.modelId,
              promptVersion: s.promptVersion,
              summaryMarkdown: s.summaryMarkdown,
              inputHash: s.inputHash,
              generatedAt: Value(s.generatedAt),
              keyEventsJson: Value(
                jsonEncode(s.keyEvents.map(_encodeKeyEvent).toList()),
              ),
              trendsJson: Value(
                jsonEncode(s.trends.map(_encodeTrend).toList()),
              ),
              redFlagsJson: Value(
                jsonEncode(s.redFlags.map(_encodeRedFlag).toList()),
              ),
            ),
          );
    });
  }
}

// --- JSON codecs for the summary parts -------------------------------------

Map<String, dynamic> _encodeKeyEvent(KeyEvent e) => {
  'date': e.date.toIso8601String(),
  'title': e.title,
  'description': e.description,
  'category': e.category,
  'recordId': e.recordId,
};

List<KeyEvent> _decodeKeyEvents(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>().map((m) {
      return KeyEvent(
        date: DateTime.parse(m['date'] as String),
        title: m['title'] as String,
        description: m['description'] as String?,
        category: m['category'] as String?,
        recordId: m['recordId'] as String?,
      );
    }).toList();

Map<String, dynamic> _encodeTrend(Trend t) => {
  'metric': t.metric,
  'direction': t.direction,
  'summary': t.summary,
};

List<Trend> _decodeTrends(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>().map((m) {
      return Trend(
        metric: m['metric'] as String,
        direction: m['direction'] as String,
        summary: m['summary'] as String,
      );
    }).toList();

Map<String, dynamic> _encodeRedFlag(RedFlag f) => {
  'severity': f.severity.name,
  'description': f.description,
};

List<RedFlag> _decodeRedFlags(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>().map((m) {
      return RedFlag(
        severity: Severity.values.byName(m['severity'] as String),
        description: m['description'] as String,
      );
    }).toList();
