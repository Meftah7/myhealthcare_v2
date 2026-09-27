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
  // Pre-seed onboarding as already seen so it doesn't sit on top of the
  // login/reset screens and swallow taps meant for them.
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
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

  test(
    'forgot password always succeeds and never reveals whether the '
    'account exists',
    () async {
      final db = newTestDatabase();
      await Seeder(db).run();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final auth = container.read(authRepositoryProvider);

      // A real identifier and a made-up one report the identical outcome.
      expect(
        await auth.requestPasswordReset('patient1@myhealth.demo'),
        isA<Ok<dynamic>>(),
      );
      expect(
        await auth.requestPasswordReset('nobody@myhealth.demo'),
        isA<Ok<dynamic>>(),
      );
    },
  );

  test(
    'a queued request is visible to admin and resolving it via the '
    'existing admin reset actually changes the password and clears the flag',
    () async {
      final db = newTestDatabase();
      await Seeder(db).run();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final auth = container.read(authRepositoryProvider);
      final users = container.read(userRepositoryProvider);

      final patient = (await users.byRole(UserRole.patient)).valueOrNull!
          .firstWhere((u) => u.email == 'patient1@myhealth.demo');
      final admin = (await users.byRole(UserRole.admin)).valueOrNull!.first;

      await auth.requestPasswordReset('patient1@myhealth.demo');
      final pending = await users.userIdsWithPendingPasswordResetRequests();
      expect(pending.valueOrNull, contains(patient.id));

      final reset = await users.resetPassword(
        id: patient.id,
        newPassword: 'brandNewPw9',
      );
      expect(reset, isA<Ok<dynamic>>());
      await users.resolvePasswordResetRequests(
        userId: patient.id,
        staffId: admin.id,
      );

      final pendingAfter =
          await users.userIdsWithPendingPasswordResetRequests();
      expect(pendingAfter.valueOrNull, isNot(contains(patient.id)));

      // Old password no longer works, new one does.
      expect(
        await auth.login(
          email: 'patient1@myhealth.demo',
          password: 'password',
        ),
        isA<Err<dynamic>>(),
      );
      expect(
        await auth.login(
          email: 'patient1@myhealth.demo',
          password: 'brandNewPw9',
        ),
        isA<Ok<dynamic>>(),
      );
    },
  );

  test('admin reset rejects a too-short password', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final users = container.read(userRepositoryProvider);
    final patient = (await users.byRole(UserRole.patient)).valueOrNull!.first;
    expect(
      await users.resetPassword(id: patient.id, newPassword: 'short'),
      isA<Err<dynamic>>(),
    );
  });

  test('login locks the account after repeated wrong passwords', () async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authRepositoryProvider);

    for (var i = 0; i < 5; i++) {
      final r = await auth.login(
        email: 'patient1@myhealth.demo',
        password: 'wrong-password',
      );
      expect(r, isA<Err<dynamic>>());
    }

    // Locked out now, even with the correct password.
    final locked = await auth.login(
      email: 'patient1@myhealth.demo',
      password: 'password',
    );
    expect(locked.isErr, isTrue);
    expect(locked.failureOrNull!.message, contains('Too many attempts'));
  });

  test(
    'login never distinguishes an unknown identifier from a wrong password',
    () async {
      final db = newTestDatabase();
      await Seeder(db).run();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final auth = container.read(authRepositoryProvider);

      final unknown = await auth.login(
        email: 'nobody@myhealth.demo',
        password: 'whatever12',
      );
      final wrongPassword = await auth.login(
        email: 'patient1@myhealth.demo',
        password: 'whatever12',
      );
      expect(unknown.failureOrNull!.message, wrongPassword.failureOrNull!.message);
    },
  );

  testWidgets(
    'forgot-password screen never lets the requester set a new password '
    'directly — it queues a request and shows one generic confirmation',
    (tester) async {
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

      // No password field is ever shown from this unauthenticated flow.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Request sent'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Back to sign in'));
      await _settle(tester);

      // Back on the sign-in screen.
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
