/// AI health summary screen (P3-09): markdown summary, key events, trends,
/// red flags — with the safety banner (P3-13) on top.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../application/ai_summary_provider.dart';

class AiSummaryScreen extends ConsumerWidget {
  const AiSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(patientAiSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI health summary'),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
            icon: const Icon(Icons.refresh),
            onPressed: summary.isLoading
                ? null
                : () async {
                    final entity = await ref
                        .read(aiSummaryControllerProvider)
                        .load(forceRegenerate: true);
                    ref
                      ..invalidate(patientAiSummaryProvider)
                      ..invalidate(patientAiSummaryProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Regenerated ${fmtDateTime(entity.generatedAt)}',
                          ),
                        ),
                      );
                    }
                  },
          ),
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
                onRetry: () => ref.invalidate(patientAiSummaryProvider),
              ),
              data: (s) => ListView(
                padding: const EdgeInsets.all(Space.lg),
                children: [
                  Text(s.summaryMarkdown, style: theme.textTheme.bodyLarge),
                  Text(
                    'Generated ${fmtDateTime(s.generatedAt)} · ${s.modelId} · '
                    '${s.promptVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (s.redFlags.isNotEmpty) ...[
                    const SizedBox(height: Space.lg),
                    Text('Things to check', style: theme.textTheme.titleMedium),
                    const SizedBox(height: Space.xs),
                    for (final f in s.redFlags)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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

                  if (s.trends.isNotEmpty) ...[
                    const SizedBox(height: Space.lg),
                    Text('Trends', style: theme.textTheme.titleMedium),
                    const SizedBox(height: Space.xs),
                    for (final t in s.trends)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_trendIcon(t.direction)),
                        title: Text(t.metric),
                        subtitle: Text(t.summary),
                        onTap: () => context.go(AppRoutes.patientVitals),
                      ),
                  ],

                  if (s.keyEvents.isNotEmpty) ...[
                    const SizedBox(height: Space.lg),
                    Text('Key events', style: theme.textTheme.titleMedium),
                    const SizedBox(height: Space.xs),
                    for (final e in s.keyEvents)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.star_outline),
                        title: Text(e.title),
                        subtitle: Text(
                          '${fmtDate(e.date)}'
                          '${e.description == null ? '' : ' · ${e.description}'}',
                        ),
                        onTap: e.recordId == null
                            ? null
                            : () => context.push(
                                AppRoutes.patientRecord(e.recordId!),
                              ),
                      ),
                  ],
                ],
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
