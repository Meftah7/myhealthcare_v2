/// System tables: audit log, app settings (P1-05).
library;

import 'package:drift/drift.dart';

import 'users.dart';

/// Append-only trail of security-relevant actions (feeds the privacy chapter).
@DataClassName('AuditLogRow')
class AuditLog extends Table {
  TextColumn get id => text()();
  TextColumn get actorUserId => text().nullable().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get detail => text().nullable()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row settings table. The app enforces exactly one row (id == 1).
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get aiEnabled => boolean().withDefault(const Constant(true))();

  /// When true, the app uses MockAiService regardless of key presence (P3-07).
  BoolColumn get mockMode => boolean().withDefault(const Constant(true))();
  TextColumn get modelId =>
      text().withDefault(const Constant('claude-sonnet-5'))();

  /// AI-score weight when blended with the deterministic rule score (P5-10),
  /// 0.0–1.0.
  RealColumn get aiTaskWeight => real().withDefault(const Constant(0.5))();

  /// Bumped by the seeder so re-seeds are detectable (P1-21).
  IntColumn get seedVersion => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
