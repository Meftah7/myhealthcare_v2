// Health Records has a Timeline/Medications toggle; the Nutrition tab replaces
// the old Medications tab and computes macro targets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/app_scaffold.dart';
import 'package:myhealthcare/core/presentation/quick_actions.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:myhealthcare/features/nutrition/application/macro_calculator.dart';
import 'package:myhealthcare/features/nutrition/application/nutrition_providers.dart';
import 'package:myhealthcare/features/nutrition/presentation/nutrition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _signIn(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
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
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await passMfa(tester);
  await _settle(tester);
  return container;
}

/// The page's own vertical list — not the navigation sidebar shown on wide
/// windows.
Finder _content() => find
    .descendant(
      of: find.byType(ScrollToTopSignal),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .last;

void main() {
  group('macro calculator', () {
    test('Mifflin–St Jeor matches the reference formula', () {
      final r = calculateMacros(
        const MacroInputs(
          age: 30,
          sex: Sex.male,
          weightKg: 80,
          heightCm: 180,
          activityFactor: 1.55,
          goal: FitnessGoal.maintain,
          weeklyRateKg: 0.5,
          preset: MacroPreset.balanced,
        ),
      );
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 1780
      expect(r.bmr, 1780);
      expect(r.tdee, (1780 * 1.55).round());
      expect(r.targetCalories, r.tdee);
      // Balanced split: 30/40/30.
      expect(r.protein, ((r.targetCalories * 0.30) / 4).round());
    });

    test('a cut never drops below the 1200 kcal floor', () {
      final r = calculateMacros(
        const MacroInputs(
          age: 60,
          sex: Sex.female,
          weightKg: 50,
          heightCm: 155,
          activityFactor: 1.2,
          goal: FitnessGoal.lose,
          weeklyRateKg: 1.0,
          preset: MacroPreset.balanced,
        ),
      );
      expect(r.targetCalories, greaterThanOrEqualTo(1200));
    });
  });

  testWidgets('Health Records opens medications with their instructions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signIn(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Records').first);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Records'), findsOneWidget);

    // History and upload lead; the existing health shortcuts are secondary.
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('Upload document'), findsOneWidget);
    expect(find.text('All records'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Your health'),
      240,
      scrollable: _content(),
    );
    await tester.ensureVisible(find.text('Your health'));
    await _settle(tester);
    await tester.tap(find.text('Your health'));
    await _settle(tester);
    expect(find.byType(QuickActionTile), findsNWidgets(8));
    for (final label in [
      'Home care',
      'Medication',
      'Bills',
      'Visited doctors',
      'Imaging',
      'Sick leave',
      'Vital signs report',
      'Allergies',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    // Switch to Medications.
    await tester.ensureVisible(
      find.widgetWithText(QuickActionTile, 'Medication'),
    );
    await tester.tap(find.widgetWithText(QuickActionTile, 'Medication'));
    await _settle(tester);
    expect(find.byType(SearchBar), findsNothing);
    // Seeded chronic patient is on medication.
    expect(find.text('Current'), findsOneWidget);

    // The medications page shows medications only — no other tabs.
    expect(find.text('Bills'), findsNothing);
    expect(find.text('Timeline'), findsNothing);

    // A medicine opens its instructions and the refill request.
    await tester.tap(
      find
          .descendant(
            of: find.byType(ScrollToTopSignal),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await _settle(tester);
    expect(find.text('How often'), findsOneWidget);
    expect(find.text('Request a refill'), findsOneWidget);
    await tester.tap(find.text('Request a refill'));
    await _settle(tester);
    expect(find.textContaining('Refill request sent'), findsOneWidget);
    // It reached the doctor as a chat message.
    final threads = await container.read(patientThreadsProvider.future);
    expect(
      threads.any((t) => t.lastMessage.body.startsWith('Refill request:')),
      isTrue,
    );

    // Returning restores the record history and its upload action.
    await tester.tap(find.text('Back to Records'));
    await _settle(tester);
    expect(find.text('Timeline'), findsNothing);
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('Upload document'), findsOneWidget);

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
    expect(find.widgetWithText(AppBar, 'Nutrition estimates'), findsOneWidget);

    // The bottom nav is still visible (Nutrition is a shell branch).
    expect(find.text('Appointment'), findsWidgets);

    // Tabs, in order: Calculator → Daily targets → Foods.
    expect(find.text('Calculator'), findsWidgets);
    expect(find.text('Example split'), findsNothing);
    expect(find.text('Daily targets'), findsOneWidget);

    // Calculator is the default view; calculate.
    await tester.tap(find.text('Calculator').first);
    await _settle(tester);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Calculate estimate'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Calculate estimate'));
    await _settle(tester);
    expect(find.text('Daily targets'), findsWidgets);
    expect(find.text('Preferences'), findsOneWidget); // was "Split"
    expect(find.textContaining('kcal / day'), findsWidgets);

    // The daily-target view reads the saved calculator result.
    await tester.tap(find.text('Daily targets').first);
    await _settle(tester);
    final targets = container.read(macroTargetsProvider)!;
    expect(find.text('${targets.targetCalories}'), findsOneWidget);
    expect(find.text('Build my day'), findsNothing);
    expect(find.text('Example split'), findsNothing);

    // Foods view: the full database, a category filter, six figures per item.
    await tester.tap(find.text('Foods').first);
    await _settle(tester);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), 'salmon');
    await _settle(tester);
    expect(find.text('Baked salmon fillet'), findsOneWidget);
    // Six figures per item, including Calories (the one that used to be missing).
    expect(find.text('Calories'), findsWidgets);
    expect(find.text('Sat. fat'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Nutrition targets survive closing the app', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    Future<ProviderContainer> launch() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) => db),
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
        'patient1@myhealth.demo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        Seeder.demoPassword,
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await passMfa(tester);
      await _settle(tester);
      return container;
    }

    // First session: calculate and save targets.
    final first = await launch();
    await tester.tap(find.text('Nutrition').first);
    await _settle(tester);
    await tester.tap(find.text('Calculator').first);
    await _settle(tester);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Calculate estimate'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Calculate estimate'));
    await _settle(tester);
    expect(find.text('Daily targets'), findsWidgets);
    final savedTargets = first.read(macroTargetsProvider)!;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    first.dispose();

    // A fresh "session" — new ProviderContainer, same SharedPreferences and
    // database, as if the app had been closed and reopened. Targets
    // should already be available without calculating again.
    final second = await launch();
    addTearDown(second.dispose);
    await tester.tap(find.text('Nutrition').first);
    await _settle(tester);
    expect(find.text('Daily targets'), findsWidgets);
    await tester.tap(find.text('Daily targets').first);
    await _settle(tester);
    expect(find.text('${savedTargets.targetCalories}'), findsOneWidget);
    expect(second.read(macroTargetsProvider)!.protein, savedTargets.protein);
    expect(find.text('Example split'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
