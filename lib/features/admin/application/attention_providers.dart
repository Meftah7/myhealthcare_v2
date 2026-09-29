/// The administrator's exception queues (Phase 6): work that is overdue,
/// unowned, unconfirmed or undelivered — each with how much, how old, and
/// where to fix it. Replaces vanity totals as the dashboard's focus.
///
/// Every queue is its own provider, so one failing read shows as "couldn't
/// check" on its own row and never hides the others — or turns into an
/// all-clear.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/di.dart';
import '../../../core/observability/operational_metrics.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../care/application/care_providers.dart';
import 'admin_providers.dart';

enum AttentionKind {
  resultReviews,
  unansweredMessages,
  referrals,
  unconfirmedPayments,
  deliveries,
  overdueInvoices,
  passwordResets,
  homeVisits,
  feedback,
}

/// One exception queue as the dashboard shows it.
class AttentionItem {
  const AttentionItem({
    required this.kind,
    required this.count,
    required this.route,
    this.oldest,
    this.parts = const {},
  });

  final AttentionKind kind;
  final int count;

  /// Where to fix it.
  final String route;

  /// When the longest-waiting item started waiting.
  final DateTime? oldest;

  /// Breakdown worth naming ("unassigned" → 2, "overdue" → 1).
  final Map<String, int> parts;
}

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

DateTime? _earliest(Iterable<DateTime?> times) {
  final list = [...times.whereType<DateTime>()]..sort();
  return list.firstOrNull;
}

/// Open result reviews that are unassigned, overdue or escalated.
final resultReviewAttentionProvider = FutureProvider<AttentionItem>((
  ref,
) async {
  final reviews = _unwrap(
    await ref
        .watch(resultReviewRepositoryProvider)
        .openReviews(needsAttentionOnly: true),
  );
  final now = DateTime.now();
  return AttentionItem(
    kind: AttentionKind.resultReviews,
    count: reviews.length,
    route: AppRoutes.adminWorkQueue,
    oldest: _earliest(reviews.map((r) => r.createdAt)),
    parts: {
      'unassigned': reviews.where((r) => r.ownerStaffId == null).length,
      'overdue': reviews.where((r) => r.isOverdueAt(now)).length,
      'escalated': reviews
          .where((r) => r.status == ResultReviewStatus.escalated)
          .length,
    },
  );
});

/// Patient messages past their reply-by time.
final overdueMessagesProvider = FutureProvider<List<CareMessage>>((ref) async {
  final waiting = _unwrap(
    await ref.watch(careMessageRepositoryProvider).awaitingReply(),
  );
  final now = DateTime.now();
  final overdue = waiting.where((m) => m.isOverdueAt(now)).toList();
  if (overdue.isNotEmpty) {
    recordThrottled(
      ref.read(operationalMetricsProvider),
      OperationalSignal.followUpOverdue,
      workflow: 'care_messages',
      count: overdue.length,
    );
  }
  return overdue;
});

final messageAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final overdue = await ref.watch(overdueMessagesProvider.future);
  return AttentionItem(
    kind: AttentionKind.unansweredMessages,
    count: overdue.length,
    route: AppRoutes.adminWorkQueue,
    oldest: _earliest(overdue.map((m) => m.sentAt)),
  );
});

/// Open referrals with no owner, past due, or waiting on clarification.
final referralAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final open = await ref.watch(pendingReferralRequestsProvider.future);
  final now = DateTime.now();
  final unowned = open.where((r) => r.ownerStaffId == null).toList();
  final overdue = open
      .where((r) => r.dueAt != null && r.dueAt!.isBefore(now))
      .toList();
  return AttentionItem(
    kind: AttentionKind.referrals,
    count: open.length,
    route: AppRoutes.adminReferralRequests,
    oldest: _earliest(open.map((r) => r.createdAt)),
    parts: {'unowned': unowned.length, 'overdue': overdue.length},
  );
});

