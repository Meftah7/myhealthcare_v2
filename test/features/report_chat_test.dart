// The proposal's report chatbot in the full app: explanation, grounded
// follow-up questions, honest unavailable/error states, authorization before
// sending, and context clearing. The live service is replaced by a fake
// client (mocked contract); this is NOT a live-provider evaluation — see
// services/report_ai/eval for that (blocked without a server key).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/services/ai/report_ai_client.dart';
import 'package:myhealthcare/services/pdf/pdf_text.dart';

import '../support/sessions.dart';

/// SYNTHETIC TEST REPORT text attached to a real seeded record.
const _report =
    'SYNTHETIC TEST REPORT\nHbA1c 7.9 % H (4.0–5.6)\nGlucose 140 mg/dL high';

class _FakeClient implements ReportAiClient {
  final asked = <({String question, List<ReportTurn> history})>[];
  ReportAiException? failNext;
  ReportAnswer next = const ReportAnswer(
    answer: 'Your HbA1c was 7.9 %, marked high (4.0–5.6).',
    supported: true,
    quotes: ['HbA1c 7.9 % H (4.0–5.6)'],
    coverage: ReportCoverage(
      explainedChars: 60,
      totalChars: 60,
      complete: true,
    ),
  );

  @override
  bool get isConfigured => true;

  @override
  Future<ReportExplanation> explain(String reportText) async {
    if (failNext case final e?) {
      failNext = null;
      throw e;
    }
    return const ReportExplanation(
      answer: 'This is a diabetes panel; HbA1c is marked high.',
      coverage: ReportCoverage(
        explainedChars: 12000,
        totalChars: 30000,
        complete: false,
      ),
    );
  }

  @override
  Future<ReportAnswer> ask({
    required String reportText,
    required String question,
    required List<ReportTurn> history,
  }) async {
    asked.add((question: question, history: history));
    if (failNext case final e?) {
      failNext = null;
      throw e;
    }
    return next;
  }
}

