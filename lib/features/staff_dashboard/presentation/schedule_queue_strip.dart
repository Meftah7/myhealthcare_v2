/// "Today's queue" on the schedule day view: a tracking list of the patients
/// still waiting, soonest first. Tapping any chip makes that patient current —
/// it scrolls and glows their card on the timeline, exactly like "Next" — so
/// the doctor can move freely in either direction, not just forward. "Next" is
/// the fast-forward convenience for the common case of working the list in
/// order. The currently selected patient's summary sits inline under the
/// strip, always visible while they're selected.
///
/// Nothing here navigates away — that is the timeline card's job. There are
/// no accept / decline actions here either — that is also the card's job.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../application/staff_providers.dart';

class ScheduleQueueStrip extends ConsumerWidget {
  const ScheduleQueueStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final queueAsync = ref.watch(staffQueueProvider);
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};
    final currentId = ref.watch(scheduleQueueCurrentIdProvider);

    final queue = queueAsync.valueOrNull;
    if (queue == null || queue.isEmpty) return const SizedBox.shrink();

    final idx = queue.indexWhere((a) => a.id == currentId);
    final selected = idx >= 0 ? queue[idx] : null;
    final atEnd = idx >= 0 && idx == queue.length - 1;

    String nameOf(Appointment a) =>
        names[a.patientId] ?? visitTypeLabel(a.visitType);

    void select(Appointment a) =>
        ref.read(scheduleQueueCurrentIdProvider.notifier).state = a.id;

    void advance() {
      final next = idx < 0
          ? queue.first
          : (idx + 1 < queue.length ? queue[idx + 1] : null);
      if (next != null) select(next);
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
                  t.todaysQueueCaps,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  t.waitingCount(queue.length),
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
                  onTap: () => select(a),
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
                      ? t.tapPatientOrPressNext
                      : atEnd
                      ? t.lastPatientInQueue
                      : t.nowLabel(nameOf(queue[idx])),
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
                      label: Text(t.nextLabel),
                    ),
            ],
          ),
          AppReveal(
            child: selected == null
                ? const SizedBox.shrink(key: ValueKey('queue-summary-none'))
                : _InlineSummary(
                    key: ValueKey('queue-summary-${selected.id}'),
                    appointment: selected,
                    name: nameOf(selected),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoMore extends StatelessWidget {
  const _NoMore();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
          t.noMorePatients,
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

/// The selected queue patient's summary — room, reason, key facts, and a way
/// into their chart. Sits inline under the strip so it's always visible while
/// they're selected, rather than a tap-away sheet.
class _InlineSummary extends ConsumerWidget {
  const _InlineSummary({
    required this.appointment,
    required this.name,
    super.key,
  });

  final Appointment appointment;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = ref.watch(chartPatientProvider(appointment.patientId));

    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Radii.cardSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: theme.textTheme.titleSmall),
                ),
                Text(
                  fmtTime(appointment.slotStart),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [
                visitTypeLabel(appointment.visitType),
                if (appointment.roomNumber != null)
                  t.roomNumber('${appointment.roomNumber}'),
                if (appointment.ticketTag != null)
                  t.ticketLabel(appointment.ticketTag!),
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xs),
            patient.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
              data: (p) => _PatientFacts(patient: p),
            ),
            if (appointment.reasonText != null) ...[
              const SizedBox(height: Space.xxs),
              Text(
                t.reasonLabel(appointment.reasonText!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: Space.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => context.go(
                  AppRoutes.staffPatientChart(appointment.patientId),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: Text(t.openChartAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                  side: BorderSide(color: scheme.outlineVariant),
                  visualDensity: VisualDensity.compact,
                ),
              ),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final u = patient.user;
    final facts = [
      if (u.ageYears != null) t.ageYearsAbbrev(u.ageYears!),
      ?u.gender?.label(context),
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
              t.allergiesInlineLabel(patient.allergies.join(', ')),
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
