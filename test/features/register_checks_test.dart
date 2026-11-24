// Creating an account: the password rule shown matches the one enforced
// (8 characters), phone and national ID are required, and an email or
// national ID already in use is reported on the step where it is typed —
// not only when the account is finally created.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('sign-up checks each step before moving on', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
    final db = newTestDatabase();
    await Seeder(db).run();
    // A known national ID already on file.
    await (db.update(db.users)
          ..where((u) => u.email.equals('patient1@myhealth.demo')))
        .write(const UsersCompanion(nationalId: Value('912345678')));
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);
    c.read(routerProvider).go(AppRoutes.register);
    await _settle(tester);

    final continueButton = find.widgetWithText(FilledButton, 'Continue');

    // Step 1 — the password rule is shown up front and matches the check.
    expect(find.text('At least 8 characters'), findsOneWidget);
    await tester.enterText(_field('Full name'), 'Ali');
    await tester.enterText(_field('Email'), 'Patient1@MyHealth.demo');
    await tester.enterText(_field('Password'), '123456');
    await tester.tap(continueButton);
    await _settle(tester);
    expect(find.text('Step 1 of 3 · Account'), findsOneWidget);

    // Eight characters is enough; the taken email is now caught here.
    await tester.enterText(_field('Password'), '12345678');
    await tester.tap(continueButton);
    await _settle(tester);
    expect(
      find.text('An account with this email already exists. Sign in instead.'),
      findsOneWidget,
    );
    expect(find.text('Step 1 of 3 · Account'), findsOneWidget);

    // A new email moves on.
    await tester.enterText(_field('Email'), 'ali.new@example.test');
    await tester.tap(continueButton);
    await _settle(tester);
    expect(find.text('Step 2 of 3 · Details'), findsOneWidget);

    // Step 2 — phone and national ID are required, not optional.
    expect(find.textContaining('(optional)'), findsNothing);
    await tester.tap(continueButton);
    await _settle(tester);
    expect(
      find.text('Enter a phone number with at least 8 digits.'),
      findsOneWidget,
    );
    expect(find.text('Enter your National ID.'), findsOneWidget);

    await tester.enterText(_field('Phone'), '+973 3612 3456');
    await tester.enterText(_field('National ID'), '912345678');
    await tester.tap(continueButton);
    await _settle(tester);
    expect(
      find.text('An account with this National ID already exists.'),
      findsOneWidget,
    );
    expect(find.text('Step 2 of 3 · Details'), findsOneWidget);

    await tester.enterText(_field('National ID'), '987654321');
    await tester.tap(continueButton);
    await _settle(tester);
    expect(find.text('Step 3 of 3 · Medical (optional)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
