// The admin page rebuilt on the patient/staff pattern: a Profile hub of rows
// that open their own pages, a device-local working-status pill, and the
// dashboard's new layout (date overline + greeting + one hero + a three-figure
// row + row-tile Quick actions).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/app_card.dart';
import 'package:myhealthcare/core/presentation/app_scaffold.dart';
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
    'admin@myhealth.demo',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
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

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandLockup),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.byType(GradientHeroCard), findsOneWidget);
    expect(find.text('SYSTEM HEALTH'), findsOneWidget);
    for (final label in const ['Patients', 'Staff', 'Departments']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('QUICK ACTIONS'), findsOneWidget);

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

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    for (final row in const [
      'Account',
      'Audit log',
      'System analytics',
      'Capacity forecast',
      'AI settings',
      'AI activity',
      'Preferences',
    ]) {
      expect(find.text(row), findsOneWidget);
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

  testWidgets('the working-status pill changes and persists per device', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInAdmin(tester);
    addTearDown(container.dispose);

    expect(container.read(adminStatusProvider), AdminStatus.available);
    expect(find.text('Available'), findsWidgets);

    await tester.tap(find.text('Available').first);
    await _settle(tester);
    await tester.tap(find.text('In a meeting').last);
    await _settle(tester);

    expect(container.read(adminStatusProvider), AdminStatus.meeting);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('ui.adminStatus'), 'meeting');

    await _teardown(tester);
  });
}
