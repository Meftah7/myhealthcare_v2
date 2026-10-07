/// Record detail (P2-10). Labs render as a table with abnormal values flagged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/clinical/lab_history.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/records_providers.dart';
import 'lab_values_table.dart';
import 'record_activity_panel.dart';
import 'record_filters_sheet.dart';

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
                _RecordSubject(patientId: r.patientId),
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
                  ImportProvenanceCard(record: r, showReview: false),
                ],
                const SizedBox(height: Space.sm),
                SectionHeader(t.recordsOriginals, overline: true),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    if (r.sourceDocument != null)
                      DocumentDownloadButton(
                        label: t.openOriginalAction,
                        filename: r.sourceDocument!.fileName,
                        icon: Icons.description_outlined,
                        build: () => openOriginalFile(ref, r),
                      ),
                  ],
                ),
                if (r.sourceDocument == null) Text(t.recordsNoOriginal),
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
                SectionHeader(t.recordsRecordedInformation, overline: true),
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
                  _LabHistory(recordId: r.id),
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
                SectionHeader(t.recordsClinicalReview, overline: true),
                _ClinicalReview(record: r),
                SectionHeader(t.recordsGeneratedSummary, overline: true),
                Text(t.recordsGeneratedNotice),
                DocumentDownloadButton(
                  label: t.exportRecordAction,
                  filename: 'record-${r.id}.pdf',
                  build: () => buildRecordSummary(
                    ref,
                    r,
                    recordTypeLabel: r.recordType.label(context),
                  ),
                ),
                const SizedBox(height: Space.md),
                RecordActivityPanel(record: r),
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
  const ImportProvenanceCard({
    required this.record,
    this.showReview = true,
    super.key,
  });

  final MedicalRecord record;
  final bool showReview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final doc = record.sourceDocument;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.provenanceHeader, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          if (showReview) ...[
            Text(recordReviewLabel(t, record.reviewStatus)),
            if (record.reviewNote != null) Text(record.reviewNote!),
          ],
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

class _RecordSubject extends ConsumerWidget {
  const _RecordSubject({required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final profile = patientId == ref.watch(currentUserProvider)?.id
        ? ref.watch(patientProfileProvider)
        : ref.watch(linkedPatientProvider(patientId));
    return profile.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text(t.recordsSubjectUnavailable),
      data: (p) => Text('${t.importForLabel}: ${p.fullName}'),
    );
  }
}

class _ClinicalReview extends ConsumerWidget {
  const _ClinicalReview({required this.record});
  final MedicalRecord record;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final names = ref.watch(doctorDirectoryProvider).valueOrNull ?? {};
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recordReviewLabel(t, record.reviewStatus)),
          if (record.reviewedByStaffId != null)
            Text(
              names[record.reviewedByStaffId]?.name ?? t.recordsUnknownAuthor,
            ),
          if (record.reviewedAt != null) Text(fmtDate(record.reviewedAt!)),
          if (record.reviewNote != null) Text(record.reviewNote!),
        ],
      ),
    );
  }
}

final _labHistoryProvider =
    FutureProvider.family<Map<String, LabObservation>, String>((ref, id) async {
      final record = await ref.watch(recordDetailProvider(id).future);
      final repo = ref.watch(recordRepositoryProvider);
      var request = const PageRequest(size: PageLimits.maxSize);
      final history = <MedicalRecord>[];
      while (true) {
        final page = recordValue(
          await repo.timelinePage(record.patientId, page: request),
        );
        history.addAll(page.items);
        if (!page.hasMore) break;
        request = request.next;
      }
      return comparableLabHistory(record, history);
    });

class _LabHistory extends ConsumerWidget {
  const _LabHistory({required this.recordId});
  final String recordId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final record = ref.watch(recordDetailProvider(recordId)).requireValue;
    return ref
        .watch(_labHistoryProvider(recordId))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(_labHistoryProvider(recordId)),
            child: Text(t.recordsTrendsUnavailable),
          ),
          data: (previous) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final lab in record.labValues)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    previous[labHistoryKey(lab)] != null
                        ? '${lab.analyte} – ${t.recordsPreviousResult}: ${previous[labHistoryKey(lab)]!.value} ${previous[labHistoryKey(lab)]!.unit} (${fmtDate(previous[labHistoryKey(lab)]!.at)})'
                        : '${lab.analyte}: ${t.recordsNoComparableResult}',
                  ),
                ),
            ],
          ),
        );
  }
}
