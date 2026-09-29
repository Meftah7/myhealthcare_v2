/// Admin → capacity forecast (ported from the FirstSemMyHealth admin "AI
/// Forecast & Overflow Predictions" widget): a 7-day, per-weekday view of the
/// clinic's busiest hours and where demand is likely to outrun capacity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/operational_list.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/capacity_forecast.dart';

class AdminForecastScreen extends ConsumerStatefulWidget {
  const AdminForecastScreen({super.key});

  @override
  ConsumerState<AdminForecastScreen> createState() =>
      _AdminForecastScreenState();
}

class _AdminForecastScreenState extends ConsumerState<AdminForecastScreen> {
  int _visibleSources = 20;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final forecast = ref.watch(capacityForecastProvider);
    final gutter = WindowSize.of(context).gutter;
    final compact = WindowSize.of(context).isCompact;

    return AppScaffold(
      title: t.capacityForecastTitle,
      actions: [
        IconButton(
          tooltip: t.recomputeTooltip,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(capacityForecastProvider),
        ),
      ],
      body: forecast.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotComputeForecast,
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
                        t.forecastExplainerNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      _MetricContract(metadata: f.metadata),
                      const SizedBox(height: Space.md),
                      if (compact)
                        for (final d in f.days)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.xs),
                            child: _DayCard(day: d, theme: theme),
                          )
                      else
                        for (var r = 0; r < f.days.length; r += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _DayCard(day: f.days[r], theme: theme),
                                ),
                                const SizedBox(width: Space.sm),
                                Expanded(
                                  child: r + 1 < f.days.length
                                      ? _DayCard(
                                          day: f.days[r + 1],
                                          theme: theme,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: Space.lg),
                      const SectionHeader(
                        'Source appointments',
                        overline: true,
                      ),
                      OperationalList<DemandSourceRow>(
                        items: f.sourceRows.take(_visibleSources).toList(),
                        itemId: (row) => row.appointmentId,
                        searchText: (row) =>
                            '${row.appointmentId} ${row.staffId} ${row.status.name}',
                        columns: [
                          OperationalColumn(
                            label: 'Appointment',
                            value: (row) => row.appointmentId,
                          ),
                          OperationalColumn(
                            label: 'Time',
                            value: (row) => fmtDateTime(row.slotStart),
                          ),
                          OperationalColumn(
                            label: 'Staff',
                            value: (row) => row.staffId,
                          ),
                          OperationalColumn(
                            label: 'Status',
                            value: (row) => row.status.name,
                          ),
                        ],
                        searchHint: 'Search source appointments',
                        allLabel: 'All',
                        fetchedAt: f.metadata.refreshedAt,
                        onRefresh: () =>
                            ref.invalidate(capacityForecastProvider),
                        hasMore: _visibleSources < f.sourceRows.length,
                        onLoadMore: () => setState(() => _visibleSources += 20),
                        empty: const EmptyState(
                          icon: Icons.event_busy_outlined,
                          message: 'No included appointments in this window.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      centerBody: false,
    );
  }
}

class _MetricContract extends StatelessWidget {
  const _MetricContract({required this.metadata});
  final ForecastMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final start = metadata.windowStart;
    final end = metadata.windowEnd;
    return Semantics(
      label: 'Metric definition and source',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metric details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Space.xs),
            if (metadata.isStaleAt(DateTime.now()))
              Text(
                'Stale data — refresh before making an operational decision.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Text('Source: ${metadata.source}'),
            Text(
              'Window: ${start == null ? 'No included data' : '${fmtDate(start)} – ${fmtDate(end!)}'}',
            ),
            Text('Excludes: ${metadata.exclusions}'),
            Text('Timezone: ${metadata.timezone}'),
            Text('Freshness: calculated ${fmtDateTime(metadata.refreshedAt)}'),
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
    final t = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    final ramp = theme.clinicalStatus;
    final (levelLabel, levelStyle) = switch (day.level) {
      DemandLevel.high => (t.demandLevelHigh, ramp.riskHigh),
      DemandLevel.moderate => (t.demandLevelModerate, ramp.riskMedium),
      DemandLevel.low => (t.demandLevelLow, ramp.riskLow),
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
                  label: t.overflowRiskLabel,
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
                ? t.noHistoryYet
                : t.peakWindowSummary(day.peakWindow, day.peakCount),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
