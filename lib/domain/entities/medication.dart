/// A prescribed or self-reported medication (P1-09).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication.freezed.dart';

@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    required String id,
    required String patientId,
    required String name,
    required DateTime startDate,
    required bool isActive,
    String? prescriberId,
    String? dose,
    String? frequency,
    DateTime? endDate,
  }) = _Medication;

  const Medication._();

  bool get isCurrent {
    if (!isActive) return false;
    final end = endDate;
    return end == null || end.isAfter(DateTime.now());
  }
}
