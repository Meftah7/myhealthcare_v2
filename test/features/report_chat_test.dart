// The assistant's document conversation: a summary of a record already in
// Records, factual follow-up lookups (quotes, bounded history, the current
// question sent once), medical follow-ups refused, honest failures with
// retry, authorization before anything is sent, and context clearing. The
// AI service is a fake client (mocked contract) — not a live-provider test.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/ai_chat/application/assistant_actions.dart';
import 'package:myhealthcare/features/ai_chat/application/assistant_policy.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/services/ai/report_ai_client.dart';

import '../support/fake_report_ai.dart';
import '../support/sessions.dart';

/// SYNTHETIC TEST REPORT text attached to a real seeded record.
const _report =
    'SYNTHETIC TEST REPORT\nHbA1c 7.9 % H (4.0–5.6)\nGlucose 140 mg/dL high';

late AppDatabase _db;

Future<MedicalRecord> _ownRecord(String email) async {
  final user = await (_db.select(
    _db.users,
  )..where((u) => u.email.equals(email))).getSingle();
  final r = await (_db.select(
    _db.medicalRecords,
  )..where((r) => r.patientId.equals(user.id))).get().then((l) => l.first);
  return MedicalRecord(
    id: r.id,
    patientId: r.patientId,
    recordType: r.recordType,
    title: r.title,
    occurredAt: r.occurredAt,
    createdAt: r.createdAt,
    extractedText: _report,
  );
}

Future<ProviderContainer> _signedIn({ReportAiClient? client}) async {
  final (c, db) = await seededContainer(
    overrides: [
      if (client != null) reportAiClientProvider.overrideWithValue(client),
    ],
  );
  _db = db;
  await signInAs(c, 'patient3@myhealth.demo');
  return c;
}

/// Lets queued async work (readiness checks, fake replies) finish.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ChatMessage _last(ProviderContainer c) =>
    c.read(careNavigatorProvider).messages.last;

Future<ChatMessage> _say(ProviderContainer c, String text) async {
  c.read(careNavigatorProvider.notifier).send(text);
  await _settle();
  return _last(c);
}

