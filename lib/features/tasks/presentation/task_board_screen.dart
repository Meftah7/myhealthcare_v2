/// Staff task board (P5-11) with per-task rationale and the AI-prioritise
/// action (P5-10). Rule score is always shown; the AI score is layered on when
/// present and the two are blended by [StaffTask.effectivePriority].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../staff_dashboard/application/staff_providers.dart';

class TaskBoardScreen extends ConsumerWidget {
  const TaskBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(staffTasksProvider);
    final weight = ref.watch(aiTaskWeightProvider).valueOrNull ?? 0.5;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task board'),
        actions: [_PrioritiseButton()],
      ),
      body: tasks.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load tasks.',
          onRetry: () => ref.invalidate(staffTasksProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.checklist_outlined,
              message: 'No open tasks. Run a panel scan from the dashboard.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: Space.xs,
                ),
                child: Text(
                  'Priority = rule score blended ${(weight * 100).round()}% '
                  'with AI score.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final t in list) _TaskCard(task: t, weight: weight),
            ],
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
    try {
      await ref.read(staffOpsProvider).prioritiseWithAi();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tasks re-prioritised.')));
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
      label: const Text('Prioritise'),
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
    final priority = task.effectivePriority(weight);
    return Card(
      child: Padding(
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text('Start'),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.done,
                      child: Text('Complete'),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.dismissed,
                      child: Text('Dismiss'),
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
                _Tag(label: _kindLabel(task.kind)),
                _Tag(label: 'rule ${task.ruleScore.toStringAsFixed(2)}'),
                if (task.aiPriorityScore != null)
                  _Tag(
                    label: 'AI ${task.aiPriorityScore!.toStringAsFixed(2)}',
                    icon: Icons.auto_awesome,
                  ),
                if (task.dueAt != null)
                  _Tag(
                    label: 'due ${fmtRelativeDay(task.dueAt!)}',
                    error: task.isOverdue,
                  ),
                if (task.status == TaskStatus.inProgress)
                  const _Tag(label: 'in progress'),
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

String _kindLabel(TaskKind k) => switch (k) {
  TaskKind.followUpDue => 'Follow-up',
  TaskKind.unreviewedAbnormalLab => 'Abnormal lab',
  TaskKind.unsignedNote => 'Unsigned note',
  TaskKind.medicationReview => 'Medication review',
  TaskKind.referralAction => 'Referral',
  TaskKind.other => 'Other',
};
