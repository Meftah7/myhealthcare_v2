/// AI-facing tables: cached summaries, staff tasks, risk flags (P1-04).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

/// One cached summary per distinct patient context. Keyed for lookup by
/// [inputHash] so an unchanged context reuses the row — identical demo output
/// every run, no wasted API calls (P3-08).
@DataClassName('AiSummaryRow')
class AiSummaries extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get generatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Traceability (P3-14).
  TextColumn get modelId => text()();
  TextColumn get promptVersion => text()();

  TextColumn get summaryMarkdown => text()();

  /// JSON arrays — parsed into typed models by the AI layer.
  TextColumn get keyEventsJson => text().withDefault(const Constant('[]'))();
  TextColumn get trendsJson => text().withDefault(const Constant('[]'))();
  TextColumn get redFlagsJson => text().withDefault(const Constant('[]'))();

  /// Hash of the context the summary was generated from (cache key).
  TextColumn get inputHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StaffTaskRow')
class StaffTasks extends Table {
  TextColumn get id => text()();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get patientId => text().nullable().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get kind => textEnum<TaskKind>()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('open'))();

  /// Deterministic rule score (P5-03) — always present.
  RealColumn get ruleScore => real().withDefault(const Constant(0))();

  /// LLM priority + rationale (P5-10) — null when AI is off.
  RealColumn get aiPriorityScore => real().nullable()();
  TextColumn get aiRationale => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RiskFlagRow')
class RiskFlags extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<RiskFlagKind>()();
  TextColumn get severity => textEnum<Severity>()();
  TextColumn get rationale => text()();
  DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get source =>
      textEnum<FlagSource>().withDefault(const Constant('rule'))();

  /// De-duplication key so the same finding isn't re-flagged daily (P5-02).
  TextColumn get dedupeKey => text()();

  TextColumn get acknowledgedBy => text().nullable().references(Users, #id)();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
