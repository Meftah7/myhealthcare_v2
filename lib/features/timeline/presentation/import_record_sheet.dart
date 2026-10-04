/// Import a PDF from outside the clinic (a lab result, an old report) as a
/// health record (Phase 5): pick the file, say who it is for and who issued
/// it, review the text read from it, and save.
///
/// The text is read on this device; the original file is stored with the
/// record (in the app's database, on every platform) and fingerprinted, so it
/// can be opened again exactly as imported. The record is marked "not
/// reviewed by a clinician" until one reviews it. Nothing is uploaded to any
/// outside service by the import itself — the AI chat may send the text to
/// the live model to explain it, only when an admin has enabled live AI.
///
/// Failures never lose what was entered: a file that can't be read, or a
/// save that fails, leaves every field as it was with the reason and a way
/// to try again.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../app/theme/theme.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';

/// Returns the saved record, or null if the patient closed the sheet.
Future<MedicalRecord?> showImportRecordSheet(BuildContext context) {
  return showModalBottomSheet<MedicalRecord>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: const _ImportRecordSheet(),
    ),
  );
}

class _ImportRecordSheet extends ConsumerStatefulWidget {
  const _ImportRecordSheet();

  @override
  ConsumerState<_ImportRecordSheet> createState() => _ImportRecordSheetState();
}

class _ImportRecordSheetState extends ConsumerState<_ImportRecordSheet> {
  final _title = TextEditingController();
  final _issuer = TextEditingController();
  String? _fileName;
  Uint8List? _bytes;
  String? _extractedText;
  RecordType _recordType = RecordType.labResult;
  DateTime _occurredAt = DateTime.now();

  /// Whose record this is: the signed-in patient, or someone they manage.
  String? _patientId;

  bool _reading = false;
  bool _saving = false;
  String? _error;
  String? _issuerError;

  /// One key per save attempt, kept across a retry so a retried save files
  /// the record once.
  IdempotencyKey _key = IdempotencyKey.generate();

  static bool _looksLikePdf(Uint8List bytes) =>
      bytes.length > 5 &&
      bytes[0] == 0x25 && // %PDF-
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46 &&
      bytes[4] == 0x2D;

  @override
  void dispose() {
    _title.dispose();
    _issuer.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final t = AppLocalizations.of(context)!;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null || !mounted) return;

    setState(() => _reading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > NewSourceFile.maxBytes) {
        if (!mounted) return;
        setState(() {
          _reading = false;
          _error = t.pdfTooLargeError;
        });
        return;
      }
      // Untrusted input: check the magic bytes, then parse off the UI isolate
      // with page/text caps and a timeout (SEC-PAT-10).
      if (!_looksLikePdf(bytes)) throw const FormatException('not a PDF');
      final text = await compute(
        _extractPdfText,
        bytes,
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _bytes = bytes;
        _extractedText = text.trim();
        _reading = false;
        _key = IdempotencyKey.generate();
        if (_title.text.trim().isEmpty) {
          _title.text = file.name.replaceAll(
            RegExp(r'\.pdf$', caseSensitive: false),
            '',
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reading = false;
        _error = t.pdfImportFailedError;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(now.year - 15),
      lastDate: now,
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  bool get _canSave =>
      _bytes != null && !_reading && !_saving && _title.text.trim().isNotEmpty;

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    final bytes = _bytes;
    if (user == null || bytes == null) return;
    if (_issuer.text.trim().isEmpty) {
      setState(() => _issuerError = t.importIssuerRequired);
      return;
    }
    final patientId = _patientId ?? user.id;
    setState(() {
      _saving = true;
      _error = null;
      _issuerError = null;
    });
    final result = await ref
        .read(recordRepositoryProvider)
        .add(
          NewRecord(
            patientId: patientId,
            recordType: _recordType,
            title: _title.text.trim(),
            occurredAt: _occurredAt,
            sourceFacility: _issuer.text.trim(),
            extractedText: _extractedText,
            uploadedByPatient: true,
            sourceFile: NewSourceFile(
              fileName: _fileName ?? 'document.pdf',
              mimeType: 'application/pdf',
              bytes: bytes,
            ),
            idempotencyKey: _key,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.invalidate(patientTimelinePageProvider);
        if (patientId != user.id) {
          ref.invalidate(linkedTimelinePageProvider(patientId));
        }
        Navigator.of(context).pop(value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.importedRecordSavedMessage)));
      case Err(:final failure):
        // Everything entered stays; the same key makes "Save" again safe.
        setState(() {
          _saving = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final managed = [
      for (final v
          in ref.watch(linkedAccountsProvider).valueOrNull ??
              const <FamilyLinkView>[])
        if (v.link.canManage) v,
    ];

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.importRecordTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              t.importRecordSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.lg),

            OutlinedButton.icon(
              onPressed: _reading || _saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _reading
                    ? t.extractingPdfMessage
                    : (_fileName ?? t.chooseFileAction),
              ),
            ),

            if (_fileName != null) ...[
              const SizedBox(height: Space.md),
              if (managed.isNotEmpty && user != null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _patientId ?? user.id,
                  decoration: InputDecoration(labelText: t.importForLabel),
                  items: [
                    DropdownMenuItem(
                      value: user.id,
                      child: Text(t.importForMe),
                    ),
                    for (final v in managed)
                      DropdownMenuItem(
                        value: v.counterpart.id,
                        child: Text(v.counterpart.fullName),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _patientId = v),
                ),
                const SizedBox(height: Space.sm),
              ],
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: t.titleLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _issuer,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.importIssuerLabel,
                  helperText: t.importIssuerHelper,
                  errorText: _issuerError,
                ),
                onChanged: (_) {
                  if (_issuerError != null) {
                    setState(() => _issuerError = null);
                  }
                },
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<RecordType>(
                initialValue: _recordType,
                decoration: InputDecoration(labelText: t.recordTypeLabel),
                items: [
                  for (final r in RecordType.values)
                    DropdownMenuItem(value: r, child: Text(r.label(context))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _recordType = v);
                },
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('${t.dateLabel}: ${fmtDate(_occurredAt)}'),
              ),
              const SizedBox(height: Space.sm),
              InlineBanner.info(t.importReviewNotice),
              if (_extractedText != null && _extractedText!.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                Text(
                  t.extractedTextPreviewLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xs),
                AppCard(
                  padding: const EdgeInsets.all(Space.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      child: Text(
                        _extractedText!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ],

            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],

            const SizedBox(height: Space.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.saveRecordAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _maxPdfPages = 200;
const _maxExtractedChars = 200000;

/// Top-level so [compute] can run it on a background isolate.
String _extractPdfText(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    if (document.pages.count > _maxPdfPages) {
      throw const FormatException('too many pages');
    }
    final text = PdfTextExtractor(document).extractText();
    return text.length > _maxExtractedChars
        ? text.substring(0, _maxExtractedChars)
        : text;
  } finally {
    document.dispose();
  }
}
