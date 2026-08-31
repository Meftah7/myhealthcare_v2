/// Medical record, vitals and medication contracts (P1-11).
library;

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
    this.body,
    this.sourceFacility,
    this.attachmentPath,
    this.extractedText,
    this.labValues = const [],
  });

  final String patientId;
  final RecordType recordType;
  final String title;
  final DateTime occurredAt;
  final String? authorStaffId;
  final String? body;
  final String? sourceFacility;
  final String? attachmentPath;
  final String? extractedText;
  final List<NewLabValue> labValues;
}

class NewLabValue {
  const NewLabValue({
    required this.analyte,
    required this.value,
    this.unit,
    this.refLow,
    this.refHigh,
  });

  final String analyte;
  final double value;
  final String? unit;
  final double? refLow;
  final double? refHigh;
}

abstract interface class RecordRepository {
  Future<Result<MedicalRecord>> byId(String id);

  /// Chronological record feed, newest first, paginated (P2-08, P1-14).
  Future<Result<List<MedicalRecord>>> timeline(
    String patientId, {
    int limit,
    int offset,
    Set<RecordType>? types,
    String? textQuery,
  });

  Stream<List<MedicalRecord>> watchTimeline(String patientId, {int limit});

  /// Adds a record and any attached lab values in one transaction. Computes
  /// each lab value's [AbnormalFlag] from its reference range.
  Future<Result<MedicalRecord>> add(NewRecord record);
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

  Future<Result<void>> discontinue(String id, DateTime endDate);
}
