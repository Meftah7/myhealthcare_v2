/// A result, its provenance, and its owned review (Phase 4). Opened from the
/// chart timeline and the dashboard's "Results to review". The clinician who
/// holds the review can start it, record the outcome, or escalate it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_documents.dart';
import '../../patient/presentation/document_download_button.dart';
import '../../records/presentation/lab_values_table.dart';
import '../../records/presentation/record_detail_screen.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/result_review_providers.dart';

Future<void> showResultSheet(BuildContext context, String recordId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _ResultSheet(recordId: recordId),
    ),
  );
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.recordId});
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final record = ref.watch(chartRecordProvider(recordId));
    final review = ref.watch(recordReviewProvider(recordId));
    final staff = ref.watch(staffDirectoryProvider).valueOrNull ?? const [];
    final names = {for (final s in staff) s.id: s.fullName};

    return record.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadRecord,
        onRetry: () => ref.invalidate(chartRecordProvider(recordId)),
      ),
      data: (r) => ListView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
        children: [
          Text(r.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.xxs),
          Text(
            '${r.recordType.label(context)} · ${fmtDate(r.occurredAt)}'
            '${r.sourceFacility == null ? '' : ' · ${r.sourceFacility}'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (r.uploadedByPatient) ...[
            const SizedBox(height: Space.sm),
            InlineBanner.info(t.uploadedByPatientNote),
            const SizedBox(height: Space.sm),
            ImportProvenanceCard(record: r),
            const SizedBox(height: Space.xs),
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
                if (r.awaitingReview &&
                    ref.watch(canProvider(Permission.writeClinicalRecord))) ...[
                  FilledButton.tonal(
                    onPressed: () => _decideImport(
                      context,
                      ref,
                      r,
                      ImportReviewStatus.reviewed,
                    ),
                    child: Text(t.acceptImportAction),
                  ),
                  TextButton(
                    onPressed: () => _decideImport(
                      context,
                      ref,
                      r,
                      ImportReviewStatus.rejected,
                    ),
                    child: Text(t.rejectImportAction),
                  ),
                ],
              ],
            ),
          ],
          if (r.body != null && r.body!.trim().isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            AppCard(child: Text(r.body!)),
          ],
          if (r.labValues.isNotEmpty) ...[
            SectionHeader(t.resultsSection, overline: true),
            AppCard(
              child: LabValuesTable(
                labs: r.labValues,
                showProvenance: true,
                clinicianNames: names,
              ),
            ),
          ],
          review.when(
            loading: () => const LoadingSkeleton(height: 80),
            error: (e, _) => InlineBanner.error(t.couldNotLoadResultReviews),
            data: (rv) => rv == null
                ? const SizedBox.shrink()
                : _ReviewPanel(review: rv, names: names, staff: staff),
          ),
        ],
      ),
    );
  }
}

Future<void> _decideImport(
  BuildContext context,
  WidgetRef ref,
  MedicalRecord record,
  ImportReviewStatus decision,
) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  String? note;
  if (decision == ImportReviewStatus.rejected) {
    note = await _askText(
      context,
      t.rejectImportAction,
      t.rejectImportReasonLabel,
    );
    if (note == null) return;
  }
  final r = await reviewImport(ref, record, decision: decision, note: note);
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (r) {
        Ok() => t.importReviewSaved,
        Err(:final failure) => describeFailure(
          AppLocalizations.of(context)!,
          failure,
        ).message,
      }),
    ),
  );
}

class _ReviewPanel extends ConsumerStatefulWidget {
  const _ReviewPanel({
    required this.review,
    required this.names,
    required this.staff,
  });

  final ResultReview review;
  final Map<String, String> names;
  final List<Staff> staff;

