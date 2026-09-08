/// Radiology / imaging results (P10-03): the patient's imaging studies, each
/// openable in full and exportable as a one-page report PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
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

    final list = imaging.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: 'Could not load your imaging results.',
        onRetry: () => ref.invalidate(patientImagingProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
            icon: Icons.image_outlined,
            message:
                'No imaging results yet.\nX-rays, scans and ultrasounds '
                'show up here after a study.',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imaging'),
        actions: const [PatientTopActions()],
      ),
      body: list,
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

    return AppCard(
      onTap: () => context.push(AppRoutes.patientRecord(record.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: Radii.chip,
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: theme.textTheme.titleSmall),
                    Text(
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
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: DocumentDownloadButton(
              label: 'Report PDF',
              filename: 'radiology-${_slug(record.title)}.pdf',
              build: () => buildRadiologyReport(ref, record),
            ),
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
