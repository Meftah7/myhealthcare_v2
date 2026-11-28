// Staff opens their profile, sees read-only details, and changes the device
// preferences — theme mode and language (P8-07).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 18; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('staff profile: details + theme + language', (tester) async {
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'staff1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);

    // Open the Settings tab from the bottom navigation.
    await tester.tap(find.text('Settings').last);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

    Future<void> reveal(Finder f, {double delta = 120}) async {
      // The page's scroll view, not the navigation rail's — from `medium` up
      // the rail is scrollable too, so an unscoped finder is ambiguous.
      await tester.scrollUntilVisible(
        f,
        delta,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await tester.ensureVisible(f);
      await _settle(tester);
    }

    // Account details is its own page.
    await reveal(find.widgetWithText(ListTile, 'Account'));
    await tester.tap(find.widgetWithText(ListTile, 'Account'));
    await _settle(tester);
    expect(find.text('Specialty'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);

    // The preference controls sit on Settings itself, like the patient app.
    // Switch to dark mode — the controls sit above the account rows.
    await reveal(find.text('Dark'), delta: -120);
    await tester.tap(find.text('Dark'));
    await _settle(tester);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // Switch language to Arabic → app goes RTL and the labels localise.
    await reveal(find.text('العربية'));
    await tester.tap(find.text('العربية'));
    await _settle(tester);
    expect(container.read(localeProvider), const Locale('ar'));
    // Settings and its bottom-bar label localise and run right-to-left.
    expect(find.text('الإعدادات'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('الإعدادات').first)),
      TextDirection.rtl,
    );
  });
}
