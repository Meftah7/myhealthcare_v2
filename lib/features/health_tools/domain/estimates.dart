/// Health estimates: ideal body weight, body-fat percentage, pregnancy due
/// date and fertile-window/ovulation. Every result is an **estimate** for
/// adults; none is a diagnosis, a fertility guarantee or contraception
/// advice. Inputs outside the validated range return `null` so the screen
/// never shows a stale or extrapolated value.
///
/// Sources
/// - Ideal body weight: B. J. Devine, "Gentamicin therapy", Drug Intell Clin
///   Pharm 1974;8:650–655 (50 kg / 45.5 kg + 2.3 kg per inch over 5 ft).
///   Healthy-weight range: WHO adult BMI 18.5–24.9 kg/m².
/// - Body fat: J. A. Hodgdon & M. B. Beckett, "Prediction of percent body fat
///   for U.S. Navy men/women from body circumferences and height", Naval
///   Health Research Center reports 84-11 and 84-29 (1984).
/// - Due date: Naegele's rule (LMP + 280 days), adjusted by (cycle − 28)
///   days for regular cycles; ACOG Committee Opinion 700 (2017), "Methods
///   for estimating the due date".
/// - Ovulation: ovulation ≈ 14 days before the next expected period (luteal
///   phase); fertile window = the 5 days before ovulation plus ovulation day
///   (A. J. Wilcox et al., NEJM 1995;333:1517–1521).
library;

import 'dart:math' as math;

enum Sex { male, female }

/// Regular-cycle range the calendar methods are valid for.
const minCycleDays = 21;
const maxCycleDays = 35;

class IdealWeightEstimate {
  const IdealWeightEstimate({
    required this.devineKg,
    required this.healthyMinKg,
    required this.healthyMaxKg,
  });

  final double devineKg;
  final double healthyMinKg;
  final double healthyMaxKg;
}

/// Adults 152.4–220 cm (Devine is defined from 5 ft upward).
IdealWeightEstimate? idealWeight({required Sex sex, required double heightCm}) {
  if (!heightCm.isFinite || heightCm < 152.4 || heightCm > 220) return null;
  final inchesOver5ft = (heightCm / 2.54) - 60;
  final base = sex == Sex.male ? 50.0 : 45.5;
  final m = heightCm / 100;
  return IdealWeightEstimate(
    devineKg: base + 2.3 * inchesOver5ft,
    healthyMinKg: 18.5 * m * m,
    healthyMaxKg: 24.9 * m * m,
  );
}

/// U.S. Navy circumference method, centimetres. Women need [hipCm].
/// Returns `null` for out-of-range or impossible measurements.
double? navyBodyFat({
  required Sex sex,
  required double heightCm,
  required double neckCm,
  required double waistCm,
  double? hipCm,
}) {
  bool ok(double v, double lo, double hi) => v.isFinite && v >= lo && v <= hi;
  if (!ok(heightCm, 120, 230) || !ok(neckCm, 20, 70) || !ok(waistCm, 40, 200)) {
    return null;
  }
  final double result;
  if (sex == Sex.male) {
    final d = waistCm - neckCm;
    if (d <= 0) return null;
    result =
        495 / (1.0324 - 0.19077 * _log10(d) + 0.15456 * _log10(heightCm)) - 450;
  } else {
    final hip = hipCm;
    if (hip == null || !ok(hip, 50, 200)) return null;
    final d = waistCm + hip - neckCm;
    if (d <= 0) return null;
    result =
        495 / (1.29579 - 0.35004 * _log10(d) + 0.22100 * _log10(heightCm)) -
        450;
  }
  // Outside a physiological range the measurements were almost certainly
  // mistyped; say so rather than show a number.
  if (!result.isFinite || result < 2 || result > 60) return null;
  return result;
}

double _log10(double x) => math.log(x) / math.ln10;

class DueDateEstimate {
  const DueDateEstimate({
    required this.dueDate,
    required this.gestationWeeks,
    required this.gestationDays,
  });

  final DateTime dueDate;
  final int gestationWeeks;
  final int gestationDays;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// [lmp] = first day of the last menstrual period. Valid when it is not in
/// the future, at most 42 weeks before [today], and the cycle is 21–35 days.
DueDateEstimate? dueDate({
  required DateTime lmp,
  required DateTime today,
  int cycleDays = 28,
}) {
  final start = _day(lmp);
  final now = _day(today);
  if (cycleDays < minCycleDays || cycleDays > maxCycleDays) return null;
  if (start.isAfter(now)) return null;
  final elapsed = now.difference(start).inDays;
  if (elapsed > 42 * 7) return null;
  // Calendar-day arithmetic (DateTime(y, m, d + n)) avoids DST drift.
  final due = DateTime(
    start.year,
    start.month,
    start.day + 280 + (cycleDays - 28),
  );
  return DueDateEstimate(
    dueDate: due,
    gestationWeeks: elapsed ~/ 7,
    gestationDays: elapsed % 7,
  );
}

class FertilityEstimate {
  const FertilityEstimate({
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
    required this.nextPeriod,
  });

  final DateTime ovulation;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final DateTime nextPeriod;
}

/// Next expected cycle from [lmp] for a regular 21–35 day cycle. [lmp] must
/// not be in the future and at most one cycle plus 14 days ago.
FertilityEstimate? fertileWindow({
  required DateTime lmp,
  required DateTime today,
  required int cycleDays,
}) {
  final start = _day(lmp);
  final now = _day(today);
  if (cycleDays < minCycleDays || cycleDays > maxCycleDays) return null;
  if (start.isAfter(now)) return null;
  if (now.difference(start).inDays > cycleDays + 14) return null;
  DateTime add(int days) => DateTime(start.year, start.month, start.day + days);
  final ovulationDay = cycleDays - 14;
  return FertilityEstimate(
    ovulation: add(ovulationDay),
    fertileStart: add(ovulationDay - 5),
    fertileEnd: add(ovulationDay),
    nextPeriod: add(cycleDays),
  );
}
