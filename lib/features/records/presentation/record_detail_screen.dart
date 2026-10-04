/// Record detail (P2-10). Labs render as a table with abnormal values flagged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import 'lab_values_table.dart';

final recordDetailProvider = FutureProvider.family<MedicalRecord, String>((
  ref,
  id,
) async {
  final result = await ref.watch(recordRepositoryProvider).byId(id);
  return switch (result) {
    Ok(:final value)
        when value.patientId == ref.watch(currentUserProvider)?.id =>
      value,
    Ok() => throw const AuthFailure('You cannot access this record.'),
    Err(:final failure) => throw failure,
  };
});

class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({required this.recordId, super.key});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final record = ref.watch(recordDetailProvider(recordId));

    return AppScaffold(
      title: t.recordTitle,
      actions: const [PatientTopActions()],
      body: record.when(
        loading: () => const SkeletonList(),
        // Access loss explains the boundary instead of offering a retry
        // that can never succeed.
        error: (e, _) => e is AccessDeniedFailure
            ? ErrorStateView(message: t.accessDeniedBody)
            : ErrorStateView(
                message: t.couldNotLoadRecord,
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
                  '${r.recordType.label(context)} · ${fmtDate(r.occurredAt)}'
                  '${r.sourceFacility == null ? '' : ' · ${r.sourceFacility}'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (r.uploadedByPatient) ...[
                  const SizedBox(height: Space.sm),
                  InlineBanner.info(
                    AppLocalizations.of(context)!.uploadedByPatientNote,
                  ),
                  const SizedBox(height: Space.sm),
                  ImportProvenanceCard(record: r),
                ],
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    DocumentDownloadButton(
                      label: t.exportRecordAction,
                      filename: 'record-${r.id}.pdf',
                      build: () => buildRecordSummary(
                        ref,
                        r,
                        recordTypeLabel: r.recordType.label(context),
                      ),
                    ),
                    if (r.sourceDocument != null)
                      DocumentDownloadButton(
                        label: t.openOriginalAction,
                        filename: r.sourceDocument!.fileName,
                        icon: Icons.description_outlined,
                        build: () => openOriginalFile(ref, r),
                      ),
                  ],
                ),
                if (r.appointmentId case final visitId?) ...[
                  const SizedBox(height: Space.xs),
                  // Opens the visit, where everything from it is listed.
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push(
                      AppRoutes.patientAppointmentDetail(visitId),
                    ),
                    icon: const Icon(Icons.event_note_outlined, size: 18),
                    label: Text(t.fromYourVisitOn(fmtDate(r.occurredAt))),
                  ),
                ],
                if (r.body != null) ...[
                  const SizedBox(height: Space.md),
                  AppCard(
                    child: Text(r.body!, style: theme.textTheme.bodyLarge),
                  ),
                ],
                if (r.recordType == RecordType.referral &&
                    r.sourceFacility != null) ...[
                  const SizedBox(height: Space.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DocumentDownloadButton(
                      label: t.referralLetterLabel,
                      filename: 'referral-letter.pdf',
                      icon: Icons.forward_to_inbox_outlined,
                      build: () => buildReferralLetter(ref, r),
                    ),
                  ),
                ],
                if (r.labValues.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  SectionHeader(t.resultsSection, overline: true),
                  AppCard(child: LabValuesTable(labs: r.labValues)),
                ],
                if (r.extractedText != null) ...[
                  const SizedBox(height: Space.md),
                  SectionHeader(t.extractedTextSection, overline: true),
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
      centerBody: false,
    );
  }
}

/// Where an imported record came from — issuer, when it was imported, the
/// original file — and whether a clinician has reviewed it.
class ImportProvenanceCard extends StatelessWidget {
  const ImportProvenanceCard({required this.record, super.key});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final doc = record.sourceDocument;
    final (status, icon) = switch (record.reviewStatus) {
      ImportReviewStatus.pendingReview || ImportReviewStatus.notRequired => (
        t.importStatusPending,
        Icons.hourglass_top_outlined,
      ),
      ImportReviewStatus.reviewed => (
        t.importStatusReviewed,
        Icons.verified_outlined,
      ),
      ImportReviewStatus.rejected => (
        t.importStatusRejected,
        Icons.block_outlined,
      ),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.provenanceHeader, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: Space.xs),
              Expanded(child: Text(status)),
            ],
          ),
          if (record.reviewNote != null && record.reviewNote!.isNotEmpty)
            Text(record.reviewNote!, style: theme.textTheme.bodySmall),
          if (record.sourceFacility != null)
            Text(t.provenanceIssuer(record.sourceFacility!)),
          Text(t.provenanceImportedOn(fmtDate(record.createdAt))),
          if (doc != null)
            Text(
              t.provenanceFile(
                doc.fileName,
                '${(doc.sizeBytes / 1024).toStringAsFixed(0)} KB',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
