// A staff member signs in, works the redesigned dashboard: Quick actions,
// a panel scan, the queue, and the task board (P5-04..P5-11 + rebuild).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/app_scaffold.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('staff dashboard: sign in, quick actions, scan panel, tasks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = newTestDatabase();
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
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

    // Lands on the staff dashboard, laid out like the patient one: greeting,
    // a single gradient hero, a three-figure shift row, then Quick actions.
    // The desktop toolbar shows the signed-in clinician's name.
    final scaffold = tester.widget<AppScaffold>(find.byType(AppScaffold).first);
    expect(find.text(scaffold.title!), findsOneWidget);
    expect(find.text('On duty'), findsNothing);
    expect(find.text('Quick Statistics'), findsOneWidget);
    for (final label in ['Ongoing', 'Upcoming', 'Completed']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Quick actions'), findsOneWidget);

    // Run a panel scan from the Quick actions grid.
    expect(find.text('Panel scan'), findsOneWidget);
    await tester.tap(find.text('Panel scan'));
    // Let the in-memory scan finish and the result snackbar animate in, but
    // stop before its ~4s auto-dismiss.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.textContaining('Panel scan complete'), findsOneWidget);

    // Task board is reachable and renders.
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(AppScaffold).first),
    );
    scope.read(routerProvider).go(AppRoutes.staffTasks);
    await _settle(tester);
    expect(find.text('Task board'), findsOneWidget);

    scope.read(routerProvider).go(AppRoutes.staffChat);
    await _settle(tester);
    expect(find.widgetWithText(AppBar, 'Chat'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
