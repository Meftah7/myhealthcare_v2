// Arabic regressions: (1) the role shells' navigation labels follow the
// locale, (2) the patient-home ticket carousel doesn't overflow when Arabic
// falls back to platform Arabic fonts (taller line metrics than the bundled
// Latin fonts), and (3) the staff patient list is fully Arabic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _boot(WidgetTester tester) async {
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
  addTearDown(db.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
  return container;
}

Future<void> _signIn(WidgetTester tester, {required String email}) async {
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

Iterable<String> _navLabels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is NavigationBar || w is NavigationRail,
        ),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data ?? '');

void main() {
  testWidgets('arabic: nav labels localize and patient home never overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _boot(tester);
    await _signIn(tester, email: 'patient3@myhealth.demo');

    final ar = lookupAppLocalizations(const Locale('ar'));

    // Before: the (hardcoded) English labels are visible.
    expect(_navLabels(tester), contains('Home'));

    // Switch to Arabic.
    await container.read(localeProvider.notifier).set(const Locale('ar'));
    await _settle(tester);

    // Issue 1 — the bottom navigation bar follows the locale.
    expect(_navLabels(tester), contains(ar.navHome));
    expect(_navLabels(tester), isNot(contains('Home')));

    // Issue 2 — nothing overflows on the Arabic home screen: the carousel
    // card height must account for Arabic fallback font metrics. Drain the
    // auto-advance timer too, so every card lays out.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('arabic: staff patient list is localized', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _boot(tester);
    await _signIn(tester, email: 'staff1@myhealth.demo');

    final ar = lookupAppLocalizations(const Locale('ar'));
    await container.read(localeProvider.notifier).set(const Locale('ar'));
    await _settle(tester);

    // Issue 1 — the staff rail follows the locale too.
    expect(_navLabels(tester), contains(ar.navPatients));

    // Issue 3 — the staff Patients screen is Arabic.
    container.read(routerProvider).go(AppRoutes.staffPatients);
    await _settle(tester);

    expect(find.text(ar.navPatients), findsWidgets);
    expect(find.text(ar.searchByNameOrNationalId), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
