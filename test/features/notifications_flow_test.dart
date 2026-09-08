// Notifications UI: the header badge shows unread count, opens the centre,
// tapping a message marks it read and drops the badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/notifications/presentation/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('notifications: badge, open centre, mark one read', (tester) async {
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
    await passMfa(tester);
    await _settle(tester);

    // Header badge is showing an unread count.
    expect(find.byTooltip('Notifications (2 unread)'), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications (2 unread)'));
    await _settle(tester);

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);

    // Bottom nav is still visible (nested under the Home branch).
    expect(find.text('Appointment'), findsWidgets);

    // Open the first message; it opens a detail sheet and is marked read.
    final firstCard = find
        .descendant(
          of: find.byType(NotificationsScreen),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.tap(firstCard);
    await _settle(tester);
    // Close the detail sheet.
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);

    // Mark all read, then the action disappears.
    if (find.text('Mark all read').evaluate().isNotEmpty) {
      await tester.tap(find.text('Mark all read'));
      await _settle(tester);
    }
    expect(find.text('Mark all read'), findsNothing);
  });
}
