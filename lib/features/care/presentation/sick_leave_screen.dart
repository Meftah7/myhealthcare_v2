/// Sick-leave certificates the patient's doctors have issued (P10-05).
/// Read-only — each row exports to a PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../../records/application/records_providers.dart';
import '../application/care_providers.dart';

class SickLeaveScreen extends ConsumerWidget {
  const SickLeaveScreen({this.patientId, super.key});
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final certs = patientId == null
        ? ref.watch(patientSickLeaveProvider)
        : ref.watch(_subjectSickLeaveProvider(patientId!));
    final profile =
        patientId == null || patientId == ref.watch(currentUserProvider)?.id
        ? ref.watch(patientProfileProvider)
        : ref.watch(linkedPatientProvider(patientId!));
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: t.quickActionSickLeave,
      actions: const [PatientTopActions()],
      body: certs.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadCertificates,
          onRetry: () => ref.invalidate(patientSickLeaveProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.event_busy_outlined,
              message: t.noSickLeaveCertificatesMessage,
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
                  subjectName: profile.valueOrNull?.fullName,
                  doctorName: doctors[list[i].issuedByStaffId]?.name,
                ),
              ),
            ),
          );
        },
      ),
      centerBody: false,
    );
  }
}

class _CertCard extends ConsumerWidget {
  const _CertCard({required this.cert, this.doctorName, this.subjectName});

  final SickLeaveCertificate cert;
  final String? doctorName;
  final String? subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subjectName != null) Text('${t.importForLabel}: $subjectName'),
          Row(
            children: [
              Expanded(
                child: ReadableLabel(
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
                    t.activeChip,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.clinicalStatus.riskLow.onContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            t.dateRangeDays(
              fmtDate(cert.fromDate),
              fmtDate(cert.toDate),
              cert.days,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${t.issuedOn(fmtDate(cert.issuedAt))}'
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
            alignment: AlignmentDirectional.centerStart,
            child: DocumentDownloadButton(
              label: t.certificatePdfLabel,
              filename: 'sick-leave-${fmtDate(cert.fromDate)}.pdf',
              build: () => buildSickLeave(ref, cert),
            ),
          ),
        ],
      ),
    );
  }
}

final _subjectSickLeaveProvider =
    FutureProvider.family<List<SickLeaveCertificate>, String>(
      (ref, id) async => recordValue(
        await ref.watch(sickLeaveRepositoryProvider).forPatient(id),
      ),
    );
