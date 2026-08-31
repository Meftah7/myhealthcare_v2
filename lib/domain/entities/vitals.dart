/// A single vitals measurement set (P1-09).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'vitals.freezed.dart';

@freezed
abstract class Vitals with _$Vitals {
  const factory Vitals({
    required String id,
    required String patientId,
    required DateTime recordedAt,
    int? systolic,
    int? diastolic,
    int? heartRate,
    double? tempC,
    double? weightKg,
    double? heightCm,
    int? spo2,
    double? glucose,
    String? recordedByStaffId,
  }) = _Vitals;

  const Vitals._();

  bool get hasBloodPressure => systolic != null && diastolic != null;

  /// Body-mass index, when both weight and height are present.
  double? get bmi {
    final w = weightKg;
    final h = heightCm;
    if (w == null || h == null || h == 0) return null;
    final m = h / 100;
    return w / (m * m);
  }
}
