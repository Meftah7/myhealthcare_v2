/// Staff task board (P5-11) with per-task rationale and the AI-prioritise
/// action (P5-10). Rule score is always shown; the AI score is layered on when
/// present and the two are blended by [StaffTask.effectivePriority].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';

class TaskBoardScreen extends ConsumerWidget {
  const TaskBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final tasks = ref.watch(staffTasksProvider);
    final weight = ref.watch(aiTaskWeightProvider).valueOrNull ?? 0.5;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.taskBoardTitle),
        actions: [
          _PrioritiseButton(),
          const StaffTopActions(),
        ],
      ),
      body: tasks.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadTasks,
          onRetry: () => ref.invalidate(staffTasksProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.checklist_outlined,
              message: t.noOpenTasksMessage,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.xxl,
                ),
                children: [
                  InlineBanner.info(
                    t.priorityBlendNote((weight * 100).round()),
                  ),
                  const SizedBox(height: Space.sm),
                  for (final t in list) ...[
                    _TaskCard(task: t, weight: weight),
                    const SizedBox(height: Space.sm),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrioritiseButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PrioritiseButton> createState() => _PrioritiseButtonState();
}

class _PrioritiseButtonState extends ConsumerState<_PrioritiseButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(staffOpsProvider).prioritiseWithAi();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.tasksReprioritised)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(AppLocalizations.of(context)!.prioritiseButton),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.weight});

  final StaffTask task;
  final double weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final priority = task.effectivePriority(weight);
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityDot(priority),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(task.title, style: theme.textTheme.titleSmall),
                ),
                PopupMenuButton<TaskStatus>(
                  onSelected: (s) =>
                      ref.read(staffOpsProvider).setTaskStatus(task.id, s),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text(t.startAction),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.done,
                      child: Text(t.completeAction),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.dismissed,
                      child: Text(t.dismissAction),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Tag(label: _kindLabel(t, task.kind)),
                _Tag(label: t.ruleScoreTag(task.ruleScore.toStringAsFixed(2))),
                if (task.aiPriorityScore != null)
                  _Tag(
                    label: t.aiScoreTag(task.aiPriorityScore!.toStringAsFixed(2)),
                    icon: Icons.auto_awesome,
                  ),
                if (task.dueAt != null)
                  _Tag(
                    label: t.dueTag(fmtRelativeDay(task.dueAt!)),
                    error: task.isOverdue,
                  ),
                if (task.status == TaskStatus.inProgress)
                  _Tag(label: t.taskStatusInProgress),
              ],
            ),
            if (task.aiRationale != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                task.aiRationale!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot(this.priority);
  final double priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = priority >= 0.8
        ? scheme.error
        : priority >= 0.55
        ? scheme.tertiary
        : scheme.primary;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon, this.error = false});

  final String label;
  final IconData? icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = error
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: Radii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

String _kindLabel(AppLocalizations t, TaskKind k) => switch (k) {
  TaskKind.followUpDue => t.taskKindFollowUpShort,
  TaskKind.unreviewedAbnormalLab => t.taskKindAbnormalLabShort,
  TaskKind.unsignedNote => t.taskKindUnsignedNote,
  TaskKind.medicationReview => t.taskKindMedicationReview,
  TaskKind.referralAction => t.taskKindReferralShort,
  TaskKind.other => t.taskKindOther,
};