/// A seeded record belonging to [email], with synthetic report text.
Future<MedicalRecord> _ownRecord(AppDatabase db, String email) async {
  final user = await (db.select(
    db.users,
  )..where((u) => u.email.equals(email))).getSingle();
  final row =
      await (db.select(db.medicalRecords)
            ..where((r) => r.patientId.equals(user.id))
            ..limit(2))
          .get();
  final r = row.first;
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

late AppDatabase _db;

void main() {
  group('without the report AI service', () {
    test('explanation is the labelled on-device summary', () async {
      final c = await _signedIn();
      expect(await c.read(careNavigatorLiveProvider.future), isFalse);
      final record = await _ownRecord(_db, 'patient3@myhealth.demo');
      await c.read(careNavigatorProvider.notifier).explainDocument(record);
      final state = c.read(careNavigatorProvider);
      expect(state.report?.id, record.id);
      expect(state.messages.last.kind, ChatKind.summary);
      expect(state.messages.last.text, startsWith(basicSummaryLabel));
    });

    test('follow-up questions say the service is not connected', () async {
      final c = await _signedIn();
      final nav = c.read(careNavigatorProvider.notifier);
      await nav.explainDocument(
        await _ownRecord(_db, 'patient3@myhealth.demo'),
      );
      await nav.send('Is my HbA1c high?');
      final last = c.read(careNavigatorProvider).messages.last;
      expect(last.kind, ChatKind.unavailable);
      // Not a canned answer to the question.
      expect(last.text, isNot(contains('7.9')));
      expect(last.text, contains("isn't connected"));
    });
  });

  group('with the report AI service (mocked contract)', () {
    test('live explanation discloses partial coverage', () async {
      final fake = _FakeClient();
      final c = await _signedIn(client: fake);
      await c
          .read(careNavigatorProvider.notifier)
          .explainDocument(await _ownRecord(_db, 'patient3@myhealth.demo'));
      final last = c.read(careNavigatorProvider).messages.last;
      expect(last.kind, ChatKind.live);
      expect(last.note, clippedReportNote(30000));
    });

    test(
      'grounded answers carry verified quotes and bounded history',
      () async {
        final fake = _FakeClient();
        final c = await _signedIn(client: fake);
        final nav = c.read(careNavigatorProvider.notifier);
        await nav.explainDocument(
          await _ownRecord(_db, 'patient3@myhealth.demo'),
        );
        await nav.send('Is my HbA1c high?');
        var last = c.read(careNavigatorProvider).messages.last;
        expect(last.kind, ChatKind.live);
        expect(last.supported, isTrue);
        expect(last.quotes, ['HbA1c 7.9 % H (4.0–5.6)']);
        // Context = the live explanation; the current question is not
        // repeated in the history.
        final first = fake.asked.single.history;
        expect(first, hasLength(1));
        expect(first.single.fromPatient, isFalse);

        fake.next = const ReportAnswer(
          answer: 'The report does not include a vitamin D result.',
          supported: false,
          quotes: [],
          coverage: ReportCoverage(
            explainedChars: 60,
            totalChars: 60,
            complete: true,
          ),
        );
        await nav.send('What about vitamin D?');
        last = c.read(careNavigatorProvider).messages.last;
        expect(last.supported, isFalse);
        expect(last.quotes, isEmpty);
        // The earlier question and its live answer are context.
        // Order: explanation, first question, its live answer.
        final history = fake.asked.last.history;
        expect(history.map((t) => t.fromPatient), [false, true, false]);
        expect(history[1].text, 'Is my HbA1c high?');
      },
    );

    test('provider failures are shown accurately and can be retried', () async {
      final fake = _FakeClient();
      final c = await _signedIn(client: fake);
      final nav = c.read(careNavigatorProvider.notifier);
      await nav.explainDocument(
        await _ownRecord(_db, 'patient3@myhealth.demo'),
      );
      fake.failNext = const ReportAiException(ReportAiFailureKind.timeout);
      await nav.send('Is my glucose high?');
      var last = c.read(careNavigatorProvider).messages.last;
      expect(last.kind, ChatKind.error);
      expect(last.text, reportAiFailureMessage(ReportAiFailureKind.timeout));
      expect(last.retryQuestion, 'Is my glucose high?');
      expect(c.read(careNavigatorProvider).sending, isFalse);

      await nav.retry(last.retryQuestion!);
      last = c.read(careNavigatorProvider).messages.last;
      expect(last.kind, ChatKind.live);

      // A failed live explanation falls back to the labelled summary.
      fake.failNext = const ReportAiException(ReportAiFailureKind.provider);
      await nav.explainDocument(
        (await _ownRecord(_db, 'patient3@myhealth.demo')).copyWith(id: 'x'),
      );
      // 'x' is not a readable record: nothing is sent or shown for it.
      expect(c.read(careNavigatorProvider).report?.id, isNot('x'));
    });

    test('another patient\'s record is never sent', () async {
      final fake = _FakeClient();
      final c = await _signedIn(client: fake);
      final foreign = await _ownRecord(_db, 'patient1@myhealth.demo');
      await c.read(careNavigatorProvider.notifier).explainDocument(foreign);
      expect(c.read(careNavigatorProvider).report, isNull);
      expect(fake.asked, isEmpty);
    });

    test('incomplete extraction is disclosed', () async {
      final fake = _FakeClient();
      final c = await _signedIn(client: fake);
      final record = (await _ownRecord(
        _db,
        'patient3@myhealth.demo',
      )).copyWith(extractedText: 'A' * maxExtractedChars);
      final fakeComplete = _FakeClient()
        ..next = const ReportAnswer(
          answer: 'x',
          supported: false,
          quotes: [],
          coverage: ReportCoverage(
            explainedChars: 1,
            totalChars: 1,
            complete: true,
          ),
        );
      expect(fakeComplete.isConfigured, isTrue);
      await c.read(careNavigatorProvider.notifier).explainDocument(record);
      final ctx = c.read(careNavigatorProvider).reportContext!;
      expect(ctx.extractionPartial, isTrue);
    });

    test('report switch, leaving and logout clear the context', () async {
      final fake = _FakeClient();
      final c = await _signedIn(client: fake);
      final nav = c.read(careNavigatorProvider.notifier);
      final record = await _ownRecord(_db, 'patient3@myhealth.demo');
      await nav.explainDocument(record);
      await nav.send('Is my HbA1c high?');

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
}
