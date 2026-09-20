/// Nutrition — a calorie/macro calculator, an allergen-safe meal plan, and a
/// searchable food database. Ported from the standalone Nutrition project and
/// rebuilt on the app's design system; runs the same on phone, tablet,
/// desktop and web.
///
/// Tabs, in order: Calculator → Meal plan → Foods. The Calculator's result
/// feeds the Meal plan (portions are matched to the day's targets and split
/// across the meals).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nutritionTitle),
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
                    segments: [
                      ButtonSegment(
                        value: _View.calculator,
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(t.calculatorSegment),
                      ),
                      ButtonSegment(
                        value: _View.meals,
                        icon: const Icon(Icons.restaurant_menu),
                        label: Text(t.mealPlanSegment),
                      ),
                      ButtonSegment(
                        value: _View.foods,
                        icon: const Icon(Icons.search),
                        label: Text(t.foodsSegment),
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
    // Prefer what the patient last calculated (persisted across restarts)
    // over the profile-derived defaults, so the form shows what they
    // actually entered rather than resetting every time.
    final MacroInputs d =
        ref.read(macroInputsProvider) ?? ref.read(defaultMacroInputsProvider);
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
      unawaited(ref.read(macroInputsProvider.notifier).set(next));
    }
  }

  void _calculate() {
    final next = _i.copyWith(
      age: int.tryParse(_age.text) ?? _i.age,
      weightKg: double.tryParse(_weight.text) ?? _i.weightKg,
      heightCm: double.tryParse(_height.text) ?? _i.heightCm,
    );
    setState(() => _inputs = next);
    unawaited(ref.read(macroInputsProvider.notifier).set(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final result = ref.watch(macroTargetsProvider);
    final cols = WindowSize.of(context).isCompact ? 2 : 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
      children: [
        SectionHeader(t.aboutYouSection, overline: true),
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
                      decoration: InputDecoration(labelText: t.ageLabel),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: DropdownButtonFormField<Sex>(
                      initialValue: _i.sex,
                      decoration: InputDecoration(labelText: t.sexLabel),
                      items: [
                        DropdownMenuItem(
                          value: Sex.male,
                          child: Text(t.genderMale),
                        ),
                        DropdownMenuItem(
                          value: Sex.female,
                          child: Text(t.genderFemale),
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
                      decoration: InputDecoration(
                        labelText: t.weightKgLabel,
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
                      decoration: InputDecoration(
                        labelText: t.heightCmLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<double>(
                initialValue: _i.activityFactor,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.activityLabel),
                items: [
                  DropdownMenuItem(value: 1.2, child: Text(t.activitySedentary)),
                  DropdownMenuItem(
                    value: 1.375,
                    child: Text(t.activityLightlyActive),
                  ),
                  DropdownMenuItem(
                    value: 1.55,
                    child: Text(t.activityModeratelyActive),
                  ),
                  DropdownMenuItem(
                    value: 1.725,
                    child: Text(t.activityVeryActive),
                  ),
                  DropdownMenuItem(
                    value: 1.9,
                    child: Text(t.activityExtraActive),
                  ),
                ],
                onChanged: (v) => v == null
                    ? null
                    : _update(_i.copyWith(activityFactor: v)),
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<FitnessGoal>(
                initialValue: _i.goal,
                decoration: InputDecoration(labelText: t.goalLabel),
                items: [
                  DropdownMenuItem(
                    value: FitnessGoal.maintain,
                    child: Text(t.goalMaintain),
                  ),
                  DropdownMenuItem(
                    value: FitnessGoal.lose,
                    child: Text(t.goalLose),
                  ),
                  DropdownMenuItem(
                    value: FitnessGoal.gain,
                    child: Text(t.goalGain),
                  ),
                ],
                onChanged: (v) =>
                    v == null ? null : _update(_i.copyWith(goal: v)),
              ),
              if (_i.goal != FitnessGoal.maintain) ...[
                const SizedBox(height: Space.sm),
                DropdownButtonFormField<double>(
                  initialValue: _i.weeklyRateKg,
                  decoration: InputDecoration(labelText: t.weeklyRateLabel),
                  items: [
                    DropdownMenuItem(value: 0.25, child: Text(t.weeklyRate025)),
                    DropdownMenuItem(value: 0.5, child: Text(t.weeklyRate05)),
                    DropdownMenuItem(value: 1.0, child: Text(t.weeklyRate10)),
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
                label: Text(t.calculateTargetsButton),
              ),
            ],
          ),
        ),

        if (result != null) ...[
          const SizedBox(height: Space.lg),
          SectionHeader(t.preferencesSection, overline: true),
          Text(
            t.macroSplitNote,
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
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(_presetLabel(t, p)),
                      selected: _i.preset == p,
                      onSelected: (_) => _update(_i.copyWith(preset: p)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          SectionHeader(t.dailyTargetsSection, overline: true),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Space.sm,
            mainAxisSpacing: Space.sm,
            childAspectRatio: 1.5,
            children: [
              _MacroCard(t.macroCalories, '${result.targetCalories}', t.unitKcalPerDay,
                  accent: theme.colorScheme.primary),
              _MacroCard(t.macroProtein, '${result.protein} g', t.unitPerDay,
                  accent: theme.colorScheme.primary),
              _MacroCard(t.macroCarbs, '${result.carbs} g', t.unitPerDay,
                  accent: theme.colorScheme.tertiary),
              _MacroCard(t.macroFat, '${result.fat} g', t.unitPerDay,
                  accent: theme.clinicalStatus.riskLow.onContainer),
              _MacroCard(t.macroSugar, '≤ ${result.maxSugar} g', t.unitDailyCap,
                  accent: theme.clinicalStatus.riskMedium.onContainer),
              _MacroCard(t.macroSatFat, '≤ ${result.maxSatFat} g', t.unitDailyCap,
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
                    t.bmrTdeeNote(result.bmr, result.tdee),
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

  static String _presetLabel(AppLocalizations t, MacroPreset p) => switch (p) {
    MacroPreset.balanced => t.presetBalanced,
    MacroPreset.lowFat => t.presetLowFat,
    MacroPreset.lowCarb => t.presetLowCarb,
    MacroPreset.highCarb => t.presetHighCarb,
    MacroPreset.highProtein => t.presetHighProtein,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: theme.textTheme.titleLarge),
          ),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final t = AppLocalizations.of(context)!;
    final categories = ref.watch(foodCategoriesProvider);
    final selectedCat = ref.watch(foodCategoryFilterProvider);
    final foods = ref.watch(filteredFoodsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
          child: SearchBar(
            hintText: t.searchFoodsHint,
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
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: ChoiceChip(
                    label: Text(t.allCategoriesChip),
                    selected: selectedCat == null,
                    onSelected: (_) => ref
                        .read(foodCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
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
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              t.itemsCount(foods.length),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: foods.isEmpty
              ? EmptyState(
                  icon: Icons.no_meals_outlined,
                  message: t.noFoodsMatch,
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
    final t = AppLocalizations.of(context)!;

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
            t.servingLabel(food.serving),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          // Six figures: calories + the five macros, three to a row.
          _PillGrid(
            pills: [
              _Pill(t.macroCalories, '${food.calories}', accent: scheme.primary),
              _Pill(t.macroProtein, _g(food.protein), accent: scheme.primary),
              _Pill(t.macroCarbs, _g(food.carbs), accent: scheme.primary),
              _Pill(t.macroFat, _g(food.fat), accent: scheme.primary),
              _Pill(t.macroSugar, _g(food.sugar), accent: scheme.primary),
              _Pill(t.macroSatFat, _g(food.satFat), accent: scheme.primary),
            ],
          ),
          if (food.micros.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            // Everything else is an extra note, not one of the six figures.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${t.also}  ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: food.micros.entries
                        .map((e) => '${e.key} ${e.value}')
                        .join('  ·  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (food.allergens.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              t.containsAllergens(food.allergens.join(', ')),
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
    final t = AppLocalizations.of(context)!;
    final plan = ref.watch(mealPlanProvider);
    final targets = ref.watch(macroTargetsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
      children: [
        SectionHeader(t.preferencesSection, overline: true),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.includeDessertTitle),
                subtitle: Text(t.includeDessertSubtitle),
                value: _includeSweet,
                onChanged: (v) => setState(() => _includeSweet = v),
              ),
              const SizedBox(height: Space.xs),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.restaurant_menu),
                label: Text(t.buildMyDayButton),
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
                    t.runCalculatorFirstNote,
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
    final t = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.yourDayTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xxs),
          Text(
            // P/C/F/kcal kept as the universal Latin macro shorthand used by
            // nutrition apps generally, rather than invented Arabic initials.
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
                      _mealLabel(t, m.type),
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

String _mealLabel(AppLocalizations t, MealType type) => switch (type) {
  MealType.breakfast => t.mealBreakfast,
  MealType.lunch => t.mealLunch,
  MealType.dinner => t.mealDinner,
  MealType.sweet => t.mealDessert,
};
