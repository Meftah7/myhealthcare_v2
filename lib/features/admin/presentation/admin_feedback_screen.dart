/// Admin → feedback inbox (ported from the FirstSemMyHealth admin "Reports"
/// view): every user-submitted report, filterable by status, with a
/// resolve / re-open toggle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final feedback = ref.watch(feedbackProvider(_filter));
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.feedbackTitle),
        actions: const [AdminTopActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: Row(
              children: [
                for (final (label, value) in [
                  (FeedbackStatus.open.label(context), FeedbackStatus.open),
                  (
                    FeedbackStatus.resolved.label(context),
                    FeedbackStatus.resolved,
                  ),
                  (t.allFilterChip, null),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
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
          message: t.couldNotLoadFeedback,
          onRetry: () => ref.invalidate(feedbackProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              message: t.noFeedbackInView,
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
    final t = AppLocalizations.of(context)!;
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
                  feedbackCategoryLabel(context, feedback.category),
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
                    t.feedbackStatusResolved,
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
              feedback.reporterName ??
                  feedback.reporterEmail ??
                  t.anonymousFallback,
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
            alignment: AlignmentDirectional.centerStart,
            child: resolved
                ? TextButton(
                    onPressed: () => ref
                        .read(adminActionsProvider)
                        .setFeedbackStatus(
                          id: feedback.id,
                          status: FeedbackStatus.open,
                        ),
                    child: Text(t.reopenAction),
                  )
                : FilledButton.tonal(
                    onPressed: () => ref
                        .read(adminActionsProvider)
                        .setFeedbackStatus(
                          id: feedback.id,
                          status: FeedbackStatus.resolved,
                        ),
                    child: Text(t.markResolvedAction),
                  ),
          ),
        ],
      ),
    );
  }
}
