/// Drift-backed [NotificationRepository].
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import '../db/tables/sync.dart';
import '../sync/outbox.dart';
import 'mappers.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._db, {AccessPolicy? access, Outbox? outbox})
    : _access = access ?? AccessPolicy.unenforced(_db),
      _outbox = outbox ?? Outbox(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final Outbox _outbox;

  /// An inbox belongs to one account; nobody else reads or clears it.
  Future<void> _ownInbox(String recipientId, {String? entityId}) => _access
      .assertActor(recipientId, entityType: 'notification', entityId: entityId);

  SimpleSelectStatement<$NotificationsTable, NotificationRow> _query(
    String recipientId,
  ) => _db.select(_db.notifications)
    ..where((n) => n.recipientId.equals(recipientId))
    ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);

  @override
  Future<Result<List<AppNotification>>> forRecipient(String recipientId) {
    return Result.guardAsync(() async {
      await _ownInbox(recipientId);
      final rows = await _query(recipientId).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<AppNotification>> watchForRecipient(String recipientId) {
    return authorizedStream(
      () => _ownInbox(recipientId),
      () => _query(
        recipientId,
      ).watch().map((rows) => rows.map((r) => r.toEntity()).toList()),
    );
  }

  @override
  Future<Result<void>> markRead({
    required String id,
    required String recipientId,
  }) {
    return Result.guardAsync(() async {
      await _ownInbox(recipientId, entityId: id);
      // recipientId is part of the predicate, so another patient's row simply
      // matches nothing rather than being updated.
      await (_db.update(_db.notifications)..where(
            (n) =>
                n.id.equals(id) &
                n.recipientId.equals(recipientId) &
                n.readAt.isNull(),
          ))
          .write(NotificationsCompanion(readAt: Value(DateTime.now())));
    });
  }

  @override
  Future<Result<void>> markAllRead(String recipientId) {
    return Result.guardAsync(() async {
      await _ownInbox(recipientId);
      await (_db.update(_db.notifications)..where(
            (n) => n.recipientId.equals(recipientId) & n.readAt.isNull(),
          ))
          .write(NotificationsCompanion(readAt: Value(DateTime.now())));
    });
  }

  @override
  Future<Result<String>> send(NewNotification n) {
    return Result.guardAsync(() async {
      // Event notifications are raised by the app on behalf of whoever is
      // signed in (a booking confirmation, a new message).
      await _access.principal();
      return _outbox.enqueueNotification(n);
    });
  }

  @override
  Future<Result<int>> broadcast({
    required NotificationAudience audience,
    required NotificationCategory category,
    required String title,
    required String body,
    String? deepLink,
  }) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.broadcastNotifications,
        entityType: 'notification',
      );
      final roles = switch (audience) {
        NotificationAudience.allPatients => [UserRole.patient],
        NotificationAudience.allStaff => [UserRole.staff],
        NotificationAudience.everyone => [UserRole.patient, UserRole.staff],
      };
      final recipients =
          await (_db.select(_db.users)..where(
                (u) => u.role.isInValues(roles) & u.isActive.equals(true),
              ))
              .get();
      final now = DateTime.now();
      await _db.batch((b) {
        for (final u in recipients) {
          b.insert(
            _db.notifications,
            NotificationsCompanion.insert(
              id: newId('ntf'),
              recipientId: u.id,
              category: category,
              title: title,
              body: body,
              deepLink: Value(deepLink),
              createdAt: Value(now),
            ),
          );
        }
      });
      return recipients.length;
    });
  }

  @override
  Future<Result<DeliveryHealth>> deliveryHealth() {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.viewOperationalReports,
        entityType: 'delivery',
      );
      final failedEvents = await (_db.select(
        _db.outboxEvents,
      )..where((e) => e.status.equalsValue(OutboxStatus.failed))).get();
      // A refused or unsupported browser alert is the patient's setting,
      // not a delivery fault — the in-app copy still went out.
      final failedReminders =
          await (_db.select(_db.reminders)..where(
                (r) =>
                    r.deliveryStatus.equalsValue(
                      ReminderDeliveryStatus.failed,
                    ) &
                    r.lastError.equals('transient_failure'),
              ))
              .get();
      final overdue =
          await (_db.select(_db.reminders)..where(
                (r) =>
                    r.deliveryStatus.equalsValue(
                      ReminderDeliveryStatus.queued,
                    ) &
                    r.scheduledFor.isSmallerThanValue(
                      DateTime.now().subtract(const Duration(hours: 1)),
                    ),
              ))
              .get();
      final times = <DateTime>[
        for (final e in failedEvents) e.createdAt,
        for (final r in failedReminders) r.scheduledFor,
        for (final r in overdue) r.scheduledFor,
      ]..sort();
      return DeliveryHealth(
        failedSideEffects: failedEvents.length,
        failedReminders: failedReminders.length,
        overdueReminders: overdue.length,
        oldestProblemAt: times.firstOrNull,
      );
    });
  }

  @override
  Future<Result<int>> retryFailedDeliveries() {
    return Result.guardAsync(() async {
      await _access.require(Permission.manageSettings, entityType: 'delivery');
      final n =
          await (_db.update(
            _db.outboxEvents,
          )..where((e) => e.status.equalsValue(OutboxStatus.failed))).write(
            OutboxEventsCompanion(
              status: const Value(OutboxStatus.pending),
              attempts: const Value(0),
              nextAttemptAt: Value(DateTime.now()),
            ),
          );
      await _access.audit(
        'delivery.retry_failed',
        entityType: 'delivery',
        detail: '$n event(s)',
      );
      return n;
    });
  }
}
