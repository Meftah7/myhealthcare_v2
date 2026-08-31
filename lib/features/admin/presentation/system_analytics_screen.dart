/// Admin → system analytics (P5-17): headline counts plus the panel-wide
/// no-show / utilization figures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';

class SystemAnalyticsScreen extends ConsumerWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(systemStatsProvider);
    final panel = ref.watch(panelStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('System analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(systemStatsProvider)
            ..invalidate(panelStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            stats.when(
              loading: () => const LoadingSkeleton(height: 120),
              error: (e, _) => const Text('Could not load system stats.'),
              data: (s) => Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  _Stat(label: 'Patients', value: s.patients),
                  _Stat(label: 'Staff', value: s.staff),
                  _Stat(label: 'Admins', value: s.admins),
                  _Stat(label: 'Departments', value: s.departments),
                  _Stat(label: 'Open risk flags', value: s.openFlags),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(
              'Appointments (90-day window)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Space.sm),
            panel.when(
              loading: () => const LoadingSkeleton(height: 80),
              error: (e, _) => const Text('Could not load appointment stats.'),
              data: (p) => Column(
                children: [
                  _Row(
                    label: 'No-show rate',
                    value: '${(p.noShowRate * 100).toStringAsFixed(1)}%',
                  ),
                  _Row(
                    label: 'Cancellation rate',
                    value: '${(p.cancellationRate * 100).toStringAsFixed(1)}%',
                  ),
                  _Row(label: 'Completed', value: '${p.completed}'),
                  _Row(label: 'Upcoming', value: '${p.upcoming}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: Radii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
