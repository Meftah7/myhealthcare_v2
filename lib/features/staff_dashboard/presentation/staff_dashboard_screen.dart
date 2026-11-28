/// Staff Home. Dispatches each role to its own Home; doctors and dentists get
/// the clinical Home here, in the patient Home's style: one compact greeting,
/// the ongoing visit (or the next one) as the primary card, today's schedule
/// grouped Ongoing / Upcoming / Completed, then walk-ins, results awaiting
/// review, unread conversations, risk flags and the clinical tools.
library;

import 'dart:async';
import '../../workforce/workforce_home.dart';
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
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/data_state_view.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/paging_widgets.dart';
import '../../../core/presentation/readable_label.dart';
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
import '../../../core/ui/patient/patient_components.dart';
import '../../workforce/workforce_repository.dart';
import 'role_workspaces.dart';
import 'staff_chat_screen.dart';
import 'staff_home.dart';
import 'staff_quick_actions.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Every role gets its own Home: nurse, pharmacy, reception (and an
    // unassigned role) have their own work; doctors and dentists get this.
    if (StaffRole.parse(
          ref.watch(staffProfileProvider).valueOrNull?.jobTitle,
        ) ==
        StaffRole.nurse)
      return const NurseWorkspace();
    final workspace = roleWorkspaceFor(ref.watch(permissionsProvider));
    if (workspace != null) return workspace;
    final t = AppLocalizations.of(context)!;
    String w(String en, String ar) => workText(context, en, ar);
    final role = StaffRole.parse(
      ref.watch(staffProfileProvider).valueOrNull?.jobTitle,
    );
    final stats = workspaceStat;
    final home = ref.watch(workforceDataProvider('home')).valueOrNull;

    return StaffHomeScaffold(
      onRefresh: () async {
        ref
          ..invalidate(staffTodayProvider)
          ..invalidate(staffQueueProvider)
          ..invalidate(unacknowledgedFlagsProvider)
          ..invalidate(myResultReviewsProvider)
          ..invalidate(staffAwaitingReplyProvider)
          ..invalidate(staffTasksProvider)
          ..invalidate(departmentWalkInsProvider)
          ..invalidate(workforceDataProvider('home'))
          ..invalidate(workforceDataProvider('conversations'));
      },
      children: [
        // 1. The one primary card: the visit happening now, else the next.
        const _ClinicalWorkCard(),
        // 2. Today in four figures.
        const SizedBox(height: Space.md),
        StaffFigureGrid([
          StaffFigure(
            label: w('Visits today', 'زيارات اليوم'),
            value: '${stats(home, 'appointmentsToday') ?? '—'}',
            icon: Icons.event_note_outlined,
            onTap: () => context.go(AppRoutes.staffSchedule),
          ),
          StaffFigure(
            label: w('Completed today', 'المكتملة اليوم'),
            value: '${stats(home, 'completedToday') ?? '—'}',
            icon: Icons.task_alt,
            accent: PatientAccent.green,
          ),
          StaffFigure(
            label: w('Follow-ups', 'المتابعات'),
            value: '${stats(home, 'followUp') ?? '—'}',
            icon: Icons.event_repeat_outlined,
            accent: PatientAccent.amber,
            onTap: () => unawaited(context.push(AppRoutes.staffTasks)),
          ),
          StaffFigure(
            label: role == StaffRole.dentist
                ? w('Unsigned dental notes', 'ملاحظات أسنان غير موقعة')
                : w('Unsigned notes', 'ملاحظات غير موقعة'),
            value: '${stats(home, 'unsignedNotes') ?? '—'}',
            icon: Icons.edit_note,
            accent: PatientAccent.amber,
          ),
        ]),
        // 3. Today's schedule, grouped Ongoing / Upcoming / Completed.
        const _TodayScheduleSummary(),
        // 4. What else needs this clinician: walk-ins, results, messages.
        const _DepartmentWalkIns(),
        if (ref.watch(canProvider(Permission.reviewResults))) ...[
          SectionHeading(t.resultsToReviewHeader),
          const _ResultReviewQueue(),
        ],
        const StaffUnreadConversations(),
        SectionHeading(t.awaitingReplyHeader),
        const _AwaitingReply(),
        const PrescriptionClarifications(),
        SectionHeading(
          t.riskFlagsHeader,
          actionLabel: t.patientsAction,
          onAction: () => context.go(AppRoutes.staffPatients),
        ),
        _RiskFlags(),
        // 5. Clinical actions and role tools.
        SectionHeading(t.quickActionsHeader),
        const StaffQuickActions(),
        StaffToolsCard(staffTools(context, role)),
      ],
    );
  }
}

