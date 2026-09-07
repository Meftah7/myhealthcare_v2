// Profile: each section is a row that opens its own page with a back button;
// tapping back returns to the same Profile screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

    // The six section rows are all present; no form fields leak onto Profile.
    for (final label in const [
      'Personal info',
      'Health details',
      'Wallet',
      'Preferences',
      'Notification channels',
      'Family network',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.widgetWithText(TextField, 'First name'), findsNothing);

    // Open Preferences → its own page with the theme picker + a back button.
    await tester.tap(find.text('Preferences'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Preferences'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

    // Notification channels page: SMS + Email, no Push.
    await tester.tap(find.text('Notification channels'));
    await _settle(tester);
    expect(
      find.widgetWithText(AppBar, 'Notification channels'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SwitchListTile, 'SMS'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Email'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Push'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);

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
}
