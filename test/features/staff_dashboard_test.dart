// A staff member signs in, scans the panel and works the dashboard (P5-04..P5-11).

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
  testWidgets('staff dashboard: sign in, scan panel, see tasks', (
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

    // Lands on the staff dashboard.
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.textContaining('Hello,'), findsOneWidget);

    // Run a panel scan from the app bar.
    await tester.tap(find.byTooltip('Scan panel for risks'));
    await _settle(tester);
    expect(find.textContaining('Panel scan complete'), findsOneWidget);

    // Task board is reachable and renders.
    await tester.tap(find.text('Tasks').first);
    await _settle(tester);
    expect(find.text('Task board'), findsOneWidget);
  });
}
