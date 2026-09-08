/// Nutrition — a calorie/macro calculator, an allergen-safe meal plan, and a
/// searchable food database. Ported from the standalone Nutrition project and
/// rebuilt on the app's design system; runs the same on phone, tablet,
/// desktop and web.
///
/// Tabs, in order: Calculator → Meal plan → Foods. The Calculator's result
/// feeds the Meal plan (portions are matched to the day's targets and split
/// across the meals).
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

enum _View { calculator, meals, foods }

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  _View _view = _View.calculator;

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
                        value: _View.calculator,
                        icon: Icon(Icons.calculate_outlined),
                        label: Text('Calculator'),
                      ),
                      ButtonSegment(
                        value: _View.meals,
                        icon: Icon(Icons.restaurant_menu),
                        label: Text('Meal plan'),
                      ),
                      ButtonSegment(
                        value: _View.foods,
                        icon: Icon(Icons.search),
                        label: Text('Foods'),
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
                  _View.calculator => const _CalculatorView(),
                  _View.meals => const _MealPlanView(),
                  _View.foods => const _FoodsView(),
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
// Calculator — the calorie & macro targets
// ---------------------------------------------------------------------------

class _CalculatorView extends ConsumerStatefulWidget {
  const _CalculatorView();

  @override
  ConsumerState<_CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends ConsumerState<_CalculatorView> {
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
          const SectionHeader('Preferences', overline: true),
          Text(
            'The macro split used for your targets and your meal plan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
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
// Foods — the macro + micronutrient database
// ---------------------------------------------------------------------------

class _FoodsView extends ConsumerWidget {
  const _FoodsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(foodCategoriesProvider);
    final selectedCat = ref.watch(foodCategoryFilterProvider);
    final foods = ref.watch(filteredFoodsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
          child: SearchBar(
            hintText: 'Search foods',
            leading: const Icon(Icons.search),
            onChanged: (v) =>
                ref.read(foodSearchQueryProvider.notifier).state = v,
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCat == null,
                    onSelected: (_) => ref
                        .read(foodCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: selectedCat == c,
                      onSelected: (_) => ref
                          .read(foodCategoryFilterProvider.notifier)
                          .state = (selectedCat == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${foods.length} ${foods.length == 1 ? 'item' : 'items'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
                    Space.xs,
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
          // Six figures: calories + the five macros, three to a row.
          _PillGrid(
            pills: [
              _Pill('Calories', '${food.calories}', accent: scheme.primary),
              _Pill('Protein', _g(food.protein), accent: scheme.primary),
              _Pill('Carbs', _g(food.carbs), accent: scheme.primary),
              _Pill('Fat', _g(food.fat), accent: scheme.primary),
              _Pill('Sugar', _g(food.sugar), accent: scheme.primary),
              _Pill('Sat. fat', _g(food.satFat), accent: scheme.primary),
            ],
          ),
          if (food.micros.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            // Micronutrients, same pill treatment as the macros above.
            _PillGrid(
              pills: [
                for (final e in food.micros.entries)
                  _Pill(e.key, e.value, accent: scheme.primary),
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

  static String _g(double v) =>
      '${v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1)} g';
}

/// Lays [pills] out three to a row (so six figures = two rows), each cell the
/// same size.
class _PillGrid extends StatelessWidget {
  const _PillGrid({required this.pills});

  final List<_Pill> pills;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: Space.xs,
      mainAxisSpacing: Space.xs,
      mainAxisExtent: 54,
      children: pills,
    );
  }
}

/// One labelled figure in a food card's macro / micro grid.
class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value, {this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: Radii.chip,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: accent != null ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal plan — allergen-safe suggestions matched to the day's targets
// ---------------------------------------------------------------------------

class _MealPlanView extends ConsumerStatefulWidget {
  const _MealPlanView();

  @override
  ConsumerState<_MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends ConsumerState<_MealPlanView> {
  bool _includeSweet = true;

  void _generate() {
    ref
        .read(mealPlanProvider.notifier)
        .generate(MealPlanRequest(includeSweet: _includeSweet));
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include a dessert'),
                subtitle: const Text('Splits the day into four meals instead '
                    'of three'),
                value: _includeSweet,
                onChanged: (v) => setState(() => _includeSweet = v),
              ),
              const SizedBox(height: Space.xs),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Build my day'),
              ),
            ],
          ),
        ),

        if (targets == null) ...[
          const SizedBox(height: Space.sm),
          AppCard(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Run the Calculator first — then your calorie and macro '
                    'goal is split across the meals here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (plan != null && targets != null && plan.perMeal != null) ...[
          const SizedBox(height: Space.lg),
          _DailySplitCard(targets: targets, perMeal: plan.perMeal!),
        ],
      ],
    );
  }
}

/// The daily targets and how they divide across the meals.
class _DailySplitCard extends StatelessWidget {
  const _DailySplitCard({required this.targets, required this.perMeal});

  final MacroResult targets;
  final List<MealTargets> perMeal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your day', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            '${targets.targetCalories} kcal · P ${targets.protein} g · '
            'C ${targets.carbs} g · F ${targets.fat} g',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          const Divider(height: 1),
          const SizedBox(height: Space.sm),
          for (final m in perMeal)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      _mealLabel(m.type),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${m.calories} kcal   ·   P ${m.protein} · '
                      'C ${m.carbs} · F ${m.fat} g',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _mealLabel(MealType t) => switch (t) {
  MealType.breakfast => 'Breakfast',
  MealType.lunch => 'Lunch',
  MealType.dinner => 'Dinner',
  MealType.sweet => 'Dessert',
};
