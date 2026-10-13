// Patient re-check: every main patient section at 320, 768 and 1024 dp with
// the Small, Default and Large text preferences renders without a layout
// exception. Set CAPTURE_DIR to also write a PNG of each.
//
//   CAPTURE_DIR=docs/rebuild_screenshots/patient_widths \
//     flutter test test/visual/patient_widths_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';

import '../support/fonts.dart';
import '../support/sessions.dart';

final _dir = Platform.environment['CAPTURE_DIR'];

const _routes = {
  'home': AppRoutes.patientHome,
  'records': AppRoutes.patientTimeline,
  'appointments': AppRoutes.patientAppointments,
  'book': AppRoutes.patientBookLanding,
  'messages': AppRoutes.patientMessages,
  'services': AppRoutes.patientServices,
  'calculators': AppRoutes.patientCalculators,
  'converters': AppRoutes.patientConverters,
  'emergency': AppRoutes.patientEmergency,
  'documents': AppRoutes.patientDocuments,
  'settings': AppRoutes.patientSettings,
};

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

  for (final width in const [320.0, 768.0, 1024.0]) {
    for (final level in TextScaleLevel.options) {
      testWidgets('patient sections at ${width.toInt()} dp, ${level.label}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, width < 600 ? 780 : 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final (c, _) = await seededContainer(
          prefs: {'ui.hasSeenOnboarding': true, 'ui.textScale': level.name},
        );
        await signInAs(c, 'patient1@myhealth.demo');
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: UncontrolledProviderScope(
              container: c,
              child: const MyHealthCareApp(),
            ),
          ),
        );
        final problems = <String>[];
        for (final MapEntry(key: name, value: route) in _routes.entries) {
          c.read(routerProvider).go(route);
          for (var i = 0; i < 16; i++) {
            await tester.pump(const Duration(milliseconds: 80));
          }
          final error = tester.takeException();
          if (error != null) problems.add('$name: $error');
          if (_dir != null) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                  '$_dir/${name}_${width.toInt()}_${level.label.toLowerCase()}.png',
                )
                ..createSync(recursive: true)
                ..writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
