/// Record detail (P2-10). Labs render as a table with abnormal values flagged.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

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
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/clinical/lab_history.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_chat/application/care_navigator.dart';
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
                kPatientInset,
                Space.sm,
                kPatientInset,
                Space.xxl,
              ),
              children: [
                _RecordHeaderCard(record: r),
                if (r.uploadedByPatient) ...[
                  const SizedBox(height: Space.sm),
                  InlineBanner.info(
                    AppLocalizations.of(context)!.uploadedByPatientNote,
                  ),
                  const SizedBox(height: Space.sm),
                  ImportProvenanceCard(record: r, showReview: false),
                ],
                SectionHeading(t.recordsOriginals),
                _OriginalCard(record: r),
                if (r.appointmentId case final visitId?)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.patientAppointmentDetail(visitId),
                      ),
                      icon: const Icon(Icons.event_note_outlined, size: 18),
                      label: Text(t.fromYourVisitOn(fmtDate(r.occurredAt))),
                    ),
                  ),
                if (r.body != null ||
                    (r.recordType == RecordType.referral &&
                        r.sourceFacility != null)) ...[
                  SectionHeading(t.recordsRecordedInformation),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.body != null)
                          SelectableText(
                            r.body!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        if (r.recordType == RecordType.referral &&
                            r.sourceFacility != null) ...[
                          const SizedBox(height: Space.sm),
                          DocumentDownloadButton(
                            label: t.referralLetterLabel,
                            filename: 'referral-letter.pdf',
                            icon: Icons.forward_to_inbox_outlined,
                            build: () => buildReferralLetter(ref, r),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (r.labValues.isNotEmpty) ...[
                  SectionHeading(t.resultsSection),
                  SurfaceCard(child: LabValuesTable(labs: r.labValues)),
                  const SizedBox(height: Space.sm),
                  _LabHistory(recordId: r.id),
                ],
                if (r.extractedText != null) ...[
                  const SizedBox(height: Space.sm),
                  // The source text the explanation is based on — a preview
                  // of what was read from the PDF, separate from the record.
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: const Icon(Icons.text_snippet_outlined),
                      title: Text(t.extractedTextSection),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        Space.md,
                        0,
                        Space.md,
                        Space.md,
                      ),
                      children: [
                        SelectableText(
                          r.extractedText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: AppFonts.mono,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SectionHeading(t.recordsClinicalReview),
                _ClinicalReview(record: r),
                SectionHeading(t.recordsGeneratedSummary),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.recordsGeneratedNotice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: PatientPalette.of(context).textMuted,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      DocumentDownloadButton(
                        label: t.exportRecordAction,
                        filename: 'record-${r.id}.pdf',
                        build: () => buildRecordSummary(
                          ref,
                          r,
                          recordTypeLabel: r.recordType.label(context),
                        ),
                      ),
                    ],
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

/// Title, type, date, source, who it belongs to and its status labels.
class _RecordHeaderCard extends ConsumerWidget {
  const _RecordHeaderCard({required this.record});
  final MedicalRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final palette = PatientPalette.of(context);
    final r = record;
    return SurfaceCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: switch (r.recordType) {
                  RecordType.labResult => Icons.science_outlined,
                  RecordType.imaging => Icons.image_outlined,
                  RecordType.prescription => Icons.medication_outlined,
                  RecordType.referral => Icons.forward_to_inbox_outlined,
                  _ => Icons.notes_outlined,
                },
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.recordType.label(context)} · ${fmtDate(r.occurredAt)}'
                      '${r.sourceFacility == null ? '' : ' · ${r.sourceFacility}'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          _RecordSubject(patientId: r.patientId),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xxs,
            runSpacing: Space.xxs,
            children: [
              StatusBadge(recordReviewLabel(t, r.reviewStatus)),
              if (r.hasAbnormalLabs)
                StatusBadge(
                  t.paOutOfRange,
                  accent: PatientAccent.red,
                  icon: Icons.priority_high,
                ),
              if (r.uploadedByPatient) StatusBadge(t.uploadedByPatientTag),
            ],
          ),
        ],
      ),
    );
  }
}

/// The original file: View (in-app preview), Download (save/share the same
/// authorized bytes) and Explain (report chat) are distinct actions.
class _OriginalCard extends ConsumerWidget {
  const _OriginalCard({required this.record});
  final MedicalRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final doc = record.sourceDocument;
    final canExplain = (record.extractedText ?? '').trim().isNotEmpty;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doc == null)
            Text(
              t.recordsNoOriginal,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            )
          else ...[
            Row(
              children: [
                const IconTile(icon: Icons.picture_as_pdf_outlined, size: 40),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    '${doc.fileName} · '
                    '${(doc.sizeBytes / 1024).toStringAsFixed(0)} KB',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                DocumentDownloadButton(
                  label: t.openOriginalAction,
                  filename: doc.fileName,
                  icon: Icons.visibility_outlined,
                  build: () => openOriginalFile(ref, record),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('download-original'),
                  onPressed: () async {
                    try {
                      final bytes = await openOriginalFile(ref, record);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: doc.fileName,
                      );
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.couldNotLoadRecord)),
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
          if (canExplain) ...[
            const SizedBox(height: Space.sm),
            FilledButton.icon(
              key: const ValueKey('explain-record'),
              onPressed: () {
                ref.read(careNavigatorViewProvider.notifier).state =
                    CareNavView.panel;
                unawaited(
                  ref
                      .read(careNavigatorProvider.notifier)
                      .explainDocument(record),
                );
              },
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(t.paExplainReport),
            ),
          ],
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
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recordReviewLabel(t, record.reviewStatus),
            style: Theme.of(context).textTheme.titleSmall,
          ),
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
          data: (previous) => SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.paEarlierResults,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final lab in record.labValues)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            lab.analyte,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            previous[labHistoryKey(lab)] != null
                                ? '${previous[labHistoryKey(lab)]!.value} ${previous[labHistoryKey(lab)]!.unit} · ${fmtDate(previous[labHistoryKey(lab)]!.at)}'
                                : t.recordsNoComparableResult,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
  }
}
