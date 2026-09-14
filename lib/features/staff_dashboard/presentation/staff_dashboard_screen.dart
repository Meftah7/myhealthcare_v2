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
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient_chart/presentation/chart_write_sheets.dart';
import '../application/staff_providers.dart';
import 'staff_quick_actions.dart';
import 'staff_top_actions.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? t.greetingFallbackName).split(
      ' ',
    ).first;

    return AppScaffold(
      // The brand lockup, not the word "Dashboard": the greeting below already
      // says where you are, and two headings competing is one too many.
      titleWidget: AppBrandLockup(subtitle: t.roleStaff),
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
            SectionHeader(t.yourShiftHeader, overline: true),
            _ShiftSnapshot(),
            SectionHeader(t.quickActionsHeader, overline: true),
            const StaffQuickActions(),
          ],
          secondary: [
            const _DepartmentWalkIns(),
            SectionHeader(
              t.todaysQueueHeader,
              overline: true,
              action: t.scheduleAction,
              onAction: () => context.go(AppRoutes.staffSchedule),
            ),
            _QueueCard(),
            SectionHeader(
              t.riskFlagsHeader,
              overline: true,
              action: t.patientsAction,
              onAction: () => context.go(AppRoutes.staffPatients),
            ),
            _RiskFlags(),
            SectionHeader(
              t.tasksHeader,
              overline: true,
              action: t.taskBoardAction,
              onAction: () => context.go(AppRoutes.staffTasks),
            ),
            _TaskPreview(),
          ],
        ),
      ],
    );
  }
}

/// Patients referred into this doctor's department with a walk-in ticket —
/// no scheduled slot, waiting at the desk. "Start" turns the ticket into an
/// in-progress visit and opens the consultation. Hidden when there are none.
class _DepartmentWalkIns extends ConsumerWidget {
  const _DepartmentWalkIns();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final walkIns = ref.watch(departmentWalkInsProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final list = walkIns.valueOrNull ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          t.departmentWalkInsHeader(list.length),
          overline: true,
        ),
        ListCard(
          children: [
            for (final t in list)
              _WalkInRow(ticket: t, patientName: names[t.patientId]),
          ],
        ),
      ],
    );
  }
}

class _WalkInRow extends ConsumerStatefulWidget {
  const _WalkInRow({required this.ticket, this.patientName});

  final WalkInTicket ticket;
  final String? patientName;

  @override
  ConsumerState<_WalkInRow> createState() => _WalkInRowState();
}

class _WalkInRowState extends ConsumerState<_WalkInRow> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(staffOpsProvider).startWalkIn(widget.ticket);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        unawaited(context.push(AppRoutes.staffConsultation(value)));
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ticket = widget.ticket;
    return Padding(
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
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: Radii.chip,
            ),
            child: Text(
              ticket.ticketTag,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.patientName ?? t.rolePatient,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ticket.reason != null)
                  Text(
                    ticket.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          FilledButton.tonal(
            onPressed: _busy ? null : _start,
            child: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.startAction),
          ),
        ],
      ),
    );
  }
}

/// The screen's one saturated surface — whoever you see next, and the way in
/// to their chart. The staff equivalent of the patient's "Quick appointment".
class _NextPatientHero extends ConsumerWidget {
  const _NextPatientHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final queue = ref.watch(staffQueueProvider).valueOrNull;
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final next = (queue == null || queue.isEmpty) ? null : queue.first;

    if (next == null) {
      return GradientHeroCard(
        icon: Icons.event_available_outlined,
        title: t.yourQueueIsClear,
        subtitle: t.nobodyWaitingOpenWeek,
        onTap: () => context.go(AppRoutes.staffSchedule),
      );
    }

    final who = names[next.patientId] ?? visitTypeLabel(next.visitType);
    return GradientHeroCard(
      icon: Icons.play_circle_outline,
      title: t.nextPatientLabel(who),
      subtitle: [
        fmtTime(next.slotStart),
        visitTypeLabel(next.visitType),
        if (next.roomNumber != null) t.roomNumber('${next.roomNumber}'),
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
    final t = AppLocalizations.of(context)!;
    final today = ref.watch(staffTodayProvider).valueOrNull;
    final queue = ref.watch(staffQueueProvider).valueOrNull;
    final flags = ref.watch(unacknowledgedFlagsProvider).valueOrNull;

    return MetricRow(
      children: [
        MetricTile(
          value: '${today?.length ?? 0}',
          label: t.todayLabel,
          icon: Icons.calendar_today_outlined,
          onTap: () => context.go(AppRoutes.staffSchedule),
        ),
        MetricTile(
          value: '${queue?.length ?? 0}',
          label: t.inQueueLabel,
          icon: Icons.groups_outlined,
        ),
        MetricTile(
          value: '${flags?.length ?? 0}',
          label: t.openFlagsLabel,
          icon: Icons.flag_outlined,
          onTap: () => context.go(AppRoutes.staffPatients),
        ),
      ],
    );
  }
}

/// Today's queue — soonest first. A read-only tracking list: tap a row for the
/// patient's chart, or use the overflow menu for note / transfer / cancel. The
/// arrival workflow (call / arrived / not arrived / complete) lives on the
/// Schedule timeline, not here.
class _QueueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final queue = ref.watch(staffQueueProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};