  @override
  ConsumerState<_ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends ConsumerState<_ReviewPanel> {
  bool _busy = false;

  Future<void> _run(Future<Result<Object?>> Function() action) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final r = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => t.resultReviewUpdated,
          Err(:final failure) => describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message,
        }),
      ),
    );
  }

  Future<void> _resolve() async {
    final t = AppLocalizations.of(context)!;
    final note = await _askText(
      context,
      t.resolveReviewAction,
      t.reviewOutcomeLabel,
    );
    if (note == null || !mounted) return;
    await _run(
      () => ref.read(resultReviewActionsProvider).resolve(widget.review, note),
    );
  }

  Future<void> _escalate() async {
    final me = ref.read(currentUserProvider)?.id;
    final doctors = [
      for (final s in widget.staff)
        if (s.isDoctor && s.user.isActive && s.id != me) s,
    ];
    final picked = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EscalateDialog(doctors: doctors),
    );
    if (picked == null || !mounted) return;
    await _run(
      () => ref
          .read(resultReviewActionsProvider)
          .escalate(widget.review, toStaffId: picked.$1, note: picked.$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rv = widget.review;
    final me = ref.watch(currentUserProvider)?.id;
    final canResolve = ref.watch(canProvider(Permission.reviewResults));
    final holds = me != null && rv.isHeldBy(me);
    final overdue = rv.isOverdueAt(DateTime.now());
    final due = '${fmtDate(rv.dueAt)} ${fmtTime(rv.dueAt)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(t.resultReviewHeader, overline: true),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xxs,
                children: [
                  Chip(label: Text(rv.status.label(context))),
                  Chip(label: Text(rv.priority.label(context))),
                ],
              ),
              const SizedBox(height: Space.xs),
              if (rv.ownerStaffId != null)
                Text(
                  t.resultReviewOwner(
                    widget.names[rv.ownerStaffId] ?? rv.ownerStaffId!,
                  ),
                ),
              if (rv.coverageStaffId != null)
                Text(
                  t.resultReviewCoveredBy(
                    widget.names[rv.coverageStaffId] ?? rv.coverageStaffId!,
                  ),
                ),
              if (rv.isOpen)
                Text(
                  overdue ? t.resultReviewOverdue(due) : t.resultReviewDue(due),
                  style: overdue
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
              if (rv.escalationNote != null) ...[
                const SizedBox(height: Space.xs),
                Text(rv.escalationNote!, style: theme.textTheme.bodySmall),
              ],
              if (rv.resolutionNote != null) ...[
                const SizedBox(height: Space.xs),
                Text(rv.resolutionNote!, style: theme.textTheme.bodyMedium),
              ],
              if (rv.isOpen && holds) ...[
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    if (canResolve &&
                        (rv.status == ResultReviewStatus.assigned ||
                            rv.status == ResultReviewStatus.escalated))
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ref
                                    .read(resultReviewActionsProvider)
                                    .start(rv),
                              ),
                        child: Text(t.startReviewAction),
                      ),
                    if (canResolve)
                      FilledButton(
                        onPressed: _busy ? null : _resolve,
                        child: Text(t.resolveReviewAction),
                      ),
                    TextButton(
                      onPressed: _busy ? null : _escalate,
                      child: Text(t.escalateReviewAction),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Future<String?> _askText(BuildContext context, String title, String label) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _EscalateDialog extends StatefulWidget {
  const _EscalateDialog({required this.doctors});
  final List<Staff> doctors;

  @override
  State<_EscalateDialog> createState() => _EscalateDialogState();
}

class _EscalateDialogState extends State<_EscalateDialog> {
  final _reason = TextEditingController();
  String? _to;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ready = _to != null && _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(t.escalateReviewAction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _to,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.escalateToLabel),
            items: [
              for (final d in widget.doctors)
                DropdownMenuItem(value: d.id, child: Text(d.fullName)),
            ],
            onChanged: (v) => setState(() => _to = v),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: t.escalationReasonLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, (_to!, _reason.text.trim()))
              : null,
          child: Text(t.escalateReviewAction),
        ),
      ],
    );
  }
}
