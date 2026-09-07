// The auth pages: sign in by national ID, forgot -> reset password, and the
// MFA verify step (behind kRequireMfaAtSignIn).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
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
  return container;
}

void main() {
  test('login accepts the national ID as the identifier', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final patient = (await container
            .read(userRepositoryProvider)
            .byRole(UserRole.patient))
        .valueOrNull!
        .firstWhere((u) => u.nationalId != null);

    final byId = await container.read(authRepositoryProvider).login(
          email: patient.nationalId!,
          password: Seeder.demoPassword,
        );
    expect(byId, isA<Ok<User>>());
    expect(byId.valueOrNull!.id, patient.id);
  });

  test('forgot → reset actually changes the password', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authRepositoryProvider);

    final found = await auth.accountForIdentifier('patient1@myhealth.demo');
    expect(found, isA<Ok<User>>());
    final userId = found.valueOrNull!.id;

    final reset =
        await auth.resetPassword(userId: userId, newPassword: 'brandNewPw9');
    expect(reset, isA<Ok<dynamic>>());

    // Old password no longer works, new one does.
    expect(
      await auth.login(email: 'patient1@myhealth.demo', password: 'password'),
      isA<Err<dynamic>>(),
    );
    expect(
      await auth.login(
        email: 'patient1@myhealth.demo',
        password: 'brandNewPw9',
      ),
      isA<Ok<dynamic>>(),
    );
  });

  test('reset rejects a too-short password', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authRepositoryProvider);
    final userId = (await auth.accountForIdentifier('patient1@myhealth.demo'))
        .valueOrNull!
        .id;
    expect(
      await auth.resetPassword(userId: userId, newPassword: 'short'),
      isA<Err<dynamic>>(),
    );
  });

  testWidgets('forgot-password screen routes to reset and back to login', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Forgot password?'));
    await _settle(tester);
    expect(find.text('Forgot your password?'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email or national ID'),
      'patient1@myhealth.demo',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await _settle(tester);

    expect(find.text('New password'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password (8+ characters)'),
      'freshPass12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'freshPass12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Update password'));
    await _settle(tester);

    // Back on the sign-in screen.
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
