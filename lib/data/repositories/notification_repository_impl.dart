/// Drift-backed [NotificationRepository].
library;

import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/notification_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$NotificationsTable, NotificationRow> _query(
    String recipientId,
  ) =>
      _db.select(_db.notifications)
        ..where((n) => n.recipientId.equals(recipientId))
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);

  @override
  Future<Result<List<AppNotification>>> forRecipient(String recipientId) {
    return Result.guardAsync(() async {
      final rows = await _query(recipientId).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<AppNotification>> watchForRecipient(String recipientId) {
    return _query(
      recipientId,
    ).watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<void>> markRead({
    required String id,
    required String recipientId,
  }) {
    return Result.guardAsync(() async {
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
      await (_db.update(_db.notifications)..where(
            (n) => n.recipientId.equals(recipientId) & n.readAt.isNull(),
          ))
          .write(NotificationsCompanion(readAt: Value(DateTime.now())));
    });
  }

  @override
  Future<Result<AppNotification>> send(NewNotification n) {
    return Result.guardAsync(() async {
      final id = newId('ntf');
      await _db
          .into(_db.notifications)
          .insert(
            NotificationsCompanion.insert(
              id: id,
              recipientId: n.recipientId,
              category: n.category,
              title: n.title,
              body: n.body,
              deepLink: Value(n.deepLink),
              createdAt: Value(n.createdAt ?? DateTime.now()),
            ),
          );
      final row = await (_db.select(
        _db.notifications,
      )..where((r) => r.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }
}
