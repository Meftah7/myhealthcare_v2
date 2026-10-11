// First-launch experience: the readiness-driven splash (with a slow-start
// retry), then the two-page intro shown once per device. Skip / Get Started
// save completion, continue to sign-in and keep a protected deep link's
// destination; completion survives sign-out.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/auth/presentation/splash_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

const _bookTitle = 'Book appointments in a few taps';
const _recordsTitle = 'Your records and reports, made clearer';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pump(kSplashDuration + const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

/// The app with an instant bootstrap and no database behind it.
Future<SharedPreferences> _pumpLight(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        appBootstrapProvider.overrideWith((ref) async {}),
      ],
      child: const MyHealthCareApp(),
    ),
  );
  await _pumpPastSplash(tester);
  return sp;
}

/// The full app over a seeded test database, so accounts can sign in.
Future<(ProviderContainer, SharedPreferences)> _pumpSeeded(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
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
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  return (c, sp);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _signIn(WidgetTester tester, String email) async {
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
  testWidgets('first launch shows page 1 with progress, Skip and Next', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpLight(tester);

    expect(find.text(_bookTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 of 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Next'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Skip saves completion and continues to sign-in', (tester) async {
    final prefs = await _pumpLight(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_bookTitle), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isTrue);
  });

  testWidgets('Next moves to page 2, which ends on Get started', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final prefs = await _pumpLight(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text(_recordsTitle), findsOneWidget);
    expect(find.bySemanticsLabel('Page 2 of 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isNull);

    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(_recordsTitle), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isTrue);
    semantics.dispose();
  });

  testWidgets('swiping also reaches page 2', (tester) async {
    await _pumpLight(tester);
    await tester.fling(find.text(_bookTitle), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_recordsTitle), findsOneWidget);
  });

  testWidgets('a returning launch goes straight to sign-in', (tester) async {
    await _pumpLight(tester, prefs: {'ui.hasSeenOnboarding': true});

    expect(find.text(_bookTitle), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('works in Arabic with RTL and localized labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpLight(tester, prefs: {'ui.locale': 'ar'});

    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).last)
          .textDirection,
      TextDirection.rtl,
    );
    expect(find.bySemanticsLabel('الصفحة 1 من 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('signing out does not show onboarding again', (tester) async {
    final (c, _) = await _pumpSeeded(
      tester,
      prefs: {'ui.hasSeenOnboarding': true},
    );
    await _signIn(tester, 'patient1@myhealth.demo');
    expect(c.read(sessionProvider).isAuthenticated, isTrue);

    unawaited(c.read(sessionProvider.notifier).logout());
    await _settle(tester);

    expect(find.text(_bookTitle), findsNothing);
    expect(find.text('Sign in'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a protected deep link survives onboarding and sign-in', (
    tester,
  ) async {
    final (c, prefs) = await _pumpSeeded(tester);

    // Signed out: the link is held as the sign-in destination, and no
    // patient data renders beneath the intro.
    c.read(routerProvider).go(AppRoutes.patientVitals);
    await _settle(tester);
    expect(_location(c), startsWith(AppRoutes.login));
    expect(_location(c), contains('from='));
    expect(find.text(_bookTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await _settle(tester);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isTrue);
    expect(_location(c), contains('from='));

    await _signIn(tester, 'patient1@myhealth.demo');
    expect(_location(c), AppRoutes.patientVitals);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a stalled startup offers a retry instead of spinning forever', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final never = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appBootstrapProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) await never.future;
          }),
        ],
        child: const MyHealthCareApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Loading MyHealth'), findsOneWidget);
    expect(find.text('This is taking longer than usual'), findsNothing);

    await tester.pump(kSplashSlowAfter);
    expect(find.text('This is taking longer than usual'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _pumpPastSplash(tester);

    expect(attempts, 2);
    expect(find.text('This is taking longer than usual'), findsNothing);
    expect(find.text(_bookTitle), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a failed startup shows the retry screen, not onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appBootstrapProvider.overrideWith(
            (ref) async => throw Exception('storage unavailable'),
          ),
        ],
        child: const MyHealthCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your data"), findsOneWidget);
    expect(find.text(_bookTitle), findsNothing);
  });
}
