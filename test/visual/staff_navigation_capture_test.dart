// Same-size renders of the real app after sign-in — patient, reception and
// pharmacy — so the bottom bars can be compared directly, plus each staff
// tab, Arabic, the largest text setting and the laptop sidebar. Writes PNGs
// only when CAPTURE_DIR is set; otherwise skipped.
//
//   CAPTURE_DIR=docs/rebuild_screenshots/staff_navigation \
//     flutter test test/visual/staff_navigation_capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';

import '../support/fonts.dart';
import '../support/sessions.dart';

const _captureDefine = String.fromEnvironment('CAPTURE_DIR');
final _dir =
    Platform.environment['CAPTURE_DIR'] ??
    (_captureDefine.isEmpty ? null : _captureDefine);

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

void main() {
  const phone = Size(390, 844);
  final shots = <(String, String, String, Size, String, String)>[
    // name, account, route, size, locale, text size
    ('1_patient_home', 'patient1', AppRoutes.patientHome, phone, 'en', 'small'),
    (
      '2_reception_home',
      'reception',
      AppRoutes.staffDashboard,
      phone,
      'en',
      'small',
    ),
    (
      '3_pharmacy_home',
      'pharmacy',
      AppRoutes.staffDashboard,
      phone,
      'en',
      'small',
    ),
    ('4_doctor_home', 'staff1', AppRoutes.staffDashboard, phone, 'en', 'small'),
    ('5_nurse_home', 'nurse', AppRoutes.staffDashboard, phone, 'en', 'small'),
    for (final (tab, route) in [
      ('schedule', AppRoutes.staffSchedule),
      ('patients', AppRoutes.staffPatients),
      ('chat', AppRoutes.staffChat),
      ('settings', AppRoutes.staffProfile),
    ]) ...[
      ('reception_$tab', 'reception', route, phone, 'en', 'small'),
      ('pharmacy_$tab', 'pharmacy', route, phone, 'en', 'small'),
      ('doctor_$tab', 'staff1', route, phone, 'en', 'small'),
    ],
    (
      'reception_home_ar',
      'reception',
      AppRoutes.staffDashboard,
      phone,
      'ar',
      'small',
    ),
    (
      'pharmacy_home_ar',
      'pharmacy',
      AppRoutes.staffDashboard,
      phone,
      'ar',
      'small',
    ),
    (
      'reception_home_large_text',
      'reception',
      AppRoutes.staffDashboard,
      phone,
      'en',
      'medium',
    ),
    (
      'reception_home_small_text',
      'reception',
      AppRoutes.staffDashboard,
      phone,
      'en',
      'xSmall',
    ),
    (
      'reception_tablet',
      'reception',
      AppRoutes.staffDashboard,
      const Size(800, 1000),
      'en',
      'small',
    ),
    (
      'reception_laptop',
      'reception',
      AppRoutes.staffDashboard,
      const Size(1366, 860),
      'en',
      'small',
    ),
    (
      'patient_laptop',
      'patient1',
      AppRoutes.patientHome,
      const Size(1366, 860),
      'en',
      'small',
    ),
  ];

  for (final (name, account, route, size, locale, textScale) in shots) {
    testWidgets(name, skip: _dir == null, (tester) async {
      await tester.runAsync(_loadFonts);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, _) = await seededContainer(
        prefs: {
          'ui.hasSeenOnboarding': true,
          'ui.locale': locale,
          'ui.textScale': textScale,
          'ui.themeMode': 'light',
        },
      );
      await signInAs(c, '$account@myhealth.demo');
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: UncontrolledProviderScope(
            container: c,
            child: const MyHealthCareApp(),
          ),
        ),
      );
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      c.read(routerProvider).go(route);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      late final ui.Image image;
      await tester.runAsync(
        () async => image = await boundary.toImage(pixelRatio: 2),
      );
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      File('$_dir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
