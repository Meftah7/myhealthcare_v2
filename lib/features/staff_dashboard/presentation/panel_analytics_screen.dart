/// Panel analytics (P5-13, redesign v2): no-show rate, cancellations,
/// utilisation over the last 90 days. Reads `noShowRisk` / `riskBand` stored on
/// appointments (P4-17).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../application/staff_providers.dart';

class PanelAnalyticsScreen extends ConsumerWidget {
  const PanelAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final stats = ref.watch(panelStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.panelAnalyticsTitle)),
      body: stats.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotComputeAnalytics,
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
                SectionHeader(t.lastNDays(s.windowDays), overline: true),
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
                      label: t.noShowRateLabel,
                      caption: t.noShowRateCaption(
                        s.noShow,
                        s.completed + s.noShow,
                      ),
                    ),
                    MetricTile(
                      value:
                          '${(s.cancellationRate * 100).toStringAsFixed(1)}%',
                      label: t.cancellationRateLabel,
                      caption: t.cancelledCaption(s.cancelled),
                    ),
                    MetricTile(
                      value: '${s.completed}',
                      label: t.completedLabel,
                      caption: t.perDayCaption(
                        s.keptPerDay.toStringAsFixed(1),
                      ),
                    ),
                    MetricTile(
                      value: '${s.upcoming}',
                      label: t.upcomingLabel,
                      caption: t.bookedOrConfirmedCaption,
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
