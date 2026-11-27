/// A document the patient attaches in the assistant, from picking to
/// summary — kept apart from sending chat messages.
///
///   attach()  validating → reading (on this device) → ready
///   send()    saving (to Records, on this device) → uploading (the
///             extracted text, with real byte progress) → summarizing → done
///
/// Picking never asks for a summary: only [DocumentAttachment.send] does,
/// after the patient taps Summarize. The original file stays on the device
/// (saved in Records); only its extracted text is uploaded to the summary
/// service. Without that service the summary is made on the device and
/// labelled so.
///
/// Every step re-checks a generation counter, so removing or replacing the
/// attachment, restarting the conversation or changing account turns late
/// results into no-ops. Retries reuse the same record key and summary key:
/// no duplicate record, upload or summary.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../../services/ai/report_ai_client.dart';
import '../../../services/documents/document_text.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../records/application/records_providers.dart';
import 'assistant_connection.dart';
import 'care_navigator.dart';
import 'report_reader.dart';

enum AttachmentStatus {
  validating,

  /// Reading the text on this device.
  reading,

  /// Read; waiting for the patient to tap Summarize.
  ready,

  /// Saving the original to Records on this device.
  saving,

  /// Uploading the extracted text to the summary service.
  uploading,

  /// The summary service (or this device) is writing the summary.
  summarizing,
  complete,
  failed,
  cancelled,
}

/// Why an attachment failed.
enum AttachmentProblem { document, saveFailed, ai }

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.status,
    this.format,
    this.sentBytes,
    this.totalBytes,
    this.documentProblem,
    this.aiProblem,
    this.problem,
    this.charCount,
    this.extractionComplete = true,
    this.recordId,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final DocumentFormat? format;
  final AttachmentStatus status;

  /// Real upload progress, while [AttachmentStatus.uploading].
  final int? sentBytes;
  final int? totalBytes;

  final AttachmentProblem? problem;
  final DocumentProblem? documentProblem;
  final ReportAiFailureKind? aiProblem;

  /// Characters read from the document.
  final int? charCount;
  final bool extractionComplete;

  /// The record holding the original, once saved.
  final String? recordId;

  /// Upload progress 0–1, or null when it cannot be measured.
  double? get progress =>
      status == AttachmentStatus.uploading &&
          totalBytes != null &&
          totalBytes! > 0
      ? (sentBytes ?? 0) / totalBytes!
      : null;

  bool get busy => switch (status) {
    AttachmentStatus.validating ||
    AttachmentStatus.reading ||
    AttachmentStatus.saving ||
    AttachmentStatus.uploading ||
    AttachmentStatus.summarizing => true,
    _ => false,
  };

  /// Summarize can be tapped: ready, or a summary step failed and can be
  /// retried without choosing the file again.
  bool get canSummarize =>
      status == AttachmentStatus.ready ||
      (status == AttachmentStatus.failed &&
          problem != AttachmentProblem.document &&
          charCount != null);

  ChatAttachment copyWith({
    AttachmentStatus? status,
    DocumentFormat? format,
    int? sentBytes,
    int? totalBytes,
    AttachmentProblem? problem,
    DocumentProblem? documentProblem,
    ReportAiFailureKind? aiProblem,
    int? charCount,
    bool? extractionComplete,
    String? recordId,
    bool clearProblem = false,
    bool clearProgress = false,
  }) => ChatAttachment(
    id: id,
    fileName: fileName,
    sizeBytes: sizeBytes,
    format: format ?? this.format,
    status: status ?? this.status,
    sentBytes: clearProgress ? null : sentBytes ?? this.sentBytes,
    totalBytes: clearProgress ? null : totalBytes ?? this.totalBytes,
    problem: clearProblem ? null : problem ?? this.problem,
    documentProblem: clearProblem
        ? null
        : documentProblem ?? this.documentProblem,
    aiProblem: clearProblem ? null : aiProblem ?? this.aiProblem,
    charCount: charCount ?? this.charCount,
    extractionComplete: extractionComplete ?? this.extractionComplete,
    recordId: recordId ?? this.recordId,
  );
}

class DocumentAttachment extends Notifier<ChatAttachment?> {
  int _generation = 0;
  CancelToken? _cancel;
  Uint8List? _bytes;
  ExtractedDocument? _document;
  IdempotencyKey? _recordKey;
  String? _summaryKey;

