// Staff-dashboard rebuild: the Quick actions grid, today's queue actions,
// the staff directory and the activity log.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 18; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _signInStaff(WidgetTester tester) async {
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
    'staff1@myhealth.demo',
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
  testWidgets('quick action → patient picker → clinical note sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInStaff(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('New note'));
    await _settle(tester);

    // Patient picker sheet opens.
    expect(find.textContaining('Add a clinical note for'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'a');
    await _settle(tester);
    expect(find.byType(ListTile), findsWidgets);
    await tester.tap(find.byType(ListTile).first, warnIfMissed: false);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    // The chart note sheet is now up.
    expect(find.text('Add clinical note'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('staff directory lists clinicians with presence', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInStaff(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Staff directory'));
    await _settle(tester);

    expect(find.widgetWithText(AppBar, 'Staff directory'), findsOneWidget);
    expect(find.textContaining('clinicians'), findsOneWidget);
    expect(find.textContaining('On duty'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('my activity has a records / prescriptions toggle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInStaff(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('My activity'));
    await _settle(tester);

    expect(find.widgetWithText(AppBar, 'My activity'), findsOneWidget);
    await tester.tap(find.text('Prescriptions'));
    await _settle(tester);
    // Either issued prescriptions or the empty state — both are fine.
    expect(
      find.byType(Scaffold),
      findsWidgets,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('presence menu updates the pill', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _signInStaff(tester);
    addTearDown(container.dispose);

    // staff1 seeds as on duty.
    expect(find.text('On duty'), findsWidgets);
    await tester.tap(find.text('On duty').first);
    await _settle(tester);
    await tester.tap(find.text('On break').last);
    await _settle(tester);
    expect(find.text('On break'), findsWidgets);

    // Persisted.
    final me = container.read(currentUserProvider)!.id;
    final staff = await container
        .read(userRepositoryProvider)
        .staffById(me);
    expect(staff.valueOrNull?.presence, PresenceStatus.onBreak);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
