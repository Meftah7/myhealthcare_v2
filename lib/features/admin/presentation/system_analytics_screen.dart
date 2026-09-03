/// Admin → system analytics (P5-17, redesign v2): headline counts plus the
/// panel-wide no-show / utilisation figures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';

class SystemAnalyticsScreen extends ConsumerWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(systemStatsProvider);
    final panel = ref.watch(panelStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('System analytics'),
        actions: const [SignOutAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(systemStatsProvider)
            ..invalidate(panelStatsProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.xxl,
              ),
              children: [
                const SectionHeader('Directory', overline: true),
                stats.when(
                  loading: () => const LoadingSkeleton(height: 160),
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
                      MetricTile(value: '${s.patients}', label: 'Patients'),
                      MetricTile(value: '${s.staff}', label: 'Staff'),
                      MetricTile(value: '${s.admins}', label: 'Admins'),
                      MetricTile(
                        value: '${s.departments}',
                        label: 'Departments',
                      ),
                      MetricTile(
                        value: '${s.openFlags}',
                        label: 'Open risk flags',
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
                    child: Column(
                      children: [
                        _Row(
                          'No-show rate',
                          '${(p.noShowRate * 100).toStringAsFixed(1)}%',
                        ),
                        const Divider(height: Space.md),
                        _Row(
                          'Cancellation rate',
                          '${(p.cancellationRate * 100).toStringAsFixed(1)}%',
                        ),
                        const Divider(height: Space.md),
                        _Row('Completed', '${p.completed}'),
                        const Divider(height: Space.md),
                        _Row(
                          'Upcoming',
                          '${p.upcoming}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'No-show risk predictions come from the offline logistic-'
                  'regression model (RQ2).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
    );
  }
}
