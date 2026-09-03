// Staff opens their profile, sees read-only details, and changes the device
// preferences — theme mode and language (P8-07).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _settle(tester);

    // Open the Profile tab from the bottom navigation.
    await tester.tap(find.text('Profile').last);
    await _settle(tester);

    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    expect(find.text('Specialty'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);

    final scrollable = find
        .descendant(
          of: find.byType(StaffProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> reveal(Finder f) async {
      await tester.scrollUntilVisible(f, 120, scrollable: scrollable);
      await tester.ensureVisible(f);
      await _settle(tester);
    }

    // Switch to dark mode.
    await reveal(find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await _settle(tester);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // Switch language to Arabic → app goes RTL and the label localises.
    await reveal(find.text('العربية'));
    await tester.tap(find.text('العربية'));
    await _settle(tester);
    expect(container.read(localeProvider), const Locale('ar'));
    expect(find.text('الملف الشخصي'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('الملف الشخصي').first)),
      TextDirection.rtl,
    );
  });
}
