/// Staff patient search + list (P5-06).
///
/// From `expanded` up this is a list-detail screen: the panel stays on the left
/// and the selected patient's chart fills the pane beside it, so a clinician
/// can move down a list of patients without losing their place. On a phone it
/// is the list alone, and a tap pushes the chart as its own screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/two_pane.dart';
import '../../../domain/entities/entities.dart';
import '../../patient_chart/presentation/patient_chart_screen.dart';
import '../application/staff_providers.dart';
import 'staff_top_actions.dart';

/// The patient selected in the wide list-detail layout. Null until one is
/// picked, and irrelevant on narrow windows, where selection is a route.
final selectedPatientIdProvider = StateProvider<String?>((ref) => null);

class StaffPatientsScreen extends ConsumerWidget {
  const StaffPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(patientSearchResultsProvider);
    final selectedId = ref.watch(selectedPatientIdProvider);
    final split = TwoPane.isSplit(context);

    return AppScaffold(
      title: 'Patients',
      actions: const [StaffTopActions()],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
          child: SearchBar(
            hintText: 'Search by name or national ID',
            leading: const Icon(Icons.search),
            onChanged: (v) =>
                ref.read(patientSearchQueryProvider.notifier).state = v,
          ),
        ),
      ),
      // The panes manage their own scrolling and want the full window width.
      centerBody: !split,
      body: TwoPane(
        placeholderIcon: Icons.folder_shared_outlined,
        placeholderMessage: 'Pick a patient to open their chart.',
        detail: selectedId == null
            ? null
            : PatientChartScreen(
                key: ValueKey(selectedId),
                patientId: selectedId,
                embedded: true,
              ),
        list: results.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorStateView(
            message: 'Could not load patients.',
            onRetry: () => ref.invalidate(patientSearchResultsProvider),
          ),
          data: (patients) {
            if (patients.isEmpty) {
              return const EmptyState(
                icon: Icons.person_search_outlined,
                message: 'No patients match that search.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.xxl,
              ),
              itemCount: patients.length,
              itemBuilder: (context, i) {
                final p = patients[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: _PatientRow(
                    patient: p,
                    selected: split && p.id == selectedId,
                    onTap: () {
                      if (split) {
                        ref.read(selectedPatientIdProvider.notifier).state =
                            p.id;
                      } else {
                        context.go(AppRoutes.staffPatientChart(p.id));
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  final Patient patient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initials = patient.fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();

    final meta = [
      if (patient.user.nationalId != null) 'ID ${patient.user.nationalId}',
      if (patient.chronicConditions.isNotEmpty)
        patient.chronicConditions.join(', '),
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(Space.sm),
      onTap: onTap,
      // The selected row picks up the same tint as the navigation indicator,
      // so "where I am" reads identically in the rail and in the list.
      color: selected ? scheme.secondaryContainer : null,
      borderColor: selected ? scheme.secondary.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: selected
                ? scheme.onSecondaryContainer.withValues(alpha: 0.12)
                : scheme.secondaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: kTrailingChevronSize,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
