/// Nutrition-section state: the patient's macro targets (shared between the
/// calculator and the meal planner) and the food search query.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// The last-computed macro targets, or null until the patient calculates.
/// Persisted for the session so the meal planner can use it.
class MacroTargetsController extends Notifier<MacroResult?> {
  @override
  MacroResult? build() => null;

  void set(MacroInputs inputs) => state = calculateMacros(inputs);
  void clear() => state = null;
}

final macroTargetsProvider =
    NotifierProvider<MacroTargetsController, MacroResult?>(
      MacroTargetsController.new,
    );

final foodSearchQueryProvider = StateProvider<String>((_) => '');

final filteredFoodsProvider = Provider<List<NutritionFood>>((ref) {
  final q = ref.watch(foodSearchQueryProvider);
  return nutritionFoods.where((f) => f.matches(q)).toList();
});

/// Meal-planner inputs and the generated plan.
class MealPlanRequest {
  const MealPlanRequest({this.allergens = const [], this.includeSweet = true});
  final List<String> allergens;
  final bool includeSweet;
}

class MealPlanController extends Notifier<List<MealRecipe>?> {
  @override
  List<MealRecipe>? build() => null;

  void generate(MealPlanRequest req) {
    final safe = <MealType, MealRecipe?>{};
    for (final type in MealType.values) {
      safe[type] = mealRecipes
          .where((m) => m.type == type && m.isSafeFor(req.allergens))
          .firstOrNull;
    }
    state = [
      if (safe[MealType.breakfast] != null) safe[MealType.breakfast]!,
      if (safe[MealType.lunch] != null) safe[MealType.lunch]!,
      if (safe[MealType.dinner] != null) safe[MealType.dinner]!,
      if (req.includeSweet && safe[MealType.sweet] != null)
        safe[MealType.sweet]!,
    ];
  }

  void clear() => state = null;
}

final mealPlanProvider =
    NotifierProvider<MealPlanController, List<MealRecipe>?>(
      MealPlanController.new,
    );
