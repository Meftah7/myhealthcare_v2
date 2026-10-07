import '../entities/medical_record.dart';
import '../enums.dart';

typedef LabObservation = ({double value, String? unit, DateTime at});

String labHistoryKey(LabValue value) =>
    '${value.analyte.trim().toLowerCase()}\u0000${value.unit?.trim() ?? ''}';

/// No conversions or assumptions about an absent unit. Only earlier results
/// from this patient and the exact same test/unit may be compared.
Map<String, LabObservation> comparableLabHistory(
  MedicalRecord current,
  List<MedicalRecord> history,
) {
  final wanted = {
    for (final lab in current.labValues)
      if (lab.unit?.trim().isNotEmpty ?? false) labHistoryKey(lab),
  };
  final earlier =
      history
          .where(
            (r) =>
                r.patientId == current.patientId &&
                r.id != current.id &&
                r.occurredAt.isBefore(current.occurredAt) &&
                r.reviewStatus != ImportReviewStatus.rejected,
          )
          .toList()
        ..sort((a, b) {
          final date = b.occurredAt.compareTo(a.occurredAt);
          return date == 0 ? b.id.compareTo(a.id) : date;
        });
  final out = <String, LabObservation>{};
  for (final record in earlier) {
    for (final lab in record.labValues) {
      final key = labHistoryKey(lab);
      if (wanted.contains(key)) {
        out.putIfAbsent(
          key,
          () => (value: lab.value, unit: lab.unit, at: record.occurredAt),
        );
      }
    }
  }
  return out;
}
