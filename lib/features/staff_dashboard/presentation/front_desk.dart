/// The receptionist's three working tabs:
///
/// * Home ([FrontDeskWorkspace]) — the next arrival with Check in, Book for a
///   patient and Find an appointment, today's figures, arrivals and the
///   documents awaiting an administrative copy check.
/// * Schedule ([DeskSchedule]) — any day's clinic appointments: find one,
///   view it, check in, reschedule, cancel, assign nursing intake, and book.
/// * Patients ([ReceptionPatientLookup]) — patient lookup for booking,
///   check-in and permitted document work.
///
/// Every action is re-authorized by its repository; these screens only
/// decide what to offer. Patient keys (patient_058) are never shown as names:
/// the CPR / ID appears only where identity is being checked.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../../workforce/role_navigation.dart'
    show
        DeskRescheduleSheet,
        NursingAssignmentSheet,
        deskAppointmentNamesProvider,
        deskDayAppointmentsProvider;
import '../../workforce/workforce_repository.dart';
import '../../workspace/workspace_repository.dart';
import '../../workspace/workspace_widgets.dart' show wallTime, workspaceStat;
import 'role_workspaces.dart'
    show ConfirmCopySheet, DeskBookingSheet, staffFailureText;
import 'staff_chat_screen.dart';
import 'staff_home.dart';
import 'staff_top_actions.dart';

String _t(BuildContext c, String en, String ar) => workText(c, en, ar);

/// Clinic wall-clock time (Bahrain), as on every desk screen.
String deskTime(DateTime d) => wallTime(d.millisecondsSinceEpoch ~/ 1000);

/// One of today's visits at the desk, with the names staff read.
typedef DeskArrival = ({
  Appointment visit,
  String patientName,
  String clinicianName,
});

/// Today's clinic visits that can still be checked in (or just were), with
/// patient and clinician names, earliest first.
final deskArrivalsProvider = FutureProvider.autoDispose<List<DeskArrival>>((
  ref,
) async {
  ref.watch(workspaceChangesProvider);
  final start = clinicStart(clinicDay());
  final result = await ref
      .watch(appointmentRepositoryProvider)
      .inRange(start, start.add(const Duration(days: 1)));
  final visits = switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
  final patients = ref.watch(patientRepositoryProvider);
  final users = ref.watch(userRepositoryProvider);
  final names = <String, String>{};
  final out = <DeskArrival>[];
  for (final a in visits.where(
    (a) =>
        a.status == AppointmentStatus.booked ||
        a.status == AppointmentStatus.confirmed ||
        a.status == AppointmentStatus.checkedIn,
  )) {
    names[a.patientId] ??=
        (await patients.byId(a.patientId)).valueOrNull?.user.fullName ?? '';
    names[a.staffId] ??= clinicianName(
      (await users.staffById(a.staffId)).valueOrNull?.fullName ?? '',
    );
    out.add((
      visit: a,
      patientName: names[a.patientId]!,
      clinicianName: names[a.staffId]!,
    ));
  }
  out.sort((a, b) => a.visit.slotStart.compareTo(b.visit.slotStart));
  return out;
});

/// Set by Home's "Find an appointment" so the Schedule opens on its search.
final deskFindRequestProvider = StateProvider<int>((ref) => 0);

/// Whether reception may record this visit's arrival now.
bool canCheckIn(Appointment a) =>
    a.checkedInAt == null &&
    (a.status == AppointmentStatus.booked ||
        a.status == AppointmentStatus.confirmed);

/// Records an arrival after the identity check at the desk, then refreshes
/// every desk view of today.
Future<void> deskCheckIn(
  BuildContext context,
  WidgetRef ref,
  Appointment a,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = _t(context, 'Arrival checked in.', 'تم تسجيل الوصول.');
  final r = await ref
      .read(appointmentRepositoryProvider)
      .deskCheckIn(a.id, at: DateTime.now(), expectedVersion: a.version);
  ref
    ..invalidate(deskArrivalsProvider)
    ..invalidate(deskDayAppointmentsProvider)
    ..invalidate(workforceDataProvider('home'));
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (r) {
        Ok() => done,
        Err(:final failure) => failure.message,
      }),
    ),
  );
}

