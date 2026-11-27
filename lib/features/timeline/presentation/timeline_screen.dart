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
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_summary/application/ai_summary_provider.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../records/application/records_providers.dart';

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
  String get key;
}

class _RecordEntry extends _Entry {
  _RecordEntry(this.record);
  final MedicalRecord record;
  @override
  DateTime get at => record.occurredAt;
  @override
  String get key => 'record:${record.id}';
}

class _VitalsEntry extends _Entry {
  _VitalsEntry(this.vitals);
  final Vitals vitals;
  @override
  DateTime get at => vitals.recordedAt;
  @override
  String get key => 'vitals:${vitals.id}';
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({
    this.embedded = false,
    this.header,
    this.onRefresh,
    super.key,
  });

  /// When true, render the filters + feed without a Scaffold/AppBar — the
  /// Health Records screen supplies those.
  final bool embedded;
  final Widget? header;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  GoRouter? _router;
  bool _open = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == _router) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = router;
    _router?.routerDelegate.addListener(_onRouteChanged);
    if (router != null) _resetFilters();
    _onRouteChanged();
  }

  void _onRouteChanged() {
    final uri = _router?.routerDelegate.currentConfiguration.uri;
    final path = uri?.path;
    final open =
        (path == AppRoutes.patientTimeline &&
            uri?.queryParameters['view'] != 'medications') ||
        (path?.startsWith('${AppRoutes.patientTimeline}/') ?? false);
    if (_open && !open) _resetFilters();
    _open = open;
  }

  void _resetFilters() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(recordFiltersProvider);
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final records = ref.watch(recordsHistoryProvider);
    final vitals = ref.watch(recordsVitalsProvider);
    final subject = ref.watch(recordsPatientIdProvider);
    final filter = ref.watch(recordFiltersProvider(subject));
    final readState = ref.watch(recordReadIdsProvider);
    final names = ref.watch(doctorDirectoryProvider).valueOrNull ?? {};
    final feed = records.when(
      loading: () => SkeletonList(lines: widget.embedded ? 3 : 5),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadRecords,
        onRetry: () {
          ref.invalidate(patientTimelinePageProvider);
          ref.invalidate(linkedTimelinePageProvider(subject));
          ref.invalidate(recordsHistoryProvider);
        },
      ),
      data: (recs) {
        final entries =
            <_Entry>[
              for (final r in recs)
                if (filter.matches(r, authorName: names[r.authorStaffId]?.name))
                  _RecordEntry(r),
              if (filter.includesVitals)
                for (final v in vitals.valueOrNull ?? const <Vitals>[])
                  _VitalsEntry(v),
            ]..sort((a, b) {
              final date = filter.compareDates(a.at, b.at);
              return date == 0 ? a.key.compareTo(b.key) : date;
            });

        if (entries.isEmpty) {
          return ListView(
            children: [
              EmptyState(
                icon: Icons.timeline_outlined,
                message: t.nothingMatchesFilters,
              ),
            ],
          );
        }
        final fallbackDates = <String, DateTime>{};
        void rememberVisit(String? id, DateTime at) {
          if (id == null) return;
          final previous = fallbackDates[id];
          if (previous == null || at.isBefore(previous)) fallbackDates[id] = at;
        }

        for (final record in recs) {
          rememberVisit(record.appointmentId, record.occurredAt);
        }
        for (final measurement in vitals.valueOrNull ?? const <Vitals>[]) {
          rememberVisit(measurement.appointmentId, measurement.recordedAt);
        }
        final visitDates = fallbackDates.isEmpty
            ? const <String, DateTime>{}
            : ref.watch(recordsVisitDatesProvider).valueOrNull ??
                  const <String, DateTime>{};
        return _GroupedList(
          entries: entries,
          filter: filter,
          visitDates: {...fallbackDates, ...visitDates},
        );
      },
    );

    final content = ScrollableHeaderBody(
      header: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: _Filters(key: ValueKey(subject)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            widget.onRefresh ??
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
        ?widget.header,
        Expanded(child: content),
      ],
    );
    if (widget.embedded) return workspace;

    return AppScaffold(
      title: t.recordsTitle,
      body: workspace,
      centerBody: false,
    );
  }
}

