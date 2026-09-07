/// Nutrition — macro/calorie targets, a food reference, and an allergen-safe
/// meal planner. Ported from the standalone Nutrition project and rebuilt on
/// the app's design system; runs the same on phone, tablet, desktop and web.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/macro_calculator.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition_data.dart';

enum _View { targets, foods, meals }

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  _View _view = _View.targets;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: const [PatientTopActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.sm),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_View>(
                    segments: const [
                      ButtonSegment(
                        value: _View.targets,
                        icon: Icon(Icons.track_changes_outlined),
                        label: Text('Targets'),
                      ),
                      ButtonSegment(
                        value: _View.foods,
                        icon: Icon(Icons.search),
                        label: Text('Foods'),
                      ),
                      ButtonSegment(
                        value: _View.meals,
                        icon: Icon(Icons.restaurant_menu),
                        label: Text('Meal plan'),
                      ),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: switch (_view) {
                  _View.targets => const _TargetsView(),
                  _View.foods => const _FoodsView(),
                  _View.meals => const _MealPlanView(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Targets — the calorie & macro calculator
// ---------------------------------------------------------------------------

class _TargetsView extends ConsumerStatefulWidget {
  const _TargetsView();

  @override
  ConsumerState<_TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends ConsumerState<_TargetsView> {
  MacroInputs? _inputs;
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _height;

  @override
  void initState() {
    super.initState();
    _age = TextEditingController();
    _weight = TextEditingController();
    _height = TextEditingController();
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  MacroInputs get _i => _inputs ??= _seed();

  MacroInputs _seed() {
    final d = ref.read(defaultMacroInputsProvider);
    _age.text = '${d.age}';
    _weight.text = _trim(d.weightKg);
    _height.text = _trim(d.heightCm);
    return d;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  void _update(MacroInputs next) {
    setState(() => _inputs = next);
    // Live-update the result if one is already showing.
    if (ref.read(macroTargetsProvider) != null) {
      ref.read(macroTargetsProvider.notifier).set(next);
    }
  }

  void _calculate() {
    final next = _i.copyWith(
      age: int.tryParse(_age.text) ?? _i.age,
      weightKg: double.tryParse(_weight.text) ?? _i.weightKg,
      heightCm: double.tryParse(_height.text) ?? _i.heightCm,
    );
    setState(() => _inputs = next);
    ref.read(macroTargetsProvider.notifier).set(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = ref.watch(macroTargetsProvider);
    final cols = WindowSize.of(context).isCompact ? 2 : 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
      children: [
        const SectionHeader('About you', overline: true),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(labelText: 'Age'),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: DropdownButtonFormField<Sex>(
                      initialValue: _i.sex,
                      decoration: const InputDecoration(labelText: 'Sex'),
                      items: const [
                        DropdownMenuItem(value: Sex.male, child: Text('Male')),
                        DropdownMenuItem(
                          value: Sex.female,
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (v) =>
                          v == null ? null : _update(_i.copyWith(sex: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: TextField(
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<double>(
                initialValue: _i.activityFactor,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Activity'),
                items: const [
                  DropdownMenuItem(value: 1.2, child: Text('Sedentary')),
                  DropdownMenuItem(
                    value: 1.375,
                    child: Text('Lightly active (1–3 days/wk)'),
                  ),
                  DropdownMenuItem(
                    value: 1.55,
                    child: Text('Moderately active (3–5 days/wk)'),
                  ),
                  DropdownMenuItem(
                    value: 1.725,
                    child: Text('Very active (6–7 days/wk)'),
                  ),
                  DropdownMenuItem(
                    value: 1.9,
                    child: Text('Extra active (physical job)'),
                  ),
                ],
                onChanged: (v) => v == null
                    ? null
                    : _update(_i.copyWith(activityFactor: v)),
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<FitnessGoal>(
                initialValue: _i.goal,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: const [
                  DropdownMenuItem(
                    value: FitnessGoal.maintain,
                    child: Text('Maintain weight'),
                  ),
                  DropdownMenuItem(
                    value: FitnessGoal.lose,
                    child: Text('Lose weight'),
                  ),
                  DropdownMenuItem(
                    value: FitnessGoal.gain,
                    child: Text('Gain weight'),
                  ),
                ],
                onChanged: (v) =>
                    v == null ? null : _update(_i.copyWith(goal: v)),
              ),
              if (_i.goal != FitnessGoal.maintain) ...[
                const SizedBox(height: Space.sm),
                DropdownButtonFormField<double>(
                  initialValue: _i.weeklyRateKg,
                  decoration: const InputDecoration(labelText: 'Weekly rate'),
                  items: const [
                    DropdownMenuItem(value: 0.25, child: Text('0.25 kg / week')),
                    DropdownMenuItem(value: 0.5, child: Text('0.5 kg / week')),
                    DropdownMenuItem(value: 1.0, child: Text('1.0 kg / week')),
                  ],
                  onChanged: (v) => v == null
                      ? null
                      : _update(_i.copyWith(weeklyRateKg: v)),
                ),
              ],
              const SizedBox(height: Space.md),
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate targets'),
              ),
            ],
          ),
        ),

        if (result != null) ...[
          const SizedBox(height: Space.lg),
          const SectionHeader('Split', overline: true),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in MacroPreset.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: ChoiceChip(
                      label: Text(_presetLabel(p)),
                      selected: _i.preset == p,
                      onSelected: (_) => _update(_i.copyWith(preset: p)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          const SectionHeader('Daily targets', overline: true),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Space.sm,
            mainAxisSpacing: Space.sm,
            childAspectRatio: 1.5,
            children: [
              _MacroCard('Calories', '${result.targetCalories}', 'kcal / day',
                  accent: theme.colorScheme.primary),
              _MacroCard('Protein', '${result.protein} g', 'per day',
                  accent: theme.colorScheme.primary),
              _MacroCard('Carbs', '${result.carbs} g', 'per day',
                  accent: theme.colorScheme.tertiary),
              _MacroCard('Fat', '${result.fat} g', 'per day',
                  accent: theme.clinicalStatus.riskLow.onContainer),
              _MacroCard('Sugar', '≤ ${result.maxSugar} g', 'daily cap',
                  accent: theme.clinicalStatus.riskMedium.onContainer),
              _MacroCard('Sat. fat', '≤ ${result.maxSatFat} g', 'daily cap',
                  accent: theme.clinicalStatus.riskHigh.onContainer),
            ],
          ),
          const SizedBox(height: Space.md),
          AppCard(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'BMR ${result.bmr} kcal · TDEE ${result.tdee} kcal. '
                    'A guide only — your clinician can tailor this to your care.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _presetLabel(MacroPreset p) => switch (p) {
    MacroPreset.balanced => 'Balanced',
    MacroPreset.lowFat => 'Low fat',
    MacroPreset.lowCarb => 'Low carb',
    MacroPreset.highCarb => 'High carb',
    MacroPreset.highProtein => 'High protein',
  };
}

class _MacroCard extends StatelessWidget {
  const _MacroCard(this.title, this.value, this.unit, {required this.accent});

  final String title;
  final String value;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(Space.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleLarge),
          ),
          Text(
            unit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Foods — the micronutrient reference
// ---------------------------------------------------------------------------

class _FoodsView extends ConsumerWidget {
  const _FoodsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = ref.watch(filteredFoodsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
          child: SearchBar(
            hintText: 'Search foods',
            leading: const Icon(Icons.search),
            onChanged: (v) =>
                ref.read(foodSearchQueryProvider.notifier).state = v,
          ),
        ),
        Expanded(
          child: foods.isEmpty
              ? const EmptyState(
                  icon: Icons.no_meals_outlined,
                  message: 'No foods match that search.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    0,
                    Space.md,
                    Space.xxl,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: _FoodCard(foods[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard(this.food);
  final NutritionFood food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(food.name, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: Space.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: Radii.chip,
                ),
                child: Text(
                  food.category,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Serving ${food.serving}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.md,
            runSpacing: Space.xs,
            children: [
              _macro('Protein', food.protein),
              _macro('Carbs', food.carbs),
              _macro('Fat', food.fat),
              _macro('Sugar', food.sugar),
              _macro('Sat. fat', food.satFat),
            ],
          ),
          if (food.micros.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final e in food.micros.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: Radii.chip,
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ],
          if (food.allergens.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              'Contains: ${food.allergens.join(', ')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.clinicalStatus.riskHigh.onContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _macro(String label, double grams) => Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text('${_g(grams)} g', style: theme.textTheme.bodyMedium),
        ],
      );
    },
  );

  static String _g(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
}

// ---------------------------------------------------------------------------
// Meal plan — allergen-safe suggestions
// ---------------------------------------------------------------------------

class _MealPlanView extends ConsumerStatefulWidget {
  const _MealPlanView();

  @override
  ConsumerState<_MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends ConsumerState<_MealPlanView> {
  final _allergens = TextEditingController();
  bool _includeSweet = true;

  @override
  void dispose() {
    _allergens.dispose();
    super.dispose();
  }

  List<String> get _parsedAllergens => _allergens.text
      .toLowerCase()
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _generate() {
    ref.read(mealPlanProvider.notifier).generate(
          MealPlanRequest(
            allergens: _parsedAllergens,
            includeSweet: _includeSweet,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref.watch(mealPlanProvider);
    final targets = ref.watch(macroTargetsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
      children: [
        const SectionHeader('Preferences', overline: true),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _allergens,
                decoration: const InputDecoration(
                  labelText: 'Allergies & foods to avoid',
                  hintText: 'e.g. dairy, nuts, fish, egg, gluten',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include a dessert'),
                value: _includeSweet,
                onChanged: (v) => setState(() => _includeSweet = v),
              ),
              const SizedBox(height: Space.xs),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Suggest meals'),
              ),
            ],
          ),
        ),

        if (targets == null) ...[
          const SizedBox(height: Space.sm),
          Text(
            'Tip: calculate your targets first so portions can be matched to '
            'your calorie goal.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        if (plan != null) ...[
          const SizedBox(height: Space.lg),
          if (_parsedAllergens.isNotEmpty)
            AppCard(
              color: theme.clinicalStatus.riskLow.container,
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: theme.clinicalStatus.riskLow.onContainer,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Excluded: ${_parsedAllergens.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.clinicalStatus.riskLow.onContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          if (plan.isEmpty)
            const EmptyState(
              icon: Icons.no_meals_outlined,
              message: 'No meals fit those exclusions. Try removing one.',
            )
          else
            for (final m in plan)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _MealCard(m),
              ),
        ],
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(this.meal);
  final MealRecipe meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: Radii.chip,
                ),
                child: Text(
                  _typeLabel(meal.type),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${meal.calories} kcal',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(meal.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            'P ${meal.protein} g · C ${meal.carbs} g · F ${meal.fat} g',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            meal.ingredients.join(', '),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            '${meal.prepTime} · ${meal.instructions}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(MealType t) => switch (t) {
    MealType.breakfast => 'BREAKFAST',
    MealType.lunch => 'LUNCH',
    MealType.dinner => 'DINNER',
    MealType.sweet => 'DESSERT',
  };
}
