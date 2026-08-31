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
  }) = _LabValue;

  const LabValue._();

  bool get isAbnormal => abnormalFlag != AbnormalFlag.normal;
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
    String? body,
    String? sourceFacility,
    String? attachmentPath,
    String? extractedText,
  }) = _MedicalRecord;

  const MedicalRecord._();

  bool get hasAttachment => attachmentPath != null;
  bool get hasAbnormalLabs => labValues.any((v) => v.isAbnormal);
}