    return AppReveal(
      child: queue.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('q-load'), height: 88),
        error: (e, _) => InlineBanner.error(
          t.couldNotLoadYourQueue,
          key: const ValueKey('q-err'),
        ),
        data: (appts) => ListCard(
          key: const ValueKey('q-data'),
          emptyIcon: Icons.event_available_outlined,
          emptyText: t.nobodyWaitingQueueClear,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = appointment;
    final ops = ref.read(staffOpsProvider);
    final checkedIn = a.checkedInAt != null;

    final menu = PopupMenuButton<String>(
      tooltip: t.moreActionsTooltip,
      onSelected: (v) => unawaited(switch (v) {
        'chart' => Future.sync(
          () => context.go(AppRoutes.staffPatientChart(a.patientId)),
        ),
        'note' => showChartNoteSheet(context, a.patientId),
        'transfer' => showTransferSheet(context, ref),
        'cancel' => _confirmThen(
          context,
          title: t.cancelThisVisitTitle,
          message: t.patientWillNeedToRebook,
          confirmLabel: t.cancelVisitAction,
          action: () => ops.cancelAppointment(a.id),
        ),
        'noshow' => _confirmThen(
          context,
          title: t.markAsNoShowTitle,
          message: t.recordsPatientDidNotAttend,
          confirmLabel: t.markNoShowAction,
          action: () => ops.cancelAppointment(a.id, noShow: true),
        ),
        _ => Future<void>.value(),
      }),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'chart', child: Text(t.openChartAction)),
        PopupMenuItem(value: 'note', child: Text(t.addNoteAction)),
        PopupMenuItem(value: 'transfer', child: Text(t.transferVisitAction)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'cancel', child: Text(t.cancelVisitAction)),
        PopupMenuItem(value: 'noshow', child: Text(t.markNoShowAction)),
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
                  if (a.roomNumber != null) t.roomNumber('${a.roomNumber}'),
                  if (checkedIn) t.checkedInLabel,
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
        child: Row(
          children: [
            Expanded(child: identity),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final flags = ref.watch(unacknowledgedFlagsProvider);
    return AppReveal(
      child: flags.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('f-load'), height: 72),
        error: (e, _) => InlineBanner.error(
          t.couldNotLoadRiskFlags,
          key: const ValueKey('f-err'),
        ),
        data: (list) {
          final sorted = [...list]
            ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
          return ListCard(
            key: const ValueKey('f-data'),
            emptyIcon: Icons.verified_outlined,
            emptyText: t.noOpenRiskFlagsRunScan,
            children: [
              for (final f in sorted.take(6))
                ListTile(
                  leading: SeverityChip(f.severity),
                  title: Text(
                    f.rationale,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(f.kind.label(context)),
                  trailing: IconButton(
                    tooltip: t.acknowledgeTooltip,
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
                    t.moreOnPatientsTab(sorted.length - 6),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasks = ref.watch(staffTasksProvider);
    return AppReveal(
      child: tasks.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('t-load'), height: 72),
        error: (e, _) => InlineBanner.error(
          t.couldNotLoadTasks,
          key: const ValueKey('t-err'),
        ),
        data: (list) => ListCard(
          key: const ValueKey('t-data'),
          emptyIcon: Icons.checklist_outlined,
          emptyText: t.noOpenTasksRunScan,
          children: [
            for (final task in list.take(5))
              ListTile(
                leading: const Icon(Icons.radio_button_unchecked, size: 20),
                title: Text(task.title),
                subtitle: task.dueAt == null
                    ? null
                    : Text(
                        t.dueTag(fmtRelativeDay(task.dueAt!)),
                        style: task.isOverdue
                            ? theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              )
                            : theme.textTheme.bodySmall,
                      ),
                trailing: IconButton(
                  tooltip: t.markDoneTooltip,
                  icon: const Icon(Icons.check),
                  onPressed: () => ref
                      .read(staffOpsProvider)
                      .setTaskStatus(task.id, TaskStatus.done),
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