void main() {
  group('without the AI service', () {
    test('the summary is made on the device and labelled', () async {
      final c = await _signedIn();
      expect(await c.read(careNavigatorLiveProvider.future), isFalse);
      final record = await _ownRecord('patient3@myhealth.demo');
      await c.read(careNavigatorProvider.notifier).explainDocument(record);
      final state = c.read(careNavigatorProvider);
      expect(state.report?.id, record.id);
      expect(state.messages.last.kind, ChatKind.summary);
      expect(state.messages.last.text, startsWith(basicSummaryLabel));
      // Why it was made on the device is said.
      expect(state.messages.last.note, contains('not set up'));
    });

    test('factual follow-ups are answered from the document, quoted', () async {
      final c = await _signedIn();
      await c
          .read(careNavigatorProvider.notifier)
          .explainDocument(await _ownRecord('patient3@myhealth.demo'));
      final m = await _say(c, 'Which results are labelled high?');
      expect(m.kind, ChatKind.summary);
      expect(m.quotes, contains('HbA1c 7.9 % H (4.0–5.6)'));
      final missing = await _say(c, 'What is my vitamin D value?');
      expect(missing.text, AssistantText.notFound(false));
    });
  });

  group('with the AI service (mocked contract)', () {
    test(
      'the summary comes from the service and covers the document',
      () async {
        final fake = FakeReportAiClient();
        final c = await _signedIn(client: fake);
        await _settle();
        expect(await c.read(careNavigatorLiveProvider.future), isTrue);
        await c
            .read(careNavigatorProvider.notifier)
            .explainDocument(await _ownRecord('patient3@myhealth.demo'));
        final last = _last(c);
        expect(last.kind, ChatKind.live);
        expect(
          last.text,
          contains('• The document labels HbA1c 7.9 % as High.'),
        );
        expect(fake.explained.single, _report);
      },
    );

    test('factual lookups carry verified quotes and bounded history', () async {
      final fake = FakeReportAiClient();
      final c = await _signedIn(client: fake);
      await c
          .read(careNavigatorProvider.notifier)
          .explainDocument(await _ownRecord('patient3@myhealth.demo'));
      var last = await _say(c, 'What value does the document list for HbA1c?');
      expect(last.kind, ChatKind.live);
      expect(last.supported, isTrue);
      expect(last.quotes, ['HbA1c 7.9 % H (4.0–5.6)']);
      // The current question is not repeated in the history.
      expect(
        fake.asked.single.history.where(
          (t) => t.text == 'What value does the document list for HbA1c?',
        ),
        isEmpty,
      );

      fake.answer = const ReportAnswer(
        answer: 'Probably fine, vitamin D is usually 30.',
        supported: false,
        quotes: [],
        coverage: ReportCoverage(
          explainedChars: 60,
          totalChars: 60,
          complete: true,
        ),
      );
      last = await _say(c, 'What is my vitamin D value?');
      // Never the model's own words for an unsupported answer.
      expect(last.text, AssistantText.notFound(false));
      expect(last.quotes, isEmpty);
      expect(fake.asked.last.history.any((t) => t.fromPatient), isTrue);
    });

    test(
      'medical follow-ups are refused, with doctor and booking buttons',
      () async {
        final fake = FakeReportAiClient();
        final c = await _signedIn(client: fake);
        await c
            .read(careNavigatorProvider.notifier)
            .explainDocument(await _ownRecord('patient3@myhealth.demo'));
        for (final q in [
          'What does this glucose value mean?',
          'Is this result normal?',
          'Should I stop my medication?',
          'هل هذه النتيجة طبيعية؟',
        ]) {
          final m = await _say(c, q);
          expect(m.isMedicalRefusal, isTrue, reason: q);
          expect(m.text, AssistantText.medical(isArabicText(q)));
          expect(m.actions, contains(AssistantAction.bookAppointment));
        }
        expect(fake.asked, isEmpty, reason: 'never sent to the service');
      },
    );

    test('a gateway refusal is shown as the fixed refusal', () async {
      final fake = FakeReportAiClient()
        ..answer = const ReportAnswer(
          answer: 'You should take levothyroxine.',
          supported: false,
          quotes: [],
          refusal: true,
          coverage: ReportCoverage(
            explainedChars: 1,
            totalChars: 1,
            complete: true,
          ),
        );
      final c = await _signedIn(client: fake);
      await c
          .read(careNavigatorProvider.notifier)
          .explainDocument(await _ownRecord('patient3@myhealth.demo'));
      final m = await _say(c, 'What does the document say I should do?');
      expect(m.text, AssistantText.medical(false));
      expect(m.text, isNot(contains('levothyroxine')));
    });

    test('failures are shown plainly and can be retried', () async {
      final fake = FakeReportAiClient();
      final c = await _signedIn(client: fake);
      final nav = c.read(careNavigatorProvider.notifier);
      await nav.explainDocument(await _ownRecord('patient3@myhealth.demo'));
      fake.failNext = const ReportAiException(ReportAiFailureKind.timeout);
      var last = await _say(c, 'Which results are labelled high?');
      expect(last.kind, ChatKind.error);
      expect(last.text, reportAiFailureMessage(ReportAiFailureKind.timeout));
      expect(last.retryQuestion, 'Which results are labelled high?');
      expect(c.read(careNavigatorProvider).sending, isFalse);

      final before = c.read(careNavigatorProvider).messages.length;
      await nav.retry(last.retryQuestion!);
      await _settle();
      last = _last(c);
      expect(last.kind, ChatKind.live);
      // Retried without adding the question again.
      expect(c.read(careNavigatorProvider).messages.length, before);
    });

    test("another patient's record is never sent", () async {
      final fake = FakeReportAiClient();
      final c = await _signedIn(client: fake);
      final foreign = await _ownRecord('patient1@myhealth.demo');
      await c.read(careNavigatorProvider.notifier).explainDocument(foreign);
      expect(c.read(careNavigatorProvider).report, isNull);
      expect(fake.explained, isEmpty);
    });

    test('leaving, resetting and logging out clear the context', () async {
      final fake = FakeReportAiClient();
      final c = await _signedIn(client: fake);
      final nav = c.read(careNavigatorProvider.notifier);
      final record = await _ownRecord('patient3@myhealth.demo');
      await nav.explainDocument(record);
      nav.leaveReport();
      expect(c.read(careNavigatorProvider).reportContext, isNull);
      expect(c.read(careNavigatorProvider).messages, hasLength(1));

      await nav.explainDocument(record);
      await c.read(sessionProvider.notifier).logout();
      final state = c.read(careNavigatorProvider);
      expect(state.reportContext, isNull);
      expect(state.messages, hasLength(1));
    });
  });

  test('the on-device summary repeats facts and adds no meaning or advice', () {
    final text = explainDocumentOffline(
      'Gulf Diagnostics Lab\nFerritin 8 ng/mL L (15-150)\nGlucose 7.9 mmol/L H\n'
      'Comment: Ferritin below range.',
      title: 'Blood test',
    );
    expect(
      text,
      contains(
        'Ferritin 8 ng/mL L (15-150) — the document labels this result as Low',
      ),
    );
    expect(
      text,
      contains('The document states: “Comment: Ferritin below range.”'),
    );
    for (final added in [
      'iron stores',
      'healthcare professional',
      'means',
      'normal',
    ]) {
      expect(text.toLowerCase(), isNot(contains(added)), reason: added);
    }
  });

  test('a long lookup discloses that only part was searched', () {
    final note = clippedReportNote(30000);
    expect(note, contains('$kReportExplainLimit'));
    expect(note, contains('30000'));
  });
}
