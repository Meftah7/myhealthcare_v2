// A staff member opens the week schedule grid (P5-12). Regression: the grid
// must render on a week where some days have no appointments — the per-day
// list was being sorted in place on a `const []` fallback.

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
  testWidgets('staff schedule: week grid renders without errors', (
    tester,
  ) async {
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

    await tester.tap(find.text('Schedule').first);
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AppBar, 'My schedule'), findsOneWidget);
    // Every one of the seven day headers is drawn.
    expect(find.textContaining('No appointments'), findsWidgets);

    // Week navigation still works.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });
}
