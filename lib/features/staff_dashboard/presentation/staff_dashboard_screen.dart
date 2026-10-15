/// Staff dashboard (staff-dashboard rebuild): the shift overview — greeting +
/// presence, a stat row, the Quick actions grid, today's queue with clinical
/// actions, open risk flags and the top tasks. Rule-engine driven, fully
/// useful with AI off. Mirrors the FirstSemMyHealth doctor dashboard.
library;

import 'dart:async';
import '../../workspace/workspace_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/patient_palette.dart';
import '../../../core/failures.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/data_state_view.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/paging_widgets.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../care/application/care_providers.dart';
import '../../patient_chart/application/result_review_providers.dart';
import '../../patient_chart/presentation/chart_write_sheets.dart';
import '../../patient_chart/presentation/result_review_sheet.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../application/staff_providers.dart';
import 'role_workspaces.dart';
import 'staff_quick_actions.dart';
import 'staff_top_actions.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reception, pharmacy and unknown roles get their own Today workspace;
    // clinicians (doctor, dentist, nurse) keep this dashboard.
    final workspace = roleWorkspaceFor(ref.watch(permissionsProvider));
    if (workspace != null) return workspace;
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? t.greetingFallbackName)
        .split(' ')
        .first;

    return AppScaffold(
      stagger: true,
      heroOverline: greeting(firstName),
      // "Dr" only for doctors and dentists (by validated role).
      title: user == null
          ? t.greetingFallbackName
          : staffDisplayName(
              user.fullName,
              ref.watch(staffProfileProvider).valueOrNull?.jobTitle,
            ),
      actions: const [StaffTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(staffTodayProvider)
          ..invalidate(staffQueueProvider)
          ..invalidate(unacknowledgedFlagsProvider)
          ..invalidate(myResultReviewsProvider)
          ..invalidate(staffAwaitingReplyProvider)
          ..invalidate(staffTasksProvider);
      },
      // Same structure as patient Home: feature card, four shortcuts,
      // workspace cards, Quick Access directly below them, then the owned
      // work and attention panels side by side on wide screens.
      children: [
        const StaffQuickStatistics(),
        const _TodayScheduleSummary(),
        SectionHeader(t.quickActionsHeader, overline: true),
        const StaffQuickActions(),
        SectionColumns(
          primary: [const _DepartmentWalkIns()],
          secondary: [
            if (ref.watch(canProvider(Permission.reviewResults))) ...[
              SectionHeader(t.resultsToReviewHeader, overline: true),
              const _ResultReviewQueue(),
            ],
            SectionHeader(
              t.awaitingReplyHeader,
              overline: true,
              action: t.messagesTitle,
              onAction: () => context.push(AppRoutes.staffInbox),
            ),
            const _AwaitingReply(),
            SectionHeader(
              t.riskFlagsHeader,
              overline: true,
              action: t.patientsAction,
              onAction: () => context.go(AppRoutes.staffPatients),
            ),
            _RiskFlags(),
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
    // A failed read is not "nobody waiting": say so, and offer a retry.
    if (walkIns.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: ErrorStateView(
          message: (walkIns.error is Failure)
              ? (walkIns.error! as Failure).message
              : UnexpectedFailure.from(walkIns.error!).message,
          onRetry: () => ref.invalidate(departmentWalkInsProvider),
        ),
      );
    }
    final list = walkIns.valueOrNull ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(t.departmentWalkInsHeader(list.length), overline: true),
        FreshnessBar(
          fetchedAt: ref.watch(departmentWalkInsFetchedAtProvider),
          onRefresh: () => ref.invalidate(departmentWalkInsProvider),
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
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              describeFailure(AppLocalizations.of(context)!, failure).message,
            ),
          ),
        );
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
      onTap: () => context.push(AppRoutes.staffConsultation(a.id)),
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
                    onPressed: () async {
                      final result = await Result.guardAsync(
                        () => ref.read(staffOpsProvider).acknowledgeFlag(f.id),
                      );
                      if (!context.mounted) return;
                      showMutationFeedback(
                        context,
                        result,
                        onReload: () =>
                            ref.invalidate(unacknowledgedFlagsProvider),
                      );
                    },
                  ),
                  onTap: () =>
                      context.push(AppRoutes.staffPatientChart(f.patientId)),
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

