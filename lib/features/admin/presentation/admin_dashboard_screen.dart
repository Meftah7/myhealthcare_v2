/// Admin dashboard (redesign v2): one overview of the whole system — headline
/// metrics, appointment health, quick links, recent activity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/application/session.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';
import 'admin_quick_actions.dart';
import 'admin_top_actions.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    final stats = ref.watch(systemStatsProvider);
    final panel = ref.watch(panelStatsProvider);
    final audit = ref.watch(auditLogProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [AdminTopActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(systemStatsProvider)
            ..invalidate(panelStatsProvider)
            ..invalidate(unpaidInvoiceCountProvider)
            ..invalidate(openFeedbackCountProvider)
            ..invalidate(auditLogProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.xxl),
              children: [
                Text(greeting(firstName), style: theme.textTheme.headlineSmall),
                const SizedBox(height: Space.xxs),
                Text(
                  'System overview',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),

                stats.when(
                  loading: () => const LoadingSkeleton(height: 180),
                  error: (e, _) =>
                      const InlineBanner.error('Could not load system stats.'),
                  data: (s) {
                    final unpaid = ref
                        .watch(unpaidInvoiceCountProvider)
                        .valueOrNull;
                    final openFeedback = ref
                        .watch(openFeedbackCountProvider)
                        .valueOrNull;
                    final compact = WindowSize.of(context).isCompact;
                    return GridView.count(
                      crossAxisCount: compact ? 2 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Space.sm,
                      crossAxisSpacing: Space.sm,
                      childAspectRatio: compact ? 1.7 : 1.6,
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
                          value: '${s.admins}',
                          label: 'Admins',
                          icon: Icons.shield_outlined,
                          onTap: () => context.go(AppRoutes.adminUsers),
                        ),
                        MetricTile(
                          value: '${s.departments}',
                          label: 'Departments',
                          icon: Icons.apartment_outlined,
                          onTap: () => context.go(AppRoutes.adminDepartments),
                        ),
                        MetricTile(
                          value: '${s.openFlags}',
                          label: 'Open risk flags',
                          icon: Icons.flag_outlined,
                        ),
                        MetricTile(
                          value: '${unpaid ?? 0}',
                          label: 'Unpaid invoices',
                          icon: Icons.request_quote_outlined,
                          onTap: () => context.push(AppRoutes.adminBilling),
                        ),
                        MetricTile(
                          value: '${openFeedback ?? 0}',
                          label: 'Open feedback',
                          icon: Icons.forum_outlined,
                          onTap: () => context.push(AppRoutes.adminFeedback),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: Space.md),
                const SectionHeader('Quick actions', overline: true),
                const AdminQuickActions(),

                const SizedBox(height: Space.md),
                const SectionHeader('Appointments · last 90 days', overline: true),
                panel.when(
                  loading: () => const LoadingSkeleton(height: 120),
                  error: (e, _) => const InlineBanner.error(
                    'Could not load appointment stats.',
                  ),
                  data: (p) => AppCard(
                    onTap: () => context.push(AppRoutes.adminAnalytics),
                    child: Column(
                      children: [
                        _Kv(
                          'No-show rate',
                          '${(p.noShowRate * 100).toStringAsFixed(1)}%',
                        ),
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
                ),

                const SizedBox(height: Space.md),
                const SectionHeader('Recent activity', overline: true),
                audit.when(
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
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < list.take(6).length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, indent: Space.md),
                            ListTile(
                              dense: true,
                              title: Text(list[i].action),
                              subtitle: Text(
                                [
                                  list[i].entityType,
                                  ?list[i].entityId,
                                ].join(' · '),
                              ),
                              trailing: Text(
                                fmtDateTime(list[i].at),
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
                ),
              ],
            ),
          ),
        ),
      ),
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

