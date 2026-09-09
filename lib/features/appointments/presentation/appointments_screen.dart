/// My appointments (P4-16, P8-11): upcoming and past, grouped and labelled,
/// with cancel + reschedule on upcoming ones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../booking/presentation/booking_screen.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: 'My appointments',
      actions: const [PatientTopActions()],
      onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
      children: [
        // The two ways in stay put while the list below them loads — there is
        // no reason to make someone wait on a query to book a visit.
        const _EntryButtons(),
        ...appts.when(
          loading: () => const [
            SizedBox(height: Space.md),
            SkeletonList(lines: 4),
          ],
          error: (e, _) => [
            const SizedBox(height: Space.xl),
            ErrorStateView(
              message: 'Could not load appointments.',
              onRetry: () => ref.invalidate(patientAppointmentsProvider),
            ),
          ],
          data: (list) {
            final upcoming = list.where((a) => a.isUpcoming).toList()
              ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
            final past = list.where((a) => !a.isUpcoming).toList()
              ..sort((a, b) => b.slotStart.compareTo(a.slotStart));

            Widget card(Appointment a, {required bool upcoming}) => _ApptCard(
              a,
              upcoming: upcoming,
              doctor: doctors[a.staffId]?.name,
              department: departments[a.departmentId],
            );

            return [
              SectionHeader('Upcoming (${upcoming.length})', overline: true),
              if (upcoming.isEmpty)
                const _EmptyNote(
                  'Nothing booked. Use Book now or Schedule above.',
                )
              else
                CardColumns(
                  children: [for (final a in upcoming) card(a, upcoming: true)],
                ),

              SectionHeader('History (${past.length})', overline: true),
              if (past.isEmpty)
                const _EmptyNote('No past visits yet.')
              else
                for (final entry in _byMonth(past.take(40)).entries) ...[
                  _MonthLabel(entry.key),
                  CardColumns(
                    children: [
                      for (final a in entry.value) card(a, upcoming: false),
                    ],
                  ),
                ],
            ];
          },
        ),
      ],
    );
  }

  static Map<DateTime, List<Appointment>> _byMonth(Iterable<Appointment> xs) {
    final out = <DateTime, List<Appointment>>{};
    for (final a in xs) {
      final key = DateTime(a.slotStart.year, a.slotStart.month);
      (out[key] ??= []).add(a);
    }
    return out;
  }
}

/// The Appointments entry point (redesign v2): "Book Now" jumps straight to
/// today's (or the soonest) open slots; "Schedule" keeps the date-picking
/// step for a later visit.
class _EntryButtons extends StatelessWidget {
  const _EntryButtons();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EntryCard(
              icon: Icons.bolt_outlined,
              title: 'Book now',
              subtitle: 'Soonest opening',
              filled: true,
              onTap: () =>
                  context.push(AppRoutes.patientBook, extra: BookingMode.now),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: EntryCard(
              icon: Icons.calendar_month_outlined,
              title: 'Schedule',
              subtitle: 'Pick a date',
              onTap: () => context.push(
                AppRoutes.patientBook,
                extra: BookingMode.schedule,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.month);
  final DateTime month;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
    child: Text(
      fmtMonthYear(month),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// A one-line "nothing here yet" note inside a section — the quiet sibling of
/// [EmptyState], which owns a whole screen.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _ApptCard extends ConsumerWidget {
  const _ApptCard(
    this.appt, {
    required this.upcoming,
    this.doctor,
    this.department,
  });

  final Appointment appt;
  final bool upcoming;
  final String? doctor;
  final String? department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meta = [
      visitTypeLabel(appt.visitType),
      ?doctor,
      ?department,
    ].join('  ·  ');
    final ticketMeta = [
      appt.ticketTag == null ? 'Ticket —' : 'Ticket ${appt.ticketTag}',
      'Room ${appt.roomNumber ?? '—'}',
    ].join('  ·  ');

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcoming
                          ? '${fmtRelativeDay(appt.slotStart)} · '
                                '${fmtTime(appt.slotStart)}'
                          : fmtDate(appt.slotStart),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (!upcoming)
                      Text(
                        fmtTime(appt.slotStart),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              AppointmentStatusPill(appt.status, dense: true),
            ],
          ),
          if (appt.bookedForName != null) ...[
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Space.xxs),
                Text(
                  'For ${appt.bookedForName}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
          // Space.xs between the detail lines, not xxs: at 4dp the block read
          // as one dense paragraph rather than four separate facts.
          const SizedBox(height: Space.xs),
          Text(
            meta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            ticketMeta,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (appt.reasonText != null) ...[
            const SizedBox(height: Space.xs),
            Text(appt.reasonText!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.xs),
          Text(
            'Booked ${fmtDate(appt.bookedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (upcoming && appt.riskBand != null) ...[
            const SizedBox(height: Space.sm),
            RiskBadge(appt.riskBand!),
          ],
          if (upcoming) ...[
            const SizedBox(height: Space.sm),
            // Outlined for the tertiary action and error-outlined for the
            // destructive one — the same pair the rest of the app uses
            // (DESIGN.md §5.1). Wrap so they stack instead of overflowing when
            // the card is narrow or the text is scaled up.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  OutlinedButton(
                    onPressed: () => _reschedule(context, ref),
                    child: const Text('Reschedule'),
                  ),
                  OutlinedButton(
                    onPressed: () => _cancel(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: 'Cancel appointment?',
      message: 'This frees the slot for someone else.',
      confirmLabel: 'Cancel it',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(appointmentRepositoryProvider).cancel(appt.id);
    ref.invalidate(patientAppointmentsProvider);
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = appt.slotStart.isAfter(now) ? appt.slotStart : today;
    final date = await showDatePicker(
      context: context,
      initialDate: isClinicDay(base) ? base : nextClinicDay(today),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: isClinicDay,
      helpText: 'Clinic days: Sunday–Thursday',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.slotStart),
      helpText: 'Clinic hours: 08:00–20:00',
    );
    if (time == null) return;
    if (time.hour < clinicOpenHour || time.hour >= clinicCloseHour) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a time between 08:00 and 20:00.')),
        );
      }
      return;
    }
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await ref
        .read(appointmentRepositoryProvider)
        .reschedule(
          id: appt.id,
          newStart: newStart,
          newEnd: newStart.add(appt.duration),
        );
    ref.invalidate(patientAppointmentsProvider);
  }
}
