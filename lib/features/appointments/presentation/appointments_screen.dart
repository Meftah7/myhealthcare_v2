/// My appointments — upcoming / past, cancel, reschedule (P4-16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/application/patient_data_providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(patientAppointmentsProvider);
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
              message: 'No appointments yet.',
            );
          }
          final upcoming = list.where((a) => a.isUpcoming).toList()
            ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
          final past = list.where((a) => !a.isUpcoming).toList()
            ..sort((a, b) => b.slotStart.compareTo(a.slotStart));
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _Header('Upcoming'),
                for (final a in upcoming) _ApptTile(a, upcoming: true),
              ],
              if (past.isNotEmpty) ...[
                const _Header('Past'),
                for (final a in past.take(30)) _ApptTile(a, upcoming: false),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _ApptTile extends ConsumerWidget {
  const _ApptTile(this.appt, {required this.upcoming});
  final Appointment appt;
  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fmtDateTime(appt.slotStart),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _statusChip(theme),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Text(
              appt.visitType.name +
                  (appt.reasonText == null ? '' : ' · ${appt.reasonText}'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
                  TextButton(
                    onPressed: () => _cancel(context, ref),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme) {
    final (label, color) = switch (appt.status) {
      AppointmentStatus.booked => ('Booked', theme.colorScheme.primary),
      AppointmentStatus.confirmed => ('Confirmed', theme.colorScheme.primary),
      AppointmentStatus.completed => (
        'Completed',
        theme.colorScheme.onSurfaceVariant,
      ),
      AppointmentStatus.cancelled => (
        'Cancelled',
        theme.colorScheme.onSurfaceVariant,
      ),
      AppointmentStatus.noShow => ('No-show', theme.colorScheme.error),
    };
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(color: color),
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
    final date = await showDatePicker(
      context: context,
      initialDate: appt.slotStart.isAfter(now) ? appt.slotStart : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.slotStart),
    );
    if (time == null) return;
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
