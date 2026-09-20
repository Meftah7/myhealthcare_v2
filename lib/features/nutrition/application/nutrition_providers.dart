/// Nutrition-section state: the patient's macro targets (shared between the
/// calculator and the meal planner), the food database, and its filters.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/enums.dart' as app;
import '../../patient/application/patient_data_providers.dart';
import '../domain/nutrition_data.dart';
import 'macro_calculator.dart';

/// A sensible starting point for the calculator, pre-filled from the patient's
/// own profile where it's known (age from date of birth, sex from gender).
final defaultMacroInputsProvider = Provider<MacroInputs>((ref) {
  final profile = ref.watch(patientProfileProvider).valueOrNull;
  final dob = profile?.user.dob;
  final age = dob == null
      ? 30
      : ((DateTime.now().difference(dob).inDays) / 365).floor().clamp(14, 100);
  final sex = switch (profile?.user.gender) {
    app.Gender.male => Sex.male,
    app.Gender.female => Sex.female,
    _ => Sex.male,
  };
  return MacroInputs(
    age: age,
    sex: sex,
    weightKg: 70,
    heightCm: 175,
    activityFactor: 1.375,
    goal: FitnessGoal.maintain,
    weeklyRateKg: 0.5,
    preset: MacroPreset.balanced,
  );
});

// --- macro calculator -----------------------------------------------------

const _macroAgeKey = 'nutrition.age';
const _macroSexKey = 'nutrition.sex';
const _macroWeightKey = 'nutrition.weightKg';
const _macroHeightKey = 'nutrition.heightCm';
const _macroActivityKey = 'nutrition.activityFactor';
const _macroGoalKey = 'nutrition.goal';
const _macroRateKey = 'nutrition.weeklyRateKg';
const _macroPresetKey = 'nutrition.preset';

/// The inputs behind the last calculation, or null until the patient
/// calculates for the first time. Persisted to [SharedPreferences] (like the
/// rest of `ui_prefs.dart`'s device settings) so the Calculator and the Meal
/// plan survive closing the app, not just the session.
class MacroInputsController extends Notifier<MacroInputs?> {
  @override
  MacroInputs? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final age = prefs.getInt(_macroAgeKey);
    final sexName = prefs.getString(_macroSexKey);
    final weight = prefs.getDouble(_macroWeightKey);
    final height = prefs.getDouble(_macroHeightKey);
    final activity = prefs.getDouble(_macroActivityKey);
    final goalName = prefs.getString(_macroGoalKey);
    final rate = prefs.getDouble(_macroRateKey);
    final presetName = prefs.getString(_macroPresetKey);
    if (age == null ||
        sexName == null ||
        weight == null ||
        height == null ||
        activity == null ||
        goalName == null ||
        rate == null ||
        presetName == null) {
      return null;
    }
    return MacroInputs(
      age: age,
      sex: Sex.values.byName(sexName),
      weightKg: weight,
      heightCm: height,
      activityFactor: activity,
      goal: FitnessGoal.values.byName(goalName),
      weeklyRateKg: rate,
      preset: MacroPreset.values.byName(presetName),
    );
  }

  Future<void> set(MacroInputs inputs) async {
    state = inputs;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_macroAgeKey, inputs.age);
    await prefs.setString(_macroSexKey, inputs.sex.name);
    await prefs.setDouble(_macroWeightKey, inputs.weightKg);
    await prefs.setDouble(_macroHeightKey, inputs.heightCm);
    await prefs.setDouble(_macroActivityKey, inputs.activityFactor);
    await prefs.setString(_macroGoalKey, inputs.goal.name);
    await prefs.setDouble(_macroRateKey, inputs.weeklyRateKg);
    await prefs.setString(_macroPresetKey, inputs.preset.name);
  }

  Future<void> clear() async {
    state = null;
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in [
      _macroAgeKey,
      _macroSexKey,
      _macroWeightKey,
      _macroHeightKey,
      _macroActivityKey,
      _macroGoalKey,
      _macroRateKey,
      _macroPresetKey,
    ]) {
      await prefs.remove(key);
    }
  }
}

final macroInputsProvider =
    NotifierProvider<MacroInputsController, MacroInputs?>(
      MacroInputsController.new,
    );

/// The last-computed macro targets, or null until the patient calculates —
/// purely derived from [macroInputsProvider], which is what's actually
/// persisted.
final macroTargetsProvider = Provider<MacroResult?>((ref) {
  final inputs = ref.watch(macroInputsProvider);
  return inputs == null ? null : calculateMacros(inputs);
});

