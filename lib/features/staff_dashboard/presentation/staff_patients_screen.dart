/// Staff patient search + list (P5-06).
///
/// From `expanded` up this is a list-detail screen: the panel stays on the left
/// and the selected patient's chart fills the pane beside it, so a clinician
/// can move down a list of patients without losing their place. On a phone it
/// is the list alone, and a tap pushes the chart as its own screen.
library;

import 'package:flutter/material.dart';
import '../../workspace/workspace_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/paging_widgets.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/two_pane.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../consultation/presentation/encounter_context.dart';
import '../../patient_chart/application/chart_providers.dart';
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
    final t = AppLocalizations.of(context)!,
        results = ref.watch(patientSearchResultsProvider),
        selectedId = ref.watch(selectedPatientIdProvider),
        split = TwoPane.isSplit(context);
    final hasMore =
        ref.watch(patientSearchPageProvider).valueOrNull?.hasMore ?? false;
    return AppScaffold(
      title: t.navPatients,
      actions: const [StaffTopActions()],
      centerBody: !split,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SearchBar(
            hintText: t.searchByNameOrNationalId,
            leading: const Icon(Icons.search),
            onChanged: (v) =>
                ref.read(patientSearchQueryProvider.notifier).state = v,
          ),
        ),
      ),
      body: TwoPane(
        placeholderIcon: Icons.folder_shared_outlined,
        placeholderMessage: t.pickPatientPlaceholder,
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
            message: '$e',
            onRetry: () => ref.invalidate(patientSearchResultsProvider),
          ),
          data: (patients) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 48),
            itemCount: patients.length + 1 + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == 0)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PatientHistoryStatistics(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (value, en, ar) in [
                          ('all', 'All', 'الكل'),
                          ('critical', 'Critical', 'حرجة'),
                          ('followUp', 'Follow-up', 'المتابعة'),
                        ])
                          FilterChip(
                            label: Text(wt(context, en, ar)),
                            selected:
                                ref.watch(patientHistoryFilterProvider) ==
                                value,
                            onSelected: (_) {
                              ref
                                      .read(
                                        patientHistoryFilterProvider.notifier,
                                      )
                                      .state =
                                  value;
                              ref
                                      .read(patientSearchPagesProvider.notifier)
                                      .state =
                                  1;
                            },
                          ),
                      ],
                    ),
                    if (patients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(t.noPatientsMatchSearch),
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              if (i == patients.length + 1)
                return LoadMoreFooter(
                  onLoadMore: () =>
                      ref.read(patientSearchPagesProvider.notifier).state++,
                );
              final patient = patients[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PatientRow(
                  patient: patient,
                  selected: split && patient.id == selectedId,
                  onTap: () {
                    ref.read(selectedPatientIdProvider.notifier).state =
                        patient.id;
                    if (!split)
                      context.go(AppRoutes.staffPatientChart(patient.id));
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The selected patient stays visible while the clinician moves between the
/// chart, inbox, tasks and schedule branches.
class StaffPatientContextHeader extends ConsumerWidget {
  const StaffPatientContextHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // An open encounter takes precedence: its patient, visit and note stage
    // stay visible on every staff screen until it is completed or closed.
    final encounter = ref.watch(activeEncounterProvider);
    if (encounter != null) return EncounterContextBar(appointmentId: encounter);
    final id = ref.watch(selectedPatientIdProvider);
    // Reserve the same strip height before selection so choosing a patient
    // never moves the queue or loses the operator's visual position.
    if (id == null) return const SizedBox(height: 48);
    final patient = ref.watch(chartPatientProvider(id)).valueOrNull;
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: Space.md),
          child: Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  patient?.fullName ?? t.patientChartFallbackTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.staffPatientChart(id)),
                child: Text(t.openChartAction),
              ),
              IconButton(
                tooltip: t.clearSearchTooltip,
                onPressed: () =>
                    ref.read(selectedPatientIdProvider.notifier).state = null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientRow extends ConsumerWidget {
  const _PatientRow({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  final Patient patient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final initials = patient.fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();

    final history = ref
        .watch(historyRowsPageProvider)
        .valueOrNull
        ?.items
        .where((r) => r['id'] == patient.id)
        .firstOrNull;
    final meta = [
      if (history != null)
        '${wt(context, "Last qualifying visit", "آخر زيارة مؤهلة")}: ${wallDate(history['last_visit'])}',
      if (history?['legacy_completion'] == 1)
        wt(
          context,
          'Legacy visits may use scheduled dates',
          'قد تستخدم الزيارات القديمة تواريخ المواعيد',
        ),
      if (patient.user.dob != null)
        '${patient.user.ageYears} · ${wlabel(context, patient.user.gender?.name)}',
      if (history?['critical'] == 1) wt(context, 'Critical', 'حرجة'),
      if (history?['follow_up'] == 1) wt(context, 'Follow-up', 'المتابعة'),
      if (patient.user.nationalId != null)
        t.idValueLabel(patient.user.nationalId!),
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
