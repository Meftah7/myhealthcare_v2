// A patient signs in and browses their record (P2-07..P2-16).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('patient sees home, timeline and vitals from seeded data', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();

    // patient_003 is chronic in the seeded set — plenty of history.
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
      'patient3@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _settle(tester);

    // Home greeting.
    expect(find.textContaining('Good '), findsOneWidget);

    // Go to the timeline tab.
    await tester.tap(find.text('Timeline').first);
    await _settle(tester);
    expect(find.text('Health timeline'), findsOneWidget);
    // Seeded chronic patient has visit notes / lab panels.
    expect(
      find.byType(ListTile),
      findsWidgets,
      reason: 'timeline should list records',
    );

    // Go to vitals.
    await tester.tap(find.text('Vitals').first);
    await _settle(tester);
    expect(find.text('Add reading'), findsOneWidget);
  });
}
