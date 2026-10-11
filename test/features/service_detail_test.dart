// Service detail pages: each of the six Services entries opens one shared
// detail layout; only Health Trackers offers a real action (View Vitals).
// Planned services explain Future work and never offer sign-in, connect or
// booking actions they cannot honour. Layout holds in Arabic/dark/Large text
// on a short phone and on desktop.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/service_catalog/presentation/services_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({
    'ui.hasSeenOnboarding': true,
    ...prefs,
  });
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
  await _settle(tester);
  return c;
}

Future<void> _signIn(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'patient1@myhealth.demo');
  await tester.enterText(fields.at(1), Seeder.demoPassword);
  final submit = find.byType(FilledButton).first;
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await passMfa(tester);
  await _settle(tester);
}

String _location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

const _pages = {
  'Complete Checkup': 'Health checkup packages are planned for MyHealth',
  'E-Referral': 'Electronic referrals are planned for MyHealth',
  'Blood Donation': 'Blood donation information is planned for MyHealth',
  'Health Trackers': 'Review the vitals recorded in your health record',
  'Wearables': 'Smartwatch connections are planned for MyHealth',
  'Water tracking': 'Water intake tracking is planned for MyHealth',
};

void main() {
  testWidgets('each Services entry opens its detail page and Back returns', (
    tester,
  ) async {
    final c = await _pumpApp(tester);
    await _signIn(tester);

    for (final MapEntry(key: entry, value: heading) in _pages.entries) {
      c.read(routerProvider).go(AppRoutes.patientServices);
      await _settle(tester);
      final tile = find.text(entry);
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ServicesScreen),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first,
      );
      await tester.ensureVisible(tile.last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(tile.last);
      await _settle(tester);

      expect(find.text(heading), findsOneWidget, reason: entry);
      expect(find.text('Future work'), findsWidgets, reason: entry);
      // No reference-style sign-in or unsupported device/booking actions.
      for (final banned in ['Login', 'Connect', 'Sync', 'Register']) {
        expect(find.text(banned), findsNothing, reason: '$entry: $banned');
      }

      await tester.tap(find.byType(BackButton));
      await _settle(tester);
      expect(_location(c), AppRoutes.patientServices, reason: entry);
    }
    await _done(tester);
  });

  testWidgets('a planned service explains Future work', (tester) async {
    final c = await _pumpApp(tester);
    await _signIn(tester);
    c.read(routerProvider).go(AppRoutes.patientServiceDetail('wearables'));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('service-detail-action')));
    await _settle(tester);
    expect(
      find.textContaining('planned future work and is not part'),
      findsOneWidget,
    );
    await _done(tester);
  });

  testWidgets('Health Trackers opens the real Vitals screen', (tester) async {
    final c = await _pumpApp(tester);
    await _signIn(tester);
    c
        .read(routerProvider)
        .go(AppRoutes.patientServiceDetail('health-trackers'));
    await _settle(tester);

    expect(find.text('View Vitals'), findsOneWidget);
    await tester.tap(find.text('View Vitals'));
    await _settle(tester);
    expect(_location(c), AppRoutes.patientVitals);
    await _done(tester);
  });

  testWidgets('a signed-out link to a detail page resumes after sign-in', (
    tester,
  ) async {
    final c = await _pumpApp(tester);
    final target = AppRoutes.patientServiceDetail('health-trackers');
    c.read(routerProvider).go(target);
    await _settle(tester);
    expect(_location(c), startsWith(AppRoutes.login));
    expect(find.text('View Vitals'), findsNothing);

    await _signIn(tester);
    expect(_location(c), target);
    await _done(tester);
  });

  for (final (name, size, prefs) in [
    (
      'short phone, Arabic, dark, Large text, OS 1.3x',
      const Size(360, 600),
      {'ui.locale': 'ar', 'ui.themeMode': 'dark', 'ui.textScale': 'medium'},
    ),
    (
      'desktop, English, light, Small text',
      const Size(1366, 768),
      {'ui.textScale': 'xSmall'},
    ),
  ]) {
    testWidgets('detail layout fits: $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      if (name.contains('OS')) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      }
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final c = await _pumpApp(tester, prefs: prefs);
      await _signIn(tester);
      for (final id in ['blood-donation', 'health-trackers']) {
        c.read(routerProvider).go(AppRoutes.patientServiceDetail(id));
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: id);
        final action = find.byKey(const ValueKey('service-detail-action'));
        expect(action, findsOneWidget);
        // The action sits fully on screen.
        final rect = tester.getRect(action);
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: id);
      }
      await _done(tester);
    });
  }
}
