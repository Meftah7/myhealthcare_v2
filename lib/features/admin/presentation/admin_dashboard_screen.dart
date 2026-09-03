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
import '../../auth/presentation/sign_out_action.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';

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
        actions: const [SignOutAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(systemStatsProvider)
            ..invalidate(panelStatsProvider)
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
                  data: (s) => GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Space.sm,
                    crossAxisSpacing: Space.sm,
                    childAspectRatio: 1.5,
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
                    ],
                  ),
                ),

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
                const SectionHeader('Manage', overline: true),
                const _LinkCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Users',
                  subtitle: 'Patients, staff and admins',
                  route: AppRoutes.adminUsers,
                ),
                const SizedBox(height: Space.xs),
                const _LinkCard(
                  icon: Icons.apartment_outlined,
                  title: 'Departments',
                  subtitle: 'Create, rename and remove departments',
                  route: AppRoutes.adminDepartments,
                ),
                const SizedBox(height: Space.xs),
                const _LinkCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Audit log',
                  subtitle: 'Full trail of system activity',
                  route: AppRoutes.adminAudit,
                ),
                const SizedBox(height: Space.xs),
                const _LinkCard(
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI settings',
                  subtitle: 'Provider, key, mock mode and demo data',
                  route: AppRoutes.adminAiSettings,
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

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      onTap: () => context.go(route),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: Radii.chip,
            ),
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
