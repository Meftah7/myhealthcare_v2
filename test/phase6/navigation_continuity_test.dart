import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/app_card.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets(
    'staff tabs remain single and keep the selected patient context',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = newTestDatabase();
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
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

      container.read(routerProvider).go(AppRoutes.staffPatients);
      await _settle(tester);
      await tester.tap(find.byType(AppCard).first);
      await _settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Open chart'), findsOneWidget);

      await tester.tap(find.text('Tasks').last);
      await _settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Open chart'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
