/// Import a PDF from outside the clinic (a lab result, an old report) as a
/// health record: pick a file, pull its text out locally on-device, review
/// and save. Nothing is uploaded anywhere — the PDF never leaves the device.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/crypto/document_cipher.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';

Future<void> showImportRecordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
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
  String? _fileName;
  Uint8List? _bytes;
  String? _extractedText;
  RecordType _recordType = RecordType.labResult;
  DateTime _occurredAt = DateTime.now();

  bool _reading = false;
  bool _saving = false;
  String? _error;

  /// Largest PDF accepted — larger files are almost always scans that would
  /// bloat on-device storage and stall text extraction.
  static const _maxBytes = 20 * 1024 * 1024;

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
      if (bytes.length > _maxBytes) {
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

  /// Encrypts the picked PDF into app storage and returns its path; null on
  /// web, which has no app file system (the name is kept instead).
  Future<String?> _storeOriginal(String patientId) async {
    final bytes = _bytes;
    if (kIsWeb || bytes == null) return null;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/imports/$patientId');
    await dir.create(recursive: true);
    // Encrypted at rest with a keystore-held key (SEC-PAT-08); read back
    // through DocumentCipher.decrypt.
    final sealed = await DocumentCipher().encrypt(bytes);
    final file = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.pdf.enc',
    );
    await file.writeAsBytes(sealed, flush: true);
    return file.path;
  }

  bool get _canSave =>
      _fileName != null &&
      !_reading &&
      !_saving &&
      _title.text.trim().isNotEmpty;

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    // Keep the original document, not just its name — the extracted text is
    // lossy, and a clinician reviewing the upload needs the real file.
    String? storedPath;
    try {
      storedPath = await _storeOriginal(user.id);
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = t.pdfImportFailedError;
      });
      return;
    }
    if (!mounted) return;
    final result = await ref
        .read(recordRepositoryProvider)
        .add(
          NewRecord(
            patientId: user.id,
            recordType: _recordType,
            title: _title.text.trim(),
            occurredAt: _occurredAt,
            attachmentPath: storedPath ?? _fileName,
            extractedText: _extractedText,
            uploadedByPatient: true,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(patientTimelineProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.importedRecordSavedMessage)));
      case Err(:final failure):
        if (storedPath != null) {
          try {
            await File(storedPath).delete();
          } on FileSystemException {
            // Best-effort cleanup; preserve the original persistence failure.
          }
        }
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
              onPressed: _reading ? null : _pickFile,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _reading
                    ? t.extractingPdfMessage
                    : (_fileName ?? t.chooseFileAction),
              ),
            ),

            if (_fileName != null) ...[
              const SizedBox(height: Space.md),
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: t.titleLabel),
                onChanged: (_) => setState(() {}),
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
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
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
