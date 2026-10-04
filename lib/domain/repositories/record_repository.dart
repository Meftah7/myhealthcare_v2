/// Medical record, vitals and medication contracts (P1-11).
library;

import 'dart:typed_data';

import '../../core/data/contracts.dart';
import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

class NewRecord {
  const NewRecord({
    required this.patientId,
    required this.recordType,
    required this.title,
    required this.occurredAt,
    this.authorStaffId,
    this.appointmentId,
    this.body,
    this.sourceFacility,
    this.referralUrgency,
    this.attachmentPath,
    this.extractedText,
    this.labValues = const [],
    this.uploadedByPatient = false,
    this.sourceFile,
    this.idempotencyKey,
  });

  final String patientId;
  final RecordType recordType;
  final String title;
  final DateTime occurredAt;
  final String? authorStaffId;
  final String? appointmentId;
  final String? body;
  final String? sourceFacility;
  final ReferralUrgency? referralUrgency;
  final String? attachmentPath;
  final String? extractedText;
  final List<NewLabValue> labValues;
  final bool uploadedByPatient;

  /// The original file for an import, stored with the record (Phase 5).
  final NewSourceFile? sourceFile;

  /// Reuse across retries of the same save: a retry returns the record the
  /// first attempt created instead of filing it twice.
  final IdempotencyKey? idempotencyKey;
}

/// An imported file, as picked. Stored in the database, fingerprinted, and
/// only ever read back through [RecordRepository.sourceFile].
class NewSourceFile {
  const NewSourceFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  /// Largest accepted file.
  static const maxBytes = 20 * 1024 * 1024;
}

/// A stored original, read back.
class SourceFile {
  const SourceFile({required this.document, required this.bytes});
  final SourceDocument document;
  final Uint8List bytes;
}

class NewLabValue {
  const NewLabValue({
    required this.analyte,
    required this.value,
    this.unit,
    this.refLow,
    this.refHigh,
    this.criticalLow,
    this.criticalHigh,
    this.source,
  });

  final String analyte;
  final double value;
  final String? unit;

  /// Reference range. Leave both null when none was given: the value is then
  /// stored as [AbnormalFlag.unknown], never assumed normal.
  final double? refLow;
  final double? refHigh;

  /// Explicit critical limits from the issuing lab, when known. Without them
  /// `LabRules` applies its documented demonstration heuristic.
  final double? criticalLow;
  final double? criticalHigh;

  /// Where the value came from (e.g. "Clinic analyser", "Outside lab").
  final String? source;
}

abstract interface class RecordRepository {
  Future<Result<MedicalRecord>> byId(String id);

  /// All records explicitly linked to this encounter, regardless of age.
  Future<Result<List<MedicalRecord>>> forAppointment(
    String patientId,
    String appointmentId,
  );

  /// Chronological record feed, newest first, paginated (P2-08, P1-14).
  Future<Result<List<MedicalRecord>>> timeline(
    String patientId, {
    int limit,
    int offset,
    Set<RecordType>? types,
    String? textQuery,
  });

  /// One page of the timeline, newest first, saying whether more exist — so
  /// a long history shows "Load more" instead of being silently cut off.
  Future<Result<Page<MedicalRecord>>> timelinePage(
    String patientId, {
    PageRequest page,
    Set<RecordType>? types,
    String? textQuery,
  });

  Stream<List<MedicalRecord>> watchTimeline(String patientId, {int limit});

  /// Records a staff member authored, newest first — the staff "Records
  /// authored" view (ported from the FirstSemMyHealth doctor dashboard).
  Future<Result<List<MedicalRecord>>> authoredBy(String staffId, {int limit});

  /// Adds a record and any attached lab values in one transaction. Computes
  /// each lab value's [AbnormalFlag] from its reference range.
  ///
  /// A patient import must name its issuer ([NewRecord.sourceFacility]);
  /// its original file ([NewRecord.sourceFile]) is validated, fingerprinted
  /// and stored in the same transaction, and the record starts
  /// `pendingReview` until a clinician reviews it.
  Future<Result<MedicalRecord>> add(NewRecord record);

  /// The original file behind an imported record. Authorized like the
  /// record itself, and every read is audited.
  Future<Result<SourceFile>> sourceFile(String recordId);

  /// A clinician's decision on a patient import: [decision] is
  /// `reviewed` (accepted into the clinical record) or `rejected` (with a
  /// [note] saying why). Only a clinician with a care relationship, and only
  /// once.
  Future<Result<MedicalRecord>> reviewImport({
    required String recordId,
    required String staffId,
    required ImportReviewStatus decision,
    String? note,
  });
}

abstract interface class VitalsRepository {
  Future<Result<List<Vitals>>> forPatient(
    String patientId, {
    DateTime? from,
    DateTime? to,
  });

  Stream<List<Vitals>> watchForPatient(String patientId);

  Future<Result<Vitals>> add(Vitals vitals);
}

abstract interface class MedicationRepository {
  Future<Result<List<Medication>>> forPatient(
    String patientId, {
    bool activeOnly,
  });

  Future<Result<Medication>> prescribe(Medication medication);

  /// Medications a staff member prescribed, newest first — the staff
  /// "Prescriptions issued" view (ported from the FirstSemMyHealth doctor
  /// dashboard).
  Future<Result<List<Medication>>> prescribedBy(String staffId, {int limit});

  Future<Result<void>> discontinue(String id, DateTime endDate);
}
