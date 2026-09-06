/// Static nutrition reference data — foods and meal recipes.
///
/// Ported from the standalone Nutrition project (C:\…\Desktop\Nutrition) and
/// kept offline: no database table, no network. The food and recipe lists are
/// small, curated reference sets shown in the Nutrition section.
library;

class NutritionFood {
  const NutritionFood({
    required this.name,
    required this.category,
    required this.serving,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.satFat,
    required this.micros,
    this.allergens = const [],
  });

  final String name;
  final String category;
  final String serving;
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

const nutritionFoods = <NutritionFood>[
  NutritionFood(
    name: 'Grilled chicken breast',
    category: 'Protein',
    serving: '100 g',
    protein: 31,
    carbs: 0,
    fat: 3.6,
    sugar: 0,
    satFat: 1,
    micros: {'Sodium': '74 mg', 'Potassium': '256 mg', 'Iron': '5% DV', 'Vitamin B6': '30% DV'},
  ),
  NutritionFood(
    name: 'Baked salmon fillet',
    category: 'Protein · healthy fat',
    serving: '100 g',
    protein: 22,
    carbs: 0,
    fat: 13,
    sugar: 0,
    satFat: 2.5,
    micros: {'Omega-3': '2.3 g', 'Vitamin D': '100% DV', 'Potassium': '363 mg', 'Vitamin B12': '50% DV'},
    allergens: ['fish'],
  ),
  NutritionFood(
    name: 'Whole boiled egg',
    category: 'Protein',
    serving: '1 egg (50 g)',
    protein: 6.3,
    carbs: 0.4,
    fat: 5.3,
    sugar: 0.2,
    satFat: 1.6,
    micros: {'Choline': '147 mg', 'Vitamin A': '5% DV', 'Iron': '4% DV', 'Calcium': '2% DV'},
    allergens: ['egg'],
  ),
  NutritionFood(
    name: 'Plain non-fat Greek yogurt',
    category: 'Dairy · protein',
    serving: '170 g',
    protein: 17,
    carbs: 6,
    fat: 0.7,
    sugar: 6,
    satFat: 0.2,
    micros: {'Calcium': '18% DV', 'Potassium': '240 mg', 'Vitamin B12': '20% DV'},
    allergens: ['dairy', 'milk'],
  ),
  NutritionFood(
    name: 'Rolled oats (dry)',
    category: 'Carbohydrate',
    serving: '50 g',
    protein: 6.5,
    carbs: 34,
    fat: 3.5,
    sugar: 0.5,
    satFat: 0.6,
    micros: {'Fibre': '5 g', 'Iron': '10% DV', 'Magnesium': '15% DV', 'Zinc': '8% DV'},
    allergens: ['gluten'],
  ),
  NutritionFood(
    name: 'Cooked brown rice',
    category: 'Carbohydrate',
    serving: '150 g',
    protein: 4.5,
    carbs: 38,
    fat: 1.4,
    sugar: 0.5,
    satFat: 0.3,
    micros: {'Fibre': '2.7 g', 'Magnesium': '11% DV', 'Manganese': '44% DV'},
  ),
  NutritionFood(
    name: 'Baked sweet potato',
    category: 'Carbohydrate',
    serving: '130 g',
    protein: 2.6,
    carbs: 27,
    fat: 0.2,
    sugar: 7.4,
    satFat: 0.05,
    micros: {'Fibre': '4 g', 'Vitamin A': '400% DV', 'Vitamin C': '25% DV', 'Potassium': '475 mg'},
  ),
  NutritionFood(
    name: 'Fresh avocado',
    category: 'Healthy fat',
    serving: '100 g',
    protein: 2,
    carbs: 8.5,
    fat: 15,
    sugar: 0.7,
    satFat: 2.1,
    micros: {'Fibre': '6.7 g', 'Potassium': '485 mg', 'Vitamin E': '10% DV', 'Vitamin K': '26% DV'},
  ),
  NutritionFood(
    name: 'Raw almonds',
    category: 'Nuts · fat',
    serving: '30 g',
    protein: 6,
    carbs: 6,
    fat: 15,
    sugar: 1.2,
    satFat: 1.1,
    micros: {'Fibre': '3.5 g', 'Magnesium': '20% DV', 'Vitamin E': '37% DV', 'Calcium': '7% DV'},
    allergens: ['nuts', 'tree nuts', 'almond'],
  ),
  NutritionFood(
    name: 'Fresh red apple',
    category: 'Fruit',
    serving: '1 medium (182 g)',
    protein: 0.5,
    carbs: 25,
    fat: 0.3,
    sugar: 19,
    satFat: 0.05,
    micros: {'Fibre': '4.4 g', 'Vitamin C': '14% DV', 'Potassium': '195 mg'},
  ),
  NutritionFood(
    name: 'Fresh ripe banana',
    category: 'Fruit',
    serving: '1 medium (118 g)',
    protein: 1.3,
    carbs: 27,
    fat: 0.4,
    sugar: 14,
    satFat: 0.1,
    micros: {'Fibre': '3.1 g', 'Vitamin B6': '33% DV', 'Vitamin C': '11% DV', 'Potassium': '422 mg'},
  ),
  NutritionFood(
    name: 'Steamed broccoli',
    category: 'Vegetable',
    serving: '150 g',
    protein: 3.7,
    carbs: 8,
    fat: 0.6,
    sugar: 2.1,
    satFat: 0.1,
    micros: {'Fibre': '3.8 g', 'Vitamin C': '135% DV', 'Vitamin K': '115% DV', 'Folate': '14% DV'},
  ),
];

enum MealType { breakfast, lunch, dinner, sweet }

class MealRecipe {
  const MealRecipe({
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.allergens,
    required this.prepTime,
    required this.instructions,
  });

