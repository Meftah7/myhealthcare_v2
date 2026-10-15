// Admin overview, Profile hub, and persistent theme control.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 22; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _signInAdmin(WidgetTester tester) async {
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
    'admin@myhealth.demo',
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

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('dashboard uses the shared layout language', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    expect(find.widgetWithText(AppBar, 'Clinic overview'), findsOneWidget);
    expect(find.text('Total Patients'), findsOneWidget);
    expect(find.text('Upcoming Appointments'), findsOneWidget);
    expect(find.text('SYSTEM HEALTH'), findsNothing);

    // The five nav tabs.
    for (final tab in const [
      'Dashboard',
      'Users',
      'Departments',
      'Billing',
      'Profile',
    ]) {
      expect(find.text(tab), findsWidgets);
    }

    await _teardown(tester);
  });

  testWidgets('Profile is a hub of rows that open their own pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    container.read(routerProvider).go(AppRoutes.adminProfile);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    for (final row in const [
      'Account',
      'Audit log',
      'System analytics',
      'Historical demand',
      'AI settings',
      'AI activity',
      'Preferences',
    ]) {
      expect(find.widgetWithText(ListTile, row), findsOneWidget);
    }

    // A report page opens with a back button and returns here.
    await tester.tap(find.text('AI settings'));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'AI settings'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('manual status is absent and the theme persists per device', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    expect(find.text('Available'), findsNothing);
    expect(find.text('In a meeting'), findsNothing);
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await _settle(tester);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('ui.themeMode'), 'dark');

    await _teardown(tester);
  });
}
