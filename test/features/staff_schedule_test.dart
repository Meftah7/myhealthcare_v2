// The clinician's calendar (P5-12, calendar rebuild): the day timeline with
// its live "now" line, stepping a day at a time, and drilling up to the month
// grid and the year of mini-months and back down again.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _openSchedule(WidgetTester tester) async {
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
  await passMfa(tester);
  await _settle(tester);

  await tester.tap(find.text('Schedule').first);
  await _settle(tester);
  return container;
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('day timeline opens on today, with hours and the now line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _openSchedule(tester);
    addTearDown(container.dispose);

    expect(tester.takeException(), isNull);
    expect(container.read(scheduleViewProvider), ScheduleView.day);

    final today = dayOf(DateTime.now());
    expect(container.read(scheduleFocusedDayProvider), today);

    // Hour rules are labelled, and "now" is marked to the minute.
    expect(find.text('09:00'), findsWidgets);
    expect(
      find.text(DateFormat('HH:mm').format(DateTime.now())),
      findsWidgets,
      reason: 'the live now-line carries the current time',
    );

    await _teardown(tester);
  });

  testWidgets('stepping a day moves the focus and the strip follows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _openSchedule(tester);
    addTearDown(container.dispose);

    final start = container.read(scheduleFocusedDayProvider);

    await tester.tap(find.byTooltip('Next day'));
    await _settle(tester);
    expect(
      container.read(scheduleFocusedDayProvider),
      start.add(const Duration(days: 1)),
    );

    await tester.tap(find.byTooltip('Previous day'));
    await tester.tap(find.byTooltip('Previous day'));
    await _settle(tester);
    expect(
      container.read(scheduleFocusedDayProvider),
      start.subtract(const Duration(days: 1)),
    );

    await _teardown(tester);
  });

  testWidgets('day → month → year and back down again', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _openSchedule(tester);
    addTearDown(container.dispose);

    final now = DateTime.now();

    // Top-left steps up to the month.
    await tester.tap(find.text(DateFormat('MMM').format(now)).first);
    await _settle(tester);
    expect(container.read(scheduleViewProvider), ScheduleView.month);
    expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);

    // Top-left now says the year, and opens it.
    await tester.tap(find.text('${now.year}').first);
    await _settle(tester);
    expect(container.read(scheduleViewProvider), ScheduleView.year);
    // Twelve mini-months.
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tapping a month drills back down to it.
    await tester.tap(find.text('Jan'));
    await _settle(tester);
    expect(container.read(scheduleViewProvider), ScheduleView.month);
    expect(container.read(scheduleFocusedDayProvider).month, 1);

    await _teardown(tester);
  });
}
