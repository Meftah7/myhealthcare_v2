// A staff member signs in, works the redesigned dashboard: Quick actions,
// a panel scan, the queue, and the task board (P5-04..P5-11 + rebuild).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('staff dashboard: sign in, quick actions, scan panel, tasks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = newTestDatabase();
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
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

    // Lands on the staff dashboard, with the presence pill + Quick actions.
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('On duty'), findsWidgets);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);

    // Run a panel scan from the Quick actions grid.
    expect(find.text('Panel scan'), findsOneWidget);
    await tester.tap(find.text('Panel scan'));
    // Let the in-memory scan finish and the result snackbar animate in, but
    // stop before its ~4s auto-dismiss.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.textContaining('Panel scan complete'), findsOneWidget);

    // Task board is reachable and renders.
    await tester.tap(find.text('Tasks').first);
    await _settle(tester);
    expect(find.text('Task board'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
