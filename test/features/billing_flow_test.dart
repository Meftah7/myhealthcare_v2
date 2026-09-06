// Billing UI: reach it from Home's quick actions, see the balance and an
// invoice, and keep the bottom nav visible throughout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/billing/presentation/billing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('billing: open from Home, see balance and an invoice', (
    tester,
  ) async {
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

    // Billing is a Home quick action near the bottom of a lazy list.
    final tile = find.text('Billing');
    await tester.scrollUntilVisible(
      tile,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await _settle(tester);
    await tester.tap(tile.first);
    await _settle(tester);

    expect(find.widgetWithText(AppBar, 'Billing'), findsOneWidget);
    expect(find.byType(BillingScreen), findsOneWidget);

    // The balance card and at least one invoice rendered.
    expect(
      find.textContaining('BD '),
      findsWidgets,
      reason: 'invoice amounts should be formatted as currency',
    );

    // The bottom nav stays visible on Billing (it nests under the Home branch).
    expect(find.text('Appointments'), findsWidgets);
    expect(find.text('Health Records'), findsWidgets);
  });
}