/// Abnormal, critical and unjudgeable results this clinician owns or
/// covers — most urgent first, overdue in red. A failed read says so; it is
/// never an empty "all clear".
class _ResultReviewQueue extends ConsumerWidget {
  const _ResultReviewQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reviews = ref.watch(myResultReviewsProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    return AppReveal(
      child: reviews.when(
        loading: () =>
            const LoadingSkeleton(key: ValueKey('rr-load'), height: 72),
        error: (e, _) => InlineBanner.error(
          t.couldNotLoadResultReviews,
          key: const ValueKey('rr-err'),
        ),
        data: (list) => ListCard(
          key: const ValueKey('rr-data'),
          emptyIcon: Icons.science_outlined,
          emptyText: t.noResultsToReview,
          children: [
            for (final rv in list.take(5))
              Builder(
                builder: (context) {
                  final overdue = rv.isOverdueAt(DateTime.now());
                  final due = '${fmtDate(rv.dueAt)} ${fmtTime(rv.dueAt)}';
                  return ListTile(
                    leading: Icon(
                      rv.priority == WorkPriority.urgent
                          ? Icons.priority_high
                          : Icons.science_outlined,
                      color: rv.priority == WorkPriority.urgent
                          ? theme.colorScheme.error
                          : null,
                    ),
                    title: Text(
                      '${names[rv.patientId] ?? t.rolePatient} · '
                      '${rv.recordTitle}',
                    ),
                    subtitle: Text(
                      '${rv.priority.label(context)} · '
                      '${rv.status.label(context)} · '
                      '${overdue ? t.resultReviewOverdue(due) : t.resultReviewDue(due)}',
                      style: overdue
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            )
                          : theme.textTheme.bodySmall,
                    ),
                    onTap: () => showResultSheet(context, rv.recordId),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Patient messages this clinician owns or covers that still need a reply,
/// earliest due first; overdue in red. Covered threads open as the owner's
/// thread, so the reply lands where the patient is looking.
class _AwaitingReply extends ConsumerWidget {
  const _AwaitingReply();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider)?.id;
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final staff = {
      for (final s
          in ref.watch(staffDirectoryProvider).valueOrNull ?? const <Staff>[])
        s.id: s.fullName,
    };
    return AsyncDataView(
      value: ref.watch(staffAwaitingReplyProvider),
      onRetry: () => ref.invalidate(staffAwaitingReplyProvider),
      loading: const LoadingSkeleton(height: 72),
      isEmpty: (list) => list.isEmpty,
      empty: ListCard(
        emptyIcon: Icons.mark_email_read_outlined,
        emptyText: t.noMessagesAwaiting,
        children: const [],
      ),
      builder: (context, list) => ListCard(
        children: [
          for (final m in list.take(5))
            Builder(
              builder: (context) {
                final overdue = m.isOverdueAt(DateTime.now());
                final due = m.responseDueAt!;
                final covering = m.staffId != me;
                final patient = names[m.patientId] ?? t.rolePatient;
                return ListTile(
                  leading: Icon(
                    overdue
                        ? Icons.mark_email_unread
                        : Icons.mark_email_unread_outlined,
                    color: overdue ? theme.colorScheme.error : null,
                  ),
                  title: ReadableLabel(patient),
                  subtitle: Text(
                    [
                      if (covering)
                        t.coveringFor(staff[m.staffId] ?? m.staffId),
                      overdue
                          ? t.messageReplyWasDue(
                              '${fmtDate(due)} ${fmtTime(due)}',
                            )
                          : t.replyBy('${fmtDate(due)} ${fmtTime(due)}'),
                    ].join(' · '),
                    style: overdue
                        ? theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.bodySmall,
                  ),
                  onTap: () => context.push(
                    AppRoutes.staffInboxThread(
                      m.patientId,
                      name: patient,
                      ownerId: covering ? m.staffId : null,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TodayScheduleSummary extends ConsumerStatefulWidget {
  const _TodayScheduleSummary();
  @override
  ConsumerState<_TodayScheduleSummary> createState() =>
      _TodayScheduleSummaryState();
}

class _TodayScheduleSummaryState extends ConsumerState<_TodayScheduleSummary> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? {};
    return WorkspaceSection(
      workText(context, "Today's Schedule", 'جدول اليوم'),
      action: TextButton(
        onPressed: () => context.go(AppRoutes.staffSchedule),
        child: Text(workText(context, 'Full schedule', 'الجدول الكامل')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, label) in [
                workText(context, 'Ongoing', 'الجارية'),
                workText(context, 'Upcoming', 'القادمة'),
                workText(context, 'Completed', 'المكتملة'),
              ].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: tab == i,
                  onSelected: (_) => setState(() => tab = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ref
              .watch(staffTodayProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Column(
                  children: [
                    Text('$e'),
                    TextButton(
                      onPressed: () => ref.invalidate(staffTodayProvider),
                      child: Text(workText(context, 'Retry', 'إعادة المحاولة')),
                    ),
                  ],
                ),
                data: (all) {
                  final list =
                      all
                          .where(
                            (a) => tab == 0
                                ? a.status == AppointmentStatus.inProgress
                                : tab == 1
                                ? [
                                    AppointmentStatus.booked,
                                    AppointmentStatus.confirmed,
                                  ].contains(a.status)
                                : a.status == AppointmentStatus.completed,
                          )
                          .toList()
                        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
                  return Column(
                    children: [
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            workText(
                              context,
                              'No visits in this section.',
                              'لا توجد زيارات في هذا القسم.',
                            ),
                          ),
                        ),
                      for (final a in list)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (tab == 1 &&
                                a.slotStart.isBefore(DateTime.now()))
                              Text(
                                workText(
                                  context,
                                  'Late · not started',
                                  'متأخر · لم يبدأ',
                                ),
                                style: TextStyle(
                                  color: PatientPalette.of(context).warning,
                                ),
                              ),
                            _QueueRow(
                              appointment: a,
                              patientName: names[a.patientId],
                            ),
                            Text(
                              '${fmtTime(a.slotStart)} – ${fmtTime(a.slotEnd)} · ${a.status.label(context)}',
                            ),
                          ],
                        ),
                    ],
                  );
                },
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
