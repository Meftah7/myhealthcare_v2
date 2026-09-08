/// Nutrition-section state: the patient's macro targets (shared between the
/// calculator and the meal planner), the food database, and its filters.
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
/// Persisted for the session — this is the link between the Calculator and the
/// Meal plan.
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

class MealPlanController extends Notifier<GeneratedMealPlan?> {
  @override
  GeneratedMealPlan? build() => null;

  void generate(MealPlanRequest req) {
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

    state = GeneratedMealPlan(perMeal: perMeal);
  }

  void clear() => state = null;
}

final mealPlanProvider =
    NotifierProvider<MealPlanController, GeneratedMealPlan?>(
      MealPlanController.new,
    );