/// Ongoing visit (highlighted) or, failing that, the next one — with the
/// action that fits its state: Open chart while it runs, View appointment
/// before it starts.
class _ClinicalWorkCard extends ConsumerWidget {
  const _ClinicalWorkCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String w(String en, String ar) => workText(context, en, ar);
    final t = AppLocalizations.of(context)!;
    final today = ref.watch(staffTodayProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    if (today.hasError && !today.hasValue) {
      return PatientStateView(
        kind: PatientStateKind.error,
        message: w(
          "Today's schedule could not be loaded.",
          'تعذّر تحميل جدول اليوم.',
        ),
        actionLabel: w('Retry', 'إعادة المحاولة'),
        onAction: () => ref.invalidate(staffTodayProvider),
      );
    }
    if (!today.hasValue) {
      return const PatientStateView(kind: PatientStateKind.loading);
    }
    final list = [...today.requireValue]
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    final ongoing = list
        .where((a) => a.status == AppointmentStatus.inProgress)
        .firstOrNull;
    final next =
        ongoing ?? list.where((a) => _upcoming.contains(a.status)).firstOrNull;
    final late =
        next != null &&
        ongoing == null &&
        next.slotStart.isBefore(DateTime.now());
    return StaffWorkCard(
      key: const ValueKey('staff-work-card'),
      overline: ongoing != null
          ? w('Ongoing consultation', 'استشارة جارية')
          : w('Next appointment', 'الموعد التالي'),
      icon: ongoing != null
          ? Icons.play_circle_outline
          : Icons.calendar_today_outlined,
      highlight: ongoing != null,
      title: next == null
          ? null
          : names[next.patientId] ?? visitTypeLabel(next.visitType),
      lines: next == null
          ? const []
          : [
              '${fmtTime(next.slotStart)}–${fmtTime(next.slotEnd)} · ${visitTypeLabel(next.visitType)}',
              [
                if (next.roomNumber != null) t.roomNumber('${next.roomNumber}'),
                ?next.reasonText,
                if (late) w('Late · not started', 'متأخر · لم يبدأ'),
              ].join(' · '),
            ].where((s) => s.isNotEmpty).toList(),
      status: next == null ? null : appointmentStatus(context, next.status),
      primaryLabel: ongoing != null
          ? w('Open chart', 'فتح الملف')
          : w('View appointment', 'عرض الموعد'),
      onPrimary: next == null
          ? null
          : () => unawaited(
              context.push(
                ongoing != null
                    ? AppRoutes.staffConsultationChart(next.id, next.patientId)
                    : AppRoutes.staffConsultation(next.id),
              ),
            ),
      secondaryLabel: w('Full schedule', 'الجدول الكامل'),
      onSecondary: () => context.go(AppRoutes.staffSchedule),
      emptyMessage: w(
        'No more visits today. New bookings appear here.',
        'لا توجد زيارات أخرى اليوم. تظهر الحجوزات الجديدة هنا.',
      ),
    );
  }
}

const _upcoming = [
  AppointmentStatus.booked,
  AppointmentStatus.confirmed,
  AppointmentStatus.checkedIn,
];

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

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: _Section(
        title: t.departmentWalkInsHeader(list.length),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FreshnessBar(
              fetchedAt: ref.watch(departmentWalkInsFetchedAtProvider),
              onRefresh: () => ref.invalidate(departmentWalkInsProvider),
            ),
            const SizedBox(height: Space.xs),
            ListCard(
              embedded: true,
              children: [
                for (final t in list)
                  _WalkInRow(ticket: t, patientName: names[t.patientId]),
              ],
            ),
          ],
        ),
      ),
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

