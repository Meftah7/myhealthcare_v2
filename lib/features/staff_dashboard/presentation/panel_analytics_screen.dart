/// Panel analytics (P5-13, redesign v2): no-show rate, cancellations,
/// utilisation over the last 90 days. Reads `noShowRisk` / `riskBand` stored on
/// appointments (P4-17).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
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
        data: (s) => Center(
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
                SectionHeader(
                  'Last ${s.windowDays} days',
                  overline: true,
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Space.sm,
                  crossAxisSpacing: Space.sm,
                  childAspectRatio: 1.7,
                  children: [
                    MetricTile(
                      value: '${(s.noShowRate * 100).toStringAsFixed(1)}%',
                      label: 'No-show rate',
                      caption:
                          '${s.noShow} of ${s.completed + s.noShow} kept slots',
                    ),
                    MetricTile(
                      value:
                          '${(s.cancellationRate * 100).toStringAsFixed(1)}%',
                      label: 'Cancellation rate',
                      caption: '${s.cancelled} cancelled',
                    ),
                    MetricTile(
                      value: '${s.completed}',
                      label: 'Completed',
                      caption: '${s.keptPerDay.toStringAsFixed(1)} per day',
                    ),
                    MetricTile(
                      value: '${s.upcoming}',
                      label: 'Upcoming',
                      caption: 'booked or confirmed',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
