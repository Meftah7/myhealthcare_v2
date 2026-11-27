// Attaching a document in the assistant: picking reads it on the device but
// never asks for a summary; Summarize is the only way to one; upload progress
// follows real (fake-Dio) events; each format is read for real; bad files
// fail with a reason; retries and double taps never duplicate a record,
// upload or summary; removing, replacing, restarting, signing out or
// switching account turns late results into no-ops. SYNTHETIC documents;
// the AI service is a fake client (mocked contract).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/ai_chat/application/document_attachment.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/services/ai/report_ai_client.dart';
import 'package:myhealthcare/services/documents/document_text.dart';
import 'package:pdf/widgets.dart' as pw;

import '../support/fake_report_ai.dart';
import '../support/sessions.dart';

late AppDatabase _db;

Future<ProviderContainer> _patient({ReportAiClient? client}) async {
  final (c, db) = await seededContainer(
    overrides: [
      if (client != null) reportAiClientProvider.overrideWithValue(client),
    ],
  );
  _db = db;
  await signInAs(c, 'patient3@myhealth.demo');
  return c;
}

Future<void> _settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Uint8List _fixture(String name) =>
    File('test/fixtures/documents/$name').readAsBytesSync();

Future<Uint8List> _pdf(List<String> lines) => pw.Document()
    .let(
      (d) => d
        ..addPage(
          pw.Page(
            build: (_) =>
                pw.Column(children: [for (final l in lines) pw.Text(l)]),
          ),
        ),
    )
    .save();

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

const _txt =
    'SYNTHETIC TEST REPORT\nHbA1c 7.9 % H (4.0-5.6)\n'
    'Comment: HbA1c above the reference range.';

Uint8List get _txtBytes => Uint8List.fromList(utf8.encode(_txt));

