/// Nutrition-section state: the patient's macro targets (shared between the
/// calculator and the meal planner), the food database, and its filters.
///
/// The calculator inputs and the "include dessert" preference are device data
/// (like the settings in `app/settings/ui_prefs.dart`), so they're mirrored
/// into [SharedPreferences] and survive closing the app — the macro targets
/// and meal plan themselves are just recomputed from them on the next launch.
library;

import 'dart:convert';

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

const _macroInputsKey = 'nutrition.macroInputs';

Map<String, dynamic> _encodeMacroInputs(MacroInputs i) => {
  'age': i.age,
  'sex': i.sex.name,
  'weightKg': i.weightKg,
  'heightCm': i.heightCm,
  'activityFactor': i.activityFactor,
  'goal': i.goal.name,
  'weeklyRateKg': i.weeklyRateKg,
  'preset': i.preset.name,
};

MacroInputs? _decodeMacroInputs(String? raw) {
  if (raw == null) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return MacroInputs(
      age: map['age'] as int,
      sex: Sex.values.byName(map['sex'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
      heightCm: (map['heightCm'] as num).toDouble(),
      activityFactor: (map['activityFactor'] as num).toDouble(),
      goal: FitnessGoal.values.byName(map['goal'] as String),
      weeklyRateKg: (map['weeklyRateKg'] as num).toDouble(),
      preset: MacroPreset.values.byName(map['preset'] as String),
    );
  } catch (_) {
    return null;
  }
}

/// The calculator inputs last saved to the device, or null if the patient has
/// never run the calculator. Read once by the calculator form to restore its
/// fields after the app restarts.
final savedMacroInputsProvider = Provider<MacroInputs?>(
  (ref) => _decodeMacroInputs(
    ref.watch(sharedPreferencesProvider).getString(_macroInputsKey),
  ),
);

/// The last-computed macro targets, or null until the patient calculates.
/// This is the link between the Calculator and the Meal plan, and it's
/// restored from the device on launch by recomputing from the saved inputs.
class MacroTargetsController extends Notifier<MacroResult?> {
  @override
  MacroResult? build() {
    final inputs = ref.watch(savedMacroInputsProvider);
    return inputs == null ? null : calculateMacros(inputs);
  }

  Future<void> set(MacroInputs inputs) async {
    state = calculateMacros(inputs);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_macroInputsKey, jsonEncode(_encodeMacroInputs(inputs)));
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_macroInputsKey);
  }
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

const _includeSweetKey = 'nutrition.includeSweet';

/// The "include dessert" toggle last saved to the device — read once by the
/// meal-plan form to restore its switch after the app restarts.
final savedIncludeSweetProvider = Provider<bool>(
  (ref) =>
      ref.watch(sharedPreferencesProvider).getBool(_includeSweetKey) ?? true,
);

GeneratedMealPlan _buildPlan(MacroResult? targets, bool includeSweet) {
  final types = [
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
    if (includeSweet) MealType.sweet,
  ];

  List<MealTargets>? perMeal;
  if (targets != null) {
    final split = const MealSplit().withDessert(includeSweet);
    perMeal = [
      for (final t in types)
        MealTargets(
          type: t,
          calories: (targets.targetCalories * split.fractionFor(t)).round(),
          protein: (targets.protein * split.fractionFor(t)).round(),
          carbs: (targets.carbs * split.fractionFor(t)).round(),
          fat: (targets.fat * split.fractionFor(t)).round(),
        ),
    ];
  }
  return GeneratedMealPlan(perMeal: perMeal);
}

class MealPlanController extends Notifier<GeneratedMealPlan?> {
  @override
  GeneratedMealPlan? build() {
    final targets = ref.watch(macroTargetsProvider);
    if (targets == null) return null;
    // The patient already ran the calculator on a previous visit — rebuild
    // the plan they last generated instead of making them tap the button
    // again every time the app restarts.
    return _buildPlan(targets, ref.watch(savedIncludeSweetProvider));
  }

  Future<void> generate(MealPlanRequest req) async {
    state = _buildPlan(ref.read(macroTargetsProvider), req.includeSweet);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_includeSweetKey, req.includeSweet);
  }

  void clear() => state = null;
}

final mealPlanProvider =
    NotifierProvider<MealPlanController, GeneratedMealPlan?>(
      MealPlanController.new,
    );
