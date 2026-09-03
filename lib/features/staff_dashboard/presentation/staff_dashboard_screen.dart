/// Staff dashboard (P5-05, redesign v2): the shift overview — a stat row,
/// today's schedule, open risk flags, and the top tasks. Rule-engine driven,
/// fully useful with AI off.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/staff_providers.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [_ScanButton(), const SignOutAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(staffTodayProvider)
            ..invalidate(unacknowledgedFlagsProvider)
            ..invalidate(staffTasksProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.xxl),
              children: [
                Text(greeting(firstName), style: theme.textTheme.headlineSmall),
                const SizedBox(height: Space.xxs),
                Text(
                  fmtDate(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),

                _StatRow(),
                const SizedBox(height: Space.md),

                SectionHeader(
                  'Today',
                  overline: true,
                  action: 'Schedule',
                  onAction: () => context.go(AppRoutes.staffSchedule),
                ),
                _TodaySchedule(),
                const SizedBox(height: Space.md),

                SectionHeader(
                  'Risk flags',
                  overline: true,
                  action: 'Patients',
                  onAction: () => context.go(AppRoutes.staffPatients),
                ),
                _RiskFlags(),
                const SizedBox(height: Space.md),

                SectionHeader(
                  'Tasks',
                  overline: true,
                  action: 'Task board',
                  onAction: () => context.go(AppRoutes.staffTasks),
                ),
                _TaskPreview(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffTodayProvider).valueOrNull;
    final flags = ref.watch(unacknowledgedFlagsProvider).valueOrNull;
    final tasks = ref.watch(staffTasksProvider).valueOrNull;
    final overdue = tasks?.where((t) => t.isOverdue).length ?? 0;

    return Row(
      children: [
        Expanded(
          child: MetricTile(
            value: '${today?.length ?? 0}',
            label: 'Appointments today',
            icon: Icons.calendar_today_outlined,
            onTap: () => context.go(AppRoutes.staffSchedule),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: '${flags?.length ?? 0}',
            label: 'Open flags',
            icon: Icons.flag_outlined,
            onTap: () => context.go(AppRoutes.staffPatients),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: '${tasks?.length ?? 0}',
            label: 'Open tasks',
            caption: overdue > 0 ? '$overdue overdue' : null,
            icon: Icons.checklist_outlined,
            onTap: () => context.go(AppRoutes.staffTasks),
          ),
        ),
      ],
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
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.radar),
    );
  }
}

/// A card wrapping a list, with a friendly empty row.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.children, this.emptyIcon, this.emptyText});
  final List<Widget> children;
  final IconData? emptyIcon;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Icon(
              emptyIcon ?? Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                emptyText ?? 'Nothing here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: Space.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _TodaySchedule extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(staffTodayProvider);
    return today.when(
      loading: () => const LoadingSkeleton(height: 72),
      error: (e, _) =>
          const InlineBanner.error('Could not load your schedule.'),
      data: (appts) => _ListCard(
        emptyIcon: Icons.event_available_outlined,
        emptyText: 'Nothing booked today.',
        children: [
          for (final a in appts)
            ListTile(
              leading: Container(
                width: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: Radii.chip,
                ),
                child: Text(
                  fmtTime(a.slotStart),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: Text(visitTypeLabel(a.visitType)),
              subtitle: a.reasonText == null
                  ? null
                  : Text(
                      a.reasonText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: a.riskBand == null ? null : RiskBadge(a.riskBand!),
              onTap: () =>
                  context.go(AppRoutes.staffPatientChart(a.patientId)),
            ),
        ],
      ),
    );
  }
}

class _RiskFlags extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final flags = ref.watch(unacknowledgedFlagsProvider);
    return flags.when(
      loading: () => const LoadingSkeleton(height: 72),
      error: (e, _) =>
          const InlineBanner.error('Could not load risk flags.'),
      data: (list) {
        final sorted = [...list]
          ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
        return _ListCard(
          emptyIcon: Icons.verified_outlined,
          emptyText: 'No open risk flags. Run a panel scan to refresh.',
          children: [
            for (final f in sorted.take(6))
              ListTile(
                leading: SeverityChip(f.severity),
                title: Text(
                  f.rationale,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.all(Space.md),
                child: Text(
                  '+${sorted.length - 6} more on the Patients tab',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
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
      loading: () => const LoadingSkeleton(height: 72),
      error: (e, _) => const InlineBanner.error('Could not load tasks.'),
      data: (list) => _ListCard(
        emptyIcon: Icons.checklist_outlined,
        emptyText: 'No open tasks. Run a panel scan from the app bar.',
        children: [
          for (final t in list.take(5))
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked, size: 20),
              title: Text(t.title),
              subtitle: t.dueAt == null
                  ? null
                  : Text(
                      'Due ${fmtRelativeDay(t.dueAt!)}',
                      style: t.isOverdue
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
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
  }
}

String _kindLabel(RiskFlagKind k) => switch (k) {
  RiskFlagKind.abnormalVitals => 'Abnormal vitals',
  RiskFlagKind.abnormalLab => 'Abnormal lab',
  RiskFlagKind.medicationGap => 'Medication gap',
  RiskFlagKind.overdueFollowUp => 'Overdue follow-up',
  RiskFlagKind.other => 'Other',
};