Future<int> _uploads() async =>
    (await (_db.select(_db.medicalRecords)
              ..where((r) => r.uploadedByPatient.equals(true))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
            .get())
        .length;

/// Every status the attachment passed through.
List<AttachmentStatus> _track(ProviderContainer c) {
  final seen = <AttachmentStatus>[];
  c.listen<ChatAttachment?>(documentAttachmentProvider, (_, next) {
    if (next != null && (seen.isEmpty || seen.last != next.status)) {
      seen.add(next.status);
    }
  });
  return seen;
}

void main() {
  test('picking reads the file but never asks for a summary', () async {
    final fake = FakeReportAiClient();
    final c = await _patient(client: fake);
    final seen = _track(c);
    final before = await _uploads();
    await c
        .read(documentAttachmentProvider.notifier)
        .attach('panel.txt', _txtBytes);
    final a = c.read(documentAttachmentProvider)!;
    expect(a.status, AttachmentStatus.ready);
    expect(a.canSummarize, isTrue);
    expect(a.charCount, _txt.length);
    expect(a.format, DocumentFormat.txt);
    expect(seen, [
      AttachmentStatus.validating,
      AttachmentStatus.reading,
      AttachmentStatus.ready,
    ]);
    expect(fake.summaries, isEmpty);
    expect(await _uploads(), before, reason: 'not saved until Summarize');
    expect(c.read(careNavigatorProvider).messages, hasLength(1));
  });

  test(
    'Summarize: saved locally, uploaded with real progress, summarized',
    () async {
      final fake = FakeReportAiClient()
        ..progress = const [(0, 2000), (500, 2000), (1500, 2000), (2000, 2000)];
      final c = await _patient(client: fake);
      final progress = <double?>[];
      final seen = _track(c);
      c.listen<ChatAttachment?>(documentAttachmentProvider, (_, n) {
        if (n?.status == AttachmentStatus.uploading) progress.add(n!.progress);
      });
      final before = await _uploads();
      final attachment = c.read(documentAttachmentProvider.notifier);
      await attachment.attach('panel.txt', _txtBytes);
      await attachment.send();
      await _settle();

      expect(
        seen,
        containsAllInOrder([
          AttachmentStatus.ready,
          AttachmentStatus.saving,
          AttachmentStatus.uploading,
          AttachmentStatus.summarizing,
        ]),
      );
      // Progress is what the upload reported — no invented steps.
      expect(progress, containsAllInOrder([0.0, 0.25, 0.75]));
      expect(fake.summaries.single.text, _txt);
      expect(await _uploads(), before + 1);
      // The card is done; the summary is in the conversation.
      expect(c.read(documentAttachmentProvider), isNull);
      final messages = c.read(careNavigatorProvider).messages;
      expect(messages[messages.length - 2].text, '📎 panel.txt');
      expect(messages.last.kind, ChatKind.live);
      expect(
        messages.last.text,
        contains('• The document labels HbA1c 7.9 % as High.'),
      );
      expect(c.read(careNavigatorProvider).report, isNotNull);
    },
  );

  test('each format is read for real before anything is sent', () async {
    final c = await _patient(client: FakeReportAiClient());
    final attachment = c.read(documentAttachmentProvider.notifier);
    for (final (name, bytes, snippet) in [
      ('report.pdf', await _pdf(['HbA1c 7.9 % H (4.0-5.6)']), 'HbA1c 7.9 % H'),
      ('report.docx', _fixture('synthetic-report.docx'), 'HbA1c | 7.9 % H'),
      ('report.doc', _fixture('synthetic-report.doc'), 'HbA1c | 7.9 % H'),
      ('report.txt', _txtBytes, 'HbA1c 7.9 % H'),
    ]) {
      await attachment.attach(name, bytes);
      final a = c.read(documentAttachmentProvider)!;
      expect(a.status, AttachmentStatus.ready, reason: name);
      expect(a.charCount, greaterThan(snippet.length), reason: name);
    }
  });

  test('bad files fail with a reason and cannot be summarized', () async {
    final fake = FakeReportAiClient();
    final c = await _patient(client: fake);
    final attachment = c.read(documentAttachmentProvider.notifier);
    for (final (name, bytes, problem) in [
      ('empty.pdf', Uint8List(0), DocumentProblem.empty),
      ('big.txt', Uint8List(maxDocumentBytes + 1), DocumentProblem.tooLarge),
      (
        'virus.pdf',
        Uint8List.fromList([0x4D, 0x5A, 1, 2, 3, 4]),
        DocumentProblem.executable,
      ),
      (
        'locked.docx',
        _fixture('synthetic-locked.docx'),
        DocumentProblem.encrypted,
      ),
      (
        'locked.doc',
        _fixture('synthetic-locked.doc'),
        DocumentProblem.encrypted,
      ),
      (
        'sheet.xlsx',
        Uint8List.fromList([1, 2, 3]),
        DocumentProblem.unsupportedType,
      ),
    ]) {
      await attachment.attach(name, bytes);
      final a = c.read(documentAttachmentProvider)!;
      expect(a.status, AttachmentStatus.failed, reason: name);
      expect(a.documentProblem, problem, reason: name);
      expect(a.canSummarize, isFalse, reason: name);
      await attachment.send();
    }
    expect(fake.summaries, isEmpty);
  });

  test(
    'a failed summary keeps the file; Retry reuses the record and key',
    () async {
      final fake = FakeReportAiClient()
        ..failNext = const ReportAiException(ReportAiFailureKind.timeout);
      final c = await _patient(client: fake);
      final attachment = c.read(documentAttachmentProvider.notifier);
      final before = await _uploads();
      await attachment.attach('panel.txt', _txtBytes);
      await attachment.send();
      await _settle();
      final failed = c.read(documentAttachmentProvider)!;
      expect(failed.status, AttachmentStatus.failed);
      expect(failed.aiProblem, ReportAiFailureKind.timeout);
      expect(
        failed.canSummarize,
        isTrue,
        reason: 'retry without picking again',
      );
      expect(failed.recordId, isNotNull);

      await attachment.send();
      await _settle();
      expect(fake.summaries, hasLength(2));
      expect(
        fake.summaries[0].key,
        fake.summaries[1].key,
        reason: 'same summary key',
      );
      expect(await _uploads(), before + 1, reason: 'one record, not two');
      expect(c.read(documentAttachmentProvider), isNull);
    },
  );

  test('double tap on Summarize sends once', () async {
    final fake = FakeReportAiClient()..hold = Completer();
    final c = await _patient(client: fake);
    final attachment = c.read(documentAttachmentProvider.notifier);
    final before = await _uploads();
    await attachment.attach('panel.txt', _txtBytes);
    unawaited(attachment.send());
    unawaited(attachment.send());
    await _settle();
    fake.hold!.complete();
    await _settle();
    expect(fake.summaries, hasLength(1));
    expect(await _uploads(), before + 1);
  });

  test('removing during the upload discards the late summary', () async {
    final fake = FakeReportAiClient()..hold = Completer();
    final c = await _patient(client: fake);
    final attachment = c.read(documentAttachmentProvider.notifier);
    await attachment.attach('panel.txt', _txtBytes);
    unawaited(attachment.send());
    await _settle();
    expect(c.read(documentAttachmentProvider)!.busy, isTrue);
    attachment.remove();
    fake.hold!.complete();
    await _settle();
    expect(c.read(documentAttachmentProvider), isNull);
    expect(c.read(careNavigatorProvider).messages, hasLength(1));
  });

  test('replacing a file while it is read keeps only the new one', () async {
    final c = await _patient(client: FakeReportAiClient());
    final attachment = c.read(documentAttachmentProvider.notifier);
    final slow = Completer<ExtractedDocument>();
    attachment.reader = ({required fileName, required bytes}) =>
        fileName == 'old.txt'
        ? slow.future
        : readDocument(fileName: fileName, bytes: bytes);
    unawaited(attachment.attach('old.txt', _txtBytes));
    await _settle();
    expect(
      c.read(documentAttachmentProvider)!.status,
      AttachmentStatus.reading,
    );
    await attachment.attach('new.txt', _txtBytes);
    slow.complete(
      const ExtractedDocument(
        format: DocumentFormat.txt,
        text: 'late',
        complete: true,
      ),
    );
    await _settle();
    final a = c.read(documentAttachmentProvider)!;
    expect(a.fileName, 'new.txt');
    expect(a.charCount, _txt.length);
  });

  test(
    'restarting the chat or signing out discards a summary in flight',
    () async {
      for (final stop in ['reset', 'logout']) {
        final fake = FakeReportAiClient()..hold = Completer();
        final c = await _patient(client: fake);
        final attachment = c.read(documentAttachmentProvider.notifier);
        await attachment.attach('panel.txt', _txtBytes);
        unawaited(attachment.send());
        await _settle();
        if (stop == 'reset') {
          c.read(careNavigatorProvider.notifier).reset();
        } else {
          await c.read(sessionProvider.notifier).logout();
        }
        fake.hold!.complete();
        await _settle();
        expect(c.read(documentAttachmentProvider), isNull, reason: stop);
        expect(
          c.read(careNavigatorProvider).messages,
          hasLength(1),
          reason: stop,
        );
      }
    },
  );

  test('another account never sees the attachment or its result', () async {
    final fake = FakeReportAiClient()..hold = Completer();
    final c = await _patient(client: fake);
    final attachment = c.read(documentAttachmentProvider.notifier);
    await attachment.attach('panel.txt', _txtBytes);
    unawaited(attachment.send());
    await _settle();
    await signInAs(c, 'patient1@myhealth.demo');
    fake.hold!.complete();
    await _settle();
    expect(c.read(currentUserProvider)!.email, 'patient1@myhealth.demo');
    expect(c.read(documentAttachmentProvider), isNull);
    expect(c.read(careNavigatorProvider).messages, hasLength(1));
  });

  test(
    'without the AI service: summarized on the device, labelled, nothing uploaded',
    () async {
      final c = await _patient();
      final attachment = c.read(documentAttachmentProvider.notifier);
      await attachment.attach('panel.txt', _txtBytes);
      await attachment.send();
      await _settle();
      final last = c.read(careNavigatorProvider).messages.last;
      expect(last.kind, ChatKind.summary);
      expect(last.text, startsWith(basicSummaryLabel));
      expect(
        last.text,
        contains(
          'HbA1c 7.9 % H (4.0-5.6) — the document labels this result as High',
        ),
      );
      expect(last.note, contains('not set up'));
    },
  );

  test(
    'a partial summary says so; long text is sent with its true length',
    () async {
      final fake = FakeReportAiClient()
        ..summary = const DocumentSummary(
          overview: 'A long synthetic report.',
          points: ['The document lists sodium 139 mmol/L.'],
          coverage: SummaryCoverage(
            sourceChars: 200000,
            processedChars: 120000,
            complete: false,
          ),
        );
      final c = await _patient(client: fake);
      final attachment = c.read(documentAttachmentProvider.notifier);
      final long =
          'Sodium 139 mmol/L. Routine notes without measurements.\n' * 4000;
      await attachment.attach(
        'long.txt',
        Uint8List.fromList(utf8.encode(long)),
      );
      expect(c.read(documentAttachmentProvider)!.extractionComplete, isFalse);
      await attachment.send();
      await _settle();
      final sent = fake.summaries.single;
      expect(sent.text.length, ReportAiLimits.maxSummaryChars);
      expect(sent.sourceChars, maxDocumentChars);
      expect(sent.complete, isFalse);
      expect(
        c.read(careNavigatorProvider).messages.last.note,
        contains('only part'),
      );
    },
  );

  for (final (label, size, locale) in [
    ('phone, Arabic', const Size(320, 640), 'ar'),
    ('desktop, English', const Size(1366, 768), 'en'),
  ]) {
    testWidgets('the attachment card is usable — $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async => null,
          );
      final fake = FakeReportAiClient()..hold = Completer();
      final c = await _patient(client: fake);
      await c.read(localeProvider.notifier).set(Locale(locale));
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      c.read(routerProvider).go(AppRoutes.patientHome);
      c.read(careNavigatorViewProvider.notifier).state = CareNavView.panel;
      await tester.runAsync(
        () => c
            .read(documentAttachmentProvider.notifier)
            .attach('synthetic-report.docx', _fixture('synthetic-report.docx')),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(
        find.byKey(const ValueKey('assistant-attachment')),
        findsOneWidget,
      );
      expect(find.text('synthetic-report.docx'), findsOneWidget);
      final summarize = find.byKey(const ValueKey('attachment-summarize'));
      expect(summarize, findsOneWidget);
      expect(tester.takeException(), isNull);
      if (locale == 'ar') {
        expect(Directionality.of(tester.element(summarize)), TextDirection.rtl);
        expect(find.textContaining('جاهز'), findsOneWidget);
      } else {
        expect(find.textContaining('Ready'), findsOneWidget);
      }

      await tester.tap(summarize);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      // While it works: no Summarize button, a progress bar, Cancel.
      expect(summarize, findsNothing);
      expect(find.byKey(const ValueKey('attachment-progress')), findsOneWidget);
      fake.hold!.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(find.byKey(const ValueKey('assistant-attachment')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
