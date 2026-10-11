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

import 'package:myhealthcare/features/care/application/care_providers.dart';

import '../support/fonts.dart';
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

/// Every patient page in the redesign audit (signed in as a seeded patient).
const auditRoutes = <(String, String)>[
  ('/patient/timeline', 'records'),
  ('/patient/timeline?view=medications', 'medications'),
  ('/patient/timeline/documents', 'documents'),
  ('/patient/timeline/allergies', 'allergies'),
  ('/patient/timeline/imaging', 'imaging'),
  ('/patient/timeline/sick-leave', 'sick_leave'),
  ('/patient/home/vitals', 'vitals'),
  ('/patient/settings/health', 'health_details'),
  ('/patient/summary', 'summary'),
  ('/patient/home/messages', 'messages'),
  ('/patient/home/notifications', 'notifications'),
  ('/patient/nutrition', 'nutrition'),
  ('/patient/settings', 'profile'),
  ('/patient/settings/personal', 'personal'),
  ('/patient/settings/family', 'family'),
  ('/patient/home/billing', 'billing'),
  ('/patient/home/home-visit', 'home_visit'),
  ('/patient/appointments', 'appointments'),
];

void main() {
  final skip = _dir == null;

  testWidgets('capture patient page audit', skip: skip, (tester) async {
    await _loadFonts();
    final theme = Platform.environment['CAPTURE_THEME'] ?? 'light';
    final locale = Platform.environment['CAPTURE_LOCALE'] ?? 'en';
    final c = await _app(
      tester,
      email: 'patient3@myhealth.demo',
      theme: theme,
      locale: locale,
    );
    for (final (route, name) in auditRoutes) {
      _go(c, route);
      await _settle(tester);
      await _shot(tester, '${name}_${theme}_$locale');
    }
    // A record detail and a message thread.
    final records = await c
        .read(recordRepositoryProvider)
        .timeline(c.read(currentUserProvider)!.id, limit: 1);
    if (records.valueOrNull?.isNotEmpty ?? false) {
      _go(c, AppRoutes.patientRecord(records.valueOrNull!.first.id));
      await _settle(tester);
      await _shot(tester, 'record_detail_${theme}_$locale');
    }
    // A conversation thread (synthetic test message).
    final me = c.read(currentUserProvider)!.id;
    final doctors = await c.read(messageableDoctorsProvider.future);
    if (doctors.isNotEmpty) {
      await c
          .read(careMessageRepositoryProvider)
          .send(
            patientId: me,
            staffId: doctors.first.id,
            fromStaff: false,
            body: 'Synthetic test message: when should I repeat my blood test?',
          );
      _go(c, '/patient/home/messages/${doctors.first.id}');
      await _settle(tester);
      await _shot(tester, 'thread_${theme}_$locale');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
