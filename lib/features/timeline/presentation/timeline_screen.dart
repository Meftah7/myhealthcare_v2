/// Health timeline (P2-08) with type filters + search (P2-09).
///
/// Merges medical records and vitals measurements into one reverse-chronological
/// feed grouped by month.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_summary/application/ai_summary_provider.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../records/application/records_providers.dart';
import '../../records/presentation/record_filters_sheet.dart';
import 'import_record_sheet.dart';

/// Record ids the AI flagged as key events (P3-11) — empty on any failure.
final _keyEventRecordIdsProvider = Provider<Set<String>>((ref) {
  final summary = ref.watch(patientAiSummaryProvider);
  return summary.maybeWhen(
    data: (s) => {
      for (final e in s.keyEvents)
        if (e.recordId != null) e.recordId!,
    },
    orElse: () => const {},
  );
});

/// One row in the merged feed.
sealed class _Entry {
  DateTime get at;
}

class _RecordEntry extends _Entry {
  _RecordEntry(this.record);
  final MedicalRecord record;
  @override
  DateTime get at => record.occurredAt;
}

class _VitalsEntry extends _Entry {
  _VitalsEntry(this.vitals);
  final Vitals vitals;
  @override
  DateTime get at => vitals.recordedAt;
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({
    this.embedded = false,
    this.header,
    this.footer,
    this.onMedications,
    this.onRefresh,
    super.key,
  });

  /// When true, render the filters + feed without a Scaffold/AppBar — the
  /// Health Records screen supplies those.
  final bool embedded;
  final Widget? header;
  final Widget? footer;
  final VoidCallback? onMedications;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final records = ref.watch(recordsHistoryProvider);
    final vitals = ref.watch(recordsVitalsProvider);
    final subject = ref.watch(recordsPatientIdProvider);
    final filter = ref.watch(recordFiltersProvider(subject));
    final readState = ref.watch(recordReadIdsProvider);
    final names = ref.watch(doctorDirectoryProvider).valueOrNull ?? {};
    final feed = records.when(
      loading: () => SkeletonList(lines: embedded ? 3 : 5),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadRecords,
        onRetry: () {
          ref.invalidate(patientTimelinePageProvider);
          ref.invalidate(linkedTimelinePageProvider(subject));
          ref.invalidate(recordsHistoryProvider);
        },
      ),
      data: (recs) {
        if (filter.unreadOnly && !readState.hasValue) {
          return readState.hasError
              ? ErrorStateView(
                  message: t.recordsReadStateUnavailable,
                  onRetry: () => ref.invalidate(recordReadIdsProvider),
                )
              : const SkeletonList();
        }
        final entries = <_Entry>[
          for (final r in recs)
            if (filter.matches(
              r,
              readState.valueOrNull ?? {},
              authorName: names[r.authorStaffId]?.name,
            ))
              _RecordEntry(r),
          if (filter.includesVitals)
            for (final v in vitals.valueOrNull ?? const <Vitals>[])
              _VitalsEntry(v),
        ]..sort((a, b) => b.at.compareTo(a.at));

        if (entries.isEmpty) {
          return ListView(
            children: [
              EmptyState(
                icon: Icons.timeline_outlined,
                message: t.nothingMatchesFilters,
              ),
              ?footer,
            ],
          );
        }
        return _GroupedList(entries: entries, footer: footer);
      },
    );

    final content = ScrollableHeaderBody(
      header: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: _Filters(key: ValueKey(subject), onMedications: onMedications),
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            onRefresh ??
            () async {
              ref.invalidate(patientTimelinePageProvider);
              ref.invalidate(patientVitalsProvider);
              ref.invalidate(linkedTimelinePageProvider(subject));
              ref.invalidate(linkedVitalsProvider(subject));
              ref.invalidate(recordsHistoryProvider);
              ref.invalidate(recordsVitalsProvider);
            },
        child: Column(
          children: [
            if (filter.includesVitals && vitals.isLoading)
              const LinearProgressIndicator(),
            if (filter.includesVitals && vitals.hasError)
              TextButton(
                onPressed: () {
                  ref.invalidate(patientVitalsProvider);
                  ref.invalidate(linkedVitalsProvider(subject));
                  ref.invalidate(recordsVitalsProvider);
                },
                child: Text(t.couldNotLoadVitals),
              ),
            if (readState.hasError)
              TextButton(
                onPressed: () => ref.invalidate(recordReadIdsProvider),
                child: Text(t.recordsReadStateUnavailable),
              ),
            Expanded(child: feed),
          ],
        ),
      ),
    );
    final workspace = Column(
      children: [
        ?header,
        Expanded(child: content),
      ],
    );
    if (embedded) return workspace;

    return AppScaffold(
      title: t.recordsTitle,
      body: workspace,
      centerBody: false,
    );
  }
}

