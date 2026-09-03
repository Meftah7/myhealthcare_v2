/// Booking wizard: department → doctor → date → AI-ranked slots → confirm
/// (P4-13, P4-14).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../application/booking_providers.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingDraftProvider);
    final departments = ref.watch(departmentsProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Book an appointment')),
      body: departments.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load departments.',
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (depts) => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            const SectionHeader('Department'),
            DropdownButtonFormField<String>(
              initialValue: draft.departmentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Department'),
              items: [
                for (final d in depts)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              // Changing department resets the downstream choices.
              onChanged: (v) => notifier.state = BookingRequestDraft(
                departmentId: v,
                visitType: draft.visitType,
              ),
            ),

            if (draft.departmentId != null) ...[
              const SectionHeader('Doctor'),
              _DoctorPicker(departmentId: draft.departmentId!),
            ],

            if (draft.staffId != null) ...[
              const SectionHeader('Visit'),
              DropdownButtonFormField<VisitType>(
                initialValue: draft.visitType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit',
                ),
                items: [
                  for (final t in VisitType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(
                        visitTypeLabel(t),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => notifier.state = draft.copyWith(visitType: v),
              ),
              const SizedBox(height: Space.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final current = draft.date;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: (current != null && isClinicDay(current))
                        ? current
                        : nextClinicDay(today),
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 60)),
                    selectableDayPredicate: isClinicDay,
                    helpText: 'Clinic days: Sunday–Thursday',
                  );
                  if (picked != null) {
                    notifier.state = draft.copyWith(date: picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  draft.date == null ? 'Choose a date' : fmtDate(draft.date!),
                ),
              ),
            ],

            if (draft.staffId != null && draft.date != null) ...[
              const SectionHeader('Available times'),
              _SlotList(),
            ],
          ],
        ),
      ),
    );
  }

}

class _DoctorPicker extends ConsumerWidget {
  const _DoctorPicker({required this.departmentId});
  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(departmentStaffProvider(departmentId));
    final draft = ref.watch(bookingDraftProvider);
    return staff.when(
      loading: () => const LoadingSkeleton(height: 48),
      error: (e, _) => const Text('Could not load doctors'),
      data: (list) => DropdownButtonFormField<String>(
        initialValue: draft.staffId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Doctor'),
        items: [
          for (final s in list)
            DropdownMenuItem(
              value: s.id,
              child: Text(
                '${s.fullName}'
                '${s.specialty == null ? '' : ' · ${s.specialty}'}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) => ref.read(bookingDraftProvider.notifier).state = draft
            .copyWith(staffId: v),
      ),
    );
  }
}

class _SlotList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(rankedSlotsProvider);
    return slots.when(
      loading: () => const LoadingSkeleton(height: 120),
      error: (e, _) => ErrorStateView(
        message: 'Could not load slots.',
        onRetry: () => ref.invalidate(rankedSlotsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            message: 'No open slots on that day. Try another date.',
          );
        }
        // `list` is risk-ranked (best attendance first, P4-14); the visible
        // list runs in clock order from opening to closing.
        final best = list.first;
        final byTime = [...list]
          ..sort((a, b) => a.slot.start.compareTo(b.slot.start));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.all(Space.sm),
              onTap: () => _book(context, ref, best),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fmtTime(best.slot.start)} · recommended',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          best.reason,
                          style: Theme.of(context).textTheme.bodySmall,
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
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, s) in byTime.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: Space.md),
                    ListTile(
                      dense: true,
                      title: Text(fmtTime(s.slot.start)),
                      trailing: RiskBadge(s.band),
                      onTap: () => _book(context, ref, s),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _book(BuildContext context, WidgetRef ref, RankedSlot s) async {
    final ok = await confirm(
      context,
      title: 'Confirm booking',
      message: 'Book ${fmtDate(s.slot.start)} at ${fmtTime(s.slot.start)}?',
      confirmLabel: 'Book',
    );
    if (!ok || !context.mounted) return;
    final result = await ref.read(bookingControllerProvider).confirm(s);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.read(bookingDraftProvider.notifier).state =
            const BookingRequestDraft();
        context.go(AppRoutes.patientAppointments);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}
