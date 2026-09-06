// Profile: each section is a collapsible panel — collapsed sections hide their
// body, tapping the header reveals it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/expandable_section.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('profile sections collapse and expand', (tester) async {
    // A tall viewport so every collapsed section fits without scrolling.
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

    // Every section is an ExpandableSection.
    expect(find.byType(ExpandableSection), findsWidgets);
    expect(find.text('Personal info'), findsOneWidget);
    expect(find.text('Health details'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Notification channels'), findsOneWidget);
    expect(find.text('Family network'), findsOneWidget);

    // Collapsed sections show only their title — no leaked field values.
    expect(find.widgetWithText(TextField, 'First name'), findsNothing);

    // Preferences starts collapsed — its body (the theme picker) is not built.
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);

    // Expand it.
    await tester.tap(find.text('Preferences'));
    await _settle(tester);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);

    // Collapse it again.
    await tester.tap(find.text('Preferences'));
    await _settle(tester);
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);

    // Expand Personal info and its form is reachable.
    await tester.tap(find.text('Personal info'));
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
