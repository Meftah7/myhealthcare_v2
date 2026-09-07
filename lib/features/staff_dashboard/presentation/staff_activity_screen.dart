/// Staff activity log (ported from the FirstSemMyHealth doctor "Medical
/// Records" + "Prescriptions" views): everything the signed-in clinician has
/// authored, in two toggled lists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../application/staff_providers.dart';
import 'staff_top_actions.dart';

enum _ActivityView { records, prescriptions }

class StaffActivityScreen extends ConsumerStatefulWidget {
  const StaffActivityScreen({super.key});

  @override
  ConsumerState<StaffActivityScreen> createState() =>
      _StaffActivityScreenState();
}

class _StaffActivityScreenState extends ConsumerState<StaffActivityScreen> {
  _ActivityView _view = _ActivityView.records;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('My activity'),
        actions: const [StaffTopActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.sm),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_ActivityView>(
                    segments: const [
                      ButtonSegment(
                        value: _ActivityView.records,
                        icon: Icon(Icons.description_outlined),
                        label: Text('Records'),
                      ),
                      ButtonSegment(
                        value: _ActivityView.prescriptions,
                        icon: Icon(Icons.medication_outlined),
                        label: Text('Prescriptions'),
                      ),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: switch (_view) {
                  _ActivityView.records => _RecordsList(names: names),
                  _ActivityView.prescriptions => _PrescriptionsList(
                    names: names,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsList extends ConsumerWidget {
  const _RecordsList({required this.names});
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final records = ref.watch(staffRecordsAuthoredProvider);
    return records.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load your records.',
        onRetry: () => ref.invalidate(staffRecordsAuthoredProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.description_outlined,
            message: 'You have not authored any records yet.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            WindowSize.of(context).gutter,
            Space.xs,
            WindowSize.of(context).gutter,
            Space.xxl,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
          itemBuilder: (context, i) {
            final r = list[i];
            return AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.title, style: theme.textTheme.titleSmall),
                      ),
                      if (r.hasAbnormalLabs)
                        Icon(
                          Icons.priority_high,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    '${names[r.patientId] ?? 'Patient'} · '
                    '${_recordTypeLabel(r.recordType)} · '
                    '${fmtDate(r.occurredAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (r.body != null && r.body!.isNotEmpty) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      r.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PrescriptionsList extends ConsumerWidget {
  const _PrescriptionsList({required this.names});
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meds = ref.watch(staffPrescriptionsIssuedProvider);
    return meds.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load your prescriptions.',
        onRetry: () => ref.invalidate(staffPrescriptionsIssuedProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.medication_outlined,
            message: 'You have not issued any prescriptions yet.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            WindowSize.of(context).gutter,
            Space.xs,
            WindowSize.of(context).gutter,
            Space.xxl,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
          itemBuilder: (context, i) {
            final m = list[i];
            return AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(m.name, style: theme.textTheme.titleSmall),
                      ),
                      if (m.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: Radii.chip,
                          ),
                          child: Text(
                            'Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    [
                      names[m.patientId] ?? 'Patient',
                      if (m.dose != null) m.dose,
                      if (m.frequency != null) m.frequency,
                      fmtDate(m.startDate),
                    ].whereType<String>().join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _recordTypeLabel(RecordType t) => switch (t) {
  RecordType.visitNote => 'Visit note',
  RecordType.labResult => 'Lab result',
  RecordType.imaging => 'Imaging',
  RecordType.prescription => 'Prescription',
  RecordType.vaccination => 'Vaccination',
  RecordType.discharge => 'Discharge',
  RecordType.referral => 'Referral',
};
