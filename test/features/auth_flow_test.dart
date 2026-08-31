// End-to-end auth flow: seeded DB → login → role-gated redirect (P2-02..P2-05).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderScope> _app(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
    child: const MyHealthCareApp(),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await Seeder(db).run();
  });

  testWidgets('patient signs in and lands on the patient shell', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(db));
    await _pump(tester);

    expect(find.text('Sign in'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'patient1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _pump(tester);
    await _pump(tester);

    // Patient shell: bottom nav with these destinations.
    expect(find.text('Timeline'), findsWidgets);
    expect(find.text('Appointments'), findsWidgets);
  });

  testWidgets('staff sign-in lands on the staff dashboard', (tester) async {
    await tester.pumpWidget(await _app(db));
    await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'staff1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _pump(tester);
    await _pump(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Patients'), findsWidgets);
  });

  testWidgets('wrong password shows an error, stays on login', (tester) async {
    await tester.pumpWidget(await _app(db));
    await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'patient1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'nope',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _pump(tester);

    expect(find.textContaining('Incorrect'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
