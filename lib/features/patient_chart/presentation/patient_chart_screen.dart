/// Staff patient chart (P5-07) — reuses the Phase 2 record/vitals shapes, adds
/// clinical-note (P5-08), prescription and lab-entry (P5-09) actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../application/chart_providers.dart';
import 'chart_write_sheets.dart';

class PatientChartScreen extends ConsumerWidget {
  const PatientChartScreen({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(chartPatientProvider(patientId));
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.valueOrNull?.fullName ?? 'Patient chart'),
      ),
      floatingActionButton: patient.hasValue
          ? _ChartFab(patientId: patientId)
          : null,
      body: patient.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load this patient.',
          onRetry: () => ref.invalidate(chartPatientProvider(patientId)),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            _Header(patient: p),
            const SizedBox(height: Space.lg),
            _FlagsCard(patientId: patientId),
            const SizedBox(height: Space.lg),
            Text('Medications', style: Theme.of(context).textTheme.titleMedium),
            _MedicationsCard(patientId: patientId),
            const SizedBox(height: Space.lg),
            Text(
              'Recent vitals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _VitalsCard(patientId: patientId),
            const SizedBox(height: Space.lg),
            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
            _TimelineCard(patientId: patientId),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = patient.user;
    final age = u.ageYears;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.fullName, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              [
                if (age != null) '$age yrs',
                u.gender?.name,
                if (u.nationalId != null) 'ID ${u.nationalId}',
                if (patient.bloodType != null) patient.bloodType,
              ].whereType<String>().join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (patient.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xxs,
                children: [
                  for (final c in patient.chronicConditions)
                    Chip(label: Text(c), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
            if (patient.allergies.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: Space.xxs),
                  Expanded(
                    child: Text(
                      'Allergies: ${patient.allergies.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
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
}

class _FlagsCard extends ConsumerWidget {
  const _FlagsCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(chartFlagsProvider(patientId));
    return flags.when(
      loading: () => const LoadingSkeleton(height: 40),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) {
        final open = list.where((f) => !f.isAcknowledged).toList()
          ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
        if (open.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Column(
            children: [
              for (final f in open)
                ListTile(
                  leading: SeverityChip(f.severity),
                  title: Text(f.rationale),
                  trailing: IconButton(
                    tooltip: 'Acknowledge',
                    icon: const Icon(Icons.done),
                    onPressed: () => ref
                        .read(chartActionsProvider(patientId))
                        .acknowledgeFlag(f.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MedicationsCard extends ConsumerWidget {
  const _MedicationsCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meds = ref.watch(chartMedicationsProvider(patientId));
    return meds.when(
      loading: () => const LoadingSkeleton(height: 40),
      error: (e, _) => const Card(
        child: ListTile(title: Text('Could not load medications')),
      ),
      data: (list) {
        final current = list.where((m) => m.isCurrent).toList();
        if (current.isEmpty) {
          return const Card(
            child: ListTile(title: Text('No active medications')),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final m in current)
                ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(m.name),
                  subtitle: Text(
                    [m.dose, m.frequency].whereType<String>().join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VitalsCard extends ConsumerWidget {
  const _VitalsCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vitals = ref.watch(chartVitalsProvider(patientId));
    return vitals.when(
      loading: () => const LoadingSkeleton(height: 40),
      error: (e, _) =>
          const Card(child: ListTile(title: Text('Could not load vitals'))),
      data: (list) {
        if (list.isEmpty) {
          return const Card(
            child: ListTile(title: Text('No vitals on record')),
          );
        }
        final recent = [...list]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        return Card(
          child: Column(
            children: [
              for (final v in recent.take(3))
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(
                    [
                      if (v.hasBloodPressure) 'BP ${v.systolic}/${v.diastolic}',
                      if (v.heartRate != null) 'HR ${v.heartRate}',
                      if (v.spo2 != null) 'SpO₂ ${v.spo2}%',
                      if (v.glucose != null) 'Glu ${v.glucose}',
                    ].join('  '),
                  ),
                  subtitle: Text(
                    fmtDate(v.recordedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final records = ref.watch(chartTimelineProvider(patientId));
    return records.when(
      loading: () => const LoadingSkeleton(height: 40),
      error: (e, _) =>
          const Card(child: ListTile(title: Text('Could not load timeline'))),
      data: (list) {
        if (list.isEmpty) {
          return const Card(child: ListTile(title: Text('No records yet')));
        }
        return Card(
          child: Column(
            children: [
              for (final r in list.take(12))
                ListTile(
                  leading: Icon(_recordIcon(r.recordType)),
                  title: Text(r.title),
                  subtitle: Text(
                    '${fmtDate(r.occurredAt)} · ${r.recordType.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: r.hasAbnormalLabs
                      ? Icon(
                          Icons.priority_high,
                          color: theme.colorScheme.error,
                          size: 20,
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

IconData _recordIcon(RecordType t) => switch (t) {
  RecordType.visitNote => Icons.notes_outlined,
  RecordType.labResult => Icons.science_outlined,
  RecordType.imaging => Icons.image_outlined,
  RecordType.prescription => Icons.medication_outlined,
  RecordType.vaccination => Icons.vaccines_outlined,
  RecordType.discharge => Icons.local_hospital_outlined,
  RecordType.referral => Icons.forward_to_inbox_outlined,
};

class _ChartFab extends StatelessWidget {
  const _ChartFab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => unawaited(switch (v) {
        'note' => showChartNoteSheet(context, patientId),
        'rx' => showPrescribeSheet(context, patientId),
        'lab' => showLabResultSheet(context, patientId),
        _ => Future<void>.value(),
      }),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'note', child: Text('Add clinical note')),
        PopupMenuItem(value: 'rx', child: Text('Prescribe medication')),
        PopupMenuItem(value: 'lab', child: Text('Enter lab result')),
      ],
      child: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      ),
    );
  }
}
