// The two onboarding screens at a 320 × 568 phone, in English and Arabic:
// artwork, text, page indicator and buttons all fit without scrolling at the
// standard text size, the longest paragraph clears the navigation, the
// heading stays put between pages, the buttons and arrows mirror in Arabic,
// Back returns to the first page, and large accessibility text scrolls while
// the buttons stay on screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/features/auth/presentation/splash_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';

const _doctor = 'assets/images/doctor-appointment-legs-uncrossed';
const _robot = 'assets/images/explain-report-illustration.png';

const _en = (
  title1: 'Good care starts with a time that suits you.',
  body1: 'Choose a doctor and find an appointment that fits your day.',
  title2: 'Your health records, in one place.',
  body2:
      'Find your reports, prescriptions and visit history. Use the AI '
      'assistant to get a plain-language explanation of a PDF report.',
  skip: 'Skip',
  next: 'Next',
  back: 'Back',
  done: 'Get started',
  progress1: 'Page 1 of 2',
);

const _ar = (
  title1: 'احجز موعدك في الوقت الذي يناسبك',
  body1: 'اختر طبيبك واحجز موعدًا يناسب يومك.',
  title2: 'سجلاتك الصحية في مكان واحد',
  body2:
      'اطّلع على تقاريرك ووصفاتك الطبية وسجل زياراتك. استخدم مساعد الذكاء '
      'الاصطناعي للحصول على شرح مبسّط لتقرير بصيغة PDF.',
  skip: 'تخطَّ',
  next: 'التالي',
  back: 'رجوع',
  done: 'ابدأ الآن',
  progress1: 'الصفحة 1 من 2',
);

/// The app's real fonts, so text wraps — and the 320 × 568 fit is measured —
/// as on a phone (the test default font has much wider glyphs).
Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await family('Lexend', [
    'assets/fonts/static/Lexend-Medium.ttf',
    'assets/fonts/static/Lexend-SemiBold.ttf',
  ]);
  await family('Inter', [
    'assets/fonts/static/Inter-Regular.ttf',
    'assets/fonts/static/Inter-Medium.ttf',
    'assets/fonts/static/Inter-SemiBold.ttf',
    'assets/fonts/static/Inter-Bold.ttf',
  ]);
  await family('NotoNaskhArabic', ['assets/fonts/NotoNaskhArabic.ttf']);
  await loadMaterialIcons();
}

Future<void> _pump(
  WidgetTester tester, {
  required String locale,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({'ui.locale': locale});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        appBootstrapProvider.overrideWith((ref) async {}),
      ],
      child: const MyHealthCareApp(),
    ),
  );
  await tester.pump(kSplashDuration + const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

/// The vertical scroll position of the page currently shown.
ScrollPosition _pageScroll(WidgetTester tester, String title) => tester
    .state<ScrollableState>(
      find
          .ancestor(of: find.text(title), matching: find.byType(Scrollable))
          .first,
    )
    .position;

void _expectFits(
  WidgetTester tester, {
  required String art,
  required String title,
  required String body,
  required String progress,
}) {
  const screen = Rect.fromLTWH(0, 0, 320, 568);
  final artRect = tester.getRect(find.byKey(ValueKey('onboarding-art-$art')));
  final titleRect = tester.getRect(find.text(title));
  final bodyRect = tester.getRect(find.text(body));
  final navTop = tester.getRect(find.bySemanticsLabel(progress)).top;

  expect(artRect.height, greaterThanOrEqualTo(120), reason: 'art too small');
  expect(artRect.bottom, lessThanOrEqualTo(titleRect.top), reason: title);
  expect(bodyRect.bottom, lessThanOrEqualTo(navTop), reason: 'body vs nav');
  expect(screen.contains(artRect.topLeft), isTrue);
  // No scrolling needed at the standard text size.
  expect(_pageScroll(tester, title).maxScrollExtent, 0, reason: title);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final (locale, copy) in const [('en', _en), ('ar', _ar)]) {
    testWidgets('$locale: both pages fit at 320 × 568', (tester) async {
      await _pump(tester, locale: locale);
      final c = copy;

      expect(find.text(c.title1), findsOneWidget);
      _expectFits(
        tester,
        art: _doctor,
        title: c.title1,
        body: c.body1,
        progress: c.progress1,
      );
      final skip = find.byKey(const ValueKey('onboarding-skip'));
      final next = find.byKey(const ValueKey('onboarding-next'));
      expect(find.descendant(of: skip, matching: find.text(c.skip)), findsOne);
      expect(find.descendant(of: next, matching: find.text(c.next)), findsOne);
      for (final b in [skip, next]) {
        final r = tester.getRect(b);
        expect(r.bottom, lessThanOrEqualTo(568));
        expect(r.height, greaterThanOrEqualTo(48));
      }

      // Reading order: Skip at the start, Next at the end — mirrored in
      // Arabic, with Next's arrow after its label in reading order.
      final rtl = locale == 'ar';
      final skipX = tester.getCenter(skip).dx;
      final nextX = tester.getCenter(next).dx;
      expect(rtl ? skipX > nextX : skipX < nextX, isTrue, reason: 'order');
      final label = tester.getCenter(
        find.descendant(of: next, matching: find.text(c.next)),
      );
      final arrow = tester.getCenter(
        find.descendant(of: next, matching: find.byType(Icon)),
      );
      expect(rtl ? arrow.dx < label.dx : arrow.dx > label.dx, isTrue);
      // Text starts at the reading start.
      final title = tester.getRect(find.text(c.title1));
      expect(rtl ? title.right > 280 : title.left < 40, isTrue);

      final headingTop = title.top;
      await tester.tap(next);
      await _settle(tester);

      // Page 2: same heading position, the longest paragraph clears the
      // buttons, and Back / Get started.
      expect(find.text(c.title2), findsOneWidget);
      expect(tester.getRect(find.text(c.title2)).top, headingTop);
      _expectFits(
        tester,
        art: _robot,
        title: c.title2,
        body: c.body2,
        progress: rtl ? 'الصفحة 2 من 2' : 'Page 2 of 2',
      );
      final back = find.byKey(const ValueKey('onboarding-back'));
      final done = find.byKey(const ValueKey('onboarding-get-started'));
      expect(find.descendant(of: back, matching: find.text(c.back)), findsOne);
      expect(find.descendant(of: done, matching: find.text(c.done)), findsOne);
      final backX = tester.getCenter(back).dx;
      final doneX = tester.getCenter(done).dx;
      expect(rtl ? backX > doneX : backX < doneX, isTrue, reason: 'order');

      // Back returns to the first page.
      await tester.tap(back);
      await _settle(tester);
      expect(find.text(c.title1), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$locale: large text scrolls, buttons stay reachable', (
      tester,
    ) async {
      await _pump(tester, locale: locale, textScale: 2);
      final c = copy;
      final next = find.byKey(const ValueKey('onboarding-next'));
      expect(tester.getRect(next).bottom, lessThanOrEqualTo(568));
      expect(_pageScroll(tester, c.title1).maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);

      await tester.tap(next);
      await _settle(tester);
      final done = find.byKey(const ValueKey('onboarding-get-started'));
      expect(tester.getRect(done).bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }
}
