/// Staff dashboard (P5-05): today's schedule, open risk flags, and the top of
/// the task list — all populated by the rule engine, useful with AI off.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../application/staff_providers.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          _ScanButton(),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                unawaited(ref.read(sessionProvider.notifier).logout());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(staffTodayProvider)
            ..invalidate(unacknowledgedFlagsProvider)
            ..invalidate(staffTasksProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text('Hello, $firstName', style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.lg),
            _SectionHeader(
              title: 'Today',
              onSeeAll: () => context.go(AppRoutes.staffSchedule),
            ),
            _TodaySchedule(),
            const SizedBox(height: Space.lg),
            _SectionHeader(
              title: 'Risk flags',
              onSeeAll: () => context.go(AppRoutes.staffPatients),
            ),
            _RiskFlags(),
            const SizedBox(height: Space.lg),
            _SectionHeader(
              title: 'Tasks',
              onSeeAll: () => context.go(AppRoutes.staffTasks),
            ),
            _TaskPreview(),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends ConsumerState<_ScanButton> {
  bool _running = false;

  Future<void> _scan() async {
    setState(() => _running = true);
    try {
      final count = await ref.read(staffOpsProvider).refreshPanel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Panel scan complete — $count open flag(s).')),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Scan panel for risks',
      onPressed: _running ? null : _scan,
      icon: _running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.radar),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _TodaySchedule extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(staffTodayProvider);
    return today.when(
      loading: () => const LoadingSkeleton(height: 60),
      error: (e, _) => Text(
        'Could not load your schedule.',
        style: theme.textTheme.bodyMedium,
      ),
      data: (appts) {
        if (appts.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: Text(
                'Nothing booked today',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final a in appts)
                ListTile(
                  leading: Text(
                    fmtTime(a.slotStart),
                    style: theme.textTheme.titleSmall,
                  ),
                  title: Text(a.visitType.name),
                  subtitle: a.reasonText == null
                      ? null
                      : Text(
                          a.reasonText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: a.riskBand == null
                      ? _StatusChip(a.status)
                      : RiskBadge(a.riskBand!),
                  onTap: () =>
                      context.go(AppRoutes.staffPatientChart(a.patientId)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.name),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _RiskFlags extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final flags = ref.watch(unacknowledgedFlagsProvider);
    return flags.when(
      loading: () => const LoadingSkeleton(height: 60),
      error: (e, _) =>
          Text('Could not load risk flags.', style: theme.textTheme.bodyMedium),
      data: (list) {
        if (list.isEmpty) {
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'No open risk flags. Run a panel scan to refresh.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }
        final sorted = [...list]
          ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
        return Card(
          child: Column(
            children: [
              for (final f in sorted.take(6))
                ListTile(
                  leading: SeverityChip(f.severity),
                  title: Text(
                    f.rationale,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(_kindLabel(f.kind)),
                  trailing: IconButton(
                    tooltip: 'Acknowledge',
                    icon: const Icon(Icons.done),
                    onPressed: () =>
                        ref.read(staffOpsProvider).acknowledgeFlag(f.id),
                  ),
                  onTap: () =>
                      context.go(AppRoutes.staffPatientChart(f.patientId)),
                ),
              if (sorted.length > 6)
                Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Text(
                    '+${sorted.length - 6} more',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(staffTasksProvider);
    return tasks.when(
      loading: () => const LoadingSkeleton(height: 60),
      error: (e, _) =>
          Text('Could not load tasks.', style: theme.textTheme.bodyMedium),
      data: (list) {
        if (list.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: Text('No open tasks.', style: theme.textTheme.bodyMedium),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final t in list.take(5))
                ListTile(
                  leading: const Icon(Icons.task_alt_outlined),
                  title: Text(t.title, style: theme.textTheme.bodyMedium),
                  subtitle: t.dueAt == null
                      ? null
                      : Text(
                          'Due ${fmtRelativeDay(t.dueAt!)}',
                          style: t.isOverdue
                              ? theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                )
                              : theme.textTheme.bodySmall,
                        ),
                  trailing: IconButton(
                    tooltip: 'Mark done',
                    icon: const Icon(Icons.check),
                    onPressed: () => ref
                        .read(staffOpsProvider)
                        .setTaskStatus(t.id, TaskStatus.done),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _kindLabel(RiskFlagKind k) => switch (k) {
  RiskFlagKind.abnormalVitals => 'Abnormal vitals',
  RiskFlagKind.abnormalLab => 'Abnormal lab',
  RiskFlagKind.medicationGap => 'Medication gap',
  RiskFlagKind.overdueFollowUp => 'Overdue follow-up',
  RiskFlagKind.other => 'Other',
};