/// Opens the book-for-a-patient flow: find → confirm patient → service or
/// clinician → an open time → review and confirm. [patient] skips the find.
Future<void> showDeskBookingFlow(BuildContext context, {Patient? patient}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DeskBookForPatientSheet(patient: patient),
    );

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class FrontDeskWorkspace extends ConsumerWidget {
  const FrontDeskWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final arrivals = ref.watch(deskArrivalsProvider);
    final home = ref.watch(workforceDataProvider('home')).valueOrNull;
    final pendingCopies = workspaceStat(home, 'pendingCopies');
    return StaffHomeScaffold(
      onRefresh: () async {
        ref
          ..invalidate(deskArrivalsProvider)
          ..invalidate(workforceDataProvider('home'))
          ..invalidate(workforceDataProvider('conversations'));
      },
      children: [
        // 1. The one primary card: who arrives next.
        const _NextArrivalCard(),
        // 2. The two desk actions that are not tabs.
        StaffActionPair(
          actions: [
            (
              key: const ValueKey('desk-book'),
              label: t('Book for a patient', 'احجز لمريض'),
              icon: Icons.event_available_outlined,
              onPressed: () => unawaited(showDeskBookingFlow(context)),
            ),
            (
              key: const ValueKey('desk-find'),
              label: t('Find an appointment', 'ابحث عن موعد'),
              icon: Icons.manage_search,
              onPressed: () {
                ref.read(workspaceDayProvider.notifier).state = clinicDay();
                ref.read(deskFindRequestProvider.notifier).state++;
                context.go(AppRoutes.staffSchedule);
              },
            ),
          ],
        ),
        // 3. Today in four figures.
        const SizedBox(height: Space.md),
        StaffFigureGrid([
          StaffFigure(
            label: t('Arrivals today', 'وصول اليوم'),
            value: '${workspaceStat(home, 'appointmentsToday') ?? '—'}',
            icon: Icons.event_note_outlined,
            onTap: () => context.go(AppRoutes.staffSchedule),
          ),
          StaffFigure(
            label: t('Checked in', 'تم تسجيل الوصول'),
            value: '${workspaceStat(home, 'checkedIn') ?? '—'}',
            icon: Icons.how_to_reg_outlined,
            accent: PatientAccent.green,
          ),
          StaffFigure(
            label: t('Waiting to arrive', 'بانتظار الوصول'),
            value: '${workspaceStat(home, 'waiting') ?? '—'}',
            icon: Icons.hourglass_bottom,
            accent: PatientAccent.amber,
          ),
          StaffFigure(
            label: t('Documents to confirm', 'مستندات للتأكيد'),
            value: '${pendingCopies ?? '—'}',
            icon: Icons.verified_outlined,
            onTap: () => unawaited(_openConfirmCopy(context)),
          ),
        ]),
        // 4. Arrivals still to check in.
        SectionHeading(
          t('Arrivals', 'الوصول'),
          subtitle: t(
            'Check in only after confirming identity at the desk.',
            'سجّل الوصول فقط بعد التحقق من الهوية في الاستقبال.',
          ),
          actionLabel: t('View arrivals', 'عرض الوصول'),
          onAction: () {
            ref.read(workspaceDayProvider.notifier).state = clinicDay();
            context.go(AppRoutes.staffSchedule);
          },
        ),
        arrivals.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: staffFailureText(e),
            actionLabel: t('Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(deskArrivalsProvider),
          ),
          data: (list) => StaffListCard(
            emptyIcon: Icons.event_available_outlined,
            emptyMessage: t(
              'No more visits to check in today.',
              'لا توجد زيارات أخرى لتسجيل وصولها اليوم.',
            ),
            children: [for (final a in list.take(6)) _ArrivalRow(arrival: a)],
          ),
        ),
        // 5. Documents awaiting the desk's administrative copy check.
        SectionHeading(
          t('Documents awaiting confirmation', 'مستندات بانتظار التأكيد'),
        ),
        SurfaceCard(
          key: const ValueKey('desk-confirm-copy'),
          onTap: () => unawaited(_openConfirmCopy(context)),
          child: Row(
            children: [
              const IconTile(icon: Icons.verified_outlined),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReadableLabel(
                      t('Confirm issued copy', 'تأكيد نسخة صادرة'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ReadableLabel(
                      pendingCopies == null
                          ? t(
                              'Administrative check of an issued document. Not a clinical signature.',
                              'تحقق إداري من مستند صادر. ليس توقيعًا سريريًا.',
                            )
                          : t(
                              '$pendingCopies issued copies not yet confirmed. Not a clinical signature.',
                              '$pendingCopies نسخ صادرة لم تُؤكد بعد. ليس توقيعًا سريريًا.',
                            ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PatientPalette.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        // 6. Conversations, then the tools that used to live under My work.
        const StaffUnreadConversations(),
        StaffToolsCard(staffTools(context, StaffRole.receptionist)),
      ],
    );
  }
}

Future<void> _openConfirmCopy(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ConfirmCopySheet(),
    );

class _NextArrivalCard extends ConsumerStatefulWidget {
  const _NextArrivalCard();

  @override
  ConsumerState<_NextArrivalCard> createState() => _NextArrivalCardState();
}

class _NextArrivalCardState extends ConsumerState<_NextArrivalCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    final arrivals = ref.watch(deskArrivalsProvider);
    if (arrivals.hasError && !arrivals.hasValue) {
      return PatientStateView(
        kind: PatientStateKind.error,
        message: staffFailureText(arrivals.error!),
        actionLabel: t('Retry', 'إعادة المحاولة'),
        onAction: () => ref.invalidate(deskArrivalsProvider),
      );
    }
    if (!arrivals.hasValue) {
      return const PatientStateView(kind: PatientStateKind.loading);
    }
    final next = arrivals.requireValue
        .where((a) => canCheckIn(a.visit))
        .firstOrNull;
    void viewArrivals() {
      ref.read(workspaceDayProvider.notifier).state = clinicDay();
      context.go(AppRoutes.staffSchedule);
    }

    return StaffWorkCard(
      key: const ValueKey('staff-work-card'),
      overline: t('Next arrival', 'الوصول التالي'),
      icon: Icons.how_to_reg_outlined,
      title: next?.patientName,
      lines: next == null
          ? const []
          : [
              '${deskTime(next.visit.slotStart)} · ${next.clinicianName}',
              [
                visitTypeLabel(next.visit.visitType),
                ?next.visit.ticketTag,
              ].join(' · '),
            ],
      status: next == null
          ? null
          : StaffStatus(
              t('Not arrived yet', 'لم يصل بعد'),
              accent: PatientAccent.amber,
              icon: Icons.schedule,
            ),
      primaryLabel: t('Check in', 'تسجيل الوصول'),
      busy: _busy,
      onPrimary: next == null
          ? null
          : () async {
              setState(() => _busy = true);
              await deskCheckIn(context, ref, next.visit);
              if (mounted) setState(() => _busy = false);
            },
      secondaryLabel: t('View arrivals', 'عرض الوصول'),
      onSecondary: viewArrivals,
      emptyMessage: t(
        'Everyone booked for today has arrived.',
        'وصل جميع المحجوزين لهذا اليوم.',
      ),
    );
  }
}

class _ArrivalRow extends ConsumerStatefulWidget {
  const _ArrivalRow({required this.arrival});

  final DeskArrival arrival;

  @override
  ConsumerState<_ArrivalRow> createState() => _ArrivalRowState();
}

class _ArrivalRowState extends ConsumerState<_ArrivalRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.arrival;
    return StaffRow(
      leadingText: deskTime(a.visit.slotStart),
      title: a.patientName,
      subtitle: [
        a.clinicianName,
        visitTypeLabel(a.visit.visitType),
      ].where((s) => s.isNotEmpty).join(' · '),
      status: canCheckIn(a.visit)
          ? null
          : StaffStatus(
              _t(context, 'Arrived', 'وصل'),
              accent: PatientAccent.green,
              icon: Icons.check,
            ),
      trailing: canCheckIn(a.visit)
          ? OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await deskCheckIn(context, ref, a.visit);
                      if (mounted) setState(() => _busy = false);
                    },
              child: Text(_t(context, 'Check in', 'تسجيل الوصول')),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------

/// Any day's clinic appointments for the desk. Opens on today; the day,
/// search and scroll survive tab switches.
class DeskSchedule extends ConsumerStatefulWidget {
  const DeskSchedule({super.key});

  @override
  ConsumerState<DeskSchedule> createState() => _DeskScheduleState();
}

class _DeskScheduleState extends ConsumerState<DeskSchedule> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  int _handledFind = 0;

  @override
  void initState() {
    super.initState();
    _handledFind = ref.read(deskFindRequestProvider);
    // A first visit straight from "Find an appointment" focuses the search.
    if (_handledFind > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setDay(DateTime day) =>
      ref.read(workspaceDayProvider.notifier).state = day;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    ref.listen(deskFindRequestProvider, (_, next) {
      if (next != _handledFind) {
        _handledFind = next;
        _focus.requestFocus();
      }
    });
    final day = ref.watch(workspaceDayProvider);
    final today = clinicDay();
    final isToday = day == today;
    final names =
        ref.watch(deskAppointmentNamesProvider).valueOrNull ??
        const <String, String>{};
    final q = _query.text.trim().toLowerCase();
    return AppScaffold(
      title: t('Schedule', 'الجدول'),
      actions: const [StaffTopActions()],
      onRefresh: () async {
        ref
          ..invalidate(deskDayAppointmentsProvider)
          ..invalidate(deskAppointmentNamesProvider);
      },
      children: [
        PrimaryActionButton(
          key: const ValueKey('desk-schedule-book'),
          label: t('Book for a patient', 'احجز لمريض'),
          icon: Icons.event_available_outlined,
          onPressed: () => unawaited(showDeskBookingFlow(context)),
        ),
        const SizedBox(height: Space.md),
        _DayBar(
          day: day,
          isToday: isToday,
          onDay: _setDay,
          onToday: () => _setDay(today),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          key: const ValueKey('desk-find'),
          controller: _query,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.manage_search),
            labelText: t(
              'Find an appointment: patient, clinician or reference',
              'ابحث عن موعد: المريض أو الطبيب أو المرجع',
            ),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: t('Clear search', 'مسح البحث'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_query.clear),
                  ),
          ),
        ),
        const SizedBox(height: Space.sm),
        ref
            .watch(deskDayAppointmentsProvider)
            .when(
              loading: () =>
                  const PatientStateView(kind: PatientStateKind.loading),
              error: (e, _) => PatientStateView(
                kind: PatientStateKind.error,
                message: staffFailureText(e),
                actionLabel: t('Retry', 'إعادة المحاولة'),
                onAction: () => ref.invalidate(deskDayAppointmentsProvider),
              ),
              data: (visits) {
                final sorted = [...visits]
                  ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
                final shown = [
                  for (final v in sorted)
                    if (q.isEmpty ||
                        (names[v.patientId] ?? '').toLowerCase().contains(q) ||
                        (names[v.staffId] ?? '').toLowerCase().contains(q) ||
                        v.id.toLowerCase().contains(q) ||
                        (v.ticketTag ?? '').toLowerCase().contains(q))
                      v,
                ];
                return StaffListCard(
                  emptyIcon: Icons.event_busy_outlined,
                  emptyMessage: visits.isEmpty
                      ? t(
                          'No clinic appointments on this day.',
                          'لا توجد مواعيد في العيادة في هذا اليوم.',
                        )
                      : t(
                          'No appointment matches. Try the patient’s full name or another day.',
                          'لا يوجد موعد مطابق. جرّب الاسم الكامل أو يوماً آخر.',
                        ),
                  children: [
                    for (final v in shown)
                      _DeskVisitRow(
                        visit: v,
                        patientName: names[v.patientId],
                        clinician: names[v.staffId],
                      ),
                  ],
                );
              },
            ),
      ],
    );
  }
}

