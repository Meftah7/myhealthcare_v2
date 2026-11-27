import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/data/contracts.dart';
import '../../../core/failures.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/export_repository.dart';
import '../../../domain/repositories/document_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../records/application/records_providers.dart';

final issuedDocumentsProvider = StreamProvider.autoDispose
    .family<List<IssuedDocument>, String>((ref, id) {
      ref.watch(currentUserProvider);
      return ref.watch(documentServiceProvider).watchForPatient(id);
    });

final patientLegacyDocumentsProvider = FutureProvider.autoDispose
    .family<
      ({List<SickLeaveCertificate> sickLeave, List<MedicalRecord> records}),
      String
    >((ref, patientId) async {
      final repository = ref.watch(recordRepositoryProvider);
      final sickLeaveResult = await ref
          .watch(sickLeaveRepositoryProvider)
          .forPatient(patientId);
      final sickLeave = switch (sickLeaveResult) {
        Err(failure: SharedModeUnavailableFailure()) =>
          const <SickLeaveCertificate>[],
        _ => recordValue(sickLeaveResult),
      };
      final records = <MedicalRecord>[];
      var offset = 0;
      while (true) {
        final result = await repository.timelinePage(
          patientId,
          page: PageRequest(offset: offset, size: PageLimits.maxSize),
          types: {
            RecordType.discharge,
            RecordType.referral,
            RecordType.prescription,
          },
        );
        if (result case Err(failure: SharedModeUnavailableFailure())) break;
        final page = recordValue(result);
        records.addAll(page.items.where((r) => !r.uploadedByPatient));
        if (!page.hasMore) break;
        offset += page.items.length;
      }
      return (sickLeave: sickLeave, records: records);
    });

/// The same patient-authorized document list is used by Documents and visits.
class IssuedDocumentsScreen extends ConsumerWidget {
  const IssuedDocumentsScreen({this.patientId, super.key});
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final subject = patientId ?? ref.watch(currentUserProvider)?.id ?? '';
    return AppScaffold(
      title: t.paDocuments,
      onRefresh: () async {
        ref.invalidate(issuedDocumentsProvider(subject));
        ref.invalidate(patientLegacyDocumentsProvider(subject));
      },
      children: [
        Text(t.paIssuedDocumentsIntro),
        const SizedBox(height: Space.md),
        PatientDocumentList(patientId: subject),
      ],
    );
  }
}

class PatientDocumentList extends ConsumerWidget {
  const PatientDocumentList({
    required this.patientId,
    this.appointmentId,
    this.completed = false,
    super.key,
  });