class _Filters extends ConsumerStatefulWidget {
  const _Filters({this.onMedications, super.key});
  final VoidCallback? onMedications;

  @override
  ConsumerState<_Filters> createState() => _FiltersState();
}

class _FiltersState extends ConsumerState<_Filters> {
  late final _search = TextEditingController(
    text: ref
        .read(recordFiltersProvider(ref.read(recordsPatientIdProvider)))
        .query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subject = ref.watch(recordsPatientIdProvider);
    final provider = recordFiltersProvider(subject);
    final filter = ref.watch(provider);
    ref.listen(provider, (_, next) {
      if (_search.text != next.query) {
        _search.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });
    final types = filter.types;
    void update(RecordsFilter next) => ref.read(provider.notifier).state = next;
    final t = AppLocalizations.of(context)!;
    final view = filter.view;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.patientDocuments}?patientId=${Uri.encodeQueryComponent(subject)}',
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(t.recordsDocuments),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.patientSickLeave}?patientId=$subject',
                  ),
                  icon: const Icon(Icons.event_note_outlined),
                  label: Text(t.quickActionSickLeave),
                ),
                FilledButton.icon(
                  onPressed:
                      ref.watch(recordsCanManageProvider).valueOrNull == true
                      ? () => showImportRecordSheet(context, patientId: subject)
                      : null,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(t.recordsUploadDocument),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xs),
          SearchBar(
            controller: _search,
            hintText: t.searchRecordsHint,
            leading: const Icon(Icons.search),
            onChanged: (v) => update(filter.copyWith(query: v)),
          ),
          const SizedBox(height: Space.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in [
                  (RecordsView.all, t.recordsAll),
                  (RecordsView.results, t.recordsResults),
                  (RecordsView.documents, t.recordsDocuments),
                  (RecordsView.uploads, t.recordsUploads),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: view == value,
                      onSelected: (_) => update(filter.copyWith(view: value)),
                    ),
                  ),
                if (widget.onMedications != null)
                  ActionChip(
                    label: Text(t.medicationsSegment),
                    onPressed: widget.onMedications,
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: ActionChip(
                    avatar: Icon(
                      filter.hasAdvanced
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                    ),
                    label: Text(t.recordsFilters),
                    onPressed: () => showRecordFilters(context, subject),
                  ),
                ),
                for (final rt in RecordType.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      label: Text(_label(t, rt)),
                      selected: types.contains(rt),
                      onSelected: (on) {
                        final next = {...types};
                        on ? next.add(rt) : next.remove(rt);
                        update(filter.copyWith(types: next));
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations t, RecordType rt) => switch (rt) {
    RecordType.visitNote => t.filterVisits,
    RecordType.labResult => t.filterLabs,
    RecordType.imaging => t.imagingTitle,
    RecordType.prescription => t.filterPrescriptions,
    RecordType.vaccination => t.filterVaccinations,
    RecordType.discharge => t.recordTypeDischarge,
    RecordType.referral => t.filterReferrals,
  };
}

class _GroupedList extends ConsumerWidget {
  const _GroupedList({required this.entries, this.footer});

