/// Panel analytics (P5-13): no-show rate, cancellations, utilization over the
/// last 90 days. Reads `noShowRisk` / `riskBand` stored on appointments (P4-17).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../application/staff_providers.dart';

class PanelAnalyticsScreen extends ConsumerWidget {
  const PanelAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(panelStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Panel analytics')),
      body: stats.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not compute analytics.',
          onRetry: () => ref.invalidate(panelStatsProvider),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(
              'Last ${s.windowDays} days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Space.md),
            _MetricCard(
              label: 'No-show rate',
              value: '${(s.noShowRate * 100).toStringAsFixed(1)}%',
              detail: '${s.noShow} of ${s.completed + s.noShow} kept slots',
            ),
            _MetricCard(
              label: 'Cancellation rate',
              value: '${(s.cancellationRate * 100).toStringAsFixed(1)}%',
              detail: '${s.cancelled} cancelled',
            ),
            _MetricCard(
              label: 'Completed appointments',
              value: '${s.completed}',
              detail: '${s.keptPerDay.toStringAsFixed(1)} per day',
            ),
            _MetricCard(
              label: 'Upcoming',
              value: '${s.upcoming}',
              detail: 'booked or confirmed',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xxs),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.xxs),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
