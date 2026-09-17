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

    expect(find.text('Understand your health at a glance'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Understand your health at a glance'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
    expect(prefs.getBool('ui.hasSeenOnboarding'), isTrue);
  });

  testWidgets('walking all three pages ends on Get started', (tester) async {
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

    for (final title in const [
      'Book the right appointment, faster',
      'One app, your whole care team',
    ]) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sign in'), findsWidgets);
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

    expect(find.text('Understand your health at a glance'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
  });
}