/// One visit in today's schedule: time, patient, visit type and status, the
/// consultation on tap, and the visit actions in a menu.
class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.appointment, required this.patientName});

  final Appointment appointment;
  final String? patientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final a = appointment;
    final ops = ref.read(staffOpsProvider);
    final done = a.status == AppointmentStatus.completed;
    final late =
        _upcoming.contains(a.status) && a.slotStart.isBefore(DateTime.now());

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
        if (!done) ...[
          PopupMenuItem(value: 'transfer', child: Text(t.transferVisitAction)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'cancel', child: Text(t.cancelVisitAction)),
          PopupMenuItem(value: 'noshow', child: Text(t.markNoShowAction)),
        ],
      ],
    );

    return StaffRow(
      leadingText: fmtTime(a.slotStart),
      emphasis: a.status == AppointmentStatus.inProgress,
      muted: done,
      title: [
        patientName ?? visitTypeLabel(a.visitType),
        if (a.riskBand == RiskBand.high)
          workText(context, 'High risk', 'خطورة عالية'),
      ].join(' · '),
      subtitle: [
        visitTypeLabel(a.visitType),
        if (a.roomNumber != null) t.roomNumber('${a.roomNumber}'),
        if (a.ticketTag != null) a.ticketTag!,
        if (late) workText(context, 'Late · not started', 'متأخر · لم يبدأ'),
      ].join(' · '),
      status: done ? null : appointmentStatus(context, a.status),
      trailing: menu,
      onTap: () => unawaited(context.push(AppRoutes.staffConsultation(a.id))),
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
            embedded: true,
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
          embedded: true,
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
        embedded: true,
        emptyIcon: Icons.mark_email_read_outlined,
        emptyText: t.noMessagesAwaiting,
        children: const [],
      ),
      builder: (context, list) => ListCard(
        embedded: true,
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
                  onTap: () => context.go(
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

/// Today's visits grouped under Ongoing, Upcoming and Completed: ongoing
/// visits carry a filled time box, completed ones quieter text.
class _TodayScheduleSummary extends ConsumerWidget {
  const _TodayScheduleSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String w(String en, String ar) => workText(context, en, ar);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? {};
    final today = ref.watch(staffTodayProvider);
    return Column(
      key: const ValueKey('staff-today-schedule'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          w("Today's schedule", 'جدول اليوم'),
          actionLabel: w('Full schedule', 'الجدول الكامل'),
          onAction: () => context.go(AppRoutes.staffSchedule),
        ),
        today.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: w(
              "Today's schedule could not be loaded.",
              'تعذّر تحميل جدول اليوم.',
            ),
            actionLabel: w('Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(staffTodayProvider),
          ),
          data: (all) {
            final sorted = [...all]
              ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
            final groups = [
              (
                w('Ongoing', 'الجارية'),
                [
                  for (final a in sorted)
                    if (a.status == AppointmentStatus.inProgress) a,
                ],
              ),
              (
                w('Upcoming', 'القادمة'),
                [
                  for (final a in sorted)
                    if (_upcoming.contains(a.status)) a,
                ],
              ),
              (
                w('Completed', 'المكتملة'),
                [
                  for (final a in sorted)
                    if (a.status == AppointmentStatus.completed) a,
                ],
              ),
            ];
            if (groups.every((g) => g.$2.isEmpty)) {
              return StaffListCard(
                emptyIcon: Icons.event_available_outlined,
                emptyMessage: w(
                  'No visits scheduled today.',
                  'لا توجد زيارات مجدولة اليوم.',
                ),
                children: const [],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (label, visits) in groups)
                  if (visits.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Space.sm,
                        bottom: Space.xs,
                      ),
                      child: Text(
                        '$label · ${visits.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: PatientPalette.of(context).textMuted,
                        ),
                      ),
                    ),
                    StaffListCard(
                      children: [
                        for (final a in visits)
                          _QueueRow(
                            appointment: a,
                            patientName: names[a.patientId],
                          ),
                      ],
                    ),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [SectionHeading(title), child],
  );
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
