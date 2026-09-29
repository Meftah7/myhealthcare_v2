/// The admin's "Needs attention" list (Phase 6): one row per exception queue
/// with work in it — how many, the breakdown, how long the oldest has
/// waited, and a tap through to fix it. A queue that could not be checked
/// says so on its own row; queues checked and empty collapse into one quiet
/// line. Nothing here ever reads "all clear" on a failed read.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/attention_providers.dart';

String attentionLabel(AppLocalizations t, AttentionKind kind) => switch (kind) {
  AttentionKind.resultReviews => t.attentionResultReviews,
  AttentionKind.unansweredMessages => t.attentionMessages,
  AttentionKind.referrals => t.attentionReferrals,
  AttentionKind.unconfirmedPayments => t.attentionPayments,
  AttentionKind.deliveries => t.attentionDeliveries,
  AttentionKind.overdueInvoices => t.attentionOverdueInvoices,
  AttentionKind.passwordResets => t.attentionPasswordResets,
  AttentionKind.homeVisits => t.attentionHomeVisits,
  AttentionKind.feedback => t.attentionFeedback,
};

IconData _icon(AttentionKind kind) => switch (kind) {
  AttentionKind.resultReviews => Icons.science_outlined,
  AttentionKind.unansweredMessages => Icons.mark_email_unread_outlined,
  AttentionKind.referrals => Icons.forward_to_inbox_outlined,
  AttentionKind.unconfirmedPayments => Icons.sync_problem_outlined,
  AttentionKind.deliveries => Icons.notifications_off_outlined,
  AttentionKind.overdueInvoices => Icons.receipt_long_outlined,
  AttentionKind.passwordResets => Icons.lock_reset,
  AttentionKind.homeVisits => Icons.home_outlined,
  AttentionKind.feedback => Icons.feedback_outlined,
};

String _parts(AppLocalizations t, Map<String, int> parts) => [
  for (final MapEntry(:key, :value) in parts.entries)
    if (value > 0)
      switch (key) {
        'unassigned' => t.attentionPartUnassigned(value),
        'overdue' => t.attentionPartOverdue(value),
        'escalated' => t.attentionPartEscalated(value),
        'unowned' => t.attentionPartUnowned(value),
        'unconfirmed' => t.attentionPartUnconfirmed(value),
        'needsRefund' => t.attentionPartNeedsRefund(value),
        'failed' => t.attentionPartFailed(value),
        'late' => t.attentionPartLate(value),
        _ => '$value',
      },
].join(' · ');

/// Opens a queue: a tab route is switched to, anything else is pushed so
/// Back returns to the dashboard.
void openAttentionRoute(BuildContext context, String route) {
  const tabs = {AppRoutes.adminBilling, AppRoutes.adminUsers};
  if (tabs.contains(route)) {
    context.go(route);
  } else {
    unawaited(context.push(route));
  }
}

class AdminAttentionList extends ConsumerWidget {
  const AdminAttentionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <Widget>[];
    final clear = <String>[];
    var loading = 0;

    for (final (kind, source) in adminAttentionSources) {
      final value = ref.watch(source);
      if (value.hasError) {
        rows.add(
          ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(
              t.couldNotCheckQueue(attentionLabel(t, kind)),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            trailing: TextButton(
              onPressed: () => ref.invalidate(source),
              child: Text(t.tryAgain),
            ),
          ),
        );
        continue;
      }
      if (!value.hasValue) {
        loading++;
        continue;
      }
      final item = value.requireValue;
      if (item.count == 0) {
        clear.add(attentionLabel(t, item.kind));
        continue;
      }
      final detail = [
        _parts(t, item.parts),
        if (item.oldest != null) t.attentionOldest(fmtDate(item.oldest!)),
      ].where((s) => s.isNotEmpty).join(' · ');
      rows.add(
        ListTile(
          leading: Icon(_icon(item.kind)),
          title: Text(attentionLabel(t, item.kind)),
          subtitle: detail.isEmpty ? null : Text(detail),
          trailing: Badge(
            label: Text('${item.count}'),
            largeSize: 22,
            textStyle: theme.textTheme.labelMedium,
          ),
          onTap: () => openAttentionRoute(context, item.route),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows,
          for (var i = 0; i < loading; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.xs,
              ),
              child: LoadingSkeleton(height: 40),
            ),
          if (rows.isEmpty && loading == 0)
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(t.nothingNeedsAttention),
            ),
          if (clear.isNotEmpty && loading == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.md,
                Space.xs,
              ),
              child: Text(
                t.checkedAndClear(clear.join(', ')),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
