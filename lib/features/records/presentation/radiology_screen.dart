/// Radiology / imaging results (P10-03): the patient's imaging studies, each
/// openable in full and exportable as a one-page report PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';

class RadiologyScreen extends ConsumerWidget {
  const RadiologyScreen({this.embedded = false, super.key});

  /// Rendered inside the Records screen (no Scaffold of its own) vs. as its
  /// own page.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imaging = ref.watch(patientImagingProvider);
    final t = AppLocalizations.of(context)!;

    final list = imaging.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadImaging,
        onRetry: () => ref.invalidate(patientImagingProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return EmptyState(
            icon: Icons.image_outlined,
            message: t.noImagingResultsYet,
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                Space.xxl,
              ),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) => _ImagingCard(record: records[i]),
            ),
          ),
        );
      },
    );

    if (embedded) return list;

    return AppScaffold(
      title: t.imagingTitle,
      actions: const [PatientTopActions()],
      body: list,
      centerBody: false,
    );
  }
}

class _ImagingCard extends ConsumerWidget {
  const _ImagingCard({required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SurfaceCard(
      onTap: () => context.push(AppRoutes.patientRecord(record.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(
                icon: Icons.image_outlined,
                accent: PatientAccent.amber,
                size: 44,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReadableLabel(
                      record.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ReadableLabel(
                      '${fmtDate(record.occurredAt)}'
                      '${record.sourceFacility == null ? '' : ' · ${record.sourceFacility}'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((record.body ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(
              record.body!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              DocumentDownloadButton(
                label: AppLocalizations.of(context)!.reportPdfLabel,
                filename: 'radiology-${_slug(record.title)}.pdf',
                build: () => buildRadiologyReport(ref, record),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.patientRecord(record.id)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(AppLocalizations.of(context)!.paOpenAction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}
