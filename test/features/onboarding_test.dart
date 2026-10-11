// The intro carousel appears once per device after the splash, walks through
// its pages, and Skip/Get started dismiss it permanently.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/features/auth/presentation/splash_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pump(kSplashDuration + const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('onboarding appears after the splash and Skip dismisses it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const MyHealthCareApp(),
      ),
    );

    await _pumpPastSplash(tester);

    expect(find.text('Book appointments in a few taps'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Skip lands on guest Home (public browsing).
    expect(find.text('Book appointments in a few taps'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Login or Register'), findsOneWidget);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isTrue);
  });

  testWidgets('walking both pages ends on Get started', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const MyHealthCareApp(),
      ),
    );

    await _pumpPastSplash(tester);

    for (final title in const ['Your records and reports, made clearer']) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Login or Register'), findsOneWidget);
  });

  testWidgets('does not appear again once already seen', (tester) async {
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const MyHealthCareApp(),
      ),
    );

    await _pumpPastSplash(tester);

    expect(find.text('Book appointments in a few taps'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
  });
}
