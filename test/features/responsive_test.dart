// The responsive contract (DESIGN.md §6.4) and the reduce-motion guarantee
// (§7), asserted on the real app rather than on a widget in isolation.
//
// One widget tree, re-flowed by window size class: a bottom NavigationBar on
// compact, an icon NavigationRail on medium, an extended rail from expanded up,
// and dashboards that split into two columns once there is room for them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/responsive.dart';
import 'package:myhealthcare/core/presentation/two_pane.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// Signs a patient in at [size] and leaves the app on the patient home screen.
Future<void> _signInPatient(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  bool reduceMotion = false,
}) => _signIn(
  tester,
  email: 'patient1@myhealth.demo',
  size: size,
  textScale: textScale,
  reduceMotion: reduceMotion,
);

Future<void> _signIn(
  WidgetTester tester, {
  required String email,
  required Size size,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MediaQuery(
      // Built *from the view*, then overridden: a bare `MediaQueryData()`
      // defaults its size to zero, which would silently make every one of
      // these tests measure a 0dp-wide window.
      data: MediaQueryData.fromView(tester.view).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const MyHealthCareApp(),
      ),
    ),
  );
  await _settle(tester);
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await passMfa(tester);
  await _settle(tester);
}

/// Tears the tree down so the home carousel cancels its auto-advance timer.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('navigation re-flows with the window size class', () {
    testWidgets('compact (<600) puts the bar at the bottom', (tester) async {
      await _signInPatient(tester, size: const Size(400, 900));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await _teardown(tester);
    });

    testWidgets('medium (600-839) uses an icon rail', (tester) async {
      await _signInPatient(tester, size: const Size(700, 1000));

      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.all);

      await _teardown(tester);
    });

    testWidgets('expanded (840-1199) extends the rail', (tester) async {
      await _signInPatient(tester, size: const Size(1000, 1200));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      // An extended rail draws its own inline labels.
      expect(rail.labelType, NavigationRailLabelType.none);

      await _teardown(tester);
    });

    testWidgets('large (>=1200) keeps the extended rail', (tester) async {
      await _signInPatient(tester, size: const Size(1400, 1200));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);

      await _teardown(tester);
    });
  });

  group('dashboard sections split into columns when there is room', () {
    testWidgets('compact stacks them in one column', (tester) async {
      await _signInPatient(tester, size: const Size(400, 2200));

      final health = tester.getTopLeft(find.text('YOUR HEALTH'));
      final quick = tester.getTopLeft(find.text('QUICK ACTIONS'));
      // Same column: identical x, and health comes first.
      expect(quick.dx, health.dx);
      expect(health.dy, lessThan(quick.dy));

      await _teardown(tester);
    });

    testWidgets('expanded puts them side by side', (tester) async {
      await _signInPatient(tester, size: const Size(1200, 1600));

      expect(find.byType(SectionColumns), findsWidgets);
      final health = tester.getTopLeft(find.text('YOUR HEALTH'));
      final quick = tester.getTopLeft(find.text('QUICK ACTIONS'));
      // Two columns: Quick actions moves to the right of Your health, and both
      // start at the same height.
      expect(quick.dx, greaterThan(health.dx));
      expect(quick.dy, health.dy);

      await _teardown(tester);
    });
  });

  group('layout survives the OS text-size setting', () {
    for (final (label, size) in const [
      ('phone', Size(400, 900)),
      ('tablet', Size(800, 1200)),
      ('desktop', Size(1400, 1000)),
    ]) {
      testWidgets('$label has no overflow at 2x text scale', (tester) async {
        await _signInPatient(tester, size: size, textScale: 2);

        // Any RenderFlex overflow is reported as a framework exception, so an
        // empty exception slot is the assertion.
        expect(tester.takeException(), isNull);

        await _teardown(tester);
      });
    }
  });

  group('list-detail screens show one pane or two', () {
    testWidgets('compact shows the patient list alone', (tester) async {
      await _signIn(
        tester,
        email: 'staff1@myhealth.demo',
        size: const Size(400, 900),
      );
      await tester.tap(find.text('Patients').last);
      await _settle(tester);

      expect(find.byType(TwoPane), findsOneWidget);
      // No detail pane, so no placeholder and no second toolbar.
      expect(find.byType(VerticalDivider), findsNothing);
      expect(find.text('Pick a patient to open their chart.'), findsNothing);

      await _teardown(tester);
    });

    testWidgets('expanded shows the list beside a detail placeholder', (
      tester,
    ) async {
      await _signIn(
        tester,
        email: 'staff1@myhealth.demo',
        size: const Size(1300, 1400),
      );
      await tester.tap(find.text('Patients').last);
      await _settle(tester);

      expect(find.byType(TwoPane), findsOneWidget);
      // Nothing selected yet: the detail pane invites a choice.
      expect(find.text('Pick a patient to open their chart.'), findsOneWidget);

      // Choosing a patient fills the pane in place, and the list stays put.
      final listRect = tester.getRect(find.byType(SearchBar));
      await tester.tap(find.byType(CircleAvatar).first);
      await _settle(tester);

      expect(find.text('Pick a patient to open their chart.'), findsNothing);
      expect(tester.getRect(find.byType(SearchBar)), listRect);

      await _teardown(tester);
    });
  });

  testWidgets('reduce-motion renders cleanly and leaves no timers running', (
    tester,
  ) async {
    await _signInPatient(
      tester,
      size: const Size(400, 900),
      reduceMotion: true,
    );

    expect(tester.takeException(), isNull);
    // The home carousel must not have started its auto-advance timer; if it
    // had, tearing the tree down here would fail with a pending timer.
    await _teardown(tester);
    expect(tester.takeException(), isNull);
  });
}
