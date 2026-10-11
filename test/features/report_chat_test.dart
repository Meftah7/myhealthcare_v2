// Report explanation: honest labelling, clipping disclosure, report context
// in the header, and no conversation carried across reports or accounts.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

MedicalRecord _report(String id, String text) => MedicalRecord(
  id: id,
  patientId: 'p',
  recordType: RecordType.labResult,
  title: 'Lab report $id',
  occurredAt: DateTime(2026),
  createdAt: DateTime(2026),
  extractedText: text,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
  });

  test(
    'without live AI the explanation is labelled as a basic summary',
    () async {
      expect(await container.read(careNavigatorLiveProvider.future), isFalse);
      await container
          .read(careNavigatorProvider.notifier)
          .explainDocument(_report('a', 'HbA1c 7.9 % H\nGlucose 140 high'));
      final state = container.read(careNavigatorProvider);
      expect(state.report?.id, 'a');
      expect(state.messages.last.text, startsWith(basicSummaryLabel));
      expect(state.messages.last.text, contains('Marked high'));
    },
  );

  test('absent markers are not reported as normal results', () {
    final text = explainDocumentOffline('Glucose 95 mg/dL', title: 'x');
    expect(text, isNot(contains('within the expected range')));
    expect(text, contains('does not confirm the results are normal'));
  });

  test('a long report discloses that only part was explained', () {
    final note = clippedReportNote(30000);
    expect(note, contains('$kReportExplainLimit'));
    expect(note, contains('30000'));
  });

  test('switching reports starts a clean conversation', () async {
    final nav = container.read(careNavigatorProvider.notifier);
    await nav.explainDocument(_report('a', 'Glucose 140 high'));
    await nav.explainDocument(_report('b', 'Ferritin 10 low'));
    final state = container.read(careNavigatorProvider);
    expect(state.report?.id, 'b');
    expect(
      state.messages.where((m) => m.text.contains('Lab report a')),
      isEmpty,
    );
  });

  test('signing out clears the report conversation', () async {
    await container
        .read(careNavigatorProvider.notifier)
        .explainDocument(_report('a', 'Glucose 140 high'));
    await container.read(sessionProvider.notifier).logout();
    final state = container.read(careNavigatorProvider);
    expect(state.report, isNull);
    expect(state.messages, hasLength(1));
  });
}