class _Filters extends ConsumerStatefulWidget {
  const _Filters({super.key});

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
    void update(RecordsFilter next) => ref.read(provider.notifier).state = next;
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(
              Uri(
                path: AppRoutes.patientDocuments,
                queryParameters: {'patientId': subject},
              ).toString(),
            ),
            icon: const Icon(Icons.description_outlined),
            label: ReadableLabel(t.paDocuments),
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _search,
                  hintText: t.searchRecordsHint,
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    PatientPalette.of(context).card,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: PatientPalette.of(context).divider),
                  ),
                  trailing: [
                    if (filter.query.isNotEmpty)
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        icon: const Icon(Icons.close),
                        onPressed: () => update(
                          RecordsFilter(oldestFirst: filter.oldestFirst),
                        ),
                      ),
                  ],
                  onChanged: (value) => update(
                    RecordsFilter(
                      query: value,
                      oldestFirst: filter.oldestFirst,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
              PopupMenuButton<bool>(
                tooltip: t.recordsSortFilter,
                initialValue: filter.oldestFirst,
                onSelected: (value) => update(
                  RecordsFilter(query: filter.query, oldestFirst: value),
                ),
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(
                    value: false,
                    checked: !filter.oldestFirst,
                    child: Text(t.recordsNewestFirst),
                  ),
                  CheckedPopupMenuItem(
                    value: true,
                    checked: filter.oldestFirst,
                    child: Text(t.recordsOldestFirst),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Space.sm,
                    horizontal: Space.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: Space.xxs),
                      Text(t.recordsSortFilter),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends ConsumerWidget {
  const _GroupedList({
    required this.entries,
    required this.filter,
    required this.visitDates,
  });

  final List<_Entry> entries;
  final RecordsFilter filter;
  final Map<String, DateTime> visitDates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final keyEventIds = ref.watch(selectedRecordsPatientProvider) == null
        ? ref.watch(_keyEventRecordIdsProvider)
        : <String>{};
    // Build a flat list with month headers.
    final items = <Widget>[];
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
    // One rounded card per month; visit groups are linked sub-headers.
    final palette = PatientPalette.of(context);
    final months = <String, List<Widget>>{};
    final groups = <(bool, String), List<_Entry>>{};
    for (final entry in entries) {
      final visit = visitOf(entry);
      (groups[(visit != null, visit ?? entry.key)] ??= []).add(entry);
    }
    DateTime groupDate(List<_Entry> group) =>
        visitDates[visitOf(group.first)] ?? group.first.at;
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final byDate = filter.compareDates(
          groupDate(a.value),
          groupDate(b.value),
        );
        return byDate != 0 ? byDate : a.key.$2.compareTo(b.key.$2);
      });
    for (final group in sorted) {
      final e = group.value.first;
      final visit = visitOf(e);
      final date = groupDate(group.value);
      final rows = months.putIfAbsent(fmtMonthYear(date), () => []);
      if (visit == null) {
        rows.add(tile(e));
      } else {
        rows.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.patientAppointmentDetail(visit)),
              icon: const Icon(Icons.event_note_outlined),
              label: Text(
                AppLocalizations.of(context)!.fromYourVisitOn(fmtDate(date)),
              ),
            ),
          ),
        );
        rows.addAll(group.value.map(tile));
      }
    }
    for (final MapEntry(key: month, value: rows) in months.entries) {
      items
        ..add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md + Space.xxs,
              Space.lg,
              Space.md,
              Space.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                month,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        )
        ..add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Column(
                children: [
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0)
                      Divider(
                        indent: Space.md,
                        endIndent: Space.md,
                        color: palette.divider,
                      ),
                    row,
                  ],
                ],
              ),
            ),
          ),
        );
    }
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
    final palette = PatientPalette.of(context);
    final readIds = ref.watch(recordReadIdsProvider).valueOrNull;
    final author = record.authorStaffId == null
        ? null
        : ref
                  .watch(doctorDirectoryProvider)
                  .valueOrNull?[record.authorStaffId]
                  ?.name ??
              t.recordsUnknownAuthor;
    final meta = [
      fmtDate(record.occurredAt),
      record.recordType.label(context),
      ?author,
      ?record.sourceFacility,
    ].join(' · ');
    final accent = switch (record.recordType) {
      RecordType.labResult => PatientAccent.green,
      RecordType.imaging || RecordType.referral => PatientAccent.amber,
      RecordType.discharge => PatientAccent.red,
      _ => PatientAccent.blue,
    };
    return InkWell(
      onTap: () async {
        final result = await ref
            .read(recordActivityRepositoryProvider)
            .setRead(record.id, read: true);
        if (!context.mounted) return;
        if (result.isErr) showMutationFeedback(context, result);
        ref.invalidate(recordPatientReadIdsProvider(record.patientId));
        await context.push<void>(AppRoutes.patientRecord(record.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconTile(icon: _icon, accent: accent, size: 44),
                if (isKeyEvent)
                  PositionedDirectional(
                    end: -4,
                    top: -4,
                    child: Icon(Icons.star, size: 14, color: palette.link),
                  ),
              ],
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  // Status as readable labels, never colour alone.
                  Wrap(
                    spacing: Space.xxs,
                    runSpacing: Space.xxs,
                    children: [
                      if (readIds != null && !readIds.contains(record.id))
                        StatusBadge(
                          t.recordsUnread,
                          accent: PatientAccent.blue,
                          icon: Icons.fiber_manual_record,
                        ),
                      if (record.hasAbnormalLabs)
                        StatusBadge(
                          t.paOutOfRange,
                          accent: PatientAccent.red,
                          icon: Icons.priority_high,
                        ),
                      if (record.uploadedByPatient)
                        StatusBadge(t.uploadedByPatientTag),
                      StatusBadge(recordReviewLabel(t, record.reviewStatus)),
                      if (isKeyEvent)
                        StatusBadge(
                          t.flaggedByAi,
                          accent: PatientAccent.amber,
                          icon: Icons.star,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
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
    final palette = PatientPalette.of(context);
    final onTap = ref.watch(selectedRecordsPatientProvider) == null
        ? () => context.go(AppRoutes.patientVitals)
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            const IconTile(
              icon: Icons.monitor_heart_outlined,
              accent: PatientAccent.green,
              size: 44,
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.vitalsRecordedTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fmtDate(vitals.recordedAt)} · ${parts.join('  ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: palette.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
