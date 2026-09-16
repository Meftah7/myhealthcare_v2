/// Admin dashboard — the same layout language as the patient and staff
/// dashboards: date overline + greeting, one saturated hero, a three-figure
/// "System health" row, Quick actions as row tiles, then the live queues.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../care/application/care_providers.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';
import 'admin_quick_actions.dart';
import 'admin_top_actions.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? t.greetingFallbackName).split(
      ' ',
    ).first;

    return AppScaffold(
      titleWidget: AppBrandLockup(subtitle: t.roleAdmin),
      actions: const [AdminTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(systemStatsProvider)
          ..invalidate(panelStatsProvider)
          ..invalidate(unpaidInvoiceCountProvider)
          ..invalidate(openFeedbackCountProvider)
          ..invalidate(auditLogProvider)
          ..invalidate(homeVisitQueueProvider(null));
      },
      children: [
        PageGreeting(
          overline: fmtDate(DateTime.now()),
          greeting: greeting(firstName),
        ),
        const SizedBox(height: Space.lg),

        const _NeedsYouHero(),

        SectionColumns(
          primary: [
            SectionHeader(t.systemHealthHeader, overline: true),
            _SystemHealth(),
            SectionHeader(t.quickActionsHeader, overline: true),
            const AdminQuickActions(),
          ],
          secondary: [
            SectionHeader(
              t.appointmentsLast90DaysHeader,
              overline: true,
              action: t.analyticsAction,
              onAction: () => context.push(AppRoutes.adminProfileAnalytics),
            ),
            _PanelCard(),
            SectionHeader(
              t.recentActivityHeader,
              overline: true,
              action: t.auditLogTitle,
              onAction: () => context.push(AppRoutes.adminProfileAudit),
            ),
            _ActivityCard(),
          ],
        ),
      ],
    );
  }
}

/// The screen's one saturated surface — how many things are waiting on the
/// admin, and the way into the most urgent one.
class _NeedsYouHero extends ConsumerWidget {
  const _NeedsYouHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final unpaid = ref.watch(unpaidInvoiceCountProvider).valueOrNull ?? 0;
    final feedback = ref.watch(openFeedbackCountProvider).valueOrNull ?? 0;
    final homeVisits = ref.watch(openHomeVisitCountProvider);
    final referrals = ref.watch(pendingReferralRequestCountProvider);
    final total = unpaid + feedback + homeVisits + referrals;

    if (total == 0) {
      return GradientHeroCard(
        icon: Icons.check_circle_outline,
        title: t.allClearTitle,
        subtitle: t.noQueuesWaitingSubtitle,
        onTap: () => context.push(AppRoutes.adminProfileAnalytics),
      );
    }

    final parts = <String>[
      if (unpaid > 0) t.unpaidInvoiceCount(unpaid),
      if (feedback > 0) t.openReportCount(feedback),
      if (homeVisits > 0) t.visitRequestCount(homeVisits),
      if (referrals > 0) t.referralRequestCount(referrals),
    ];

    // Deep-link to the busiest queue.
    final route =
        referrals >= unpaid && referrals >= feedback && referrals >= homeVisits
        ? AppRoutes.adminReferralRequests
        : unpaid >= feedback && unpaid >= homeVisits
        ? AppRoutes.adminBilling
        : feedback >= homeVisits
        ? AppRoutes.adminFeedback
        : AppRoutes.adminHomeVisits;

    return GradientHeroCard(
      icon: Icons.priority_high,
      title: t.thingsNeedYouTitle(total),
      subtitle: parts.join(' · '),
      onTap: () => route == AppRoutes.adminBilling
          ? context.go(route)
          : context.push(route),
    );
  }
}

/// Three figures for the whole system — the admin mirror of the patient's
/// "Your health" row.
class _SystemHealth extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final stats = ref.watch(systemStatsProvider);

    return AppReveal(
      child: stats.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('s-load'), height: 96),
        error: (e, _) => InlineBanner.error(
          t.couldNotLoadSystemStats,
          key: const ValueKey('s-err'),
        ),
        data: (s) => MetricRow(
          key: const ValueKey('s-data'),
          children: [
            MetricTile(
              value: '${s.patients}',
              label: t.patientsAction,
              icon: Icons.people_outline,
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            MetricTile(
              value: '${s.staff}',
              label: t.staffCountLabel,
              icon: Icons.badge_outlined,
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            MetricTile(
              value: '${s.departments}',
              label: t.departmentsLabel,
              icon: Icons.apartment_outlined,
              onTap: () => context.go(AppRoutes.adminDepartments),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final panel = ref.watch(panelStatsProvider);
    return panel.when(
      loading: () => const LoadingSkeleton(height: 120),
      error: (e, _) => InlineBanner.error(t.couldNotLoadAppointmentStats),
      data: (p) => AppCard(
        onTap: () => context.push(AppRoutes.adminProfileAnalytics),
        child: Column(
          children: [
            _Kv(
              t.noShowRateLabel,
              '${(p.noShowRate * 100).toStringAsFixed(1)}%',
            ),
            _Kv(
              t.cancellationRateLabel,
              '${(p.cancellationRate * 100).toStringAsFixed(1)}%',
            ),
            _Kv(t.completedLabel, '${p.completed}'),
            _Kv(t.upcomingLabel, '${p.upcoming}', last: true),
            const SizedBox(height: Space.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${t.viewDetailedAnalytics}  ${rtl ? '‹' : '›'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final audit = ref.watch(auditLogProvider);
    return audit.when(
      loading: () => const LoadingSkeleton(height: 90),
      error: (e, _) => InlineBanner.error(t.couldNotLoadAuditLog),
      data: (list) {
        if (list.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(Space.md),
            child: Text(t.noAuditEntriesYet),
          );
        }
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

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Space.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
