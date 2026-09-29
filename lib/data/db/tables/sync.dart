/// Mutation-safety tables (Phase 2): idempotency records and the outbox.
library;

import 'package:drift/drift.dart';

/// One committed mutation, keyed by the caller's idempotency key. Written in
/// the same transaction as the mutation, so a retry either finds this row
/// (and gets the original result back) or the mutation never happened.
@DataClassName('IdempotencyRecordRow')
class IdempotencyRecords extends Table {
  TextColumn get key => text()();

  /// What kind of mutation used the key (`appointment.book`,
  /// `billing.pay`…). Reusing a key for a different mutation is refused.
  TextColumn get scope => text()();

  /// The signed-in account that made the request. A key is never honoured
  /// for a different account.
  TextColumn get actorAccountId => text().nullable()();

  /// Id of the object the mutation produced or changed, returned on retry.
  TextColumn get resultRef => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

enum OutboxStatus { pending, delivered, failed }

/// A side effect (a notification today; email/SMS/push/webhooks later)
/// recorded in the same transaction as the change that caused it, then
/// delivered — and retried — separately. The core change never waits on,
/// or rolls back because of, delivery.
@DataClassName('OutboxEventRow')
class OutboxEvents extends Table {
  TextColumn get id => text()();

  /// Handler name, e.g. `notification.deliver`.
  TextColumn get type => text()();

  /// JSON payload for the handler.
  TextColumn get payload => text()();
  TextColumn get status =>
      textEnum<OutboxStatus>().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  /// Last failure reason (never payload content).
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
