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
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
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
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return AppScaffold(
      // The brand lockup, not the word "Dashboard": the greeting below already
      // says where you are, and two headings competing is one too many.
      titleWidget: const AppBrandLockup(subtitle: 'Staff'),
      actions: const [StaffTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(staffTodayProvider)
          ..invalidate(staffQueueProvider)
          ..invalidate(unacknowledgedFlagsProvider)
          ..invalidate(staffTasksProvider);
      },
      children: [
        PageGreeting(
          overline: fmtDate(DateTime.now()),
          greeting: greeting(firstName),
        ),
        const SizedBox(height: Space.lg),

        const _NextPatientHero(),

        SectionColumns(
          primary: [
            const SectionHeader('Your shift', overline: true),
            _ShiftSnapshot(),
            const SectionHeader('Quick actions', overline: true),
            const StaffQuickActions(),
          ],
          secondary: [
            SectionHeader(
              'Today’s queue',
              overline: true,
              action: 'Schedule',
              onAction: () => context.go(AppRoutes.staffSchedule),
            ),
            _QueueCard(),
            SectionHeader(
              'Risk flags',
              overline: true,
              action: 'Patients',
              onAction: () => context.go(AppRoutes.staffPatients),
            ),
            _RiskFlags(),
            SectionHeader(
              'Tasks',
              overline: true,
              action: 'Task board',
              onAction: () => context.go(AppRoutes.staffTasks),
            ),
            _TaskPreview(),
          ],
        ),
      ],
    );
  }
}

/// The screen's one saturated surface — whoever you see next, and the way in
/// to their chart. The staff equivalent of the patient's "Quick appointment".
class _NextPatientHero extends ConsumerWidget {
  const _NextPatientHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(staffQueueProvider).valueOrNull;
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final next = (queue == null || queue.isEmpty) ? null : queue.first;

    if (next == null) {
      return GradientHeroCard(
        icon: Icons.event_available_outlined,
        title: 'Your queue is clear',
        subtitle: 'Nobody waiting — open your week to plan ahead',
        onTap: () => context.go(AppRoutes.staffSchedule),
      );
    }

    final who = names[next.patientId] ?? visitTypeLabel(next.visitType);
    return GradientHeroCard(
      icon: Icons.play_circle_outline,
      title: 'Next · $who',
      subtitle: [
        fmtTime(next.slotStart),
        visitTypeLabel(next.visitType),
        if (next.roomNumber != null) 'Room ${next.roomNumber}',
      ].join(' · '),
      onTap: () => context.go(AppRoutes.staffPatientChart(next.patientId)),
    );
  }
}

/// Three figures for the shift, side by side — the staff mirror of the
/// patient's "Your health" row.
class _ShiftSnapshot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffTodayProvider).valueOrNull;
    final queue = ref.watch(staffQueueProvider).valueOrNull;
    final flags = ref.watch(unacknowledgedFlagsProvider).valueOrNull;

    return MetricRow(
      children: [
        MetricTile(
          value: '${today?.length ?? 0}',
          label: 'Today',
          icon: Icons.calendar_today_outlined,
          onTap: () => context.go(AppRoutes.staffSchedule),
        ),
        MetricTile(
          value: '${queue?.length ?? 0}',
          label: 'In queue',
          icon: Icons.groups_outlined,
        ),
        MetricTile(
          value: '${flags?.length ?? 0}',
          label: 'Open flags',
          icon: Icons.flag_outlined,
          onTap: () => context.go(AppRoutes.staffPatients),
        ),
      ],
    );
  }
}

/// Today's queue — soonest first, with the status-driven clinical actions
/// (Accept → Start → Complete) plus an overflow menu for chart / transfer /
/// cancel. Mirrors the FirstSemMyHealth "Today's Patients" table.
class _QueueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(staffQueueProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};

    return AppReveal(
      child: queue.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('q-load'), height: 88),
        error: (e, _) => const InlineBanner.error(
          'Could not load your queue.',
          key: ValueKey('q-err'),
        ),
        data: (appts) => ListCard(
          key: const ValueKey('q-data'),
          emptyIcon: Icons.event_available_outlined,
          emptyText: 'Nobody waiting — your queue is clear.',
          children: [
            for (final a in appts)
              _QueueRow(appointment: a, patientName: names[a.patientId]),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.appointment, required this.patientName});

  final Appointment appointment;
  final String? patientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = appointment;
    final ops = ref.read(staffOpsProvider);
    final accepted = a.status == AppointmentStatus.confirmed;
    final checkedIn = a.checkedInAt != null;

    final (String actionLabel, VoidCallback onAction) = !accepted
        ? ('Accept', () => unawaited(ops.acceptAppointment(a.id)))
        : !checkedIn
        ? ('Start', () => unawaited(ops.startVisit(a.id)))
        : ('Complete', () => unawaited(ops.completeAppointment(a.id)));

    // Once the OS text size is up, a time chip, a name, a filled button and an
    // overflow menu can't share one line. Past ~1.4x the action drops to its
    // own row rather than overflowing.
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 20;

    final actionButton = accepted && checkedIn
        ? FilledButton(onPressed: onAction, child: Text(actionLabel))
        : FilledButton.tonal(onPressed: onAction, child: Text(actionLabel));

    final menu = PopupMenuButton<String>(
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
    );

    final identity = Row(
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
            mainAxisSize: MainAxisSize.min,
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
      ],
    );

    return InkWell(
      onTap: () => context.go(AppRoutes.staffPatientChart(a.patientId)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.sm,
          Space.xs,
          Space.sm,
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: identity),
                      menu,
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actionButton,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: Space.xs),
                  actionButton,
                  menu,
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
    return AppReveal(
      child: flags.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('f-load'), height: 72),
        error: (e, _) => const InlineBanner.error(
          'Could not load risk flags.',
          key: ValueKey('f-err'),
        ),
        data: (list) {
          final sorted = [...list]
            ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
          return ListCard(
            key: const ValueKey('f-data'),
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
      ),
    );
  }
}

class _TaskPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(staffTasksProvider);
    return AppReveal(
      child: tasks.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('t-load'), height: 72),
        error: (e, _) => const InlineBanner.error(
          'Could not load tasks.',
          key: ValueKey('t-err'),
        ),
        data: (list) => ListCard(
          key: const ValueKey('t-data'),
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
