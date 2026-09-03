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
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/clinic_hours.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/application/patient_data_providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors =
        ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('My appointments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.patientBook),
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: appts.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load appointments.',
          onRetry: () => ref.invalidate(patientAppointmentsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.event_outlined,
              message: 'No appointments yet. Tap Book to schedule a visit.',
            );
          }
          final upcoming = list.where((a) => a.isUpcoming).toList()
            ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
          final past = list.where((a) => !a.isUpcoming).toList()
            ..sort((a, b) => b.slotStart.compareTo(a.slotStart));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.sm,
              Space.md,
              Space.xxl,
            ),
            children: [
              _SectionLabel('Upcoming', count: upcoming.length),
              if (upcoming.isEmpty)
                const _MutedLine('Nothing booked. Tap Book to schedule a visit.')
              else
                for (final a in upcoming)
                  _ApptCard(
                    a,
                    upcoming: true,
                    doctor: doctors[a.staffId]?.name,
                    department: departments[a.departmentId],
                  ),

              const SizedBox(height: Space.lg),
              _SectionLabel('History', count: past.length),
              for (final entry in _byMonth(past.take(40)).entries) ...[
                _MonthLabel(entry.key),
                for (final a in entry.value)
                  _ApptCard(
                    a,
                    upcoming: false,
                    doctor: doctors[a.staffId]?.name,
                    department: departments[a.departmentId],
                  ),
              ],
            ],
              ),
            ),
          );
        },
      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: Space.xs,
        top: Space.xs,
        bottom: Space.xs,
      ),
      child: Row(
        children: [
          Text(text, style: theme.textTheme.titleMedium),
          const SizedBox(width: Space.xs),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, Space.xxs),
    child: Text(
      fmtMonthYear(month),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _MutedLine extends StatelessWidget {
  const _MutedLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xxs, Space.xs, Space.xs),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: AppCard(
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
                _StatusChip(appt.status),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Text(
              meta,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (appt.reasonText != null) ...[
              const SizedBox(height: Space.xxs),
              Text(appt.reasonText!, style: theme.textTheme.bodySmall),
            ],
            if (upcoming && appt.riskBand != null) ...[
              const SizedBox(height: Space.xs),
              RiskBadge(appt.riskBand!),
            ],
            if (upcoming) ...[
              const SizedBox(height: Space.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _reschedule(context, ref),
                    child: const Text('Reschedule'),
                  ),
                  const SizedBox(width: Space.xs),
                  TextButton(
                    onPressed: () => _cancel(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      AppointmentStatus.booked => (
        'Booked',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppointmentStatus.confirmed => (
        'Confirmed',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppointmentStatus.completed => (
        'Completed',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      AppointmentStatus.cancelled => (
        'Cancelled',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      AppointmentStatus.noShow => (
        'No-show',
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.chip),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