  final String patientId;
  final String? appointmentId;
  final bool completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final provider = issuedDocumentsProvider(patientId);
    final legacyProvider = patientLegacyDocumentsProvider(patientId);
    final legacy = ref.watch(legacyProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};
    return ref
        .watch(provider)
        .when(
          loading: () => const SkeletonList(lines: 2),
          error: (_, _) => ErrorStateView(
            message: t.paDocumentsLoadError,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (items) {
            final official = items.where(
              (d) => appointmentId == null || d.appointmentId == appointmentId,
            );
            final issuedIds = items.map((d) => d.id).toSet();
            final certificates =
                legacy.valueOrNull?.sickLeave.where(
                  (c) =>
                      !issuedIds.contains(c.id) &&
                      (appointmentId == null ||
                          c.appointmentId == appointmentId),
                ) ??
                [];
            final issuedSources = items.map((d) => d.sourceRecordId).toSet();
            final records =
                legacy.valueOrNull?.records.where(
                  (r) =>
                      !issuedSources.contains(r.id) &&
                      (appointmentId == null ||
                          r.appointmentId == appointmentId),
                ) ??
                [];
            final hasReport = official.any(
              (d) =>
                  (d.documentType == ExportDocument.completedVisitReport ||
                      d.documentType == ExportDocument.visitSummary) &&
                  d.validity == DocumentValidity.valid,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (completed && !hasReport) Text(t.visitReportUnavailable),
                if (!completed &&
                    appointmentId != null &&
                    legacy.hasValue &&
                    official.isEmpty &&
                    certificates.isEmpty &&
                    records.isEmpty)
                  Text(t.paNoIssuedDocuments),
                if (legacy.isLoading) const LinearProgressIndicator(),
                if (legacy.hasError)
                  ErrorStateView(
                    message: t.paDocumentsLoadError,
                    onRetry: () => ref.invalidate(legacyProvider),
                  ),
                if (appointmentId == null &&
                    legacy.hasValue &&
                    official.isEmpty &&
                    certificates.isEmpty &&
                    records.isEmpty)
                  PatientStateView(
                    kind: PatientStateKind.empty,
                    icon: Icons.description_outlined,
                    title: t.paNoIssuedDocuments,
                    message: t.paNoIssuedDocumentsBody,
                  ),
                for (final d in official) ...[
                  _IssuedDocumentCard(
                    document: d,
                    showAppointment: appointmentId == null,
                  ),
                  const SizedBox(height: Space.sm),
                ],
                for (final cert in certificates) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.paSickLeave,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(cert.diagnosis),
                        Text(
                          [
                            t.issuedOn(fmtDate(cert.issuedAt)),
                            ?doctors[cert.issuedByStaffId]?.name,
                          ].join(' · '),
                        ),
                        Text(
                          t.dateRangeDays(
                            fmtDate(cert.fromDate),
                            fmtDate(cert.toDate),
                            cert.days,
                          ),
                        ),
                        if (cert.appointmentId case final id?
                            when appointmentId == null)
                          TextButton(
                            onPressed: () => context.push(
                              AppRoutes.patientAppointmentDetail(id),
                            ),
                            child: Text(t.appointmentDetailTitle),
                          ),
                        DocumentDownloadButton(
                          label: t.certificatePdfLabel,
                          filename: 'sick-leave.pdf',
                          build: () => buildSickLeave(ref, cert),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                for (final record in records) ...[
                  SurfaceCard(
                    child: ListTile(
                      title: Text(record.title),
                      subtitle: Text(
                        [
                          switch (record.recordType) {
                            RecordType.referral => t.filterReferrals,
                            RecordType.prescription => t.filterPrescriptions,
                            _ => t.legacyDischargeReport,
                          },
                          fmtDate(record.occurredAt),
                          ?doctors[record.authorStaffId]?.name,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.description_outlined),
                      onTap: () =>
                          context.push(AppRoutes.patientRecord(record.id)),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ],
            );
          },
        );
  }
}

class _IssuedDocumentCard extends ConsumerWidget {
  const _IssuedDocumentCard({
    required this.document,
    required this.showAppointment,
  });
  final IssuedDocument document;
  final bool showAppointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final d = document;
    final ready =
        d.validity == DocumentValidity.valid &&
        d.renderStatus == DocumentRenderStatus.ready;
    final (
      String status,
      PatientAccent accent,
      IconData icon,
    ) = d.validity != DocumentValidity.valid
        ? (t.paDocRevoked, PatientAccent.red, Icons.block)
        : ready
        ? (t.paDocReady, PatientAccent.green, Icons.check_circle_outline)
        : (t.paDocNotReady, PatientAccent.amber, Icons.hourglass_empty);
    final filename = '${d.documentType.name}-${d.verificationCode}.pdf';
    Future<Uint8List> bytes() async =>
        switch (await ref.read(documentServiceProvider).download(d.id)) {
          Ok(:final value) => value,
          Err(:final failure) => throw failure,
        };
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(icon: Icons.verified_outlined),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DocumentRules.title(d.documentType, arabic: ar),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (d.issuedAt != null) fmtDate(d.issuedAt!.toLocal()),
                        ?d.issuerName,
                        d.language.toUpperCase(),
                        if (d.supersedesId != null) t.paDocReplacement,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.appointmentId case final id? when showAppointment)
            TextButton.icon(
              icon: const Icon(Icons.event_note_outlined),
              label: Text(
                d.appointmentDate == null
                    ? t.appointmentDetailTitle
                    : t.fromYourVisitOn(fmtDate(d.appointmentDate!.toLocal())),
              ),
              onPressed: () =>
                  context.push(AppRoutes.patientAppointmentDetail(id)),
            ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status, accent: accent, icon: icon),
              Text(
                t.paVerificationCode,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              SelectableText(
                d.verificationCode,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: palette.text,
                ),
              ),
            ],
          ),
          if (!ready && d.validity == DocumentValidity.valid) ...[
            const SizedBox(height: Space.xs),
            Text(
              d.documentType == ExportDocument.completedVisitReport &&
                      d.renderStatus == DocumentRenderStatus.failed
                  ? t.visitReportRenderFailed
                  : t.paDocNotReadyBody,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (!ready &&
              d.validity == DocumentValidity.valid &&
              d.documentType == ExportDocument.completedVisitReport)
            DocumentDownloadButton(
              filename: filename,
              label: d.renderStatus == DocumentRenderStatus.failed
                  ? t.tryAgain
                  : t.paViewDocument,
              icon: Icons.picture_as_pdf_outlined,
              build: () async {
                final service = ref.read(documentServiceProvider);
                recordValue(await service.render(d.id));
                ref.invalidate(issuedDocumentsProvider(d.patientId));
                return bytes();
              },
            ),
          if (ready) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                DocumentDownloadButton(
                  filename: filename,
                  label: t.paViewDocument,
                  icon: Icons.visibility_outlined,
                  build: bytes,
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await Printing.sharePdf(
                        bytes: await bytes(),
                        filename: filename,
                      );
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.paDocumentsLoadError)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: Text(t.paDownloadOriginal),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
