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
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/application/patient_data_providers.dart';

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

final _typeFilterProvider = StateProvider<Set<RecordType>>((_) => {});
final _queryProvider = StateProvider<String>((_) => '');
final _showVitalsProvider = StateProvider<bool>((_) => true);

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(patientTimelineProvider);
    final vitals = ref.watch(patientVitalsProvider);
    final types = ref.watch(_typeFilterProvider);
    final query = ref.watch(_queryProvider).trim().toLowerCase();
    final showVitals = ref.watch(_showVitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health timeline'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: _Filters(),
        ),
      ),
      body: records.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your timeline.',
          onRetry: () => ref.invalidate(patientTimelineProvider),
        ),
        data: (recs) {
          final entries = <_Entry>[
            for (final r in recs)
              if (_matchesRecord(r, types, query)) _RecordEntry(r),
            if (showVitals && query.isEmpty && types.isEmpty)
              for (final v in vitals.valueOrNull ?? const <Vitals>[])
                _VitalsEntry(v),
          ]..sort((a, b) => b.at.compareTo(a.at));

          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.timeline_outlined,
              message: 'Nothing matches these filters yet.',
            );
          }
          return _GroupedList(entries: entries);
        },
      ),
    );
  }

  static bool _matchesRecord(
    MedicalRecord r,
    Set<RecordType> types,
    String query,
  ) {
    if (types.isNotEmpty && !types.contains(r.recordType)) return false;
    if (query.isEmpty) return true;
    return r.title.toLowerCase().contains(query) ||
        (r.body?.toLowerCase().contains(query) ?? false) ||
        r.labValues.any((v) => v.analyte.toLowerCase().contains(query));
  }
}

class _Filters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(_typeFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
      child: Column(
        children: [
          SearchBar(
            hintText: 'Search records',
            leading: const Icon(Icons.search),
            onChanged: (v) => ref.read(_queryProvider.notifier).state = v,
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in RecordType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: FilterChip(
                      label: Text(_label(t)),
                      selected: types.contains(t),
                      onSelected: (on) {
                        final next = {...types};
                        on ? next.add(t) : next.remove(t);
                        ref.read(_typeFilterProvider.notifier).state = next;
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

  static String _label(RecordType t) => switch (t) {
    RecordType.visitNote => 'Visits',
    RecordType.labResult => 'Labs',
    RecordType.imaging => 'Imaging',
    RecordType.prescription => 'Prescriptions',
    RecordType.vaccination => 'Vaccinations',
    RecordType.discharge => 'Discharge',
    RecordType.referral => 'Referrals',
  };
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Build a flat list with month headers.
    final items = <Widget>[];
    String? currentMonth;
    for (final e in entries) {
      final month = fmtMonthYear(e.at);
      if (month != currentMonth) {
        currentMonth = month;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.lg,
              Space.lg,
              Space.xs,
            ),
            child: Text(month, style: theme.textTheme.titleSmall),
          ),
        );
      }
      items.add(switch (e) {
        _RecordEntry(:final record) => _RecordTile(record: record),
        _VitalsEntry(:final vitals) => _VitalsTile(vitals: vitals),
      });
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final MedicalRecord record;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(_icon),
      title: Text(record.title),
      subtitle: Text(
        '${fmtDate(record.occurredAt)}'
        '${record.sourceFacility == null ? '' : ' · ${record.sourceFacility}'}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: record.hasAbnormalLabs
          ? Icon(Icons.priority_high, color: theme.colorScheme.error, size: 20)
          : const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.patientRecord(record.id)),
    );
  }
}

class _VitalsTile extends StatelessWidget {
  const _VitalsTile({required this.vitals});

  final Vitals vitals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (vitals.hasBloodPressure) 'BP ${vitals.systolic}/${vitals.diastolic}',
      if (vitals.heartRate != null) 'HR ${vitals.heartRate}',
      if (vitals.weightKg != null) '${vitals.weightKg}kg',
      if (vitals.glucose != null) 'Glu ${vitals.glucose}',
    ];
    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: const Text('Vitals recorded'),
      subtitle: Text(
        '${fmtDate(vitals.recordedAt)} · ${parts.join('  ')}',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => context.go(AppRoutes.patientVitals),
    );
  }
}
