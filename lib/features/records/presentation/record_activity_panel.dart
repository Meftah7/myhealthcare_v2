import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/medical_record.dart';
import '../../../l10n/app_localizations.dart';
import '../application/records_providers.dart';

class RecordActivityPanel extends ConsumerWidget {
  const RecordActivityPanel({required this.record, super.key});
  final MedicalRecord record;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final read = ref.watch(recordPatientReadIdsProvider(record.patientId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        read.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () =>
                ref.invalidate(recordPatientReadIdsProvider(record.patientId)),
            child: Text(t.recordsReadStateUnavailable),
          ),
          data: (ids) => TextButton.icon(
            icon: Icon(
              ids.contains(record.id)
                  ? Icons.mark_email_unread_outlined
                  : Icons.mark_email_read_outlined,
            ),
            label: Text(
              ids.contains(record.id) ? t.recordsMarkUnread : t.recordsMarkRead,
            ),
            onPressed: () async {
              final result = await ref
                  .read(recordActivityRepositoryProvider)
                  .setRead(record.id, read: !ids.contains(record.id));
              if (!context.mounted) return;
              showMutationFeedback(context, result);
              ref.invalidate(recordPatientReadIdsProvider(record.patientId));
            },
          ),
        ),
        if (ref.watch(recordCanCorrectProvider(record.patientId)).valueOrNull ==
            true)
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_note_outlined),
            label: Text(t.recordsRequestCorrection),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _CorrectionSheet(record: record),
            ),
          ),
        RecordCorrectionList(recordId: record.id),
      ],
    );
  }
}

class _CorrectionSheet extends ConsumerStatefulWidget {
  const _CorrectionSheet({required this.record});
  final MedicalRecord record;
  @override
  ConsumerState<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends ConsumerState<_CorrectionSheet> {
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = t.recordsCorrectionRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(recordActivityRepositoryProvider)
        .requestCorrection(widget.record.id, _reason.text);
    if (!mounted) return;
    if (result.isErr) {
      setState(() {
        _saving = false;
        _error = describeFailure(t, result.failureOrNull!).message;
      });
      return;
    }
    ref.invalidate(recordCorrectionsProvider(widget.record.id));
    showMutationFeedback(context, result, success: t.recordsCorrectionSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          Space.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.recordsRequestCorrection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(widget.record.title),
            Text(t.recordsCorrectionNotice),
            const SizedBox(height: Space.md),
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: t.recordsCorrectionReason,
                errorText: _error,
              ),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(t.recordsSubmitCorrection),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordCorrectionList extends ConsumerWidget {
  const RecordCorrectionList({required this.recordId, super.key});
  final String recordId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final requests = ref.watch(recordCorrectionsProvider(recordId));
    return requests.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(recordCorrectionsProvider(recordId)),
        child: Text(t.recordsCorrectionsUnavailable),
      ),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final request in items)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                '${t.recordsCorrectionPending} · ${fmtDate(request.createdAt)}\n${request.reason}',
              ),
            ),
        ],
      ),
    );
  }
}
