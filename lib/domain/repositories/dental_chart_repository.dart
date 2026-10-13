/// Dental chart (FDI two-digit notation), append-only.
///
/// Observations, planned treatment and completed treatment are separate
/// entries bound to one patient and one visit; corrections are new entries.
/// Reads follow the clinical chart rule (care relationship); writes need the
/// dentist's `recordDentalChart` permission and a care relationship.
library;

import '../../core/result.dart';
import '../enums.dart';

/// Valid FDI tooth numbers: permanent 11–18, 21–28, 31–38, 41–48 and
/// primary 51–55, 61–65, 71–75, 81–85.
bool isFdiTooth(int n) {
  final quadrant = n ~/ 10, tooth = n % 10;
  if (quadrant >= 1 && quadrant <= 4) return tooth >= 1 && tooth <= 8;
  if (quadrant >= 5 && quadrant <= 8) return tooth >= 1 && tooth <= 5;
  return false;
}

/// Permanent dentition in chart order, from the patient's upper right.
const fdiUpper = [
  18,
  17,
  16,
  15,
  14,
  13,
  12,
  11,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
];
const fdiLower = [
  48,
  47,
  46,
  45,
  44,
  43,
  42,
  41,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
];

class DentalEntry {
  const DentalEntry({
    required this.id,
    required this.patientId,
    required this.appointmentId,
    required this.tooth,
    required this.kind,
    required this.note,
    required this.authorId,
    required this.createdAt,
    this.surface,
    this.fulfilsId,
  });

  final String id;
  final String patientId;
  final String appointmentId;
  final int tooth;
  final DentalEntryKind kind;
  final String note;
  final String? surface;
  final String? fulfilsId;
  final String authorId;
  final DateTime createdAt;
}

class NewDentalEntry {
  const NewDentalEntry({
    required this.patientId,
    required this.appointmentId,
    required this.tooth,
    required this.kind,
    required this.note,
    required this.idempotencyKey,
    this.surface,
    this.fulfilsId,
  });

  final String patientId;
  final String appointmentId;
  final int tooth;
  final DentalEntryKind kind;
  final String note;
  final String? surface;
  final String? fulfilsId;
  final String idempotencyKey;
}

abstract interface class DentalChartRepository {
  /// All entries for [patientId], oldest first.
  Future<Result<List<DentalEntry>>> forPatient(String patientId);

  /// Appends one entry. A retry with the same key returns the original.
  Future<Result<DentalEntry>> add(NewDentalEntry entry);
}
