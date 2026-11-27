// Frequently Asked Questions: opened from the assistant's FAQ button,
// answers expand, the medical-questions answer is the required wording, the
// doctor / booking buttons use the existing routes only when tapped, and
// Arabic is right-to-left on a phone.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );
  final (c, _) = await seededContainer();
  await signInAs(c, 'patient3@myhealth.demo');
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
  );
  await _settle(tester);
  c.read(routerProvider).go(AppRoutes.patientHome);
  c.read(careNavigatorViewProvider.notifier).state = CareNavView.panel;
  await _settle(tester);
  // The assistant's labelled FAQ button opens the FAQ.
  await tester.tap(find.byKey(const ValueKey('assistant-faq')));
  await _settle(tester);
  expect(
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
    AppRoutes.patientFaq,
  );
  return c;
}

String _path(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('opens from the assistant, expands, buttons open real screens', (
    tester,
  ) async {
    final c = await _open(tester, const Size(1280, 900));
    final t = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('Frequently Asked Questions'), findsWidgets);
    for (final q in [t.faqQ1, t.faqQ5, t.faqQ9, t.faqQ10]) {
      expect(find.text(q), findsOneWidget);
    }

    // The medical-questions answer: the required wording and both buttons.
    await tester.ensureVisible(find.text(t.faqQ9));
    await tester.tap(find.text(t.faqQ9));
    await _settle(tester);
    expect(
      find.text(
        'No. This assistant helps you use the app and summarizes what your '
        'uploaded document says. For medical questions, please message your '
        'doctor or book an appointment.',
      ),
      findsOneWidget,
    );
    final item = find.byKey(const ValueKey('faq-item-8'));
    final book = find.descendant(
      of: item,
      matching: find.byKey(const ValueKey('faq-link-book')),
    );
    final message = find.descendant(
      of: item,
      matching: find.byKey(const ValueKey('faq-link-messageDoctor')),
    );
    expect(book, findsOneWidget);
    expect(message, findsOneWidget);
    // Nothing happens until tapped.
    expect(_path(c), AppRoutes.patientFaq);
    await tester.ensureVisible(book);
    await tester.tap(book);
    await _settle(tester);
    expect(_path(c), AppRoutes.patientBookLanding);

    c.read(routerProvider).go(AppRoutes.patientFaq);
    await _settle(tester);
    await tester.tap(find.text(t.faqQ9));
    await _settle(tester);
    await tester.ensureVisible(message);
    await tester.tap(message);
    await _settle(tester);
    expect(_path(c), AppRoutes.patientMessages);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('every answer is present and non-empty, in both languages', (
    tester,
  ) async {
    for (final code in ['en', 'ar']) {
      final t = await AppLocalizations.delegate.load(Locale(code));
      final answers = [
        t.faqA1, t.faqA2, t.faqA3, t.faqA4, t.faqA5, //
        t.faqA6, t.faqA7, t.faqA8, t.faqA9, t.faqA10,
      ];
      for (final a in answers) {
        expect(a.trim(), isNotEmpty, reason: code);
      }
      // Answers match what the app supports.
      expect(t.faqA5, contains('20'), reason: code);
      expect(t.faqA5, contains('.docx'), reason: code);
      expect(t.faqA5, contains('.doc'), reason: code);
      expect(t.faqA5, contains('.txt'), reason: code);
    }
  });

  testWidgets('Arabic, phone: right-to-left and readable', (tester) async {
    final (c, _) = await seededContainer();
    await c.read(localeProvider.notifier).set(const Locale('ar'));
    // Phone width; tall enough that every question is built.
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
    await signInAs(c, 'patient3@myhealth.demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    await _settle(tester);
    c.read(routerProvider).go(AppRoutes.patientFaq);
    await _settle(tester);
    final t = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text('الأسئلة الشائعة'), findsWidgets);
    final q = find.text(t.faqQ9);
    expect(Directionality.of(tester.element(q)), TextDirection.rtl);
    await tester.ensureVisible(q);
    await tester.tap(q);
    await _settle(tester);
    expect(find.text(t.faqA9), findsOneWidget);
    expect(find.text('راسل طبيبك'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
