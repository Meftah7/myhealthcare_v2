// Home restructure: sections in the new order, and the Upcoming appointments
// carousel shows a ticket number, a room, a "N of M" count and auto-advances.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('home carousel: ticket number, room, count, auto-slide',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      'patient3@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _settle(tester);

    // New section order: greeting, quick appointment, Your health, then
    // Upcoming appointments, then Quick actions.
    final health = tester.getTopLeft(find.text('YOUR HEALTH')).dy;
    final upcoming =
        tester.getTopLeft(find.text('UPCOMING APPOINTMENTS')).dy;
    final quick = tester.getTopLeft(find.text('QUICK ACTIONS')).dy;
    expect(health, lessThan(upcoming));
    expect(upcoming, lessThan(quick));

    // The carousel shows a well-formed ticket number and a room.
    expect(find.text('TICKET'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith(RegExp(r'[A-X]-')),
      ),
      findsWidgets,
    );
    expect(find.textContaining('Room '), findsWidgets);

    // The count is visible.
    expect(find.textContaining(RegExp(r'^\d+ of \d+$')), findsOneWidget);

    // Auto-advances after 5s.
    final firstCount = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^\d+ of \d+$')))
        .first
        .data!;
    if (firstCount != '1 of 1') {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      final nextCount = tester
          .widgetList<Text>(find.textContaining(RegExp(r'^\d+ of \d+$')))
          .first
          .data!;
      expect(nextCount, isNot(firstCount));
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
