/// Admin → capacity forecast (ported from the FirstSemMyHealth admin "AI
/// Forecast & Overflow Predictions" widget): a 7-day, per-weekday view of the
/// clinic's busiest hours and where demand is likely to outrun capacity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../application/capacity_forecast.dart';
import 'admin_top_actions.dart';

class AdminForecastScreen extends ConsumerWidget {
  const AdminForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final forecast = ref.watch(capacityForecastProvider);
    final gutter = WindowSize.of(context).gutter;
    final compact = WindowSize.of(context).isCompact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capacity forecast'),
        actions: [
          IconButton(
            tooltip: 'Recompute',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(capacityForecastProvider),
          ),
          const AdminTopActions(),
        ],
      ),
      body: forecast.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not compute the forecast.',
          onRetry: () => ref.invalidate(capacityForecastProvider),
        ),
        data: (f) => Column(
          children: [
            if (f.aiNarrated) const AiDisclaimerBanner(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Space.maxContentWidth,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      Space.md,
                      gutter,
                      Space.xxl,
                    ),
                    children: [
                      Text(
                        'Busiest window per weekday, from appointment history. '
                        'A flag means peak demand has been running at or above '
                        'a single clinician’s hourly capacity.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      GridView.count(
                        crossAxisCount: compact ? 1 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: Space.sm,
                        crossAxisSpacing: Space.sm,
                        childAspectRatio: compact ? 3.0 : 2.2,
                        children: [
                          for (final d in f.days) _DayCard(day: d, theme: theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.theme});

  final DayForecast day;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final ramp = theme.clinicalStatus;
    final (levelLabel, levelStyle) = switch (day.level) {
      DemandLevel.high => ('High demand', ramp.riskHigh),
      DemandLevel.moderate => ('Moderate', ramp.riskMedium),
      DemandLevel.low => ('Light', ramp.riskLow),
    };

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(day.dayName, style: theme.textTheme.titleSmall),
              ),
              if (day.overflowRisk)
                _Pill(
                  label: 'Overflow risk',
                  bg: ramp.riskHigh.container,
                  fg: ramp.riskHigh.onContainer,
                )
              else
                _Pill(
                  label: levelLabel,
                  bg: levelStyle.container,
                  fg: levelStyle.onContainer,
                ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            day.peakWindow == '—'
                ? 'No history yet'
                : 'Peak ${day.peakWindow} · up to ${day.peakCount}/hr',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(day.note, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.chip),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
