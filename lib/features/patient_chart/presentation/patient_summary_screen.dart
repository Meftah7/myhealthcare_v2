/// Staff-facing AI patient summary (Tier B): the timeline summary, key events,
/// trends and things-to-check for one patient, opened from their chart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';
import '../application/chart_providers.dart';
import '../application/chart_summary_provider.dart';

class PatientSummaryScreen extends ConsumerWidget {
  const PatientSummaryScreen({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patient = ref.watch(chartPatientProvider(patientId));
    final summary = ref.watch(chartPatientSummaryProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient.valueOrNull == null
              ? 'AI summary'
              : 'Summary · ${patient.valueOrNull!.fullName}',
        ),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
            icon: const Icon(Icons.refresh),
            onPressed: summary.isLoading
                ? null
                : () => ref.invalidate(chartPatientSummaryProvider(patientId)),
          ),
          const StaffTopActions(),
        ],
      ),
      body: Column(
        children: [
          const AiDisclaimerBanner(),
          Expanded(
            child: summary.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                message: 'Could not generate a summary.\n$e',
                onRetry: () =>
                    ref.invalidate(chartPatientSummaryProvider(patientId)),
              ),
              data: (s) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Space.maxContentWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      Space.md,
                      Space.md,
                      Space.xxl,
                    ),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.summaryMarkdown,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              'Generated ${fmtDateTime(s.generatedAt)}  ·  '
                              '${s.modelId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (s.redFlags.isNotEmpty) ...[
                        const SectionHeader(
                          'Things to check',
                          overline: true,
                        ),
                        AppCard(
                          padding: const EdgeInsets.all(Space.md),
                          child: Column(
                            children: [
                              for (final f in s.redFlags)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Space.xs,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SeverityChip(f.severity),
                                      const SizedBox(width: Space.xs),
                                      Expanded(
                                        child: Text(
                                          f.description,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (s.trends.isNotEmpty) ...[
                        const SectionHeader('Trends', overline: true),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final t in s.trends)
                                ListTile(
                                  dense: true,
                                  leading: Icon(_trendIcon(t.direction)),
                                  title: Text(t.metric),
                                  subtitle: Text(t.summary),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (s.keyEvents.isNotEmpty) ...[
                        const SectionHeader('Key events', overline: true),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final e in s.keyEvents)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.star_outline),
                                  title: Text(e.title),
                                  subtitle: Text(
                                    '${fmtDate(e.date)}'
                                    '${e.description == null ? '' : ' · ${e.description}'}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _trendIcon(String direction) => switch (direction) {
    'up' => Icons.trending_up,
    'down' => Icons.trending_down,
    _ => Icons.trending_flat,
  };
}
