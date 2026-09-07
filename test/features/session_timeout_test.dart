// Idle auto-sign-out: after kSessionIdleTimeout with no interaction the
// session ends and the app returns to sign-in with a notice.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('the session ends after the idle timeout', (tester) async {
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
      'patient1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);

    expect(container.read(sessionProvider).isAuthenticated, isTrue);

    // Idle past the timeout without any pointer/key events.
    await tester.pump(kSessionIdleTimeout + const Duration(minutes: 1));
    await _settle(tester);

    expect(container.read(sessionProvider).isAuthenticated, isFalse);
    expect(container.read(sessionProvider).endedByInactivity, isTrue);
    expect(find.textContaining('session ended after'), findsOneWidget);

    // Signing back in clears the notice.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'patient1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);
    expect(container.read(sessionProvider).endedByInactivity, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