/// Card payments still being confirmed, and money that settled against a
/// bill that was no longer open (needs a refund).
final paymentAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final all = _unwrap(
    await ref.watch(billingRepositoryProvider).transactions(),
  );
  final unconfirmed = all.where((t) => t.isInFlight).toList();
  final needsRefund = all
      .where((t) => t.isSettled && t.failureReason == 'invoice_not_open')
      .toList();
  return AttentionItem(
    kind: AttentionKind.unconfirmedPayments,
    count: unconfirmed.length + needsRefund.length,
    route: AppRoutes.adminBilling,
    oldest: _earliest([
      ...unconfirmed.map((t) => t.createdAt),
      ...needsRefund.map((t) => t.createdAt),
    ]),
    parts: {
      'unconfirmed': unconfirmed.length,
      'needsRefund': needsRefund.length,
    },
  );
});

final deliveryAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final health = _unwrap(
    await ref.watch(notificationRepositoryProvider).deliveryHealth(),
  );
  return AttentionItem(
    kind: AttentionKind.deliveries,
    count: health.total,
    route: AppRoutes.adminWorkQueue,
    oldest: health.oldestProblemAt,
    parts: {
      'failed': health.failedSideEffects + health.failedReminders,
      'late': health.overdueReminders,
    },
  );
});

/// Unpaid invoices past their due date — not every unpaid bill.
final overdueInvoiceAttentionProvider = FutureProvider<AttentionItem>((
  ref,
) async {
  final pending = await ref.watch(
    allInvoicesProvider(InvoiceStatus.pending).future,
  );
  final overdue = pending.where((i) => i.isOverdue).toList();
  return AttentionItem(
    kind: AttentionKind.overdueInvoices,
    count: overdue.length,
    route: AppRoutes.adminBilling,
    oldest: _earliest(overdue.map((i) => i.dueDate)),
  );
});

final passwordResetAttentionProvider = FutureProvider<AttentionItem>((
  ref,
) async {
  final ids = await ref.watch(pendingPasswordResetUserIdsProvider.future);
  return AttentionItem(
    kind: AttentionKind.passwordResets,
    count: ids.length,
    route: AppRoutes.adminUsers,
  );
});

final homeVisitAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final requested = await ref.watch(
    homeVisitQueueProvider(HomeVisitStatus.requested).future,
  );
  return AttentionItem(
    kind: AttentionKind.homeVisits,
    count: requested.length,
    route: AppRoutes.adminHomeVisits,
    oldest: _earliest(requested.map((r) => r.createdAt)),
  );
});

final feedbackAttentionProvider = FutureProvider<AttentionItem>((ref) async {
  final open = await ref.watch(feedbackProvider(FeedbackStatus.open).future);
  return AttentionItem(
    kind: AttentionKind.feedback,
    count: open.length,
    route: AppRoutes.adminFeedback,
    oldest: _earliest(open.map((f) => f.createdAt)),
  );
});

/// Every queue with its kind (so a failed read can still say which queue
/// it was), most clinically urgent first.
final adminAttentionSources = <(AttentionKind, FutureProvider<AttentionItem>)>[
  (AttentionKind.resultReviews, resultReviewAttentionProvider),
  (AttentionKind.unansweredMessages, messageAttentionProvider),
  (AttentionKind.referrals, referralAttentionProvider),
  (AttentionKind.deliveries, deliveryAttentionProvider),
  (AttentionKind.unconfirmedPayments, paymentAttentionProvider),
  (AttentionKind.overdueInvoices, overdueInvoiceAttentionProvider),
  (AttentionKind.passwordResets, passwordResetAttentionProvider),
  (AttentionKind.homeVisits, homeVisitAttentionProvider),
  (AttentionKind.feedback, feedbackAttentionProvider),
];

/// Re-read every queue.
void refreshAdminAttention(WidgetRef ref) {
  for (final (_, p) in adminAttentionSources) {
    ref.invalidate(p);
  }
  ref
    ..invalidate(pendingReferralRequestsProvider)
    ..invalidate(overdueMessagesProvider)
    ..invalidate(allInvoicesProvider)
    ..invalidate(pendingPasswordResetUserIdsProvider)
    ..invalidate(homeVisitQueueProvider)
    ..invalidate(feedbackProvider);
}
