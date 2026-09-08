/// Booking wizard: department → doctor → reason → date → AI-ranked slots →
/// review & confirm (P4-13, P4-14, redesign v3).
///
/// The draft is reset on every fresh entry, so a half-finished pick from a
/// previous visit never carries over.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
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
    super.key,
  });

  final BookingMode mode;

  /// Prefilled department / doctor — set when the patient arrives from "Book
  /// again" on a doctor they have already seen (P10-04).
  final String? initialDepartmentId;
  final String? initialStaffId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
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
      }
    });
  }

  BookingMode get mode => widget.mode;

  int _stepFor(BookingRequestDraft d) {
    if (d.departmentId == null) return 0;
    if (d.staffId == null) return 1;
    if (d.date == null) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final departments = ref.watch(departmentsProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: Text(mode == BookingMode.now ? 'Book now' : 'Schedule a visit'),
        actions: const [PatientTopActions()],
      ),
      body: departments.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load departments.',
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (depts) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                Space.md,
                gutter,
                Space.xxl,
              ),
              children: [
                const _BookingForSelector(),
                _StepBar(current: _stepFor(draft)),
                const SizedBox(height: Space.lg),

                _StepCard(
                  index: 1,
                  title: 'Department',
                  done: draft.departmentId != null,
                  child: _ChoiceWrap(
                    options: [for (final d in depts) (d.id, d.name)],
                    selectedId: draft.departmentId,
                    onSelected: (id) => notifier.state = BookingRequestDraft(
                      departmentId: id,
                      visitType: draft.visitType,
                      bookedForName: draft.bookedForName,
                    ),
                  ),
                ),

                if (draft.departmentId != null) ...[
                  const SizedBox(height: Space.sm),
                  _StepCard(
                    index: 2,
                    title: 'Doctor',
                    done: draft.staffId != null,
                    child: _DoctorPicker(
                      departmentId: draft.departmentId!,
                      mode: mode,
                    ),
                  ),
                ],

                if (draft.staffId != null) ...[
                  const SizedBox(height: Space.sm),
                  _StepCard(
                    index: 3,
                    title: 'Reason for visit',
                    done: true,
                    child: _ChoiceWrap(
                      options: [
                        for (final t in VisitType.values)
                          (t.name, visitTypeLabel(t)),
                      ],
                      selectedId: draft.visitType.name,
                      onSelected: (name) => notifier.state = draft.copyWith(
                        visitType: VisitType.values.byName(name),
                      ),
                    ),
                  ),
                ],

                if (draft.staffId != null) ...[
                  const SizedBox(height: Space.sm),
                  _StepCard(
                    index: 4,
                    title: 'Date & time',
                    done: draft.date != null,
                    child: mode == BookingMode.now
                        ? _NowDateLine(date: draft.date)
                        : _DateStrip(
                            selected: draft.date,
                            onPick: (d) =>
                                notifier.state = draft.copyWith(date: d),
                          ),
                  ),
                ],

                if (draft.staffId != null && draft.date != null) ...[
                  const SizedBox(height: Space.md),
                  _SlotList(mode: mode),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who is this for?
// ---------------------------------------------------------------------------

/// A "Booking for" chooser shown above the wizard when the account holder has
/// linked family members. "Myself" clears the draft's `bookedForName`; picking
/// a member sets it, and the booking is stamped with that name.
class _BookingForSelector extends ConsumerWidget {
  const _BookingForSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(patientFamilyMembersProvider).valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final draft = ref.watch(bookingDraftProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);
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
                Text('Who is this for?', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                ChoiceChip(
                  label: const Text('Myself'),
                  selected: selected == null,
                  onSelected: (_) =>
                      notifier.state = draft.copyWith(bookedForName: null),
                ),
                for (final m in members)
                  ChoiceChip(
                    label: Text(m.fullName),
                    selected: selected == m.fullName,
                    onSelected: (_) => notifier.state =
                        draft.copyWith(bookedForName: m.fullName),
                  ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                'This visit will be booked for $selected.',
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

  final int current; // 0..3

  static const _labels = ['Department', 'Doctor', 'Reason', 'Date & time'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clamped = current.clamp(0, _labels.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
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
          'Step ${clamped + 1} of ${_labels.length} · ${_labels[clamped]}',
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
              Text(title, style: theme.textTheme.titleMedium),
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

    return staff.when(
      loading: () => const LoadingSkeleton(height: 64),
      error: (e, _) => const Text('Could not load doctors'),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'No doctors listed for this department yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
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
                    notifier.state = draft.copyWith(staffId: s.id, date: date);
                  } else {
                    notifier.state = draft.copyWith(staffId: s.id);
                  }
                },
              ),
          ],
        );
      },
    );
  }

  static Future<DateTime> _earliestAvailableDate(
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
    return start;
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
                        'Dr ${staff.fullName}',
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
    return Row(
      children: [
        Icon(
          Icons.bolt_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            date == null
                ? 'Finding the soonest opening…'
                : 'Soonest opening: ${fmtRelativeDay(date!)}, ${fmtDate(date!)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onPick});

  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  List<DateTime> get _days {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day);
    final out = <DateTime>[];
    for (var i = 0; i < 45 && out.length < 21; i++) {
      if (isClinicDay(d)) out.add(d);
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
          final isSel = selected != null &&
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
                      color: isSel
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSel ? scheme.onPrimary : null,
                    ),
                  ),
                  Text(
                    _month(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSel
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
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

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _weekday(DateTime d) => _wd[d.weekday - 1];
  static String _month(DateTime d) => _mo[d.month - 1];
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

class _SlotList extends ConsumerWidget {
  const _SlotList({required this.mode});

  final BookingMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(rankedSlotsProvider);
    final theme = Theme.of(context);

    return slots.when(
      loading: () => const LoadingSkeleton(height: 140),
      error: (e, _) => ErrorStateView(
        message: 'Could not load times.',
        onRetry: () => ref.invalidate(rankedSlotsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            message: 'No open times that day. Try another date.',
          );
        }
        final best = list.first;
        final byTime = [...list]
          ..sort((a, b) => a.slot.start.compareTo(b.slot.start));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Recommended', overline: true),
            AppCard(
              color: theme.colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(Space.md),
              onTap: () => _review(context, ref, best),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fmtTime(best.slot.start),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          best.reason,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RiskBadge(best.band),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            const SectionHeader('All open times', overline: true),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final s in byTime)
                  _TimeChip(
                    slot: s,
                    onTap: () => _review(context, ref, s),
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
    final draft = ref.read(bookingDraftProvider);
    final staff = ref
        .read(departmentStaffProvider(draft.departmentId ?? ''))
        .valueOrNull;
    final doctor = staff
        ?.where((s) => s.id == draft.staffId)
        .map((s) => 'Dr ${s.fullName}')
        .firstOrNull;
    final depts = ref.read(departmentsProvider).valueOrNull;
    final department = depts
        ?.where((d) => d.id == draft.departmentId)
        .map((d) => d.name)
        .firstOrNull;

    if (!context.mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(
        slot: slot,
        doctor: doctor,
        department: department,
        visitType: draft.visitType,
        bookedFor: draft.bookedForName,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _book(context, ref, slot);
  }

  Future<void> _book(BuildContext context, WidgetRef ref, RankedSlot s) async {
    final result = await ref.read(bookingControllerProvider).confirm(s);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.read(bookingDraftProvider.notifier).state =
            const BookingRequestDraft();
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show('Appointment booked');
        if (!context.mounted) return;
        context.go(AppRoutes.patientHome);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.slot, required this.onTap});

  final RankedSlot slot;
  final VoidCallback onTap;

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
      avatar: Icon(Icons.circle, size: 10, color: dot),
      label: Text(fmtTime(slot.slot.start)),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.slot,
    required this.doctor,
    required this.department,
    required this.visitType,
    this.bookedFor,
  });

  final RankedSlot slot;
  final String? doctor;
  final String? department;
  final VisitType visitType;
  final String? bookedFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review & confirm', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            if (bookedFor != null) _Row(label: 'For', value: bookedFor!),
            _Row(label: 'When', value:
                '${fmtRelativeDay(slot.slot.start)}, '
                '${fmtDate(slot.slot.start)} · ${fmtTime(slot.slot.start)}'),
            if (department != null) _Row(label: 'Department', value: department!),
            if (doctor != null) _Row(label: 'Doctor', value: doctor!),
            _Row(label: 'Reason', value: visitTypeLabel(visitType)),
            const SizedBox(height: Space.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: RiskBadge(slot.band),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm booking'),
            ),
            const SizedBox(height: Space.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Back'),
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
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
