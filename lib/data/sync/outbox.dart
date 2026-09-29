/// The transactional outbox (Phase 2).
///
/// A change and the side effects it causes are recorded together: the
/// [Outbox] writes an event row using whatever transaction the caller is in,
/// so the event exists if and only if the change committed. The
/// [OutboxDispatcher] then delivers events separately, retrying with backoff;
/// a delivery failure never undoes, blocks, or duplicates the change.
///
/// Today the only side effect is an in-app notification. Email/SMS/push or
/// webhooks become new handlers without touching the code that causes them.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/notification_repository.dart';
import '../db/app_database.dart';
import '../db/tables/sync.dart';

/// Event types the dispatcher knows how to deliver.
abstract final class OutboxTypes {
  static const deliverNotification = 'notification.deliver';
}

class Outbox {
  Outbox(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Record a notification for delivery. Call inside the transaction of the
  /// change that causes it. Returns the event id.
  Future<String> enqueueNotification(NewNotification n) {
    return enqueue(OutboxTypes.deliverNotification, {
      'recipientId': n.recipientId,
      'category': n.category.name,
      'title': n.title,
      'body': n.body,
      'deepLink': n.deepLink,
      'createdAt': (n.createdAt ?? _now()).toIso8601String(),
    });
  }

  Future<String> enqueue(String type, Map<String, Object?> payload) async {
    final id = newId('evt');
    final now = _now();
    await _db
        .into(_db.outboxEvents)
        .insert(
          OutboxEventsCompanion.insert(
            id: id,
            type: type,
            payload: jsonEncode(payload),
            createdAt: now,
            nextAttemptAt: now,
          ),
        );
    return id;
  }
}

typedef OutboxHandler =
    Future<void> Function(OutboxEventRow event, Map<String, Object?> payload);

/// Delivers due outbox events. Safe to call repeatedly and concurrently:
/// only one drain runs at a time, and delivery is idempotent per event.
class OutboxDispatcher {
  OutboxDispatcher(
    this._db, {
    Map<String, OutboxHandler>? handlers,
    DateTime Function()? now,
    this.maxAttempts = 8,
  }) : _now = now ?? DateTime.now {
    _handlers = {
      OutboxTypes.deliverNotification: _deliverNotification,
      ...?handlers,
    };
  }

  final AppDatabase _db;
  final DateTime Function() _now;
  final int maxAttempts;
  late final Map<String, OutboxHandler> _handlers;
  Future<int>? _running;

  /// Retry delay after the [attempt]th failure: 2, 4, 8… seconds, capped at
  /// one hour.
  static Duration backoff(int attempt) =>
      Duration(seconds: min(3600, pow(2, attempt).toInt()));

  /// Deliver every due event. Returns how many were delivered.
  Future<int> drain() {
    final running = _running;
    if (running != null) return running;
    final run = _drain().whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  /// Fire-and-forget [drain] for "deliver soon" — errors are recorded on the
  /// events themselves, never thrown at the caller.
  void kick() => unawaited(drain().catchError((Object _) => 0));

  Future<int> _drain() async {
    var delivered = 0;
    final due =
        await (_db.select(_db.outboxEvents)
              ..where(
                (e) =>
                    e.status.equalsValue(OutboxStatus.pending) &
                    e.nextAttemptAt.isSmallerOrEqualValue(_now()),
              )
              ..orderBy([(e) => OrderingTerm(expression: e.createdAt)]))
            .get();
    for (final event in due) {
      if (await _deliver(event)) delivered++;
    }
    if (autoRetry) await _armRetry();
    return delivered;
  }

  /// When true, the dispatcher wakes itself for the next retry — so a failed
  /// delivery is retried without waiting for another user action. Off for
  /// dispatchers built ad hoc (tests, one-off drains).
  bool autoRetry = false;
  Timer? _retry;

  /// One timer, only while undelivered events remain, set for the earliest
  /// retry time. Nothing is scheduled when the outbox is clear.
  Future<void> _armRetry() async {
    _retry?.cancel();
    _retry = null;
    final next =
        await (_db.select(_db.outboxEvents)
              ..where((e) => e.status.equalsValue(OutboxStatus.pending))
              ..orderBy([(e) => OrderingTerm(expression: e.nextAttemptAt)])
              ..limit(1))
            .getSingleOrNull();
    if (next == null) return;
    final wait = next.nextAttemptAt.difference(_now());
    _retry = Timer(wait.isNegative ? Duration.zero : wait, kick);
  }

  void dispose() {
    autoRetry = false;
    _retry?.cancel();
    _retry = null;
  }

  Future<bool> _deliver(OutboxEventRow event) async {
    final attempts = event.attempts + 1;
    final handler = _handlers[event.type];
    try {
      if (handler == null) {
        throw StateError('No handler for ${event.type}');
      }
      final payload = jsonDecode(event.payload) as Map<String, Object?>;
      await handler(event, payload);
      await (_db.update(
        _db.outboxEvents,
      )..where((e) => e.id.equals(event.id))).write(
        OutboxEventsCompanion(
          status: const Value(OutboxStatus.delivered),
          attempts: Value(attempts),
          deliveredAt: Value(_now()),
          lastError: const Value(null),
        ),
      );
      return true;
    } on Object catch (error) {
      final exhausted = attempts >= maxAttempts;
      await (_db.update(
        _db.outboxEvents,
      )..where((e) => e.id.equals(event.id))).write(
        OutboxEventsCompanion(
          status: Value(exhausted ? OutboxStatus.failed : OutboxStatus.pending),
          attempts: Value(attempts),
          nextAttemptAt: Value(_now().add(backoff(attempts))),
          // The type only — an error message could echo payload content.
          lastError: Value(error.runtimeType.toString()),
        ),
      );
      onFailure?.call(exhausted: exhausted);
      return false;
    }
  }

  /// Told about each failed delivery (no payload or error text).
  void Function({required bool exhausted})? onFailure;

  /// One notification row per event: the event id is stored on the row and
  /// uniquely indexed, so a retry after a crash between "inserted" and
  /// "marked delivered" is a no-op instead of a duplicate.
  Future<void> _deliverNotification(
    OutboxEventRow event,
    Map<String, Object?> p,
  ) async {
    await _db
        .into(_db.notifications)
        .insert(
          NotificationsCompanion.insert(
            id: newId('ntf'),
            recipientId: p['recipientId']! as String,
            category: NotificationCategory.values.byName(
              p['category']! as String,
            ),
            title: p['title']! as String,
            body: p['body']! as String,
            deepLink: Value(p['deepLink'] as String?),
            createdAt: Value(DateTime.parse(p['createdAt']! as String)),
            sourceEventId: Value(event.id),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
