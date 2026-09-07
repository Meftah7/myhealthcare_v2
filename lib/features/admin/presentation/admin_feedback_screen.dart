/// Admin → feedback inbox (ported from the FirstSemMyHealth admin "Reports"
/// view): every user-submitted report, filterable by status, with a
/// resolve / re-open toggle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() =>
      _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  FeedbackStatus? _filter = FeedbackStatus.open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedback = ref.watch(feedbackProvider(_filter));
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        actions: const [AdminTopActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: Row(
              children: [
                for (final (label, value) in const [
                  ('Open', FeedbackStatus.open),
                  ('Resolved', FeedbackStatus.resolved),
                  ('All', null),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: FilterChip(
                      label: Text(label),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: feedback.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load feedback.',
          onRetry: () => ref.invalidate(feedbackProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              message: 'No feedback in this view.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                itemBuilder: (context, i) =>
                    _FeedbackCard(feedback: list[i], theme: theme),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard({required this.feedback, required this.theme});

  final UserFeedback feedback;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = theme.colorScheme;
    final resolved = feedback.status == FeedbackStatus.resolved;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedbackCategoryLabel(feedback.category),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (resolved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.clinicalStatus.riskLow.container,
                    borderRadius: Radii.chip,
                  ),
                  child: Text(
                    'Resolved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.clinicalStatus.riskLow.onContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            [
              feedback.reporterName ?? feedback.reporterEmail ?? 'Anonymous',
              fmtDate(feedback.createdAt),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(feedback.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: resolved
                ? TextButton(
                    onPressed: () => ref
                        .read(adminActionsProvider)
                        .setFeedbackStatus(
                          id: feedback.id,
                          status: FeedbackStatus.open,
                        ),
                    child: const Text('Re-open'),
                  )
                : FilledButton.tonal(
                    onPressed: () => ref
                        .read(adminActionsProvider)
                        .setFeedbackStatus(
                          id: feedback.id,
                          status: FeedbackStatus.resolved,
                        ),
                    child: const Text('Mark resolved'),
                  ),
          ),
        ],
      ),
    );
  }
}
