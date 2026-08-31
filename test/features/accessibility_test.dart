// Accessibility checks (P6-09): contrast, tap-target size, semantic labels,
// and large-text-scale layout, on the key screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<Widget> _app(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
    child: const MyHealthCareApp(),
  );
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    Seeder.demoPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await _pump(tester);
}

void main() {
  testWidgets('login screen meets contrast, tap-target and label guidelines', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(await _app(db));
    await _pump(tester);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('patient home meets contrast + tap-target guidelines', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(await _app(db));
    await _pump(tester);
    await _login(tester, 'patient1@myhealth.demo');

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('staff dashboard meets contrast + tap-target guidelines', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(await _app(db));
    await _pump(tester);
    await _login(tester, 'staff1@myhealth.demo');

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('login screen survives a 2x text scale without overflow', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: await _app(db),
      ),
    );
    await _pump(tester);

    expect(tester.takeException(), isNull);
  });
}
