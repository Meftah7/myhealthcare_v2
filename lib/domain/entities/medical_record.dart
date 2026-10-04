/// Medical record + attached lab values (P1-09).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'medical_record.freezed.dart';

@freezed
abstract class LabValue with _$LabValue {
  const factory LabValue({
    required String id,
    required String recordId,
    required String analyte,
    required double value,
    required AbnormalFlag abnormalFlag,
    String? unit,
    double? refLow,
    double? refHigh,

    /// Where the value came from (analyser, outside lab, patient import).
    String? source,

    /// Which rules judged it, and any transformation applied (Phase 4).
    String? provenance,
    @Default(VerificationStatus.unverified)
    VerificationStatus verificationStatus,
    String? verifiedByStaffId,
    DateTime? verifiedAt,
  }) = _LabValue;

  const LabValue._();

  /// Outside its reference range. An [AbnormalFlag.unknown] value is not
  /// abnormal — but it is not normal either; see [needsReview].
  bool get isAbnormal =>
      abnormalFlag == AbnormalFlag.low ||
      abnormalFlag == AbnormalFlag.high ||
      abnormalFlag == AbnormalFlag.critical;

  bool get isUnknown => abnormalFlag == AbnormalFlag.unknown;

  /// A clinician must look at it: abnormal, or no range to judge it by.
  bool get needsReview => abnormalFlag != AbnormalFlag.normal;
}

@freezed
abstract class MedicalRecord with _$MedicalRecord {
  const factory MedicalRecord({
    required String id,
    required String patientId,
    required RecordType recordType,
    required String title,
    required DateTime occurredAt,
    required DateTime createdAt,
    @Default([]) List<LabValue> labValues,
    String? authorStaffId,
    String? appointmentId,
    String? body,
    String? sourceFacility,

    /// For a referral: how soon the patient should be seen.
    ReferralUrgency? referralUrgency,
    String? attachmentPath,
    String? extractedText,

    /// Imported by the patient — not reviewed by a clinician.
    @Default(false) bool uploadedByPatient,

    /// The signed-in account that filed it (the patient, a proxy, or a
    /// clinician).
    String? createdByAccountId,

    /// Clinician review of a patient import (Phase 5).
    @Default(ImportReviewStatus.notRequired) ImportReviewStatus reviewStatus,
    String? reviewedByStaffId,
    DateTime? reviewedAt,
    String? reviewNote,

    /// The stored original file, when there is one (Phase 5).
    SourceDocument? sourceDocument,
  }) = _MedicalRecord;

  const MedicalRecord._();

  bool get hasAttachment => attachmentPath != null || sourceDocument != null;

  /// A patient import no clinician has signed off — must never read as a
  /// clinic result.
  bool get awaitingReview => reviewStatus == ImportReviewStatus.pendingReview;
  bool get hasAbnormalLabs => labValues.any((v) => v.isAbnormal);

  /// Some values could not be judged (no reference range).
  bool get hasUnknownLabs => labValues.any((v) => v.isUnknown);
}

/// Metadata of an imported record's original file. The bytes are fetched
/// separately, through an authorized and audited call.
@freezed
abstract class SourceDocument with _$SourceDocument {
  const factory SourceDocument({
    required String id,
    required String fileName,
    required String mimeType,
    required int sizeBytes,

    /// Hex SHA-256 of the stored bytes.
    required String sha256,
    required DateTime storedAt,
  }) = _SourceDocument;
}
