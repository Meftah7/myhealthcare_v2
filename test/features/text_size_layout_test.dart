import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/presentation/app_scaffold.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/fonts.dart';
import '../support/navigation.dart';
import '../support/sessions.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['TEXT_SIZE_CAPTURE_DIR'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('text-size-capture')),
  );
  await tester.runAsync(() async {
    final shot = await boundary.toImage();
    final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
    File('$directory/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    shot.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final (family, path) in const [
      ('Inter', 'assets/fonts/static/Inter-Regular.ttf'),
      ('Inter', 'assets/fonts/static/Inter-Medium.ttf'),
      ('Inter', 'assets/fonts/static/Inter-SemiBold.ttf'),
      ('Inter', 'assets/fonts/static/Inter-Bold.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-Medium.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-SemiBold.ttf'),
      ('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf'),
    ]) {
      await ui.loadFontFromList(
        await File(path).readAsBytes(),
        fontFamily: family,
      );
    }
    await loadMaterialIcons();
  });
  testWidgets(
    'drawer back, resize and short sidebar preserve the content tree',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 1024);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final (container, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
      );
      await signInAs(container, 'patient1@myhealth.demo');
      Future<void> mount() => tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyHealthCareApp(),
        ),
      );
      await mount();
      container.read(routerProvider).go('/patient/home');
      await settle(tester);
      final content = tester.element(find.byType(ScrollToTopSignal));
      const draft = BookingRequestDraft(reason: 'Preserve this draft');
      container.read(bookingDraftProvider.notifier).state = draft;
      await tester.tap(find.byKey(const ValueKey('patient-rail-account')));
      await settle(tester);
      expect(tester.element(find.byType(ScrollToTopSignal)), same(content));
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(Drawer), findsNothing);
      await tester.tap(find.byKey(const ValueKey('patient-rail-account')));
      await settle(tester);
      tester.view.physicalSize = const Size(1100, 420);
      await mount();
      await settle(tester);
      expect(find.byType(Drawer), findsNothing);
      expect(tester.element(find.byType(ScrollToTopSignal)), same(content));
      await openDrawerItem(tester, 'sign-out');
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/patient/home',
      );
      expect(tester.takeException(), isNull);
      expect(container.read(bookingDraftProvider), same(draft));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  testWidgets('resizing preserves Home scroll offset and selected route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final (container, _) = await seededContainer(
      prefs: {'ui.hasSeenOnboarding': true},
    );
    await signInAs(container, 'patient1@myhealth.demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyHealthCareApp(),
      ),
    );
    final router = container.read(routerProvider);
    router.go('/patient/home');
    await settle(tester);
    ScrollableState scroll() => tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ScrollToTopSignal),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    scroll().position.jumpTo(160);
    await settle(tester);
    for (final size in const [
      Size(768, 1024),
      Size(1366, 768),
      Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await settle(tester);
      expect(router.routeInformationProvider.value.uri.path, '/patient/home');
      expect(scroll().position.pixels, closeTo(160, 1));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
    'keyboard opens rail accounts and Escape restores trigger focus',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 1024);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final (container, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
      );
      await signInAs(container, 'patient1@myhealth.demo');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyHealthCareApp(),
        ),
      );
      container.read(routerProvider).go('/patient/home');
      await settle(tester);
      final trigger = tester.element(
        find.byKey(const ValueKey('patient-rail-account')),
      );
      bool triggerHasFocus() {
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused is! Element) return false;
        var found = identical(focused, trigger);
        focused.visitAncestorElements((parent) {
          found = found || identical(parent, trigger);
          return !found;
        });
        return found;
      }

      for (var i = 0; i < 120 && !triggerHasFocus(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        triggerHasFocus(),
        isTrue,
        reason: 'Account control is reachable by Tab',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.byType(Drawer), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.byType(Drawer), findsNothing);
      expect(
        triggerHasFocus(),
        isTrue,
        reason: 'Dismissal restores focus to Account & preferences',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  for (final language in ['en', 'ar']) {
    for (final theme in ['light', 'dark']) {
      for (final level in TextScaleLevel.options) {
        testWidgets(
          '$language $theme ${level.label}: adaptive layouts and preferences',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(390, 844);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            final (container, _) = await seededContainer(
              prefs: {
                'ui.hasSeenOnboarding': true,
                'ui.locale': language,
                'ui.themeMode': theme,
                'ui.textScale': level.name,
              },
            );
            await signInAs(container, 'patient1@myhealth.demo');
            Future<void> mount(double systemScale) => tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: TextScaler.linear(systemScale)),
                child: UncontrolledProviderScope(
                  container: container,
                  child: const RepaintBoundary(
                    key: ValueKey('text-size-capture'),
                    child: MyHealthCareApp(),
                  ),
                ),
              ),
            );
            final router = container.read(routerProvider);
            final t = lookupAppLocalizations(Locale(language));
            for (final size in const [
              Size(360, 800),
              Size(390, 844),
              Size(599, 844),
              Size(600, 844),
              Size(768, 1024),
              Size(1023, 768),
              Size(1024, 768),
              Size(1366, 768),
              Size(1920, 1080),
              Size(1100, 420),
            ]) {
              tester.view.physicalSize = size;
              await mount(1);
              router.go('/patient/home');
              await settle(tester);
              expect(tester.takeException(), isNull, reason: 'Home at $size');
              if (level == TextScaleLevel.small &&
                  [390, 768, 1366].contains(size.width)) {
                await capture(
                  tester,
                  'home_${size.width.toInt()}_${language}_${theme}_default',
                );
              }
              expect(
                find.byType(NavigationRail),
                size.width >= 600 && size.width < 1024
                    ? findsOneWidget
                    : findsNothing,
              );
              if (size.width >= 1024) {
                expect(find.byType(Drawer), findsNothing);
                expect(find.byIcon(Icons.menu), findsNothing);
                expect(
                  find.byKey(const ValueKey('drawer-preferences')),
                  findsOneWidget,
                );
              } else {
                final menu = size.width < 600
                    ? find.byType(ShellMenuButton).first
                    : find.byKey(const ValueKey('patient-rail-account'));
                await tester.tap(menu);
                await settle(tester);
                expect(find.byType(Drawer), findsOneWidget);
                expect(
                  tester.takeException(),
                  isNull,
                  reason: 'Drawer at $size',
                );
                Navigator.of(tester.element(find.byType(Drawer))).pop();
                await settle(tester);
              }
              router.go('/patient/settings/preferences');
              await settle(tester);
              final slider = find.byType(Slider);
              await tester.ensureVisible(slider);
              final control = tester.widget<Slider>(slider);
              expect(control.divisions, 2);
              expect(control.semanticFormatterCallback!(0), t.textScaleSmall);
              expect(control.semanticFormatterCallback!(1), t.textScaleDefault);
              expect(control.semanticFormatterCallback!(2), t.textScaleLarge);
              expect(
                MediaQuery.textScalerOf(tester.element(slider)).scale(16),
                closeTo(16 * level.factor, .001),
              );
              expect(
                tester.takeException(),
                isNull,
                reason: 'Preferences at $size',
              );
              if (size.width == 390) {
                await capture(
                  tester,
                  'preferences_390_${language}_${theme}_${level.label.toLowerCase()}',
                );
              }
              router.go('/patient/services');
              await settle(tester);
              expect(
                tester.takeException(),
                isNull,
                reason: 'Services at $size',
              );
              for (final element in find.byType(RichText).evaluate()) {
                final paragraph = element.renderObject;
                if (paragraph is RenderParagraph &&
                    paragraph.text.toPlainText() == t.paFutureWork) {
                  expect(
                    paragraph.didExceedMaxLines,
                    isFalse,
                    reason: 'Visible Future work label at $size',
                  );
                }
              }
              expect(find.text(t.paFutureWork), findsWidgets);
              if ([390, 768, 1366].contains(size.width)) {
                if (level == TextScaleLevel.small) {
                  await capture(
                    tester,
                    'services_${size.width.toInt()}_${language}_${theme}_default',
                  );
                }
                if (language == 'en' &&
                    theme == 'light' &&
                    level == TextScaleLevel.medium) {
                  await capture(tester, 'services_${size.width.toInt()}');
                }
              }
            }
            // Resizing and OS scaling preserve the route and app preference.
            tester.view.physicalSize = const Size(390, 844);
            await mount(2);
            router.go('/patient/settings/preferences');
            await settle(tester);
            await tester.ensureVisible(find.byType(Slider));
            expect(
              MediaQuery.textScalerOf(
                tester.element(find.byType(Slider)),
              ).scale(16),
              closeTo(32 * level.factor, .001),
            );
            final shellContent = tester.element(find.byType(ScrollToTopSignal));
            tester.view.physicalSize = const Size(768, 1024);
            await mount(2);
            await settle(tester);
            expect(tester.takeException(), isNull);
            tester.view.physicalSize = const Size(1366, 768);
            await mount(2);
            await settle(tester);
            expect(
              router.routeInformationProvider.value.uri.path,
              '/patient/settings/preferences',
            );
            expect(container.read(textScaleProvider), level);
            expect(
              tester.element(find.byType(ScrollToTopSignal)),
              same(shellContent),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
          },
        );
      }
    }
  }
}