/// ‹ date › with a Today shortcut once you have moved off today.
class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.isToday,
    required this.onDay,
    required this.onToday,
  });

  final DateTime day;
  final bool isToday;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    final label = isToday
        ? '${t('Today', 'اليوم')} · ${fmtDate(day)}'
        : fmtDate(day);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: t('Previous day', 'اليوم السابق'),
            onPressed: () => onDay(day.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton.icon(
            key: const ValueKey('desk-day'),
            icon: const Icon(Icons.event_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                onDay(DateTime.utc(picked.year, picked.month, picked.day));
              }
            },
            label: ReadableLabel(label),
          ),
          if (!isToday)
            TextButton(
              key: const ValueKey('desk-today'),
              onPressed: onToday,
              child: Text(t('Today', 'اليوم')),
            ),
          IconButton(
            tooltip: t('Next day', 'اليوم التالي'),
            onPressed: () => onDay(day.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _DeskVisitRow extends ConsumerStatefulWidget {
  const _DeskVisitRow({
    required this.visit,
    required this.patientName,
    required this.clinician,
  });

  final Appointment visit;
  final String? patientName;
  final String? clinician;

  @override
  ConsumerState<_DeskVisitRow> createState() => _DeskVisitRowState();
}

class _DeskVisitRowState extends ConsumerState<_DeskVisitRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final closed = const [
      AppointmentStatus.completed,
      AppointmentStatus.cancelled,
      AppointmentStatus.noShow,
    ].contains(v.status);
    return StaffRow(
      key: ValueKey('desk-visit-${v.id}'),
      leadingText: deskTime(v.slotStart),
      muted: closed,
      title: widget.patientName ?? _t(context, 'Patient', 'مريض'),
      subtitle: [
        visitTypeLabel(v.visitType),
        if (widget.clinician != null) clinicianName(widget.clinician!),
      ].join(' · '),
      status: appointmentStatus(context, v.status),
      trailing: canCheckIn(v)
          ? OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await deskCheckIn(context, ref, v);
                      if (mounted) setState(() => _busy = false);
                    },
              child: Text(_t(context, 'Check in', 'تسجيل الوصول')),
            )
          : null,
      onTap: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => DeskAppointmentSheet(
            visit: v,
            patientName: widget.patientName,
            clinician: widget.clinician,
          ),
        ),
      ),
    );
  }
}

