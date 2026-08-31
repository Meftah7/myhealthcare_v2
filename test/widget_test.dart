// Smoke test: the app builds, the session restores empty, and the router lands
// on the login screen (P0-05, P0-06, P0-07, P2-05).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('unauthenticated app lands on the sign-in screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyHealthCareApp(),
      ),
    );

    // Splash → session restore (empty) → redirect to /login.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Create a patient account'), findsOneWidget);
  });
}
