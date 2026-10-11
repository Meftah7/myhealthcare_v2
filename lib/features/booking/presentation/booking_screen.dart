/// Booking wizard: department → doctor → reason → date → AI-ranked slots →
/// review & confirm (P4-13, P4-14, redesign v3).
///
/// The draft is reset on every fresh entry, so a half-finished pick from a
/// previous visit never carries over.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/patient_repository.dart';
import '../../auth/application/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/scheduling/slot_recommender.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/appointment_confirmation.dart';
import '../application/booking_providers.dart';

/// Whether the wizard skips date selection and jumps straight to the soonest
/// available day — the Appointments entry point's "Book Now" vs "Schedule".
enum BookingMode { now, schedule }

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    this.mode = BookingMode.schedule,
    this.initialDepartmentId,
    this.initialStaffId,
    this.targetPatientId,
    super.key,
  });

  final BookingMode mode;

  /// Prefilled department / doctor — set when the patient arrives from "Book
  /// again" on a doctor they have already seen (P10-04).
  final String? initialDepartmentId;
  final String? initialStaffId;

  /// Set when arriving from "Book for [name]" on a "manage" linked account —
  /// this books on that account, not the signed-in patient's own.
  final String? targetPatientId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _stage = 0;
  @override
  void initState() {
    super.initState();
    // Start from a clean slate every time the page opens — a half-finished
    // pick from a previous visit never carries over, unless the caller
    // prefilled a doctor. Deferred a frame so the provider isn't mutated
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
          departmentId: widget.initialDepartmentId,
          staffId: widget.initialStaffId,
        );
        ref.read(bookingTargetPatientIdProvider.notifier).state =
            widget.targetPatientId;
      }
    });
  }

  BookingMode get mode => widget.mode;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final draft = ref.watch(bookingDraftProvider);
    final departments = ref.watch(departmentsProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);
    final gutter = WindowSize.of(context).gutter;
    final schedule = ref.watch(clinicScheduleProvider);
    return AppScaffold(
      title: _stage == 1
          ? t.stepDateTime
          : mode == BookingMode.now
          ? t.bookNowTitle
          : t.scheduleAVisitTitle,
      leading: _stage == 0
          ? null
          : IconButton(
              icon: const BackButtonIcon(),
              tooltip: t.backButton,
              onPressed: () => setState(() => _stage = 0),
            ),
      actions: const [PatientTopActions()],
      centerBody: false,
      body: departments.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadDepartments,
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (depts) {
          // A resumed or linked intent may name a department that no longer
          // exists; keep only valid intent.
          if (draft.departmentId != null &&
              !depts.any((d) => d.id == draft.departmentId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final current = ref.read(bookingDraftProvider);
              ref
                  .read(bookingDraftProvider.notifier)
                  .state = BookingRequestDraft(
                visitType: current.visitType,
                bookedForName: current.bookedForName,
              );
            });
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                key: ValueKey(_stage),
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.md,
                  gutter,
                  Space.xxl,
                ),
                children: [
                  _StepBar(current: _stage),
                  const SizedBox(height: Space.md),
                  if (_stage == 0) ...[
                    if (widget.targetPatientId != null)
                      _BookingForLinkedAccountBanner(
                        ownerPatientId: widget.targetPatientId!,
                      )
                    else
                      const _BookingForSelector(),
                    _StepCard(
                      index: 1,
                      title: t.stepDepartment,
                      done: draft.departmentId != null,
                      child: _ChoiceWrap(
                        options: [for (final d in depts) (d.id, d.name)],
                        selectedId: draft.departmentId,
                        onSelected: (id) =>
                            notifier.state = draft.withDepartment(id),
                      ),
                    ),
                    if (draft.departmentId != null) ...[
                      const SizedBox(height: Space.md),
                      _StepCard(
                        index: 2,
                        title: t.stepDoctor,
                        done: draft.staffId != null,
                        child: _DoctorPicker(
                          departmentId: draft.departmentId!,
                          mode: mode,
                        ),
                      ),
                    ],
                    if (draft.staffId != null) ...[
                      const SizedBox(height: Space.md),
                      _StepCard(
                        index: 3,
                        title: t.stepReasonForVisit,
                        done: true,
                        child: _ChoiceWrap(
                          options: [
                            for (final type in VisitType.values)
                              (type.name, visitTypeLabel(type)),
                          ],
                          selectedId: draft.visitType.name,
                          onSelected: (name) => notifier.state = draft.copyWith(
                            visitType: VisitType.values.byName(name),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Space.lg),
                    FilledButton(
                      onPressed: draft.staffId == null
                          ? null
                          : () => setState(() => _stage = 1),
                      child: Text(t.continueButton),
                    ),
                  ] else ...[
                    _StepCard(
                      index: 2,
                      title: t.stepDateTime,
                      done: draft.date != null,
                      child: mode == BookingMode.now
                          ? _NowDateLine(date: draft.date)
                          : _DateStrip(
                              selected: draft.date,
                              schedule: schedule,
                              onPick: (d) =>
                                  notifier.state = draft.copyWith(date: d),
                            ),
                    ),
                    if (draft.staffId != null && draft.date != null) ...[
                      const SizedBox(height: Space.md),
                      _SlotList(
                        mode: mode,
                        onEditDetails: () => setState(() => _stage = 0),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who is this for?
// ---------------------------------------------------------------------------

/// Shown instead of [_BookingForSelector] when this wizard was opened from
/// "Book for [name]" on a "manage" linked account — the visit is created
/// under *their* account, not a cosmetic label on the signed-in patient's own.
class _BookingForLinkedAccountBanner extends ConsumerWidget {
  const _BookingForLinkedAccountBanner({required this.ownerPatientId});

  final String ownerPatientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final patient = ref.watch(linkedPatientProvider(ownerPatientId));
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: patient.when(
        loading: () => const LoadingSkeleton(height: 48),
        error: (e, _) => InlineBanner.error(t.noAccessToThisAccount),
        data: (p) => InlineBanner.info(t.bookedForNotice(p.fullName)),
      ),
    );
  }
}

/// A "Booking for" chooser shown above the wizard when the account holder has
/// linked family members. "Myself" clears the draft's `bookedForName`; picking
/// a member sets it, and the booking is stamped with that name.
class _BookingForSelector extends ConsumerWidget {
  const _BookingForSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members =
        ref.watch(patientFamilyMembersProvider).valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final draft = ref.watch(bookingDraftProvider);
    final selector = ref.read(bookingSubjectSelectorProvider);
    final selected = draft.bookedForName;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    t.whoIsThisFor,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                ChoiceChip(
                  label: Text(t.myself),
                  selected: selected == null,
                  onSelected: (_) => selector.selectSelf(),
                ),
                for (final m in members)
                  ChoiceChip(
                    label: Text(m.fullName),
                    selected: selected == m.fullName,
                    onSelected: (_) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final r = await selector.selectMember(m);
                      if (r case Err(:final failure)) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              describeFailure(
                                AppLocalizations.of(context)!,
                                failure,
                              ).message,
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                t.bookedForNotice(selected),
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

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});

  final int current; // clinician, time, review

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final labels = [t.stepDoctor, t.stepDateTime, t.reviewAndConfirm];
    final clamped = current.clamp(0, labels.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: Space.xxs),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= clamped
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.xs),
        Text(
          t.stepProgress(clamped + 1, labels.length, labels[clamped]),
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.done,
    required this.child,
  });

  final int index;
  final String title;
  final bool done;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: done
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                child: done
                    ? Icon(Icons.check, size: 15, color: scheme.onPrimary)
                    : Text(
                        '$index',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: ReadableLabel(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pickers
// ---------------------------------------------------------------------------

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<(String, String)> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final (id, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: id == selectedId,
            onSelected: (_) => onSelected(id),
          ),
      ],
    );
  }
}

class _DoctorPicker extends ConsumerWidget {
  const _DoctorPicker({required this.departmentId, required this.mode});
  final String departmentId;
  final BookingMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(departmentStaffProvider(departmentId));
    final draft = ref.watch(bookingDraftProvider);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return staff.when(
      loading: () => const LoadingSkeleton(height: 64),
      error: (e, _) => Text(t.couldNotLoadDoctors),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            t.noDoctorsListed,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        // A prefilled/resumed clinician must belong to this department.
        if (draft.staffId != null && !list.any((s) => s.id == draft.staffId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final current = ref.read(bookingDraftProvider);
            if (current.staffId == draft.staffId) {
              ref.read(bookingDraftProvider.notifier).state = current.copyWith(
                clearStaff: true,
                clearDate: true,
              );
            }
          });
        }
        return Column(
          children: [
            for (final s in list)
              _DoctorTile(
                staff: s,
                selected: s.id == draft.staffId,
                onTap: () async {
                  final notifier = ref.read(bookingDraftProvider.notifier);
                  if (mode == BookingMode.now) {
                    final date = await _earliestAvailableDate(ref, s.id);
                    notifier.state = draft.withStaff(s.id, date: date);
                  } else {
                    notifier.state = draft.withStaff(s.id);
                  }
                },
              ),
          ],
        );
      },
    );
  }

  static Future<DateTime?> _earliestAvailableDate(
    WidgetRef ref,
    String staffId,
  ) async {
    final repo = ref.read(appointmentRepositoryProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 14; i++) {
      final day = start.add(Duration(days: i));
      final result = await repo.openSlots(staffId, day);
      if (result case Ok(:final value) when value.isNotEmpty) return day;
    }
    return null;
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({
    required this.staff,
    required this.selected,
    required this.onTap,
  });

  final Staff staff;
  final bool selected;
  final VoidCallback onTap;

  String get _initials {
    final parts = staff.fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p[0]).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Text(
                    _initials,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicianName(staff.fullName),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : null,
                        ),
                      ),
                      if (staff.specialty != null)
                        Text(
                          staff.specialty!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowDateLine extends StatelessWidget {
  const _NowDateLine({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(Icons.bolt_outlined, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            date == null
                ? t.findingSoonestOpening
                : t.soonestOpeningAt(fmtRelativeDay(date!), fmtDate(date!)),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selected,
    required this.schedule,
    required this.onPick,
  });

  final DateTime? selected;
  final ClinicSchedule schedule;
  final ValueChanged<DateTime> onPick;

  List<DateTime> get _days {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day);
    final out = <DateTime>[];
    for (var i = 0; i < 45 && out.length < 21; i++) {
      if (isClinicDay(d, schedule)) out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
        itemBuilder: (context, i) {
          final day = _days[i];
          final isSel =
              selected != null &&
              selected!.year == day.year &&
              selected!.month == day.month &&
              selected!.day == day.day;
          return InkWell(
            onTap: () => onPick(day),
            borderRadius: Radii.chip,
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: isSel ? scheme.primary : scheme.surface,
                borderRadius: Radii.chip,
                border: Border.all(
                  color: isSel
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSel ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizeDigits('${day.day}'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSel ? scheme.onPrimary : null,
                    ),
                  ),
                  Text(
                    _month(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSel ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Locale-aware short forms (was a hardcoded English lookup table) — `intl`
  // picks these up from `Intl.defaultLocale`, which `LocaleController` keeps
  // in sync with the app's language.
  static String _weekday(DateTime d) => DateFormat.E().format(d);
  static String _month(DateTime d) => DateFormat.MMM().format(d);
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

enum _ReviewAction { confirm, changeTime, editDetails }

class _SlotList extends ConsumerWidget {
  const _SlotList({required this.mode, required this.onEditDetails});

  final BookingMode mode;
  final VoidCallback onEditDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(rankedSlotsProvider);
    final busy = ref.watch(bookingInFlightProvider);
    final t = AppLocalizations.of(context)!;

    return slots.when(
      loading: () => const LoadingSkeleton(height: 140),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadTimes,
        onRetry: () => ref.invalidate(rankedSlotsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.event_busy_outlined,
            message: t.noOpenTimesThatDay,
          );
        }
        final byTime = [...list]
          ..sort((a, b) => a.slot.start.compareTo(b.slot.start));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy) ...[
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(t.paBookingInProgress)),
                ],
              ),
              const SizedBox(height: Space.sm),
            ],
            _SuggestedTimes(
              ranked: list,
              onPick: (slot) => _review(context, ref, slot),
            ),
            SectionHeader(t.allOpenTimesSection, overline: true),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final s in byTime)
                  _TimeChip(
                    slot: s,
                    onTap: busy ? null : () => _review(context, ref, s),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    RankedSlot slot,
  ) async {
    // Never open a second review while a booking is being written.
    if (ref.read(bookingInFlightProvider)) return;
    final t = AppLocalizations.of(context)!;
    final draft = ref.read(bookingDraftProvider);
    final staff = ref
        .read(departmentStaffProvider(draft.departmentId ?? ''))
        .valueOrNull
        ?.where((s) => s.id == draft.staffId)
        .firstOrNull;
    final depts = ref.read(departmentsProvider).valueOrNull;
    final department = depts
        ?.where((d) => d.id == draft.departmentId)
        .map((d) => d.name)
        .firstOrNull;
    final facility =
        (await ref.read(departmentRepositoryProvider).facility()).valueOrNull;
    // Who the visit is for: a household member, a managed linked account,
    // or the signed-in patient.
    final targetId = ref.read(bookingTargetPatientIdProvider);
    String? patientName = draft.bookedForName;
    if (patientName == null && targetId != null) {
      patientName = (await ref.read(patientRepositoryProvider).byId(targetId))
          .valueOrNull
          ?.user
          .fullName;
    }
    patientName ??= ref.read(currentUserProvider)?.fullName;

    if (!context.mounted) return;
    final action = await showModalBottomSheet<_ReviewAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(
        slot: slot,
        patient: patientName ?? t.greetingFallbackName,
        doctor: staff == null ? null : clinicianName(staff.fullName),
        specialty: staff?.specialty,
        department: department,
        facility: facility,
        visitType: draft.visitType,
        bookedFor: draft.bookedForName,
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _ReviewAction.confirm:
        await _book(context, ref, slot);
      case _ReviewAction.editDetails:
        onEditDetails();
      case _ReviewAction.changeTime || null:
        break;
    }
  }

  Future<void> _book(BuildContext context, WidgetRef ref, RankedSlot s) async {
    final result = await ref.read(bookingControllerProvider).confirm(s);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.read(bookingDraftProvider.notifier).state =
            const BookingRequestDraft();
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show(AppLocalizations.of(context)!.appointmentBooked);
        if (!context.mounted) return;
        // Success only after the repository confirmed the insert: open the
        // real appointment, with a banner linking back to Home.
        context.go('${AppRoutes.patientAppointmentDetail(value.id)}?booked=1');
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeFailure(AppLocalizations.of(context)!, failure).message,
            ),
          ),
        );
    }
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.slot, required this.onTap});

  final RankedSlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramp = theme.clinicalStatus;
    final dot = switch (slot.band) {
      RiskBand.low => ramp.riskLow.onContainer,
      RiskBand.medium => ramp.riskMedium.onContainer,
      RiskBand.high => ramp.riskHigh.onContainer,
    };
    return ActionChip(
      onPressed: onTap,
      avatar: slot.hasRiskEstimate
          ? Icon(Icons.circle, size: 10, color: dot)
          : const Icon(Icons.schedule_outlined, size: 16),
      label: Text(fmtTime(slot.slot.start)),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.slot,
    required this.patient,
    required this.doctor,
    required this.specialty,
    required this.department,
    required this.facility,
    required this.visitType,
    this.bookedFor,
  });

  final RankedSlot slot;
  final String patient;
  final String? doctor;
  final String? specialty;
  final String? department;
  final ClinicFacility? facility;
  final VisitType visitType;
  final String? bookedFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepBar(current: 2),
            const SizedBox(height: Space.md),
            Text(t.reviewAndConfirm, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            _Row(label: t.paReviewPatient, value: patient),
            if (bookedFor != null)
              _Row(label: t.rowLabelFor, value: bookedFor!),
            if (doctor != null) _Row(label: t.stepDoctor, value: doctor!),
            if (specialty != null && specialty!.isNotEmpty)
              _Row(label: t.paReviewSpecialty, value: specialty!),
            if (department != null)
              _Row(label: t.stepDepartment, value: department!),
            if (facility != null)
              _Row(
                label: t.paReviewFacility,
                value: facility!.address == null
                    ? facility!.name
                    : '${facility!.name}\n${facility!.address}',
              ),
            _Row(
              label: t.rowLabelWhen,
              value:
                  '${fmtRelativeDay(slot.slot.start)}, '
                  '${fmtDate(slot.slot.start)} · ${fmtTime(slot.slot.start)}'
                  '–${fmtTime(slot.slot.end)}',
            ),
            _Row(
              label: t.appointmentTimeZone(slot.slot.start.timeZoneName),
              value: slot.slot.start.timeZoneOffset.toString(),
            ),
            _Row(label: t.stepReasonShort, value: visitTypeLabel(visitType)),
            _Row(label: t.paReviewVisitMode, value: t.paInClinicVisits),
            if (slot.hasRiskEstimate) ...[
              const SizedBox(height: Space.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RiskBadge(slot.band),
              ),
            ],
            const SizedBox(height: Space.lg),
            FilledButton(
              key: const ValueKey('review-confirm'),
              onPressed: () => Navigator.of(context).pop(_ReviewAction.confirm),
              child: Text(t.confirmBookingButton),
            ),
            const SizedBox(height: Space.xs),
            OutlinedButton(
              key: const ValueKey('review-change-time'),
              onPressed: () =>
                  Navigator.of(context).pop(_ReviewAction.changeTime),
              child: Text(t.paReviewChangeTime),
            ),
            TextButton(
              key: const ValueKey('review-edit-details'),
              onPressed: () =>
                  Navigator.of(context).pop(_ReviewAction.editDetails),
              child: Text(t.paReviewEditDetails),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Up to three suggested times with the reasons behind them. Suggestions
/// only: the full list of open times always follows, and any can be booked.
class _SuggestedTimes extends ConsumerWidget {
  const _SuggestedTimes({required this.ranked, required this.onPick});

  final List<RankedSlot> ranked;
  final ValueChanged<RankedSlot> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // While loading or on failure, show nothing — the open times below are
    // always enough to book.
    final recs = ref.watch(slotRecommendationsProvider).valueOrNull;
    if (recs == null || recs.isEmpty) return const SizedBox.shrink();

    String reason(SlotReason r, SlotRecommendation rec) => switch (r) {
      SlotReason.reliableHour => t.slotReasonReliable,
      SlotReason.shortWait => t.slotReasonShortWait(rec.avgWaitMinutes ?? 0),
      SlotReason.yourUsualTime => t.slotReasonYourTime,
      SlotReason.popularTime => t.slotReasonPopular,
      SlotReason.earliest => t.slotReasonEarliest,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(t.recommendedSection, overline: true),
        Text(
          t.recommendedHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.xs),
        for (final (i, rec) in recs.indexed) ...[
          Builder(
            builder: (context) {
              final slot = ranked.firstWhere(
                (r) => identical(r.slot, rec.slot),
              );
              final top = i == 0;
              final ink = top
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurface;
              return AppCard(
                color: top ? theme.colorScheme.secondaryContainer : null,
                padding: const EdgeInsets.all(Space.md),
                onTap: () => onPick(slot),
                child: Row(
                  children: [
                    Icon(
                      top ? Icons.star_rounded : Icons.schedule_rounded,
                      color: ink,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmtTime(rec.slot.start),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: ink,
                            ),
                          ),
                          Text(
                            [
                              for (final r in rec.reasons) reason(r, rec),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (slot.hasRiskEstimate) RiskBadge(slot.band),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Space.xs),
        ],
        const SizedBox(height: Space.sm),
      ],
    );
  }
}
