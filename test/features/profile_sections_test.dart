// Profile: each section is a row that opens its own page with a back button;
// tapping back returns to the same Profile screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('profile section rows open pages and back returns to Profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    addTearDown(container.dispose);

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
    await passMfa(tester);
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

    // The five section rows are all present; no form fields leak onto Profile.
    for (final label in const [
      'Personal info',
      'Health details',
      'Wallet',
      'Preferences',
      'Family network',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.widgetWithText(TextField, 'First name'), findsNothing);

    // Open Preferences → its own page with the theme picker, a text-size
    // slider, and the alert channels (SMS + Email, no Push), plus a back button.
    await tester.tap(find.text('Preferences'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Preferences'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.text('Text size'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'SMS'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Email'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Push'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

    // Health details page is an editable form.
    await tester.tap(find.text('Health details'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Health details'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Allergies'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);

    // Personal info page.
    await tester.tap(find.text('Personal info'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Personal info'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('text-size preference scales app text and persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    addTearDown(container.dispose);

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
    await passMfa(tester);
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    await tester.tap(find.text('Preferences'));
    await _settle(tester);

    expect(container.read(textScaleProvider), TextScaleLevel.medium);
    final before = MediaQuery.of(
      tester.element(find.byType(Slider)),
    ).textScaler.scale(16);

    await container.read(textScaleProvider.notifier).set(TextScaleLevel.xLarge);
    await _settle(tester);

    expect(find.textContaining('Larger'), findsOneWidget);
    final after = MediaQuery.of(
      tester.element(find.byType(Slider)),
    ).textScaler.scale(16);
    expect(after, greaterThan(before));
    expect(prefs.getString('ui.textScale'), 'xLarge');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
