// Visual capture of the Care Navigator launcher on the patient dashboard — the
// floating mascot button, the head docked on the right and on the left, and a
// frame of the dock slide — with the real fonts and artwork, on a phone-sized
// view with notch and home-indicator insets. Writes PNGs only when the
// CAPTURE_DIR environment variable is set; otherwise skipped.
//
//   CAPTURE_DIR=/tmp/shots flutter test test/visual/care_navigator_launcher_capture_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/ai_chat/application/care_navigator.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';
import '../support/test_database.dart';

final _dir = Platform.environment['CAPTURE_DIR'];
const _dpr = 3.0;

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

/// Pumps frames, letting real asset loads and image decodes finish between.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _dpr);
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  File('$_dir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('capture the launcher states', skip: _dir == null, (
    tester,
  ) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390 * _dpr, 844 * _dpr);
    tester.view.devicePixelRatio = _dpr;
    tester.view.padding = const FakeViewPadding(
      top: 47 * _dpr,
      bottom: 34 * _dpr,
    );
    addTearDown(tester.view.reset);

    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(c.dispose);
    await c
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: UncontrolledProviderScope(
          container: c,
          child: const MyHealthCareApp(),
        ),
      ),
    );
    await _settle(tester);

    const fab = ValueKey('care-nav-fab');
    const dock = ValueKey('care-nav-dock');
    const head = ValueKey('care-nav-head');

    await _shot(tester, 'launcher_1_floating_right');

    // Scrolled to the end: the last row of the dashboard clears the button.
    final page = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .map((s) => s.position)
        .where((p) => p.axis == Axis.vertical)
        .reduce((a, b) => a.maxScrollExtent >= b.maxScrollExtent ? a : b);
    // The list builds lazily, so its extent grows as it is scrolled.
    for (var i = 0; i < 10 && page.pixels < page.maxScrollExtent; i++) {
      page.jumpTo(page.maxScrollExtent);
      await tester.pump();
    }
    await _settle(tester);
    await _shot(tester, 'launcher_1b_floating_right_scrolled_end');
    page.jumpTo(0);
    await _settle(tester);

    // Mid-slide frame of docking, then the docked head on the right.
    await tester.tap(find.byKey(dock));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _shot(tester, 'launcher_2_docking_midway');
    await _settle(tester);
    await _shot(tester, 'launcher_3_docked_right');

    // Drag the head across: docks on the left.
    await tester.drag(find.byKey(head), const Offset(-300, 0));
    await _settle(tester);
    await _shot(tester, 'launcher_4_docked_left');

    // Restore from the left: the button comes back on the left.
    await tester.tap(find.byKey(head));
    await _settle(tester);
    await _shot(tester, 'launcher_5_floating_left');

    // Chat opens from the button.
    await tester.tap(find.byKey(fab));
    await _settle(tester);
    await _shot(tester, 'launcher_6_chat_open');
    await c.read(localeProvider.notifier).set(const Locale('ar'));
    await _settle(tester);
    await _shot(tester, 'launcher_6b_chat_open_ar');
    await c.read(localeProvider.notifier).set(const Locale('en'));
    await _settle(tester);
    c.read(careNavigatorViewProvider.notifier).state = CareNavView.fab;
    await _settle(tester);

    // Dark theme, floating and docked.
    await c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await _settle(tester);
    await tester.drag(find.byKey(fab), const Offset(400, 0));
    await _settle(tester);
    await _shot(tester, 'launcher_7_floating_right_dark');
    await tester.tap(find.byKey(dock));
    await _settle(tester);
    await _shot(tester, 'launcher_8_docked_right_dark');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
