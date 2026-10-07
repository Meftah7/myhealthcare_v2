/// Staff task board (P5-11) with per-task rationale and the AI-prioritise
/// action (P5-10). Rule score is always shown; the AI score is layered on when
/// present and the two are blended by [StaffTask.effectivePriority].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
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
    return AppScaffold(
      hero: true,
      title: t.taskBoardTitle,
      actions: const [StaffTopActions()],
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
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _PrioritiseButton(),
                  ),
                  InlineBanner.info(
                    t.priorityBlendNote((weight * 100).round()),
                  ),
                  const SizedBox(height: Space.sm),
                  for (final t in list) ...[
                    _TaskCard(key: ValueKey(t.id), task: t, weight: weight),
                    const SizedBox(height: Space.sm),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      centerBody: false,
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
      final result = await Result.guardAsync(
        () => ref.read(staffOpsProvider).prioritiseWithAi(),
      );
      if (mounted) {
        showMutationFeedback(
          context,
          result,
          success: t.tasksReprioritised,
          onRetry: _run,
          onReload: () => ref.invalidate(staffTasksProvider),
        );
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

class _TaskCard extends ConsumerStatefulWidget {
  const _TaskCard({required this.task, required this.weight, super.key});

  final StaffTask task;
  final double weight;

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _busy = false;
  StaffTask get task => widget.task;

  Future<void> _change(TaskStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(staffOpsProvider)
          .setTaskStatus(task.id, status, expectedVersion: task.version);
      if (!mounted) return;
      showMutationFeedback(
        context,
        result,
        onRetry: () => _change(status),
        onReload: () => ref.invalidate(staffTasksProvider),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final priority = task.effectivePriority(widget.weight);
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
                enabled: !_busy,
                onSelected: _change,
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
              _Tag(
                label: switch (task.priority) {
                  WorkPriority.routine => t.workPriorityRoutine,
                  WorkPriority.priority => t.workPriorityPriority,
                  WorkPriority.urgent => t.workPriorityUrgent,
                },
                error: task.priority == WorkPriority.urgent,
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
          const SizedBox(height: Space.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _busy || !task.isOpen
                  ? null
                  : () => _change(
                      task.status == TaskStatus.open
                          ? TaskStatus.inProgress
                          : TaskStatus.done,
                    ),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      task.status == TaskStatus.open
                          ? Icons.play_arrow_outlined
                          : Icons.check,
                    ),
              label: Text(
                task.status == TaskStatus.open
                    ? t.startAction
                    : t.completeAction,
              ),
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              t.priorityBlendNote((widget.weight * 100).round()),
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  _Tag(
                    label: t.ruleScoreTag(task.ruleScore.toStringAsFixed(2)),
                  ),
                  if (task.aiPriorityScore != null)
                    _Tag(
                      label: t.aiScoreTag(
                        task.aiPriorityScore!.toStringAsFixed(2),
                      ),
                      icon: Icons.auto_awesome,
                    ),
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
