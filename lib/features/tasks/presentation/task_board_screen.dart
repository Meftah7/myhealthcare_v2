/// Staff task board (P5-11) with per-task rationale and the AI-prioritise
/// action (P5-10). Rule score is always shown; the AI score is layered on when
/// present and the two are blended by [StaffTask.effectivePriority].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
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
import '../../auth/application/session.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';
import '../application/task_list.dart';
import 'task_detail_screen.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});
  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  StaffWorkView _view = StaffWorkView.mine;
  TaskKind? _kind;
  String _query = '';
  final _search = TextEditingController();
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _search.dispose();
    super.dispose();
  }

  String s(String en, String ar) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tasks = _view == StaffWorkView.team
        ? ref.watch(teamWorkProvider)
        : ref.watch(staffWorkProvider);
    final weight = ref.watch(aiTaskWeightProvider).valueOrNull ?? 0.5;
    final staffId = ref.watch(currentUserProvider)?.id ?? '';
    return AppScaffold(
      title: t.taskBoardTitle,
      actions: const [StaffTopActions()],
      body: tasks.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadTasks,
          onRetry: () => ref.invalidate(staffWorkProvider),
        ),
        data: (list) {
          final now = DateTime.now();
          final names = {
            for (final staff
                in ref.watch(staffDirectoryProvider).valueOrNull ??
                    const <Staff>[])
              staff.id: staff.fullName,
            for (final id
                in list.map((t) => t.patientId).whereType<String>().toSet())
              id: ref.watch(taskPatientNameProvider(id)).valueOrNull ?? id,
          };
          final filtered = visibleStaffWork(
            list,
            staffId: staffId,
            view: _view,
            now: now,
            aiWeight: weight,
            query: _query,
            kind: _kind,
            names: names,
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
                key: const PageStorageKey('staff-work-list'),
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.xxl,
                ),
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        context.push('${AppRoutes.staffTasks}/handover'),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(
                      workText(
                        context,
                        'Hand over work',
                        '\u062a\u0633\u0644\u064a\u0645 \u0627\u0644\u0645\u0646\u0627\u0648\u0628\u0629',
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    children: [
                      for (final view in StaffWorkView.values)
                        ChoiceChip(
                          selected: _view == view,
                          onSelected: (_) => setState(() => _view = view),
                          label: Text(switch (view) {
                            StaffWorkView.team => s(
                              'Team work',
                              '\u0639\u0645\u0644 \u0627\u0644\u0641\u0631\u064a\u0642',
                            ),
                            StaffWorkView.mine => s('My work', 'عملي'),
                            StaffWorkView.covering => s('Covering', 'التغطية'),
                            StaffWorkView.completed => s(
                              'Completed',
                              'المكتمل',
                            ),
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      labelText: s(
                        'Search task, patient ID or owner',
                        'بحث بالمهمة أو رقم المريض أو المسؤول',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: s('Clear search', 'مسح البحث'),
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  DropdownButtonFormField<TaskKind>(
                    initialValue: _kind,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s('Task type', 'نوع المهمة'),
                    ),
                    items: [
                      DropdownMenuItem(
                        child: Text(s('All types', 'كل الأنواع')),
                      ),
                      for (final kind in TaskKind.values)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(_kindLabel(t, kind)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                  const SizedBox(height: Space.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _PrioritiseButton(),
                  ),
                  InlineBanner.info(
                    s(
                      'Mock ranking supports urgency and deadlines. It never completes work or makes clinical decisions.',
                      'الترتيب التجريبي يدعم أولوية الاستعجال والمواعيد. لا يكمل العمل ولا يتخذ قرارات طبية.',
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: Text(
                        list.isEmpty
                            ? t.noOpenTasksMessage
                            : s(
                                'No tasks match this view.',
                                'لا توجد مهام تطابق هذا العرض.',
                              ),
                      ),
                    ),
                  for (final group in TaskTimeGroup.values)
                    if (filtered.any(
                      (task) => taskTimeGroup(task, now) == group,
                    )) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.md),
                        child: Text(switch (group) {
                          TaskTimeGroup.urgent => s('Urgent', 'عاجل'),
                          TaskTimeGroup.overdue => s('Overdue', 'متأخر'),
                          TaskTimeGroup.today => s('Due today', 'مستحق اليوم'),
                          TaskTimeGroup.upcoming => s(
                            'Upcoming / no deadline',
                            'قادم / دون موعد نهائي',
                          ),
                          TaskTimeGroup.completed => s(
                            'Completed / dismissed',
                            'مكتمل / مستبعد',
                          ),
                        }, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      for (final task in filtered.where(
                        (task) => taskTimeGroup(task, now) == group,
                      )) ...[
                        _TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          weight: weight,
                        ),
                        const SizedBox(height: Space.sm),
                      ],
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
      label: Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'تحديث الترتيب التجريبي'
            : 'Refresh mock ranking',
      ),
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
      await changeTask(context, ref, task, status);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final patient = task.patientId == null
        ? null
        : ref.watch(taskPatientNameProvider(task.patientId!));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PriorityDot(
                task.priority == WorkPriority.urgent
                    ? 1
                    : task.priority == WorkPriority.priority
                    ? .6
                    : .3,
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(task.title, style: theme.textTheme.titleSmall),
              ),
              PopupMenuButton<TaskStatus>(
                enabled: !_busy && task.isOpen,
                onSelected: _change,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TaskStatus.waiting,
                    child: Text(
                      workText(
                        context,
                        'Waiting',
                        '\u0627\u0646\u062a\u0638\u0627\u0631',
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskStatus.blocked,
                    child: Text(
                      workText(
                        context,
                        'Blocked',
                        '\u0645\u062a\u0639\u0637\u0644',
                      ),
                    ),
                  ),
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
          TextButton(
            onPressed: () => context.push(
              '${AppRoutes.staffTasks}/${Uri.encodeComponent(task.id)}',
            ),
            child: Text(
              workText(
                context,
                'Details, source and history',
                '\u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644 \u0648\u0627\u0644\u0645\u0635\u062f\u0631 \u0648\u0627\u0644\u0633\u062c\u0644',
              ),
            ),
          ),
          const SizedBox(height: Space.xxs),
          if (task.patientId != null)
            Text(
              '${ar ? 'المريض' : 'Patient'}: ${patient?.valueOrNull ?? task.patientId}',
              style: theme.textTheme.bodyMedium,
            ),
          Text(
            '${ar ? 'المسؤول' : 'Owner'}: ${task.staffId}${task.coverageStaffId == null ? '' : ' · ${ar ? 'التغطية' : 'Cover'}: ${task.coverageStaffId}'}',
          ),
          Text(
            task.dueAt == null
                ? (ar ? 'لا يوجد موعد نهائي' : 'No deadline recorded')
                : '${ar ? 'الموعد النهائي' : 'Deadline'}: ${fmtDateTime(task.dueAt!)}',
          ),
          Text(
            '${ar ? 'الخطوة التالية' : 'Next action'}: ${!task.isOpen
                ? (ar ? 'تم إغلاق العمل' : 'Work closed')
                : task.status == TaskStatus.open
                ? t.startAction
                : t.completeAction}',
          ),
          if (task.patientId != null)
            TextButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.staffPatients}/${Uri.encodeComponent(task.patientId!)}',
              ),
              icon: const Icon(Icons.person_outline),
              label: Text(ar ? 'فتح ملف المريض' : 'Open patient chart'),
            ),
          const SizedBox(height: Space.xs),
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
              if (task.status == TaskStatus.waiting)
                _Tag(
                  label: workText(
                    context,
                    'Waiting; owner must review',
                    'انتظار؛ يجب على المسؤول المراجعة',
                  ),
                ),
              if (task.status == TaskStatus.blocked)
                _Tag(
                  label: workText(
                    context,
                    'Blocked; owner must review',
                    'متعطل؛ يجب على المسؤول المراجعة',
                  ),
                ),
              if (!task.isOpen)
                _Tag(
                  label: task.status == TaskStatus.done
                      ? (ar ? 'مكتمل' : 'Completed')
                      : (ar ? 'مستبعد' : 'Dismissed'),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          if (task.isOpen)
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
            key: PageStorageKey('task-rationale-${task.id}'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              ar ? 'لماذا هذه المهمة؟' : 'Why this task?',
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Text(
                ar
                    ? 'الاستعجال والموعد النهائي يسبقان الدرجة الداعمة. مصدر الترتيب: قواعد محلية وتجربة محاكاة.'
                    : 'Urgency and deadline come before the supporting score. Ranking source: local rules and a deterministic mock.',
              ),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  _Tag(
                    label: t.ruleScoreTag(task.ruleScore.toStringAsFixed(2)),
                  ),
                  if (task.aiPriorityScore != null)
                    _Tag(
                      label:
                          '${ar ? 'تجريبي' : 'Mock'} · ${t.aiScoreTag(task.aiPriorityScore!.toStringAsFixed(2))}',
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
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
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
