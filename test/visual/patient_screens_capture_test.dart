// Visual capture of the rebuilt patient screens with the real fonts, for
// comparing against the approved blue design. Writes PNGs only when the
// CAPTURE_DIR environment variable is set; otherwise skipped.
//
//   CAPTURE_DIR=/tmp/shots flutter test test/visual/patient_screens_capture_test.dart

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
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  late final ui.Image image;
  await tester.runAsync(() async {
    image = await boundary.toImage();
  });
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$_dir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<ProviderContainer> _app(
  WidgetTester tester, {
  String? email,
  String theme = 'light',
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(390, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({
    'ui.hasSeenOnboarding': true,
    'ui.themeMode': theme,
    'ui.locale': locale,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  addTearDown(container.dispose);
  if (email != null) {
    await container
        .read(sessionProvider.notifier)
        .login(email: email, password: Seeder.demoPassword);
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('capture'),
      child: UncontrolledProviderScope(
        container: container,
        child: const MyHealthCareApp(),
      ),
    ),
  );
  await _settle(tester);
  return container;
}

void _go(ProviderContainer c, String route) => c.read(routerProvider).go(route);

void main() {
  final skip = _dir == null;

  testWidgets('capture patient screens', skip: skip, (tester) async {
    await _loadFonts();

    // Guest.
    var c = await _app(tester);
    _go(c, AppRoutes.patientHome);
    await _settle(tester);
    await _shot(tester, 'guest_home_light');
    _go(c, AppRoutes.patientServices);
    await _settle(tester);
    await _shot(tester, 'services_light');
    _go(c, AppRoutes.patientBookLanding);
    await _settle(tester);
    await _shot(tester, 'book_landing_light');
    _go(c, '${AppRoutes.patientBookLanding}?mode=virtual');
    await _settle(tester);
    await _shot(tester, 'virtual_care_light');
    _go(c, AppRoutes.patientFindDoctor);
    await _settle(tester);
    await _shot(tester, 'find_doctor_light');
    _go(c, AppRoutes.login);
    await _settle(tester);
    await _shot(tester, 'login_light');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));

    // Signed-in patient, light and dark, English and Arabic.
    for (final (theme, locale) in const [
      ('light', 'en'),
      ('dark', 'en'),
      ('light', 'ar'),
    ]) {
      c = await _app(
        tester,
        email: 'patient3@myhealth.demo',
        theme: theme,
        locale: locale,
      );
      _go(c, AppRoutes.patientHome);
      await _settle(tester);
      await _shot(tester, 'patient_home_${theme}_$locale');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await _settle(tester);
      await _shot(tester, 'patient_home_quick_access_${theme}_$locale');
      _go(c, AppRoutes.patientTimeline);
      await _settle(tester);
      await _shot(tester, 'records_${theme}_$locale');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
