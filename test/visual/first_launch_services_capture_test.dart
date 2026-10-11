// Real Flutter renders of the first-launch onboarding, the slow-start splash
// and the service detail pages, with the bundled fonts. Writes PNGs only when
// CAPTURE_DIR is set; otherwise skipped.
//
//   CAPTURE_DIR=docs/rebuild_screenshots/first_launch_services \
//     flutter test test/visual/first_launch_services_capture_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/presentation/splash_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';
import '../support/mfa.dart';
import '../support/test_database.dart';

final _dir = Platform.environment['CAPTURE_DIR'];

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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  late final ui.Image image;
  await tester.runAsync(() async => image = await boundary.toImage());
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$_dir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

Widget _host(Widget app) =>
    RepaintBoundary(key: const ValueKey('capture'), child: app);

const _variants = [
  ('phone_en_light', Size(390, 844), 'en', 'light', 'small'),
  ('phone_ar_dark_large', Size(360, 640), 'ar', 'dark', 'medium'),
  ('desktop_en_light', Size(1366, 768), 'en', 'light', 'small'),
];

void main() {
  for (final (tag, size, locale, theme, text) in _variants) {
    testWidgets('capture first launch + services: $tag', skip: _dir == null, (
      tester,
    ) async {
      await _loadFonts();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final prefs = {
        'ui.locale': locale,
        'ui.themeMode': theme,
        'ui.textScale': text,
      };

      // Slow-start splash.
      SharedPreferences.setMockInitialValues(prefs);
      var sp = await SharedPreferences.getInstance();
      final never = Completer<void>();
      await tester.pumpWidget(
        _host(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(sp),
              appBootstrapProvider.overrideWith((ref) => never.future),
            ],
            child: const MyHealthCareApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await _shot(tester, '${tag}_splash_loading');
      await tester.pump(kSplashSlowAfter);
      await _shot(tester, '${tag}_splash_slow');
      await tester.pumpWidget(const SizedBox());

      // Onboarding over a seeded app, then sign-in and service details.
      final db = newTestDatabase();
      await Seeder(db).run();
      SharedPreferences.setMockInitialValues(prefs);
      sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _host(
          UncontrolledProviderScope(
            container: c,
            child: const MyHealthCareApp(),
          ),
        ),
      );
      await _settle(tester);
      await _shot(tester, '${tag}_onboarding_1');
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await _settle(tester);
      await _shot(tester, '${tag}_onboarding_2');
      await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
      await _settle(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'patient1@myhealth.demo');
      await tester.enterText(fields.at(1), Seeder.demoPassword);
      final submit = find.byType(FilledButton).first;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await passMfa(tester);
      await _settle(tester);

      for (final id in [
        'blood-donation',
        'e-referral',
        'complete-checkup',
        'water-tracking',
        'health-trackers',
        'wearables',
      ]) {
        c.read(routerProvider).go(AppRoutes.patientServiceDetail(id));
        await _settle(tester);
        await _shot(tester, '${tag}_service_$id');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
