/// Notification state for the signed-in patient: a live feed, an unread count,
/// and marking messages read.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';

/// Every notification for the signed-in patient, newest first. A [Stream] so
/// the badge and list update the moment one is marked read.
final patientNotificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) {
    return const Stream<List<AppNotification>>.empty();
  }
  return ref
      .watch(notificationRepositoryProvider)
      .watchForRecipient(user.id);
});

/// How many are unread — for the header badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(patientNotificationsProvider)
      .maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

class NotificationController {
  NotificationController(this._ref);
  final Ref _ref;

  String? get _patientId {
    final user = _ref.read(currentUserProvider);
    return (user != null && user.isPatient) ? user.id : null;
  }

  Future<Result<void>> markRead(String id) async {
    final recipientId = _patientId;
    if (recipientId == null) {
      return const Err(AuthFailure('Sign in to read notifications.'));
    }
    return _ref
        .read(notificationRepositoryProvider)
        .markRead(id: id, recipientId: recipientId);
  }

  Future<Result<void>> markAllRead() async {
    final recipientId = _patientId;
    if (recipientId == null) {
      return const Err(AuthFailure('Sign in to read notifications.'));
    }
    return _ref
        .read(notificationRepositoryProvider)
        .markAllRead(recipientId);
  }
}

final notificationControllerProvider = Provider<NotificationController>(
  NotificationController.new,
);
