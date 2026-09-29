// Gate 1 — sessions: expired, idle, deactivated and signed-out sessions are
// refused by the repositories themselves; sensitive actions need a recent
// password; account switching on a shared device reveals none of the
// previous user's state; the idle warning, resume-after-timeout and
// cross-account deep links behave in the running app.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/app_environment.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/nutrition/application/macro_calculator.dart';
import 'package:myhealthcare/features/nutrition/application/nutrition_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_documents.dart';
import 'package:myhealthcare/services/auth/auth_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/sessions.dart';
import '../support/test_database.dart';

class _Clock {
  DateTime now = DateTime.now();
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

Matcher get _expired => isA<Err<dynamic>>().having(
  (r) => r.failure,
  'failure',
  isA<SessionExpiredFailure>(),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<(ProviderContainer, AppDatabase)> _pumpApp(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
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
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
  return (container, db);
}

Future<void> _signInThroughUi(WidgetTester tester, String email) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await passMfa(tester);
  await _settle(tester);
}

String _location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  group('expired session', () {
    test(
      'every repository refuses to serve without a signed-in principal',
      () async {
        final (c, _) = await seededContainer();
        const p = 'patient_001';
        final calls = <String, Future<Result<Object?>> Function()>{
          'appointments': () =>
              c.read(appointmentRepositoryProvider).forPatient(p),
          'records': () => c.read(recordRepositoryProvider).timeline(p),
          'vitals': () => c.read(vitalsRepositoryProvider).forPatient(p),
          'medications': () =>
              c.read(medicationRepositoryProvider).forPatient(p),
          'billing': () => c.read(billingRepositoryProvider).forPatient(p),
          'patients': () => c.read(patientRepositoryProvider).byId(p),
          'notifications': () =>
              c.read(notificationRepositoryProvider).forRecipient(p),
          'sick leave': () => c.read(sickLeaveRepositoryProvider).forPatient(p),
          'messages': () =>
              c.read(careMessageRepositoryProvider).threadsForPatient(p),
          'home visits': () =>
              c.read(homeVisitRepositoryProvider).forPatient(p),
          'walk-ins': () =>
              c.read(walkInTicketRepositoryProvider).forPatient(p),
          'referrals': () =>
              c.read(referralRequestRepositoryProvider).forPatient(p),
          'tasks': () => c.read(taskRepositoryProvider).forStaff('staff_01'),
          'risk': () => c.read(riskRepositoryProvider).forPatient(p),
          'ai summaries': () =>
              c.read(aiSummaryRepositoryProvider).latestForPatient(p),
          'audit': () =>
              c.read(auditRepositoryProvider).query(const AuditQuery()),
          'feedback': () => c.read(feedbackRepositoryProvider).all(),
          'ai usage': () => c.read(aiUsageRepositoryProvider).recent(),
          'users': () =>
              c.read(userRepositoryProvider).byRole(UserRole.patient),
          'family links': () =>
              c.read(familyLinkRepositoryProvider).linkedAccounts(p),
          'care team': () => c.read(careTeamRepositoryProvider).forPatient(p),
          'credentials': () =>
              c.read(staffCredentialRepositoryProvider).forStaff('staff_01'),
        };
        for (final entry in calls.entries) {
          expect(await entry.value(), _expired, reason: entry.key);
        }
      },
    );

    test('signing out ends repository access immediately', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_001'),
        isA<Ok<dynamic>>(),
      );
      await c.read(sessionProvider.notifier).logout();
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_001'),
        _expired,
      );
    });

    test(
      'an idle session is refused by the repositories, not only the UI',
      () async {
        final clock = _Clock();
        final (c, _) = await seededContainer(
          overrides: [
            authContextProvider.overrideWith(
              (ref) => AuthContext(now: clock.call),
            ),
          ],
        );
        await signInAs(c, 'patient1@myhealth.demo');
        clock.advance(kSessionIdleTimeout + const Duration(minutes: 1));
        expect(
          await c.read(recordRepositoryProvider).timeline('patient_001'),
          _expired,
        );
      },
    );

    test(
      'activity cannot stretch a session past its absolute lifetime',
      () async {
        final clock = _Clock();
        final (c, _) = await seededContainer(
          overrides: [
            authContextProvider.overrideWith(
              (ref) => AuthContext(now: clock.call),
            ),
          ],
        );
        await signInAs(c, 'patient1@myhealth.demo');
        final context = c.read(authContextProvider);
        for (
          var t = Duration.zero;
          t <= kSessionAbsoluteLifetime;
          t += const Duration(minutes: 20)
        ) {
          clock.advance(const Duration(minutes: 20));
          context.touch();
        }
        expect(
          await c.read(recordRepositoryProvider).timeline('patient_001'),
          _expired,
        );
      },
    );

    test('deactivating an account ends its live session', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      await (db.update(db.users)..where((u) => u.id.equals('patient_001')))
          .write(const UsersCompanion(isActive: Value(false)));
      expect(
        await c.read(recordRepositoryProvider).timeline('patient_001'),
        _expired,
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sessionProvider).isAuthenticated, isFalse);
    });
  });

  group('re-authentication', () {
    test('sensitive admin actions need a recent password', () async {
      final clock = _Clock();
      final (c, _) = await seededContainer(
        overrides: [
          authContextProvider.overrideWith(
            (ref) => AuthContext(now: clock.call),
          ),
        ],
      );
      await signInAs(c, 'admin@myhealth.demo');
      final context = c.read(authContextProvider);
      // Stay active past the re-authentication window.
      for (var i = 0; i < 4; i++) {
        clock.advance(const Duration(minutes: 5));
        context.touch();
      }
      final users = c.read(userRepositoryProvider);
      final stale = await users.resetPassword(
        id: 'patient_002',
        newPassword: 'Admin-Set-123',
      );
      expect(stale.failureOrNull, isA<ReauthRequiredFailure>());

      final wrong = await c
          .read(sessionProvider.notifier)
          .reauthenticate('not-the-password');
      expect(wrong.isErr, isTrue);

      final ok = await c
          .read(sessionProvider.notifier)
          .reauthenticate(Seeder.demoPassword);
      expect(ok.isOk, isTrue);
      expect(
        await users.resetPassword(
          id: 'patient_002',
          newPassword: 'Admin-Set-123',
        ),
        isA<Ok<void>>(),
      );
    });

    test('the demo account switcher is refused in production builds', () async {
      final (c, _) = await seededContainer(
        overrides: [appModeProvider.overrideWithValue(AppMode.production)],
      );
      final r = await c.read(authRepositoryProvider).demoSignIn('patient_001');
      expect(r.failureOrNull, isA<AccessDeniedFailure>());
      expect(c.read(authContextProvider).principal, isNull);
    });
  });

  group('shared device', () {
    test(
      'switching accounts reveals none of the previous user\'s state',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, 'patient1@myhealth.demo');
        final first = c.read(currentUserProvider)!.id;

        // Leave a trail: a booking draft, a search, nutrition inputs, cached
        // visits.
        c.read(bookingDraftProvider.notifier).state = const BookingRequestDraft(
          reason: 'Private reason',
        );
        c.read(bookingTargetPatientIdProvider.notifier).state = 'patient_050';
        c.read(foodSearchQueryProvider.notifier).state = 'chocolate';
        await c
            .read(macroTargetsProvider.notifier)
            .set(
              const MacroInputs(
                age: 40,
                sex: Sex.female,
                weightKg: 71,
                heightCm: 165,
                activityFactor: 1.4,
                goal: FitnessGoal.lose,
                weeklyRateKg: 0.5,
                preset: MacroPreset.balanced,
              ),
            );
        final mine = await c.read(patientAppointmentsProvider.future);
        expect(mine.every((a) => a.patientId == first), isTrue);
        expect((await c.read(pdfIdentityProvider.future)).patientId, first);

        await signInAs(c, 'patient2@myhealth.demo');
        final second = c.read(currentUserProvider)!.id;

        expect(c.read(bookingDraftProvider).reason, isNull);
        expect(c.read(bookingTargetPatientIdProvider), isNull);
        expect(c.read(foodSearchQueryProvider), isEmpty);
        expect(c.read(macroTargetsProvider), isNull);
        final theirs = await c.read(patientAppointmentsProvider.future);
        expect(theirs.every((a) => a.patientId == second), isTrue);
        // Exports are stamped with — and built from — the new account only.
        expect((await c.read(pdfIdentityProvider.future)).patientId, second);

        // Body measurements left no trace on the device.
        final prefs = c.read(sharedPreferencesProvider);
        expect(
          prefs.getKeys().where((k) => k.startsWith('nutrition.')),
          isEmpty,
        );
        expect(db, isNotNull);
      },
    );
  });

  group('in the app', () {
    testWidgets('the idle warning appears before sign-out and can keep the '
        'session', (tester) async {
      final (c, _) = await _pumpApp(tester);
      await _signInThroughUi(tester, 'patient1@myhealth.demo');
      expect(c.read(sessionProvider).isAuthenticated, isTrue);

      await tester.pump(
        kSessionIdleTimeout - kSessionWarningLead + const Duration(seconds: 1),
      );
      await tester.pump();
      expect(find.text('Still there?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Stay signed in'));
      await tester.pump();
      expect(find.text('Still there?'), findsNothing);

      await tester.pump(kSessionWarningLead + const Duration(seconds: 5));
      expect(c.read(sessionProvider).isAuthenticated, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('after an idle timeout the same account resumes where it was; '
        'another account starts at its own home', (tester) async {
      final (c, _) = await _pumpApp(tester);
      await _signInThroughUi(tester, 'patient1@myhealth.demo');
      c.read(routerProvider).go(AppRoutes.patientAppointments);
      await _settle(tester);

      await tester.pump(kSessionIdleTimeout + const Duration(minutes: 1));
      await _settle(tester);
      expect(c.read(sessionProvider).isAuthenticated, isFalse);
      expect(find.textContaining('pick up where you left off'), findsOneWidget);

      await _signInThroughUi(tester, 'patient1@myhealth.demo');
      expect(_location(c), AppRoutes.patientAppointments);

      // A different person on the same device does not inherit it.
      c.read(routerProvider).go(AppRoutes.patientAppointments);
      await _settle(tester);
      await tester.pump(kSessionIdleTimeout + const Duration(minutes: 1));
      await _settle(tester);
      await _signInThroughUi(tester, 'patient2@myhealth.demo');
      expect(_location(c), AppRoutes.patientHome);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a deep link to another patient\'s record shows no content', (
      tester,
    ) async {
      final (c, db) = await _pumpApp(tester);
      final record =
          await (db.select(db.medicalRecords)
                ..where((r) => r.patientId.equals('patient_002'))
                ..limit(1))
              .getSingle();
      await _signInThroughUi(tester, 'patient1@myhealth.demo');

      c.read(routerProvider).go(AppRoutes.patientRecord(record.id));
      await _settle(tester);
      expect(find.text(record.title), findsNothing);
      expect(find.textContaining('belongs to another account'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
