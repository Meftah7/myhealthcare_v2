/// Notification state for the signed-in patient: a live feed, an unread count,
/// and marking messages read.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';

/// Every notification for the signed-in user, newest first — patient, staff or
/// admin alike (an admin broadcast can target staff). A [Stream] so the badge
/// and list update the moment one is marked read.
final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream<List<AppNotification>>.empty();
  return ref.watch(notificationRepositoryProvider).watchForRecipient(user.id);
});

/// How many are unread — for the header badge.
/// Null while the feed is loading or failed — never a reassuring 0.
final unreadNotificationCountProvider = Provider<int?>((ref) {
  final feed = ref.watch(myNotificationsProvider);
  if (feed.hasError || !feed.hasValue) return null;
  return feed.requireValue.where((n) => !n.isRead).length;
});

class NotificationController {
  NotificationController(this._ref);
  final Ref _ref;

  /// The signed-in recipient, whatever their role — staff and admins own
  /// notifications too, and the repository scopes every write to this id.
  String? get _recipientId => _ref.read(currentUserProvider)?.id;

  Future<Result<void>> markRead(String id) async {
    final recipientId = _recipientId;
    if (recipientId == null) {
      return const Err(AuthFailure('Sign in to read notifications.'));
    }
    return _ref
        .read(notificationRepositoryProvider)
        .markRead(id: id, recipientId: recipientId);
  }

  Future<Result<void>> markAllRead() async {
    final recipientId = _recipientId;
    if (recipientId == null) {
      return const Err(AuthFailure('Sign in to read notifications.'));
    }
    return _ref.read(notificationRepositoryProvider).markAllRead(recipientId);
  }
}

final notificationControllerProvider = Provider<NotificationController>(
  NotificationController.new,
);