  final String name;
  final MealType type;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final List<String> allergens;
  final String prepTime;
  final String instructions;

  /// True unless any user allergen appears in this recipe's tags or
  /// ingredient list.
  bool isSafeFor(List<String> userAllergens) {
    if (userAllergens.isEmpty) return true;
    bool hit(String hay) =>
        userAllergens.any((a) => hay.contains(a) || a.contains(hay));
    if (allergens.any(hit)) return false;
    return !ingredients.any((i) {
      final ing = i.toLowerCase();
      return userAllergens.any(ing.contains);
    });
  }
}

const mealRecipes = <MealRecipe>[
  MealRecipe(
    name: 'High-protein oatmeal & fruit bowl',
    type: MealType.breakfast,
    calories: 400,
    protein: 28,
    carbs: 52,
    fat: 9,
    ingredients: ['rolled oats', 'egg whites or whey protein', 'berries', 'chia seeds', 'cinnamon'],
    allergens: ['gluten', 'dairy', 'egg'],
    prepTime: '10 min',
    instructions: 'Cook rolled oats in water or milk, stir in the protein source, top with fresh berries and chia seeds.',
  ),
  MealRecipe(
    name: 'Avocado & egg-white veggie toast',
    type: MealType.breakfast,
    calories: 380,
    protein: 24,
    carbs: 35,
    fat: 14,
    ingredients: ['whole grain bread', 'egg whites', 'fresh avocado', 'spinach', 'cherry tomatoes'],
    allergens: ['gluten', 'egg'],
    prepTime: '12 min',
    instructions: 'Toast the bread, scramble egg whites with spinach, spread mashed avocado and top with tomatoes.',
  ),
  MealRecipe(
    name: 'Greek yogurt berry parfait',
    type: MealType.breakfast,
    calories: 320,
    protein: 26,
    carbs: 40,
    fat: 4,
    ingredients: ['non-fat greek yogurt', 'strawberries', 'blueberries', 'honey', 'pumpkin seeds'],
    allergens: ['dairy', 'milk'],
    prepTime: '5 min',
    instructions: 'Layer Greek yogurt with fresh berries, finish with a drizzle of honey and pumpkin seeds.',
  ),
  MealRecipe(
    name: 'Mediterranean grilled chicken & quinoa salad',
    type: MealType.lunch,
    calories: 520,
    protein: 42,
    carbs: 48,
    fat: 16,
    ingredients: ['grilled chicken breast', 'cooked quinoa', 'cucumber', 'olive oil', 'lemon juice', 'feta cheese'],
    allergens: ['dairy'],
    prepTime: '20 min',
    instructions: 'Toss diced grilled chicken, cooked quinoa, sliced cucumber and a lemon–olive oil dressing.',
  ),
  MealRecipe(
    name: 'Seared salmon with sweet potato & asparagus',
    type: MealType.lunch,
    calories: 560,
    protein: 38,
    carbs: 42,
    fat: 22,
    ingredients: ['wild salmon fillet', 'baked sweet potato', 'steamed asparagus', 'olive oil'],
    allergens: ['fish'],
    prepTime: '25 min',
    instructions: 'Pan-sear the salmon in olive oil; serve with baked sweet potato wedges and steamed asparagus.',
  ),
  MealRecipe(
    name: 'Herb-baked turkey breast with roasted vegetables',
    type: MealType.dinner,
    calories: 460,
    protein: 44,
    carbs: 32,
    fat: 12,
    ingredients: ['turkey breast', 'roasted cauliflower', 'carrots', 'olive oil', 'rosemary'],
    allergens: [],
    prepTime: '30 min',
    instructions: 'Season the turkey with herbs and olive oil, roast alongside carrots and cauliflower.',
  ),
  MealRecipe(
    name: 'Pan-seared white fish with quinoa & broccoli',
    type: MealType.dinner,
    calories: 420,
    protein: 38,
    carbs: 44,
    fat: 9,
    ingredients: ['cod fillet', 'quinoa', 'steamed broccoli', 'lemon', 'parsley'],
    allergens: ['fish'],
    prepTime: '20 min',
    instructions: 'Pan-fry the cod with lemon juice and herbs; serve over cooked quinoa with broccoli.',
  ),
  MealRecipe(
    name: 'Protein chocolate chia pudding',
    type: MealType.sweet,
    calories: 220,
    protein: 14,
    carbs: 22,
    fat: 8,
    ingredients: ['chia seeds', 'unsweetened almond milk', 'cocoa powder', 'whey protein', 'stevia'],
    allergens: ['dairy', 'milk', 'nuts', 'almond'],
    prepTime: '5 min + chill',
    instructions: 'Whisk chia seeds, cocoa, protein powder and almond milk; chill until set.',
  ),
  MealRecipe(
    name: 'Fresh berry & Greek yogurt whip',
    type: MealType.sweet,
    calories: 180,
    protein: 16,
    carbs: 20,
    fat: 2,
    ingredients: ['greek yogurt', 'raspberries', 'blueberries', 'vanilla extract'],
    allergens: ['dairy', 'milk'],
    prepTime: '5 min',
    instructions: 'Whip Greek yogurt with vanilla, top with fresh berries.',
  ),
];
