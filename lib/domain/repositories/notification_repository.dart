/// Notification contract: a patient's in-app messages and their read state.
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

class NewNotification {
  const NewNotification({
    required this.recipientId,
    required this.category,
    required this.title,
    required this.body,
    this.deepLink,
    this.createdAt,
  });

  final String recipientId;
  final NotificationCategory category;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime? createdAt;
}

/// Who an admin broadcast goes to (ported from the FirstSemMyHealth admin
/// "Quick Notification" send-to options).
enum NotificationAudience { allPatients, allStaff, everyone }

abstract interface class NotificationRepository {
  /// A recipient's notifications, newest first.
  Future<Result<List<AppNotification>>> forRecipient(String recipientId);

  /// Live feed for the same, so the unread badge updates without a refresh.
  Stream<List<AppNotification>> watchForRecipient(String recipientId);

  /// Marks one notification read.
  ///
  /// Scoped to [recipientId]: a notification belonging to someone else is
  /// treated as not found rather than silently updated (the PHP original had
  /// no such check).
  Future<Result<void>> markRead({
    required String id,
    required String recipientId,
  });

  Future<Result<void>> markAllRead(String recipientId);

  /// Queue [notification] for delivery through the outbox. Written in the
  /// caller's transaction when there is one, so it exists exactly when the
  /// change that caused it committed; delivery (and any retry) happens
  /// separately. Returns the outbox event id.
  Future<Result<String>> send(NewNotification notification);

  /// Fan a message out to everyone in [audience] (one row per recipient, each
  /// with its own read state). Returns the number of recipients. Admin only.
  Future<Result<int>> broadcast({
    required NotificationAudience audience,
    required NotificationCategory category,
    required String title,
    required String body,
    String? deepLink,
  });

  /// What did not go out (Phase 6, admin): side effects that exhausted their
  /// retries, reminders that failed for a reason other than the patient's
  /// own alert settings, and reminders still queued well past their time.
  Future<Result<DeliveryHealth>> deliveryHealth();

  /// Puts failed side effects back in the outbox queue for another round of
  /// retries (an administrator's correction). Returns how many.
  Future<Result<int>> retryFailedDeliveries();
}

/// Delivery problems an administrator should see and can correct.
class DeliveryHealth {
  const DeliveryHealth({
    required this.failedSideEffects,
    required this.failedReminders,
    required this.overdueReminders,
    this.oldestProblemAt,
  });

  final int failedSideEffects;
  final int failedReminders;

  /// Queued reminders more than an hour past due — the delivery loop is not
  /// keeping up (or nobody has opened the app).
  final int overdueReminders;
  final DateTime? oldestProblemAt;

  int get total => failedSideEffects + failedReminders + overdueReminders;
}
