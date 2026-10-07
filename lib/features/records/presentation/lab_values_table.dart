/// A lab result's values: each flagged against its reference range, with a
/// one-sided or missing range shown as it really is — a value without a
/// range reads "No range", never "Normal" (Phase 4).
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';

/// The reference range as printed: `3.5–5.0`, `< 5.2`, `> 60`, or null.
String? labReferenceText(LabValue v) {
  final low = v.refLow;
  final high = v.refHigh;
  if (low != null && high != null) return '$low–$high';
  if (high != null) return '< $high';
  if (low != null) return '> $low';
  return null;
}

class LabValuesTable extends StatelessWidget {
  const LabValuesTable({
    required this.labs,
    this.showProvenance = false,
    this.clinicianNames = const {},
    super.key,
  });

  final List<LabValue> labs;

  /// Staff view: add where each value came from and who verified it.
  final bool showProvenance;
  final Map<String, String> clinicianNames;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wideTable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(t.labColumnAnalyte)),
          DataColumn(label: Text(t.labColumnValue)),
          DataColumn(label: Text(t.labColumnReference)),
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
                    referenceText: labReferenceText(v),
                  ),
                ),
                DataCell(Text(labReferenceText(v) ?? t.abnormalFlagUnknown)),
              ],
            ),
        ],
      ),
    );
    final table = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) return wideTable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final v in labs)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.analyte, style: theme.textTheme.titleSmall),
                      const SizedBox(height: Space.xs),
                      AbnormalValueIndicator(
                        flag: v.abnormalFlag,
                        valueText:
                            '${v.value}${v.unit == null ? '' : ' ${v.unit}'}',
                        referenceText: labReferenceText(v),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        '${t.labColumnReference}: ${labReferenceText(v) ?? t.abnormalFlagUnknown}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
    final hasUnknown = labs.any((v) => labReferenceText(v) == null);
    if (!showProvenance && !hasUnknown) return table;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        table,
        if (hasUnknown)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(
              t.labValueUnknownRangeHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (showProvenance)
          for (final v in labs)
            Padding(
              padding: const EdgeInsets.only(top: Space.xxs),
              child: Text(
                [
                  v.analyte,
                  if (v.source != null) t.labSourceLabel(v.source!),
                  if (v.verificationStatus == VerificationStatus.unverified)
                    t.labUnverified
                  else
                    t.labVerifiedBy(
                      clinicianNames[v.verifiedByStaffId] ??
                          v.verifiedByStaffId ??
                          '—',
                    ),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
      ],
    );
  }
}
