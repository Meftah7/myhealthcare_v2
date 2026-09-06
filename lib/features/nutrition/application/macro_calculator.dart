/// Mifflin–St Jeor BMR/TDEE and macronutrient targets.
///
/// Ported from the standalone Nutrition project's `MacroCalculator`.
library;

import 'dart:math';

enum Sex { male, female }

enum FitnessGoal { maintain, lose, gain }

enum MacroPreset { balanced, lowFat, lowCarb, highCarb, highProtein }

class MacroInputs {
  const MacroInputs({
    required this.age,
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.activityFactor,
    required this.goal,
    required this.weeklyRateKg,
    required this.preset,
  });

  final int age;
  final Sex sex;
  final double weightKg;
  final double heightCm;

  /// 1.2 (sedentary) … 1.9 (extra active).
  final double activityFactor;
  final FitnessGoal goal;

  /// 0.25 / 0.5 / 1.0 kg per week.
  final double weeklyRateKg;
  final MacroPreset preset;

  MacroInputs copyWith({
    int? age,
    Sex? sex,
    double? weightKg,
    double? heightCm,
    double? activityFactor,
    FitnessGoal? goal,
    double? weeklyRateKg,
    MacroPreset? preset,
  }) {
    return MacroInputs(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activityFactor: activityFactor ?? this.activityFactor,
      goal: goal ?? this.goal,
      weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
      preset: preset ?? this.preset,
    );
  }
}

class MacroResult {
  const MacroResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.maxSugar,
    required this.maxSatFat,
  });

  final int bmr;
  final int tdee;
  final int targetCalories;
  final int protein;
  final int carbs;
  final int fat;
  final int maxSugar;
  final int maxSatFat;
}

MacroResult calculateMacros(MacroInputs i) {
  final bmr = i.sex == Sex.male
      ? (10 * i.weightKg) + (6.25 * i.heightCm) - (5 * i.age) + 5
      : (10 * i.weightKg) + (6.25 * i.heightCm) - (5 * i.age) - 161;

  final tdee = bmr * i.activityFactor;

  final adjustment = switch (i.weeklyRateKg) {
    0.25 => 275.0,
    0.5 => 550.0,
    1.0 => 1100.0,
    _ => 0.0,
  };

  var target = tdee;
  if (i.goal == FitnessGoal.lose) {
    target = max(1200, tdee - adjustment);
  } else if (i.goal == FitnessGoal.gain) {
    target = tdee + adjustment;
  }

  final (pRatio, cRatio, fRatio) = switch (i.preset) {
    MacroPreset.balanced => (0.30, 0.40, 0.30),
    MacroPreset.lowFat => (0.35, 0.50, 0.15),
    MacroPreset.lowCarb => (0.40, 0.20, 0.40),
    MacroPreset.highCarb => (0.20, 0.60, 0.20),
    MacroPreset.highProtein => (0.40, 0.35, 0.25),
  };

  return MacroResult(
    bmr: bmr.round(),
    tdee: tdee.round(),
    targetCalories: target.round(),
    protein: ((target * pRatio) / 4).round(),
    carbs: ((target * cRatio) / 4).round(),
    fat: ((target * fRatio) / 9).round(),
    maxSugar: ((target * 0.08) / 4).round(),
    maxSatFat: ((target * 0.09) / 9).round(),
  );
}
