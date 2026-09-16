/// Admin → system analytics (P5-17, redesign v2): headline counts plus the
/// panel-wide no-show / utilisation figures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/admin_providers.dart';

class SystemAnalyticsScreen extends ConsumerWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = ref.watch(systemStatsProvider);
    final panel = ref.watch(panelStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.systemAnalyticsTitle)),
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
                SectionHeader(t.directoryHeader, overline: true),
                stats.when(
                  loading: () => const LoadingSkeleton(height: 160),
                  error: (e, _) =>
                      InlineBanner.error(t.couldNotLoadSystemStats),
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
                        label: t.patientsAction,
                      ),
                      MetricTile(value: '${s.staff}', label: t.staffCountLabel),
                      MetricTile(value: '${s.admins}', label: t.adminsLabel),
                      MetricTile(
                        value: '${s.departments}',
                        label: t.departmentsLabel,
                      ),
                      MetricTile(
                        value: '${s.openFlags}',
                        label: t.openRiskFlagsLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.md),
                SectionHeader(
                  t.appointmentsLast90DaysHeader,
                  overline: true,
                ),
                panel.when(
                  loading: () => const LoadingSkeleton(height: 120),
                  error: (e, _) =>
                      InlineBanner.error(t.couldNotLoadAppointmentStats),
                  data: (p) => AppCard(
                    child: Column(
                      children: [
                        _Row(
                          t.noShowRateLabel,
                          '${(p.noShowRate * 100).toStringAsFixed(1)}%',
                        ),
                        const Divider(height: Space.md),
                        _Row(
                          t.cancellationRateLabel,
                          '${(p.cancellationRate * 100).toStringAsFixed(1)}%',
                        ),
                        const Divider(height: Space.md),
                        _Row(t.completedLabel, '${p.completed}'),
                        const Divider(height: Space.md),
                        _Row(t.upcomingLabel, '${p.upcoming}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  t.noShowRiskModelNote,
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
