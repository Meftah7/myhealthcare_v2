// Health Records has a Timeline/Medications toggle; the Nutrition tab replaces
// the old Medications tab and computes macro targets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/nutrition/application/macro_calculator.dart';
import 'package:myhealthcare/features/nutrition/presentation/nutrition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _signIn(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'patient3@myhealth.demo',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await _settle(tester);
  return container;
}

void main() {
  group('macro calculator', () {
    test('Mifflin–St Jeor matches the reference formula', () {
      final r = calculateMacros(const MacroInputs(
        age: 30,
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        activityFactor: 1.55,
        goal: FitnessGoal.maintain,
        weeklyRateKg: 0.5,
        preset: MacroPreset.balanced,
      ));
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 1780
      expect(r.bmr, 1780);
      expect(r.tdee, (1780 * 1.55).round());
      expect(r.targetCalories, r.tdee);
      // Balanced split: 30/40/30.
      expect(r.protein, ((r.targetCalories * 0.30) / 4).round());
    });

    test('a cut never drops below the 1200 kcal floor', () {
      final r = calculateMacros(const MacroInputs(
        age: 60,
        sex: Sex.female,
        weightKg: 50,
        heightCm: 155,
        activityFactor: 1.2,
        goal: FitnessGoal.lose,
        weeklyRateKg: 1.0,
        preset: MacroPreset.balanced,
      ));
      expect(r.targetCalories, greaterThanOrEqualTo(1200));
    });
  });

  testWidgets('Health Records toggles between timeline and medications',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signIn(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Records').first);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Records'), findsOneWidget);

    // Timeline view first: the record search bar is present.
    expect(find.byType(SearchBar), findsOneWidget);

    // Switch to Medications.
    await tester.tap(find.text('Medications'));
    await _settle(tester);
    expect(find.byType(SearchBar), findsNothing);
    // Seeded chronic patient is on medication.
    expect(find.text('CURRENT'), findsOneWidget);

    // Switch to Bills — the invoice list is here now too.
    await tester.tap(find.text('Bills'));
    await _settle(tester);
    expect(find.textContaining('BD '), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Nutrition tab calculates targets from the profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signIn(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Nutrition').first);
    await _settle(tester);
    expect(find.byType(NutritionScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Nutrition'), findsOneWidget);

    // The bottom nav is still visible (Nutrition is a shell branch).
    expect(find.text('Appointments'), findsWidgets);

    // Targets view is default; calculate.
    await tester.tap(find.widgetWithText(FilledButton, 'Calculate targets'));
    await _settle(tester);
    expect(find.text('DAILY TARGETS'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.textContaining('kcal / day'), findsWidgets);

    // Foods view searches the reference set.
    await tester.tap(find.text('Foods'));
    await _settle(tester);
    await tester.enterText(find.byType(SearchBar), 'salmon');
    await _settle(tester);
    expect(find.text('Baked salmon fillet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
