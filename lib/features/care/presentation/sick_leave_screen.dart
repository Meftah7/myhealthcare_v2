/// Sick-leave certificates the patient's doctors have issued (P10-05).
/// Read-only — each row exports to a PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/care_providers.dart';

class SickLeaveScreen extends ConsumerWidget {
  const SickLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certs = ref.watch(patientSickLeaveProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sick leave'),
        actions: const [PatientTopActions()],
      ),
      body: certs.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your certificates.',
          onRetry: () => ref.invalidate(patientSickLeaveProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.event_busy_outlined,
              message: 'No sick-leave certificates.\nYour doctor can issue one '
                  'after a visit.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) => _CertCard(
                  cert: list[i],
                  doctorName: doctors[list[i].issuedByStaffId]?.name,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CertCard extends ConsumerWidget {
  const _CertCard({required this.cert, this.doctorName});

  final SickLeaveCertificate cert;
  final String? doctorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cert.diagnosis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (cert.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.clinicalStatus.riskLow.container,
                    borderRadius: Radii.pill,
                  ),
                  child: Text(
                    'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.clinicalStatus.riskLow.onContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            '${fmtDate(cert.fromDate)} – ${fmtDate(cert.toDate)}  ·  '
            '${cert.days} day${cert.days == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Issued ${fmtDate(cert.issuedAt)}'
            '${doctorName == null ? '' : ' · $doctorName'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (cert.notes != null && cert.notes!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(cert.notes!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: DocumentDownloadButton(
              label: 'Certificate PDF',
              filename: 'sick-leave-${fmtDate(cert.fromDate)}.pdf',
              build: () => buildSickLeave(ref, cert),
            ),
          ),
        ],
      ),
    );
  }
}
