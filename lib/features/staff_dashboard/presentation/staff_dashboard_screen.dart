/// Staff dashboard (staff-dashboard rebuild): the shift overview — greeting +
/// presence, a stat row, the Quick actions grid, today's queue with clinical
/// actions, open risk flags and the top tasks. Rule-engine driven, fully
/// useful with AI off. Mirrors the FirstSemMyHealth doctor dashboard.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import '../../patient_chart/presentation/chart_write_sheets.dart';
import '../application/staff_providers.dart';
import 'staff_quick_actions.dart';
import 'staff_top_actions.dart';

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
        actions: const [StaffTopActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(staffTodayProvider)
            ..invalidate(staffQueueProvider)
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

                _StatGrid(),
                const SizedBox(height: Space.md),

                const SectionHeader('Quick actions', overline: true),
                const StaffQuickActions(),
                const SizedBox(height: Space.md),

                SectionHeader(
                  'Today’s queue',
                  overline: true,
                  action: 'Schedule',
                  onAction: () => context.go(AppRoutes.staffSchedule),
                ),
                _QueueCard(),
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

class _StatGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffTodayProvider).valueOrNull;
    final queue = ref.watch(staffQueueProvider).valueOrNull;
    final flags = ref.watch(unacknowledgedFlagsProvider).valueOrNull;
    final tasks = ref.watch(staffTasksProvider).valueOrNull;
    final overdue = tasks?.where((t) => t.isOverdue).length ?? 0;
    final compact = WindowSize.of(context).isCompact;

    return GridView.count(
      crossAxisCount: compact ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
      childAspectRatio: compact ? 1.8 : 1.5,
      children: [
        MetricTile(
          value: '${today?.length ?? 0}',
          label: 'Appointments today',
          icon: Icons.calendar_today_outlined,
          onTap: () => context.go(AppRoutes.staffSchedule),
        ),
        MetricTile(
          value: '${queue?.length ?? 0}',
          label: 'In your queue',
          icon: Icons.groups_outlined,
        ),
        MetricTile(
          value: '${flags?.length ?? 0}',
          label: 'Open flags',
          icon: Icons.flag_outlined,
          onTap: () => context.go(AppRoutes.staffPatients),
        ),
        MetricTile(
          value: '${tasks?.length ?? 0}',
          label: 'Open tasks',
          caption: overdue > 0 ? '$overdue overdue' : null,
          icon: Icons.checklist_outlined,
          onTap: () => context.go(AppRoutes.staffTasks),
        ),
      ],
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

/// Today's queue — soonest first, with the status-driven clinical actions
/// (Accept → Start → Complete) plus an overflow menu for chart / transfer /
/// cancel. Mirrors the FirstSemMyHealth "Today's Patients" table.
class _QueueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final queue = ref.watch(staffQueueProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};

    return queue.when(
      loading: () => const LoadingSkeleton(height: 88),
      error: (e, _) => const InlineBanner.error('Could not load your queue.'),
      data: (appts) => _ListCard(
        emptyIcon: Icons.event_available_outlined,
        emptyText: 'Nobody waiting — your queue is clear.',
        children: [
          for (final a in appts)
            _QueueRow(
              appointment: a,
              patientName: names[a.patientId],
              scheme: scheme,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    required this.appointment,
    required this.patientName,
    required this.scheme,
    required this.theme,
  });

  final Appointment appointment;
  final String? patientName;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final ops = ref.read(staffOpsProvider);
    final accepted = a.status == AppointmentStatus.confirmed;
    final checkedIn = a.checkedInAt != null;

    final (String actionLabel, VoidCallback onAction) = !accepted
        ? ('Accept', () => unawaited(ops.acceptAppointment(a.id)))
        : !checkedIn
        ? ('Start', () => unawaited(ops.startVisit(a.id)))
        : ('Complete', () => unawaited(ops.completeAppointment(a.id)));

    return InkWell(
      onTap: () => context.go(AppRoutes.staffPatientChart(a.patientId)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.sm,
          Space.xs,
          Space.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: Radii.chip,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmtTime(a.slotStart),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  if (a.ticketTag != null)
                    Text(
                      a.ticketTag!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          patientName ?? visitTypeLabel(a.visitType),
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (a.riskBand == RiskBand.high) ...[
                        const SizedBox(width: Space.xs),
                        RiskBadge(a.riskBand!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      visitTypeLabel(a.visitType),
                      if (a.roomNumber != null) 'Room ${a.roomNumber}',
                      if (checkedIn) 'checked in',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            accepted && checkedIn
                ? FilledButton(onPressed: onAction, child: Text(actionLabel))
                : FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (v) => unawaited(switch (v) {
                'chart' => Future.sync(
                  () => context.go(AppRoutes.staffPatientChart(a.patientId)),
                ),
                'note' => showChartNoteSheet(context, a.patientId),
                'transfer' => showTransferSheet(context, ref),
                'cancel' => _confirmThen(
                  context,
                  title: 'Cancel this visit?',
                  message: 'The patient will need to rebook.',
                  confirmLabel: 'Cancel visit',
                  action: () => ops.cancelAppointment(a.id),
                ),
                'noshow' => _confirmThen(
                  context,
                  title: 'Mark as no-show?',
                  message: 'This records that the patient did not attend.',
                  confirmLabel: 'Mark no-show',
                  action: () => ops.cancelAppointment(a.id, noShow: true),
                ),
                _ => Future<void>.value(),
              }),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'chart', child: Text('Open chart')),
                PopupMenuItem(value: 'note', child: Text('Add note')),
                PopupMenuItem(value: 'transfer', child: Text('Transfer visit')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'cancel', child: Text('Cancel visit')),
                PopupMenuItem(value: 'noshow', child: Text('Mark no-show')),
              ],
            ),
          ],
        ),
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
      error: (e, _) => const InlineBanner.error('Could not load risk flags.'),
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
        emptyText: 'No open tasks. Run a panel scan from Quick actions.',
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

Future<void> _confirmThen(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() action,
}) async {
  final ok = await confirm(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: true,
  );
  if (ok) await action();
}

String _kindLabel(RiskFlagKind k) => switch (k) {
  RiskFlagKind.abnormalVitals => 'Abnormal vitals',
  RiskFlagKind.abnormalLab => 'Abnormal lab',
  RiskFlagKind.medicationGap => 'Medication gap',
  RiskFlagKind.overdueFollowUp => 'Overdue follow-up',
  RiskFlagKind.other => 'Other',
};