// --- food database -------------------------------------------------------

/// The whole food set — curated staples + the compiled-in USDA extract.
final nutritionFoodsProvider = Provider<List<NutritionFood>>(
  (ref) => allNutritionFoods,
);

/// Every category present in the database, alphabetical — the filter chips.
final foodCategoriesProvider = Provider<List<String>>((ref) {
  return (ref.watch(nutritionFoodsProvider).map((f) => f.category).toSet().toList()
    ..sort());
});

final foodSearchQueryProvider = StateProvider<String>((_) => '');

/// The selected category chip, or null for "all".
final foodCategoryFilterProvider = StateProvider<String?>((_) => null);

final filteredFoodsProvider = Provider<List<NutritionFood>>((ref) {
  final foods = ref.watch(nutritionFoodsProvider);
  final q = ref.watch(foodSearchQueryProvider);
  final cat = ref.watch(foodCategoryFilterProvider);
  return foods
      .where((f) => f.matches(q) && (cat == null || f.category == cat))
      .toList();
});

// --- meal planner -------------------------------------------------------

/// How the day's calories are split across the meals. Breakfast / lunch /
/// dinner sum to 1.0; if a dessert is included it takes a slice and the three
/// mains are scaled to fit — the "Preferences" the meal plan is built on.
class MealSplit {
  const MealSplit({
    this.breakfast = 0.30,
    this.lunch = 0.40,
    this.dinner = 0.30,
    this.dessert = 0.0,
  });

  final double breakfast;
  final double lunch;
  final double dinner;
  final double dessert;

  double fractionFor(MealType t) => switch (t) {
    MealType.breakfast => breakfast,
    MealType.lunch => lunch,
    MealType.dinner => dinner,
    MealType.sweet => dessert,
  };

  MealSplit withDessert(bool on) => on
      ? const MealSplit(
          breakfast: 0.28,
          lunch: 0.37,
          dinner: 0.28,
          dessert: 0.07,
        )
      : const MealSplit();
}

/// One meal's slice of the daily targets.
class MealTargets {
  const MealTargets({
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final MealType type;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
}

/// Meal-planner input: whether the day is split into three meals or four.
class MealPlanRequest {
  const MealPlanRequest({this.includeSweet = true});
  final bool includeSweet;
}

class GeneratedMealPlan {
  const GeneratedMealPlan({required this.perMeal});

  /// The daily targets divided across the meals — null when the patient hasn't
  /// run the calculator yet.
  final List<MealTargets>? perMeal;
}

const _mealIncludeSweetKey = 'nutrition.includeSweet';

class MealPlanController extends Notifier<GeneratedMealPlan?> {
  @override
  GeneratedMealPlan? build() {
    // Re-derive the plan the patient last generated: if there's a saved
    // "include dessert" choice and the calculator's targets survived the
    // restart too (via [macroInputsProvider]), rebuild it immediately
    // instead of making them press "Build my day" again.
    final prefs = ref.read(sharedPreferencesProvider);
    final includeSweet = prefs.getBool(_mealIncludeSweetKey);
    if (includeSweet == null || ref.watch(macroTargetsProvider) == null) {
      return null;
    }
    return _generate(MealPlanRequest(includeSweet: includeSweet));
  }

  void generate(MealPlanRequest req) {
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setBool(_mealIncludeSweetKey, req.includeSweet),
    );
    state = _generate(req);
  }

  GeneratedMealPlan? _generate(MealPlanRequest req) {
    final types = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      if (req.includeSweet) MealType.sweet,
    ];

    final targets = ref.read(macroTargetsProvider);
    List<MealTargets>? perMeal;
    if (targets != null) {
      final split = const MealSplit().withDessert(req.includeSweet);
      perMeal = [
        for (final t in types)
          MealTargets(
            type: t,
            calories:
                (targets.targetCalories * split.fractionFor(t)).round(),
            protein: (targets.protein * split.fractionFor(t)).round(),
            carbs: (targets.carbs * split.fractionFor(t)).round(),
            fat: (targets.fat * split.fractionFor(t)).round(),
          ),
      ];
    }

    return GeneratedMealPlan(perMeal: perMeal);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_mealIncludeSweetKey);
  }
}

final mealPlanProvider =
    NotifierProvider<MealPlanController, GeneratedMealPlan?>(
      MealPlanController.new,
    );
