/// Nutrition reference data — the food database and the meal recipes.
///
/// The food set is the USDA FoodData Central extract from the standalone
/// Nutrition project (`usda_foods.g.dart`, ~360 items across 14 categories)
/// plus a dozen hand-curated staples that carry allergen tags. Compiled in as
/// a `const` list — no table, no asset decode, no network.
library;

import 'usda_foods.g.dart';

class NutritionFood {
  const NutritionFood({
    required this.name,
    required this.category,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.satFat,
    required this.micros,
    this.allergens = const [],
  });

  factory NutritionFood.fromJson(Map<String, dynamic> j) {
    final p = (j['protein'] as num?)?.toDouble() ?? 0;
    final c = (j['carbs'] as num?)?.toDouble() ?? 0;
    final f = (j['fat'] as num?)?.toDouble() ?? 0;
    final kcal = (j['calories'] as num?)?.round() ??
        (p * 4 + c * 4 + f * 9).round();
    return NutritionFood(
      name: j['name'] as String,
      category: (j['category'] as String?) ?? 'Other',
      serving: (j['serving'] as String?) ?? '100 g',
      calories: kcal,
      protein: p,
      carbs: c,
      fat: f,
      sugar: (j['sugar'] as num?)?.toDouble() ?? 0,
      satFat: (j['satFat'] as num?)?.toDouble() ?? 0,
      micros: {
        for (final e in ((j['micros'] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      allergens: [
        for (final a in ((j['allergens'] as List?) ?? const [])) '$a',
      ],
    );
  }

  final String name;
  final String category;
  final String serving;

  /// kcal for [serving]. Computed from the macros when the source lacks it
  /// (4/4/9 kcal per gram of protein / carb / fat).
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double satFat;

  /// Micronutrient → amount / %DV, shown as chips.
  final Map<String, String> micros;
  final List<String> allergens;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

/// The whole food set: curated staples first (they carry allergen tags), then
/// the USDA extract.
final List<NutritionFood> allNutritionFoods = [..._curatedFoods, ...usdaFoods];

int _kcal(double p, double c, double f) => (p * 4 + c * 4 + f * 9).round();

/// A dozen staples with allergen tags — the meal planner and the "safe for me"
/// checks lean on these.
final List<NutritionFood> _curatedFoods = [
  NutritionFood(
    name: 'Grilled chicken breast',
    category: 'Poultry',
    serving: '100 g',
    calories: _kcal(31, 0, 3.6),
    protein: 31, carbs: 0, fat: 3.6, sugar: 0, satFat: 1,
    micros: {
      'Sodium': '74 mg',
      'Potassium': '256 mg',
      'Iron': '5% DV',
      'Vitamin B6': '30% DV',
    },
  ),
  NutritionFood(
    name: 'Baked salmon fillet',
    category: 'Seafood',
    serving: '100 g',
    calories: _kcal(22, 0, 13),
    protein: 22, carbs: 0, fat: 13, sugar: 0, satFat: 2.5,
    micros: {
      'Omega-3': '2.3 g',
      'Vitamin D': '100% DV',
      'Potassium': '363 mg',
      'Vitamin B12': '50% DV',
    },
    allergens: ['fish'],
  ),
  NutritionFood(
    name: 'Whole boiled egg',
    category: 'Dairy & eggs',
    serving: '1 egg (50 g)',
    calories: _kcal(6.3, 0.4, 5.3),
    protein: 6.3, carbs: 0.4, fat: 5.3, sugar: 0.2, satFat: 1.6,
    micros: {
      'Choline': '147 mg',
      'Vitamin A': '5% DV',
      'Iron': '4% DV',
      'Calcium': '2% DV',
    },
    allergens: ['egg'],
  ),
  NutritionFood(
    name: 'Plain non-fat Greek yogurt',
    category: 'Dairy & eggs',
    serving: '170 g',
    calories: _kcal(17, 6, 0.7),
    protein: 17, carbs: 6, fat: 0.7, sugar: 6, satFat: 0.2,
    micros: {
      'Calcium': '18% DV',
      'Potassium': '240 mg',
      'Vitamin B12': '20% DV',
    },
    allergens: ['dairy', 'milk'],
  ),
  NutritionFood(
    name: 'Rolled oats (dry)',
    category: 'Grains',
    serving: '50 g',
    calories: _kcal(6.5, 34, 3.5),
    protein: 6.5, carbs: 34, fat: 3.5, sugar: 0.5, satFat: 0.6,
    micros: {
      'Fibre': '5 g',
      'Iron': '10% DV',
      'Magnesium': '15% DV',
      'Zinc': '8% DV',
    },
    allergens: ['gluten'],
  ),
  NutritionFood(
    name: 'Cooked brown rice',
    category: 'Grains',
    serving: '150 g',
    calories: _kcal(4.5, 38, 1.4),
    protein: 4.5, carbs: 38, fat: 1.4, sugar: 0.5, satFat: 0.3,
    micros: {
      'Fibre': '2.7 g',
      'Magnesium': '11% DV',
      'Manganese': '44% DV',
    },
  ),
  NutritionFood(
    name: 'Baked sweet potato',
    category: 'Vegetables',
    serving: '130 g',
    calories: _kcal(2.6, 27, 0.2),
    protein: 2.6, carbs: 27, fat: 0.2, sugar: 7.4, satFat: 0.05,
    micros: {
      'Fibre': '4 g',
      'Vitamin A': '400% DV',
      'Vitamin C': '25% DV',
      'Potassium': '475 mg',
    },
  ),
  NutritionFood(
    name: 'Fresh avocado',
    category: 'Fruits',
    serving: '100 g',
    calories: _kcal(2, 8.5, 15),
    protein: 2, carbs: 8.5, fat: 15, sugar: 0.7, satFat: 2.1,
    micros: {
      'Fibre': '6.7 g',
      'Potassium': '485 mg',
      'Vitamin E': '10% DV',
      'Vitamin K': '26% DV',
    },
  ),
  NutritionFood(
    name: 'Raw almonds',
    category: 'Nuts & seeds',
    serving: '30 g',
    calories: _kcal(6, 6, 15),
    protein: 6, carbs: 6, fat: 15, sugar: 1.2, satFat: 1.1,
    micros: {
      'Fibre': '3.5 g',
      'Magnesium': '20% DV',
      'Vitamin E': '37% DV',
      'Calcium': '7% DV',
    },
    allergens: ['nuts', 'tree nuts', 'almond'],
  ),
  NutritionFood(
    name: 'Fresh red apple',
    category: 'Fruits',
    serving: '1 medium (182 g)',
    calories: _kcal(0.5, 25, 0.3),
    protein: 0.5, carbs: 25, fat: 0.3, sugar: 19, satFat: 0.05,
    micros: {
      'Fibre': '4.4 g',
      'Vitamin C': '14% DV',
      'Potassium': '195 mg',
    },
  ),
  NutritionFood(
    name: 'Fresh ripe banana',
    category: 'Fruits',
    serving: '1 medium (118 g)',
    calories: _kcal(1.3, 27, 0.4),
    protein: 1.3, carbs: 27, fat: 0.4, sugar: 14, satFat: 0.1,
    micros: {
      'Fibre': '3.1 g',
      'Vitamin B6': '33% DV',
      'Vitamin C': '11% DV',
      'Potassium': '422 mg',
    },
  ),
  NutritionFood(
    name: 'Steamed broccoli',
    category: 'Vegetables',
    serving: '150 g',
    calories: _kcal(3.7, 8, 0.6),
    protein: 3.7, carbs: 8, fat: 0.6, sugar: 2.1, satFat: 0.1,
    micros: {
      'Fibre': '3.8 g',
      'Vitamin C': '135% DV',
      'Vitamin K': '115% DV',
      'Folate': '14% DV',
    },
  ),
];

enum MealType { breakfast, lunch, dinner, sweet }