  final List<_Entry> entries;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final keyEventIds = ref.watch(selectedRecordsPatientProvider) == null
        ? ref.watch(_keyEventRecordIdsProvider)
        : <String>{};
    // Build a flat list with month headers.
    final items = <Widget>[];
    final groupedVisits = <String>{};
    String? visitOf(_Entry entry) => switch (entry) {
      _RecordEntry(:final record) => record.appointmentId,
      _VitalsEntry(:final vitals) => vitals.appointmentId,
    };
    Widget tile(_Entry entry) => switch (entry) {
      _RecordEntry(:final record) => _RecordTile(
        record: record,
        isKeyEvent: keyEventIds.contains(record.id),
      ),
      _VitalsEntry(:final vitals) => _VitalsTile(vitals: vitals),
    };
    String? currentMonth;
    for (final e in entries) {
      final visit = visitOf(e);
      if (visit != null && !groupedVisits.add(visit)) continue;
      final month = fmtMonthYear(e.at);
      if (month != currentMonth) {
        currentMonth = month;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.lg,
              Space.md,
              Space.xs,
            ),
            child: Text(
              month.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }
      if (visit == null) {
        items.add(tile(e));
      } else {
        items.add(
          TextButton.icon(
            onPressed: () =>
                context.push(AppRoutes.patientAppointmentDetail(visit)),
            icon: const Icon(Icons.event_note_outlined),
            label: Text(
              AppLocalizations.of(context)!.fromYourVisitOn(fmtDate(e.at)),
            ),
          ),
        );
        items.addAll(
          entries.where((entry) => visitOf(entry) == visit).map(tile),
        );
      }
    }
    if (footer != null) items.add(footer!);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: ListView.builder(
          key: PageStorageKey(
            'records-history-${ref.watch(recordsPatientIdProvider)}',
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: Space.xxl),
          itemCount: items.length,
          itemBuilder: (context, i) => items[i],
        ),
      ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record, this.isKeyEvent = false});

  final MedicalRecord record;
  final bool isKeyEvent;

  IconData get _icon => switch (record.recordType) {
    RecordType.visitNote => Icons.notes_outlined,
    RecordType.labResult => Icons.science_outlined,
    RecordType.imaging => Icons.image_outlined,
    RecordType.prescription => Icons.medication_outlined,
    RecordType.vaccination => Icons.vaccines_outlined,
    RecordType.discharge => Icons.local_hospital_outlined,
    RecordType.referral => Icons.forward_to_inbox_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(_icon),
          if (isKeyEvent)
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -4,
              top: -4,
              child: Icon(
                Icons.star,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      title: Text(record.title),
      subtitle: Text(
        '${fmtDate(record.occurredAt)}'
        ' · ${record.recordType.label(context)}'
        '${record.authorStaffId == null ? '' : ' · ${ref.watch(doctorDirectoryProvider).valueOrNull?[record.authorStaffId]?.name ?? t.recordsUnknownAuthor}'}'
        '${record.sourceFacility == null ? '' : ' · ${record.sourceFacility}'}'
        '${record.uploadedByPatient ? ' · ${t.uploadedByPatientTag}' : ''}'
        ' · ${recordReviewLabel(t, record.reviewStatus)}'
        '${ref.watch(recordReadIdsProvider).valueOrNull == null ? '' : ' · ${ref.watch(recordReadIdsProvider).requireValue.contains(record.id) ? t.recordsRead : t.recordsUnread}'}'
        '${isKeyEvent ? ' · ${t.flaggedByAi}' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: record.hasAbnormalLabs
          ? Icon(Icons.priority_high, color: theme.colorScheme.error, size: 20)
          : const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await ref
            .read(recordActivityRepositoryProvider)
            .setRead(record.id, read: true);
        if (!context.mounted) return;
        if (result.isErr) showMutationFeedback(context, result);
        ref.invalidate(recordPatientReadIdsProvider(record.patientId));
        await context.push<void>(AppRoutes.patientRecord(record.id));
      },
    );
  }
}

class _VitalsTile extends ConsumerWidget {
  const _VitalsTile({required this.vitals});

  final Vitals vitals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (vitals.hasBloodPressure) 'BP ${vitals.systolic}/${vitals.diastolic}',
      if (vitals.heartRate != null) 'HR ${vitals.heartRate}',
      if (vitals.weightKg != null) '${vitals.weightKg}kg',
      if (vitals.glucose != null) 'Glu ${vitals.glucose}',
    ];
    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: Text(AppLocalizations.of(context)!.vitalsRecordedTitle),
      subtitle: Text(
        '${fmtDate(vitals.recordedAt)} · ${parts.join('  ')}',
        style: theme.textTheme.bodySmall,
      ),
      onTap: ref.watch(selectedRecordsPatientProvider) == null
          ? () => context.go(AppRoutes.patientVitals)
          : null,
    );
  }
}
