import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/application/patient_data_providers.dart';
import '../application/records_providers.dart';

Future<void> showRecordFilters(BuildContext context, String patientId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecordFilters(patientId: patientId),
    );

class _RecordFilters extends ConsumerWidget {
  const _RecordFilters({required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final provider = recordFiltersProvider(patientId);
    final f = ref.watch(provider);
    void update(RecordsFilter next) => ref.read(provider.notifier).state = next;
    final history = ref.watch(recordsHistoryProvider).valueOrNull ?? [];
    final facilities = {
      for (final r in history)
        if (r.sourceFacility != null) r.sourceFacility!,
    }.toList()..sort();
    final authors = {
      for (final r in history)
        if (r.authorStaffId != null) r.authorStaffId!,
    }.toList()..sort();
    final names = ref.watch(doctorDirectoryProvider).valueOrNull ?? {};
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          Space.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.recordsFilters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                f.from == null
                    ? t.recordsDateRange
                    : '${fmtDate(f.from!)} – ${fmtDate(f.to!)}',
              ),
              onPressed: () async {
                final dates = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  initialDateRange: f.from == null
                      ? null
                      : DateTimeRange(start: f.from!, end: f.to!),
                );
                if (dates != null && context.mounted) {
                  update(f.copyWith(from: dates.start, to: dates.end));
                }
              },
            ),
            if (f.from != null)
              TextButton(
                onPressed: () => update(f.copyWith(clearDates: true)),
                child: Text(t.recordsClearDates),
              ),
            DropdownButtonFormField<String>(
              key: ValueKey('facility-${f.facility}'),
              initialValue: facilities.contains(f.facility) ? f.facility : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.recordsFacility),
              items: [
                DropdownMenuItem(value: '', child: Text(t.recordsAny)),
                for (final name in facilities)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (v) =>
                  update(f.copyWith(facility: v, clearFacility: v == '')),
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<String>(
              key: ValueKey('author-${f.authorId}'),
              initialValue: authors.contains(f.authorId) ? f.authorId : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.recordsAuthor),
              items: [
                DropdownMenuItem(value: '', child: Text(t.recordsAny)),
                for (final id in authors)
                  DropdownMenuItem(
                    value: id,
                    child: Text(names[id]?.name ?? t.recordsUnknownAuthor),
                  ),
              ],
              onChanged: (v) =>
                  update(f.copyWith(authorId: v, clearAuthor: v == '')),
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<String>(
              key: ValueKey('review-${f.review}'),
              initialValue: f.review?.name ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: t.recordsReviewState),
              items: [
                DropdownMenuItem(value: '', child: Text(t.recordsAny)),
                for (final status in ImportReviewStatus.values)
                  DropdownMenuItem(
                    value: status.name,
                    child: Text(recordReviewLabel(t, status)),
                  ),
              ],
              onChanged: (v) => update(
                f.copyWith(
                  review: v == '' ? null : ImportReviewStatus.values.byName(v!),
                  clearReview: v == '',
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final type in RecordType.values)
                  FilterChip(
                    label: Text(type.label(context)),
                    selected: f.types.contains(type),
                    onSelected: (on) {
                      final types = {...f.types};
                      on ? types.add(type) : types.remove(type);
                      update(f.copyWith(types: types));
                    },
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.recordsUnreadOnly),
              value: f.unreadOnly,
              onChanged: (v) => update(f.copyWith(unreadOnly: v)),
            ),
            TextButton(
              onPressed: () => update(const RecordsFilter()),
              child: Text(t.recordsClearFilters),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.recordsApplyFilters),
            ),
          ],
        ),
      ),
    );
  }
}

String recordReviewLabel(AppLocalizations t, ImportReviewStatus status) =>
    switch (status) {
      ImportReviewStatus.pendingReview => t.importStatusPending,
      ImportReviewStatus.reviewed => t.importStatusReviewed,
      ImportReviewStatus.rejected => t.importStatusRejected,
      ImportReviewStatus.notRequired => t.recordsReviewNotRequired,
    };
