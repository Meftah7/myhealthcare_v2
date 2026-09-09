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
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return AppScaffold(
      titleWidget: const AppBrandLockup(subtitle: 'Admin'),
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
            const SectionHeader('System health', overline: true),
            _SystemHealth(),
            const SectionHeader('Quick actions', overline: true),
            const AdminQuickActions(),
          ],
          secondary: [
            SectionHeader(
              'Appointments · last 90 days',
              overline: true,
              action: 'Analytics',
              onAction: () => context.push(AppRoutes.adminProfileAnalytics),
            ),
            _PanelCard(),
            SectionHeader(
              'Recent activity',
              overline: true,
              action: 'Audit log',
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
    final unpaid = ref.watch(unpaidInvoiceCountProvider).valueOrNull ?? 0;
    final feedback = ref.watch(openFeedbackCountProvider).valueOrNull ?? 0;
    final homeVisits = ref.watch(openHomeVisitCountProvider);
    final total = unpaid + feedback + homeVisits;

    if (total == 0) {
      return GradientHeroCard(
        icon: Icons.check_circle_outline,
        title: 'All clear',
        subtitle: 'No invoices, reports or visit requests waiting',
        onTap: () => context.push(AppRoutes.adminProfileAnalytics),
      );
    }

    final parts = <String>[
      if (unpaid > 0) '$unpaid unpaid invoice${unpaid == 1 ? '' : 's'}',
      if (feedback > 0) '$feedback open report${feedback == 1 ? '' : 's'}',
      if (homeVisits > 0)
        '$homeVisits visit request${homeVisits == 1 ? '' : 's'}',
    ];

    // Deep-link to the busiest queue.
    final route = unpaid >= feedback && unpaid >= homeVisits
        ? AppRoutes.adminBilling
        : feedback >= homeVisits
        ? AppRoutes.adminFeedback
        : AppRoutes.adminHomeVisits;

    return GradientHeroCard(
      icon: Icons.priority_high,
      title: '$total ${total == 1 ? 'thing needs' : 'things need'} you',
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
    final stats = ref.watch(systemStatsProvider);

    return AppReveal(
      child: stats.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('s-load'), height: 96),
        error: (e, _) => const InlineBanner.error(
          'Could not load system stats.',
          key: ValueKey('s-err'),
        ),
        data: (s) => MetricRow(
          key: const ValueKey('s-data'),
          children: [
            MetricTile(
              value: '${s.patients}',
              label: 'Patients',
              icon: Icons.people_outline,
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            MetricTile(
              value: '${s.staff}',
              label: 'Staff',
              icon: Icons.badge_outlined,
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            MetricTile(
              value: '${s.departments}',
              label: 'Departments',
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
    final theme = Theme.of(context);
    final panel = ref.watch(panelStatsProvider);
    return panel.when(
      loading: () => const LoadingSkeleton(height: 120),
      error: (e, _) =>
          const InlineBanner.error('Could not load appointment stats.'),
      data: (p) => AppCard(
        onTap: () => context.push(AppRoutes.adminProfileAnalytics),
        child: Column(
          children: [
            _Kv('No-show rate', '${(p.noShowRate * 100).toStringAsFixed(1)}%'),
            _Kv(
              'Cancellation rate',
              '${(p.cancellationRate * 100).toStringAsFixed(1)}%',
            ),
            _Kv('Completed', '${p.completed}'),
            _Kv('Upcoming', '${p.upcoming}', last: true),
            const SizedBox(height: Space.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'View detailed analytics  ›',
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
    final theme = Theme.of(context);
    final audit = ref.watch(auditLogProvider);
    return audit.when(
      loading: () => const LoadingSkeleton(height: 90),
      error: (e, _) =>
          const InlineBanner.error('Could not load the audit log.'),
      data: (list) {
        if (list.isEmpty) {
          return const AppCard(
            padding: EdgeInsets.all(Space.md),
            child: Text('No audit entries yet.'),
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
