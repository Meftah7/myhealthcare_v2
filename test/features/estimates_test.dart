// Health estimates: formulas against hand-checked values from the cited
// sources, and refusal of invalid input (no stale/extrapolated results).
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/features/health_tools/domain/estimates.dart';

void main() {
  group('ideal weight (Devine)', () {
    test('matches the published formula', () {
      // 180 cm = 70.866 in → 10.866 in over 5 ft.
      final m = idealWeight(sex: Sex.male, heightCm: 180)!;
      expect(m.devineKg, closeTo(50 + 2.3 * 10.866, 0.01));
      final f = idealWeight(sex: Sex.female, heightCm: 165)!;
      expect(f.devineKg, closeTo(45.5 + 2.3 * (165 / 2.54 - 60), 0.001));
      expect(f.healthyMinKg, closeTo(18.5 * 1.65 * 1.65, 0.001));
      expect(f.healthyMaxKg, closeTo(24.9 * 1.65 * 1.65, 0.001));
    });

    test('undefined below 5 ft or for invalid input', () {
      expect(idealWeight(sex: Sex.male, heightCm: 150), isNull);
      expect(idealWeight(sex: Sex.male, heightCm: double.nan), isNull);
      expect(idealWeight(sex: Sex.female, heightCm: -170), isNull);
    });
  });

  group('body fat (U.S. Navy)', () {
    test('male reference case', () {
      // 495/(1.0324 − 0.19077·log10(47) + 0.15456·log10(180)) − 450 = 16.10
      expect(
        navyBodyFat(sex: Sex.male, heightCm: 180, neckCm: 38, waistCm: 85),
        closeTo(16.10, 0.02),
      );
    });

    test('female reference case needs hips', () {
      expect(
        navyBodyFat(sex: Sex.female, heightCm: 165, neckCm: 33, waistCm: 75),
        isNull,
      );
      expect(
        navyBodyFat(
          sex: Sex.female,
          heightCm: 165,
          neckCm: 33,
          waistCm: 75,
          hipCm: 100,
        ),
        closeTo(29.43, 0.02), // denominator 1.03247
      );
    });

    test('impossible measurements return no result', () {
      expect(
        navyBodyFat(sex: Sex.male, heightCm: 180, neckCm: 40, waistCm: 40),
        isNull,
      );
      expect(
        navyBodyFat(sex: Sex.male, heightCm: 180, neckCm: -1, waistCm: 85),
        isNull,
      );
    });
  });

  group('due date (Naegele)', () {
    final today = DateTime(2026, 10, 13);

    test('LMP + 280 days, adjusted for cycle length', () {
      final e = dueDate(lmp: DateTime(2026, 8, 1), today: today)!;
      expect(e.dueDate, DateTime(2027, 5, 8));
      expect((e.gestationWeeks, e.gestationDays), (10, 3));
      final long = dueDate(
        lmp: DateTime(2026, 8, 1),
        today: today,
        cycleDays: 32,
      )!;
      expect(long.dueDate, DateTime(2027, 5, 12));
    });

    test('crosses a leap day correctly', () {
      final e = dueDate(lmp: DateTime(2027, 5, 26), today: DateTime(2027, 6))!;
      expect(e.dueDate, DateTime(2028, 3, 1)); // 2028-02-29 exists
    });

    test('rejects future LMP, very old LMP and irregular cycles', () {
      expect(dueDate(lmp: DateTime(2026, 10, 20), today: today), isNull);
      expect(dueDate(lmp: DateTime(2025, 10, 1), today: today), isNull);
      expect(
        dueDate(lmp: DateTime(2026, 9, 1), today: today, cycleDays: 40),
        isNull,
      );
    });
  });

  group('fertile window', () {
    final today = DateTime(2026, 10, 13);

    test('ovulation 14 days before the next period', () {
      final e = fertileWindow(
        lmp: DateTime(2026, 10, 1),
        today: today,
        cycleDays: 28,
      )!;
      expect(e.ovulation, DateTime(2026, 10, 15));
      expect(e.fertileStart, DateTime(2026, 10, 10));
      expect(e.fertileEnd, DateTime(2026, 10, 15));
      expect(e.nextPeriod, DateTime(2026, 10, 29));
    });

    test('rejects out-of-range input', () {
      expect(
        fertileWindow(lmp: DateTime(2026, 10, 1), today: today, cycleDays: 50),
        isNull,
      );
      expect(
        fertileWindow(lmp: DateTime(2026, 11, 1), today: today, cycleDays: 28),
        isNull,
      );
      expect(
        fertileWindow(lmp: DateTime(2026, 7, 1), today: today, cycleDays: 28),
        isNull,
      );
    });
  });
}
