/// "Today's queue" on the schedule day view: a tracking list of the patients
/// still waiting, soonest first. Tap a patient for a short summary (with a way
/// into their chart); press "Next" to step to the following patient — which
/// scrolls their card into view on the timeline and glows it briefly.
///
/// "Next" never navigates away. There are no accept / decline actions here —
/// that is the timeline card's job.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../application/staff_providers.dart';

class ScheduleQueueStrip extends ConsumerWidget {
  const ScheduleQueueStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final queueAsync = ref.watch(staffQueueProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final currentId = ref.watch(scheduleQueueCurrentIdProvider);

    final queue = queueAsync.valueOrNull;
    if (queue == null || queue.isEmpty) return const SizedBox.shrink();

    final idx = queue.indexWhere((a) => a.id == currentId);
    final atEnd = idx >= 0 && idx == queue.length - 1;

    String nameOf(Appointment a) =>
        names[a.patientId] ?? visitTypeLabel(a.visitType);

    void advance() {
      final next = idx < 0
          ? queue.first
          : (idx + 1 < queue.length ? queue[idx + 1] : null);
      if (next == null) return;
      ref.read(scheduleQueueCurrentIdProvider.notifier).state = next.id;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: Radii.cardSmall,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xxs, Space.xxs, Space.xxs, 0),
            child: Row(
              children: [
                Text(
                  "TODAY'S QUEUE",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '${queue.length} waiting',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: queue.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.xxs),
              itemBuilder: (context, i) {
                final a = queue[i];
                return _QueueChip(
                  label: nameOf(a),
                  time: fmtTime(a.slotStart),
                  selected: a.id == currentId,
                  onTap: () => _showSummary(context, a, nameOf(a)),
                );
              },
            ),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  idx < 0
                      ? 'Start with ${nameOf(queue.first)}'
                      : atEnd
                      ? 'Last patient in the queue'
                      : 'Now: ${nameOf(queue[idx])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
              atEnd
                  ? const _NoMore()
                  : FilledButton.tonalIcon(
                      onPressed: advance,
                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                      label: const Text('Next'),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSummary(BuildContext context, Appointment a, String name) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _QueueSummarySheet(appointment: a, name: name),
      ),
    );
  }
}

class _NoMore extends StatelessWidget {
  const _NoMore();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Space.xxs),
        Text(
          'No more patients',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QueueChip extends StatelessWidget {
  const _QueueChip({
    required this.label,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? scheme.onPrimary.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant,
                  fontFeatures: kTabularFigures,
                ),
              ),
              const SizedBox(width: Space.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueSummarySheet extends ConsumerWidget {
  const _QueueSummarySheet({required this.appointment, required this.name});

  final Appointment appointment;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = ref.watch(chartPatientProvider(appointment.patientId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              [
                fmtTime(appointment.slotStart),
                visitTypeLabel(appointment.visitType),
                if (appointment.roomNumber != null)
                  'Room ${appointment.roomNumber}',
                if (appointment.ticketTag != null)
                  'Ticket ${appointment.ticketTag}',
              ].join('  ·  '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            patient.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => Text(
                'Could not load the patient.',
                style: theme.textTheme.bodySmall,
              ),
              data: (p) => _PatientFacts(patient: p),
            ),
            if (appointment.reasonText != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                'Reason: ${appointment.reasonText}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.staffPatientChart(appointment.patientId));
              },
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Open chart'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientFacts extends StatelessWidget {
  const _PatientFacts({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = patient.user;
    final facts = [
      if (u.ageYears != null) '${u.ageYears} yrs',
      ?u.gender?.name,
      if (patient.bloodType != null) patient.bloodType!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (facts.isNotEmpty)
          Text(
            facts,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (patient.allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(
              'Allergies: ${patient.allergies.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (patient.chronicConditions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(
              patient.chronicConditions.join(', '),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
