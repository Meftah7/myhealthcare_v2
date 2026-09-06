/// A message shown to one patient in the Notifications centre.
///
/// Named [AppNotification] to avoid colliding with Flutter's `Notification`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'notification.freezed.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String recipientId,
    required NotificationCategory category,
    required String title,
    required String body,
    required DateTime createdAt,
    String? deepLink,
    DateTime? readAt,
  }) = _AppNotification;

  const AppNotification._();

  bool get isRead => readAt != null;
}
