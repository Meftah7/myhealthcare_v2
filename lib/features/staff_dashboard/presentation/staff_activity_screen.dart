/// Staff activity log (ported from the FirstSemMyHealth doctor "Medical
/// Records" + "Prescriptions" views): everything the signed-in clinician has
/// authored, in two toggled lists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/staff_providers.dart';

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
    final t = AppLocalizations.of(context)!;
    final gutter = WindowSize.of(context).gutter;
    final names = ref.watch(patientNameLookupProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: Text(t.myActivityTitle)),
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
                    segments: [
                      ButtonSegment(
                        value: _ActivityView.records,
                        icon: const Icon(Icons.description_outlined),
                        label: Text(t.recordsTab),
                      ),
                      ButtonSegment(
                        value: _ActivityView.prescriptions,
                        icon: const Icon(Icons.medication_outlined),
                        label: Text(t.prescriptionsTab),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final records = ref.watch(staffRecordsAuthoredProvider);
    return records.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadYourRecords,
        onRetry: () => ref.invalidate(staffRecordsAuthoredProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.description_outlined,
            message: t.noRecordsAuthoredYet,
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
                    '${names[r.patientId] ?? t.rolePatient} · '
                    '${r.recordType.label(context)} · '
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final meds = ref.watch(staffPrescriptionsIssuedProvider);
    return meds.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadYourPrescriptions,
        onRetry: () => ref.invalidate(staffPrescriptionsIssuedProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.medication_outlined,
            message: t.noPrescriptionsIssuedYet,
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
                            t.currentMedicationChip,
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
                      names[m.patientId] ?? t.rolePatient,
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
