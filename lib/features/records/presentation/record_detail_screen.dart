/// Record detail (P2-10). Labs render as a table with abnormal values flagged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';

final recordDetailProvider = FutureProvider.family<MedicalRecord, String>((
  ref,
  id,
) async {
  final result = await ref.watch(recordRepositoryProvider).byId(id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final record = ref.watch(recordDetailProvider(recordId));

    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: record.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load this record.',
          onRetry: () => ref.invalidate(recordDetailProvider(recordId)),
        ),
        data: (r) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                Space.xxl,
              ),
              children: [
                Text(r.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: Space.xs),
                Text(
                  '${r.recordType.name} · ${fmtDate(r.occurredAt)}'
                  '${r.sourceFacility == null ? '' : ' · ${r.sourceFacility}'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (r.body != null) ...[
                  const SizedBox(height: Space.md),
                  AppCard(
                    child: Text(r.body!, style: theme.textTheme.bodyLarge),
                  ),
                ],
                if (r.labValues.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  const SectionHeader('Results', overline: true),
                  AppCard(child: _LabTable(labs: r.labValues)),
                ],
                if (r.extractedText != null) ...[
                  const SizedBox(height: Space.md),
                  const SectionHeader('Extracted text', overline: true),
                  AppCard(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      r.extractedText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabTable extends StatelessWidget {
  const _LabTable({required this.labs});

  final List<LabValue> labs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Analyte')),
          DataColumn(label: Text('Value')),
          DataColumn(label: Text('Reference')),
        ],
        rows: [
          for (final v in labs)
            DataRow(
              cells: [
                DataCell(Text(v.analyte)),
                DataCell(
                  AbnormalValueIndicator(
                    flag: v.abnormalFlag,
                    valueText:
                        '${v.value}${v.unit == null ? '' : ' ${v.unit}'}',
                    referenceText: v.refLow != null && v.refHigh != null
                        ? '${v.refLow}–${v.refHigh}'
                        : null,
                  ),
                ),
                DataCell(
                  Text(
                    v.refLow != null && v.refHigh != null
                        ? '${v.refLow}–${v.refHigh}'
                        : '—',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
