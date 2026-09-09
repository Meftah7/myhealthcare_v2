// Tier B: the AI Clinical Scribe (offline structuring + save) and the staff
// patient summary provider.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/ai_scribe/application/clinical_scribe.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient_chart/application/chart_summary_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _container() async {
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
  await container
      .read(sessionProvider.notifier)
      .login(email: 'staff1@myhealth.demo', password: Seeder.demoPassword);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_secure_storage has no test implementation; make it a no-op so
    // the AI key store resolves to "no key" instantly under fake-async.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  test('scribe: with AI off, everything lands in the HPI, editable', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final result = await container
        .read(clinicalScribeProvider)
        .structure(
          'Sore throat 3 days, no fever. Likely viral. Rest + fluids.',
        );

    expect(result, isA<Ok<ScribeDraft>>());
    final draft = (result as Ok<ScribeDraft>).value;
    expect(draft.usedAi, isFalse);
    expect(draft.hpi, contains('Sore throat'));
    expect(draft.toNoteBody(), contains('History of present illness'));
  });

  test('scribe: empty input is a validation error', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final result = await container
        .read(clinicalScribeProvider)
        .structure('   ');
    expect(result, isA<Err<ScribeDraft>>());
  });

  test('staff patient summary generates for an explicit patient id', () async {
    final container = await _container();
    addTearDown(container.dispose);

    // A seeded chronic patient with history.
    final patients = await container
        .read(patientRepositoryProvider)
        .all(limit: 5);
    final id = patients.valueOrNull!.first.id;

    final summary = await container.read(
      chartPatientSummaryProvider(id).future,
    );
    expect(summary.patientId, id);
    expect(summary.summaryMarkdown, isNotEmpty);
  });

  testWidgets('AI Scribe quick action → structure → save writes a note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2800);
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
      'staff1@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);

    await tester.tap(find.text('AI Scribe'));
    await _settle(tester);
    expect(find.textContaining('Scribe a visit note for'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'a');
    await _settle(tester);
    await tester.tap(
      // Scoped to the sheet: the dashboard behind it has ListTiles of its own.
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          )
          .first,
      warnIfMissed: false,
    );
    await _settle(tester);

    // Scribe screen.
    expect(find.widgetWithText(AppBar, 'AI Clinical Scribe'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'Follow-up hypertension. BP controlled. Continue amlodipine.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Structure with AI'));
    await _settle(tester);

    expect(find.text('STRUCTURED NOTE'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save as visit note'));
    await _settle(tester);
    expect(find.textContaining('Saved to the patient record'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
