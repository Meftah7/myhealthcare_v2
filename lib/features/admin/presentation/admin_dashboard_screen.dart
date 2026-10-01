/// Admin dashboard (Phase 6) — built around ownership and correction, not
/// totals: date overline + greeting, one hero that says how much is waiting
/// on the administrator (or that the queues could not be checked), the
/// "Needs attention" list of exception queues, Quick actions, and recent
/// activity. System totals and appointment analytics live one tap away
/// (Analytics) instead of competing for the first screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/data_state_view.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../application/admin_providers.dart';
import '../application/attention_providers.dart';
import 'admin_quick_actions.dart';
import 'admin_top_actions.dart';
import 'attention_list.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? t.greetingFallbackName)
        .split(' ')
        .first;

    return AppScaffold(
      stagger: true,
      hero: true,
      heroOverline: fmtDate(DateTime.now()),
      title: greeting(firstName),
      actions: const [AdminTopActions()],
      onRefresh: () async {
        refreshAdminAttention(ref);
        ref.invalidate(auditLogProvider);
      },
      children: [
        const _NeedsYouHero(),

        SectionColumns(
          primary: [
            SectionHeader(
              t.needsAttentionHeader,
              overline: true,
              action: t.workQueueTitle,
              onAction: () => context.push(AppRoutes.adminWorkQueue),
            ),
            const AdminAttentionList(),
            SectionHeader(t.quickActionsHeader, overline: true),
            const AdminQuickActions(),
          ],
          secondary: [
            SectionHeader(
              t.recentActivityHeader,
              overline: true,
              action: t.auditLogTitle,
              onAction: () => context.push(AppRoutes.adminProfileAudit),
            ),
            const _ActivityCard(),
            const SizedBox(height: Space.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.adminProfileAnalytics),
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: Text(t.viewDetailedAnalytics),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The screen's one saturated surface: how much is waiting on the admin, and
/// the way into the most urgent queue. "All clear" only once every queue was
/// actually read.
class _NeedsYouHero extends ConsumerWidget {
  const _NeedsYouHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final values = [
      for (final (_, source) in adminAttentionSources) ref.watch(source),
    ];
    if (values.any((v) => v.hasError)) {
      return GradientHeroCard(
        icon: Icons.sync_problem_outlined,
        title: t.queuesCheckFailedTitle,
        subtitle: t.queuesCheckFailedSubtitle,
        onTap: () => refreshAdminAttention(ref),
      );
    }
    if (values.any((v) => !v.hasValue)) {
      return GradientHeroCard(
        icon: Icons.hourglass_empty,
        title: t.queuesCheckingTitle,
        subtitle: t.queuesCheckingSubtitle,
      );
    }
    final items = [
      for (final v in values)
        if (v.requireValue.count > 0) v.requireValue,
    ];
    final total = items.fold<int>(0, (sum, i) => sum + i.count);
    if (total == 0) {
      return GradientHeroCard(
        icon: Icons.check_circle_outline,
        title: t.allClearTitle,
        subtitle: t.noQueuesWaitingSubtitle,
      );
    }
    // Queues are in clinical-priority order: the first with work leads.
    final lead = items.first;
    return GradientHeroCard(
      icon: Icons.priority_high,
      title: t.thingsNeedYouTitle(total),
      subtitle: [
        for (final i in items.take(3))
          '${attentionLabel(t, i.kind)} (${i.count})',
      ].join(' · '),
      onTap: () => openAttentionRoute(context, lead.route),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AsyncDataView(
      value: ref.watch(auditLogProvider),
      onRetry: () => ref.invalidate(auditLogProvider),
      loading: const LoadingSkeleton(height: 90),
      isEmpty: (list) => list.isEmpty,
      empty: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Text(t.noAuditEntriesYet),
      ),
      builder: (context, list) {
        final rows = list.take(6).toList();
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: Space.md),
                ListTile(
                  dense: true,
                  title: Text(rows[i].action),
                  subtitle: Text(
                    [rows[i].entityType, ?rows[i].entityId].join(' · '),
                  ),
                  trailing: Text(
                    fmtDateTime(rows[i].at),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