  /// For tests: how the document is read.
  @visibleForTesting
  Future<ExtractedDocument> Function({
    required String fileName,
    required Uint8List bytes,
  })
  reader = readDocument;

  @override
  ChatAttachment? build() {
    // A different account never sees (or completes) this attachment.
    ref.watch(currentUserProvider.select((u) => u?.id));
    _drop();
    ref.onDispose(_drop);
    return null;
  }

  void _drop() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _bytes = null;
    _document = null;
  }

  bool _current(int generation, String id) =>
      generation == _generation && state?.id == id;

  /// Attaches a picked file and reads it on the device. Replaces any
  /// current attachment (its work is cancelled). Never asks for a summary.
  Future<void> attach(String fileName, Uint8List bytes) async {
    _drop();
    final generation = _generation;
    final id = const Uuid().v4();
    _recordKey = IdempotencyKey.generate();
    _summaryKey = 'attach-${id.replaceAll('-', '')}';
    state = ChatAttachment(
      id: id,
      fileName: fileName,
      sizeBytes: bytes.length,
      format: DocumentFormat.forFileName(fileName),
      status: AttachmentStatus.validating,
    );
    final DocumentFormat format;
    try {
      format = checkDocument(fileName: fileName, bytes: bytes);
    } on DocumentReadException catch (e) {
      state = state!.copyWith(
        status: AttachmentStatus.failed,
        problem: AttachmentProblem.document,
        documentProblem: e.problem,
      );
      return;
    }
    state = state!.copyWith(status: AttachmentStatus.reading, format: format);
    try {
      final document = await reader(fileName: fileName, bytes: bytes);
      if (!_current(generation, id)) return;
      _bytes = bytes;
      _document = document;
      state = state!.copyWith(
        status: AttachmentStatus.ready,
        charCount: document.text.length,
        extractionComplete: document.complete,
      );
    } on DocumentReadException catch (e) {
      if (!_current(generation, id)) return;
      state = state!.copyWith(
        status: AttachmentStatus.failed,
        problem: AttachmentProblem.document,
        documentProblem: e.problem,
      );
    }
  }

  /// Removes the attachment, cancelling anything in flight.
  void remove() {
    final had = state != null;
    _drop();
    if (had) state = null;
  }

  /// The patient tapped Summarize (or Retry after a summary step failed).
  Future<void> send() async {
    final current = state;
    final document = _document;
    final bytes = _bytes;
    final user = ref.read(currentUserProvider);
    if (current == null ||
        !current.canSummarize ||
        document == null ||
        bytes == null ||
        user == null ||
        !user.isPatient) {
      return;
    }
    final generation = _generation;
    final id = current.id;
    final arabic = Intl.getCurrentLocale().startsWith('ar');

    // 1. Keep the original in Records (once — a retry reuses the record).
    var recordId = current.recordId;
    if (recordId == null) {
      state = current.copyWith(
        status: AttachmentStatus.saving,
        clearProblem: true,
        clearProgress: true,
      );
      final title = current.fileName
          .replaceAll(RegExp(r'\.(pdf|docx?|txt)$', caseSensitive: false), '')
          .trim();
      final result = await ref
          .read(recordRepositoryProvider)
          .add(
            NewRecord(
              patientId: user.id,
              recordType: _recordTypeFor(document.text, title),
              title: title.isEmpty ? 'Uploaded document' : title,
              occurredAt: DateTime.now(),
              sourceFacility: reportIssuer(document.text) ?? 'Not stated',
              extractedText: document.text,
              uploadedByPatient: true,
              sourceFile: NewSourceFile(
                fileName: current.fileName,
                mimeType: document.format.mimeType,
                bytes: bytes,
              ),
              idempotencyKey: _recordKey,
            ),
          );
      if (!_current(generation, id)) return;
      switch (result) {
        case Ok(:final value):
          recordId = value.id;
        case Err(failure: DuplicateUploadFailure(recordId: final existing)):
          recordId = existing;
        case Err():
          state = state!.copyWith(
            status: AttachmentStatus.failed,
            problem: AttachmentProblem.saveFailed,
          );
          return;
      }
      ref
        ..invalidate(recordsHistoryProvider)
        ..invalidate(patientTimelinePageProvider);
      state = state!.copyWith(recordId: recordId);
    }
    final record =
        (await ref.read(recordRepositoryProvider).byId(recordId)).valueOrNull;
    if (!_current(generation, id)) return;
    if (record == null) {
      state = state!.copyWith(
        status: AttachmentStatus.failed,
        problem: AttachmentProblem.saveFailed,
      );
      return;
    }

    // 2. Summarize: the live service when it is available, else this device.
    final navigator = ref.read(careNavigatorProvider.notifier);
    final readiness = await ref
        .read(assistantConnectionProvider.notifier)
        .current();
    if (!_current(generation, id)) return;
    if (readiness != GatewayReadiness.available) {
      state = state!.copyWith(
        status: AttachmentStatus.summarizing,
        clearProblem: true,
        clearProgress: true,
      );
      final summary = summarizeDocumentOnDevice(
        document.text,
        title: record.title,
      );
      navigator.showDocumentSummary(
        record: record,
        fileName: current.fileName,
        overview: summary.overview,
        points: summary.points,
        live: false,
        partial: !document.complete,
        reason: readiness,
      );
      _finish(generation, id);
      return;
    }

    final cancel = CancelToken();
    _cancel = cancel;
    final payload = document.text.length > ReportAiLimits.maxSummaryChars
        ? document.text.substring(0, ReportAiLimits.maxSummaryChars)
        : document.text;
    state = state!.copyWith(
      status: AttachmentStatus.uploading,
      clearProgress: true,
      clearProblem: true,
    );
    try {
      final summary = await ref
          .read(reportAiClientProvider)
          .summarizeDocument(
            text: payload,
            fileName: current.fileName,
            arabic: arabic,
            sourceChars: document.text.length,
            extractionComplete: document.complete,
            idempotencyKey: _summaryKey!,
            cancelToken: cancel,
            onSendProgress: (sent, total) {
              if (!_current(generation, id)) return;
              final done = total > 0 && sent >= total;
              state = state!.copyWith(
                // All bytes sent: the service is now writing the summary.
                status: done
                    ? AttachmentStatus.summarizing
                    : AttachmentStatus.uploading,
                sentBytes: sent,
                totalBytes: total > 0 ? total : null,
              );
            },
          );
      if (!_current(generation, id)) return;
      if (!summary.readable) {
        state = state!.copyWith(
          status: AttachmentStatus.failed,
          problem: AttachmentProblem.document,
          documentProblem: DocumentProblem.noText,
        );
        return;
      }
      navigator.showDocumentSummary(
        record: record,
        fileName: current.fileName,
        overview: summary.overview,
        points: summary.points,
        quotes: summary.quotes,
        live: true,
        partial: !summary.coverage.complete || !document.complete,
      );
      _finish(generation, id);
    } on ReportAiException catch (e) {
      if (!_current(generation, id)) return;
      if (e.kind == ReportAiFailureKind.cancelled) return;
      ref.read(assistantConnectionProvider.notifier).reportFailure(e.kind);
      // The prepared document and saved record are kept: Retry does not
      // need the file again.
      state = state!.copyWith(
        status: AttachmentStatus.failed,
        problem: AttachmentProblem.ai,
        aiProblem: e.kind,
        clearProgress: true,
      );
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  void _finish(int generation, String id) {
    if (!_current(generation, id)) return;
    state = state!.copyWith(status: AttachmentStatus.complete);
    // The summary is in the conversation now; the card goes away.
    _drop();
    state = null;
  }

  static RecordType _recordTypeFor(String text, String title) {
    final t = '$title ${text.length > 3000 ? text.substring(0, 3000) : text}'
        .toLowerCase();
    if (RegExp(r'x-ray|xray|\bmri\b|\bct\b|ultrasound|radiolog').hasMatch(t)) {
      return RecordType.imaging;
    }
    if (t.contains('discharge')) return RecordType.discharge;
    if (RegExp(r'prescription|\brx\b').hasMatch(t)) {
      return RecordType.prescription;
    }
    if (t.contains('referral')) return RecordType.referral;
    if (t.contains('vaccin')) return RecordType.vaccination;
    if (RegExp(
      r'laborator|\blab\b|blood|panel|hba1c|glucose|hemoglobin',
    ).hasMatch(t)) {
      return RecordType.labResult;
    }
    return RecordType.visitNote;
  }
}

final documentAttachmentProvider =
    NotifierProvider<DocumentAttachment, ChatAttachment?>(
      DocumentAttachment.new,
    );

/// A plain "3.4 MB" / "820 KB" size.
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
  return '$bytes B';
}
