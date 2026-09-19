// Does the department name's rendered color actually flip correctly when the
// user taps the light/dark toggle mid-session (not just on a fresh launch)?
// Reported: color looks right on first open, wrong after switching modes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/theme/app_colors.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 44; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets(
    'department name colour tracks the theme after an in-session toggle, '
    'not just on first launch',
    (tester) async {
      final db = newTestDatabase();
      await Seeder(db).run();
      // Pre-seed onboarding as already seen so it doesn't sit on top of the
      // login screen and swallow the tap meant for "Sign in".
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
      await _pump(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'admin@myhealth.demo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        Seeder.demoPassword,
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await passMfa(tester);
      await _pump(tester);

      await tester.tap(find.text('Departments').first);
      await _pump(tester);

      Color? nameColor() =>
          tester.widget<Text>(find.text('Cardiology')).style?.color;

      // First launch: no saved preference -> ThemeMode.system -> the test
      // platform's default brightness (light).
      final initial = nameColor();
      expect(
        initial,
        AppColors.light.onSurface,
        reason: 'first-launch colour should be the light-theme onSurface',
      );

      // Flip to dark via the same toggle button the app bar exposes.
      await tester.tap(find.byIcon(Icons.dark_mode_outlined).first);
      await _pump(tester);

      final afterDark = nameColor();
      expect(
        afterDark,
        AppColors.dark.onSurface,
        reason:
            'after switching to dark, colour should be the dark-theme '
            'onSurface, not the stale light-theme value',
      );
      expect(afterDark, isNot(initial));

      // And back to light — this is the exact "change mode" step the report
      // describes as breaking.
      await tester.tap(find.byIcon(Icons.light_mode_outlined).first);
      await _pump(tester);
      final backToLight = nameColor();
      expect(
        backToLight,
        AppColors.light.onSurface,
        reason:
            'switching back to light should restore the exact original '
            'colour, not something else',
      );
    },
  );
}