/// One appointment's details and the desk actions its state allows.
class DeskAppointmentSheet extends ConsumerWidget {
  const DeskAppointmentSheet({
    required this.visit,
    this.patientName,
    this.clinician,
    super.key,
  });

  final Appointment visit;
  final String? patientName;
  final String? clinician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final v = visit;
    final open = !const [
      AppointmentStatus.completed,
      AppointmentStatus.cancelled,
      AppointmentStatus.noShow,
    ].contains(v.status);
    final cancellable = const [
      AppointmentStatus.booked,
      AppointmentStatus.confirmed,
      AppointmentStatus.checkedIn,
    ].contains(v.status);
    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          ReadableLabel(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
    void sheet(Widget child) {
      Navigator.of(context).pop();
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadableLabel(
              patientName ?? t('Patient', 'مريض'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Space.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: appointmentStatus(context, v.status).badge(),
            ),
            const SizedBox(height: Space.md),
            // The CPR / ID is shown here because identity is checked here.
            FutureBuilder<Result<Patient>>(
              future: ref.read(patientRepositoryProvider).byId(v.patientId),
              builder: (context, snap) {
                final id = snap.data?.valueOrNull?.user.nationalId;
                return id == null
                    ? const SizedBox.shrink()
                    : fact(t('CPR / ID', 'الرقم الشخصي'), id);
              },
            ),
            fact(
              t('Time', 'الوقت'),
              '${fmtDate(v.slotStart)} · ${deskTime(v.slotStart)}–${deskTime(v.slotEnd)}',
            ),
            if (clinician != null)
              fact(t('Clinician', 'الطبيب'), clinicianName(clinician!)),
            fact(t('Visit type', 'نوع الزيارة'), visitTypeLabel(v.visitType)),
            if ((v.reasonText ?? '').isNotEmpty)
              fact(t('Reason', 'السبب'), v.reasonText!),
            fact(t('Reference', 'المرجع'), [?v.ticketTag, v.id].join(' · ')),
            const SizedBox(height: Space.sm),
            if (canCheckIn(v)) ...[
              PrimaryActionButton(
                label: t('Check in', 'تسجيل الوصول'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await deskCheckIn(context, ref, v);
                },
              ),
              const SizedBox(height: Space.xs),
            ],
            if (open) ...[
              SoftActionButton(
                label: t('Reschedule', 'تغيير الموعد'),
                icon: Icons.edit_calendar_outlined,
                onPressed: () => sheet(DeskRescheduleSheet(visit: v)),
              ),
              const SizedBox(height: Space.xs),
              SoftActionButton(
                label: t('Assign nurse intake', 'إسناد تقييم تمريضي'),
                icon: Icons.monitor_heart_outlined,
                onPressed: () => sheet(NursingAssignmentSheet(visit: v)),
              ),
            ],
            if (cancellable)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: palette.danger),
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (dc) => AlertDialog(
                        title: Text(
                          t('Cancel this appointment?', 'إلغاء هذا الموعد؟'),
                        ),
                        content: ReadableLabel(
                          '${patientName ?? ''}\n${fmtDate(v.slotStart)} ${deskTime(v.slotStart)}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dc, false),
                            child: Text(
                              t('Keep appointment', 'الاحتفاظ بالموعد'),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dc, true),
                            child: Text(
                              t('Cancel appointment', 'إلغاء الموعد'),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (yes != true || !context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    final r = await ref
                        .read(appointmentRepositoryProvider)
                        .cancel(
                          v.id,
                          patientId: v.patientId,
                          expectedVersion: v.version,
                        );
                    ref
                      ..invalidate(deskDayAppointmentsProvider)
                      ..invalidate(deskArrivalsProvider);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(switch (r) {
                          Ok() => t(
                            'Appointment cancelled.',
                            'تم إلغاء الموعد.',
                          ),
                          Err(:final failure) => failure.message,
                        }),
                      ),
                    );
                  },
                  child: Text(t('Cancel appointment', 'إلغاء الموعد')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book for a patient
// ---------------------------------------------------------------------------

/// Find the patient by name or CPR → confirm it is the right person → the
/// booking sheet (service / clinician → open time → review → confirm).
class DeskBookForPatientSheet extends ConsumerStatefulWidget {
  const DeskBookForPatientSheet({this.patient, super.key});

  final Patient? patient;

  @override
  ConsumerState<DeskBookForPatientSheet> createState() =>
      _DeskBookForPatientState();
}

class _DeskBookForPatientState extends ConsumerState<DeskBookForPatientSheet> {
  late Patient? _candidate = widget.patient;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    final candidate = _candidate;
    if (candidate != null && _confirmed) {
      return DeskBookingSheet(patient: candidate, identityConfirmed: true);
    }
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('Book for a patient', 'احجز لمريض'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              candidate == null
                  ? t(
                      'Step 1 of 3 · Find the patient',
                      'الخطوة ١ من ٣ · ابحث عن المريض',
                    )
                  : t(
                      'Step 2 of 3 · Confirm the patient',
                      'الخطوة ٢ من ٣ · أكّد المريض',
                    ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PatientPalette.of(context).textMuted,
              ),
            ),
            const SizedBox(height: Space.md),
            if (candidate == null)
              DeskPatientSearch(
                actionLabel: t('Select', 'اختيار'),
                onPatient: (p) => setState(() => _candidate = p),
              )
            else ...[
              _PatientIdentityCard(patient: candidate),
              const SizedBox(height: Space.md),
              PrimaryActionButton(
                key: const ValueKey('desk-confirm-patient'),
                label: t('This is the right patient', 'هذا هو المريض الصحيح'),
                onPressed: () => setState(() => _confirmed = true),
              ),
              const SizedBox(height: Space.xs),
              TextButton(
                onPressed: () => setState(() => _candidate = null),
                child: Text(t('Choose another patient', 'اختر مريضاً آخر')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatientIdentityCard extends StatelessWidget {
  const _PatientIdentityCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    final u = patient.user;
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(icon: Icons.badge_outlined),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReadableLabel(
                  u.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (u.nationalId != null)
                  ReadableLabel(
                    '${t('CPR / ID', 'الرقم الشخصي')}: ${u.nationalId}',
                  ),
                if (u.dob != null)
                  ReadableLabel(
                    '${t('Date of birth', 'تاريخ الميلاد')}: ${fmtDate(u.dob!)}',
                  ),
                if (u.phone != null)
                  ReadableLabel('${t('Phone', 'الهاتف')}: ${u.phone}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Search by CPR / ID, name or phone (three characters or more), then act on
/// a result. Shared by the booking flow and the Patients lookup.
class DeskPatientSearch extends ConsumerStatefulWidget {
  const DeskPatientSearch({
    required this.onPatient,
    required this.actionLabel,
    this.extraActions,
    super.key,
  });

  final ValueChanged<Patient> onPatient;
  final String actionLabel;

  /// Further actions beside the main one on each result.
  final List<Widget> Function(Patient)? extraActions;

  @override
  ConsumerState<DeskPatientSearch> createState() => _DeskPatientSearchState();
}

class _DeskPatientSearchState extends ConsumerState<DeskPatientSearch> {
  final _query = TextEditingController();
  Future<Result<List<Patient>>>? _search;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _run() {
    final q = _query.text.trim();
    if (q.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              'Enter at least 3 characters of the CPR / ID, name or phone.',
              'أدخل ٣ أحرف على الأقل من الرقم الشخصي أو الاسم أو الهاتف.',
            ),
          ),
        ),
      );
      return;
    }
    // Start the search outside setState: its closure must not return a Future.
    final search = ref.read(patientRepositoryProvider).search(q);
    setState(() {
      _search = search;
    });
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String ar) => _t(context, en, ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('desk-search'),
          controller: _query,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          decoration: InputDecoration(
            labelText: t(
              'CPR / ID, name or phone',
              'الرقم الشخصي أو الاسم أو الهاتف',
            ),
            suffixIcon: IconButton(
              tooltip: t('Search', 'بحث'),
              icon: const Icon(Icons.search),
              onPressed: _run,
            ),
          ),
        ),
        if (_search != null)
          FutureBuilder<Result<List<Patient>>>(
            future: _search,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const PatientStateView(kind: PatientStateKind.loading);
              }
              return switch (snap.data!) {
                Err(:final failure) => PatientStateView(
                  kind: PatientStateKind.error,
                  message: failure.message,
                  actionLabel: t('Retry', 'إعادة المحاولة'),
                  onAction: _run,
                ),
                Ok(:final value) when value.isEmpty => PatientStateView(
                  kind: PatientStateKind.empty,
                  message: t(
                    'No patient matches. Check the number or try the full name.',
                    'لا يوجد مريض مطابق. تحقق من الرقم أو جرّب الاسم الكامل.',
                  ),
                ),
                Ok(:final value) => Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: StaffListCard(
                    children: [
                      for (final p in value)
                        StaffRow(
                          key: ValueKey('desk-result-${p.id}'),
                          leadingIcon: Icons.person_outline,
                          title: p.user.fullName,
                          subtitle: [
                            if (p.user.nationalId != null)
                              '${t('CPR', 'الرقم الشخصي')} ${p.user.nationalId}',
                            if (p.user.dob != null) fmtDate(p.user.dob!),
                          ].join(' · '),
                          trailing: Wrap(
                            spacing: Space.xs,
                            runSpacing: Space.xs,
                            children: [
                              ...?widget.extraActions?.call(p),
                              FilledButton(
                                onPressed: () => widget.onPatient(p),
                                child: Text(widget.actionLabel),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              };
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Patients
// ---------------------------------------------------------------------------

/// Reception's Patients tab: find a patient for booking, check-in and the
/// permitted document work. No clinical chart access.
class ReceptionPatientLookup extends ConsumerWidget {
  const ReceptionPatientLookup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String ar) => _t(context, en, ar);
    final arrivals = ref.watch(deskArrivalsProvider).valueOrNull ?? const [];
    return AppScaffold(
      title: t('Patients', 'المرضى'),
      actions: const [StaffTopActions()],
      children: [
        Text(
          t(
            'Find a patient to book a visit or check in today’s arrival. Clinical records are not available to reception.',
            'ابحث عن مريض لحجز زيارة أو تسجيل وصول اليوم. السجلات السريرية غير متاحة للاستقبال.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: PatientPalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: Space.md),
        DeskPatientSearch(
          actionLabel: t('Book', 'احجز'),
          onPatient: (p) => unawaited(showDeskBookingFlow(context, patient: p)),
          extraActions: (p) => [
            for (final a in arrivals)
              if (a.visit.patientId == p.id && canCheckIn(a.visit))
                OutlinedButton(
                  key: ValueKey('lookup-checkin-${a.visit.id}'),
                  onPressed: () =>
                      unawaited(deskCheckIn(context, ref, a.visit)),
                  child: Text(
                    '${t('Check in', 'تسجيل الوصول')} ${deskTime(a.visit.slotStart)}',
                  ),
                ),
          ],
        ),
        SectionHeading(t('Documents', 'المستندات')),
        SurfaceCard(
          onTap: () => unawaited(_openConfirmCopy(context)),
          child: Row(
            children: [
              const IconTile(icon: Icons.verified_outlined),
              const SizedBox(width: Space.sm),
              Expanded(
                child: ReadableLabel(
                  t(
                    'Confirm issued copy — administrative check, not a clinical signature.',
                    'تأكيد نسخة صادرة — تحقق إداري، ليس توقيعًا سريريًا.',
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}
