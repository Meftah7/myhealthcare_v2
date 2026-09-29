// A seeding/migration failure (e.g. the browser refuses local storage) must
// hold the user on an error screen with a retry, not silently fall through
// to a normal-looking login screen backed by an empty, unseeded database —
// which would make every login, including every demo account, fail.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'a bootstrap failure shows a retry screen instead of the login screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();
      var attempts = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appBootstrapProvider.overrideWith((ref) async {
              attempts++;
              if (attempts == 1) throw Exception('storage unavailable');
            }),
          ],
          child: const MyHealthCareApp(),
        ),
      );

      // Let the first (failing) attempt settle.
      await tester.pumpAndSettle();

      // Never the login screen while the dataset never actually seeded.
      expect(find.text('Sign in'), findsNothing);
      expect(find.text("Couldn't load your data"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // Retrying (now succeeding) reaches the real login screen.
      expect(find.text("Couldn't load your data"), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
      expect(attempts, 2);
    },
  );
}
