import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';

import '../support/sessions.dart';

const _routes = <String, List<String>>{
  'auth': ['/login', '/register', '/forgot-password'],
  'patient': [
    '/patient/home',
    '/patient/timeline',
    '/patient/home/vitals',
    '/patient/home/billing',
    '/patient/home/notifications',
    '/patient/appointments',
    '/patient/appointments/book',
    '/patient/summary',
    '/patient/settings',
    '/patient/settings/personal',
    '/patient/settings/health',
    '/patient/settings/preferences',
    '/patient/settings/family',
    '/patient/timeline?view=medications',
    '/patient/nutrition',
    '/patient/timeline/imaging',
    '/patient/timeline/allergies',
    '/patient/timeline/sick-leave',
    '/patient/appointments/doctors',
    '/patient/home/messages',
    '/patient/home/home-visit',
  ],
  'staff': [
    '/staff/dashboard',
    '/staff/patients',
    '/staff/tasks',
    '/staff/schedule',
    '/staff/scribe',
    '/staff/dashboard/notifications',
    '/staff/profile',
    '/staff/dashboard/inbox',
    '/staff/profile/account',
    '/staff/profile/activity',
    '/staff/profile/directory',
    '/staff/profile/analytics',
    '/staff/profile/preferences',
  ],
  'admin': [
    '/admin/work',
    '/admin/clinic',
    '/admin/clinic/schedules',
    '/admin/documents',
    '/admin/documents/registry',
    '/admin/reports',
    '/admin/reports/operations',
    '/admin/settings',
    '/admin/settings/clinic',
    '/admin/settings/integrations',
    '/admin/settings/backup',
    '/admin/billing/exceptions',
    '/admin/dashboard',
    '/admin/users',
    '/admin/departments',
    '/admin/billing',
    '/admin/profile',
    '/admin/appointments',
    '/admin/feedback',
    '/admin/dashboard/home-visits',
    '/admin/dashboard/referral-requests',
    '/admin/dashboard/work',
    '/admin/dashboard/notifications',
    '/admin/profile/account',
    '/admin/profile/audit',
    '/admin/profile/analytics',
    '/admin/profile/forecast',
    '/admin/profile/ai',
    '/admin/profile/ai-log',
    '/admin/profile/preferences',
    '/admin/profile/clinic-hours',
  ],
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

List<String> _brokenWords(WidgetTester tester) {
  final broken = <String>{};
  final viewport = Offset.zero & tester.view.physicalSize;
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph || !render.hasSize || !render.attached)
      continue;
    final bounds = render.localToGlobal(Offset.zero) & render.size;
    if (!bounds.overlaps(viewport)) continue;
    final text = render.text.toPlainText();
    for (final token in RegExp(
      r'[A-Za-z]{5,}|[\u0620-\u064a]{4,}',
    ).allMatches(text)) {
      final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: token.start, extentOffset: token.end),
      );
      if (boxes.length < 2) continue;
      final top = boxes.map((b) => b.top).reduce((a, b) => a < b ? a : b);
      final bottom = boxes.map((b) => b.top).reduce((a, b) => a > b ? a : b);
      if (bottom - top > 5)
        broken.add('${token[0]} in "${text.replaceAll('\n', ' ')}"');
    }
  }
  return broken.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, path) in const [
      ('Inter', 'assets/fonts/static/Inter-Regular.ttf'),
      ('Inter', 'assets/fonts/static/Inter-SemiBold.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-Medium.ttf'),
      ('Lexend', 'assets/fonts/static/Lexend-SemiBold.ttf'),
      ('NotoNaskhArabic', 'assets/fonts/NotoNaskhArabic.ttf'),
    ]) {
      final bytes = await File(path).readAsBytes();
      await ui.loadFontFromList(bytes, fontFamily: family);
    }
  });
  for (final role in _routes.keys) {
    for (final language in ['en', 'ar']) {
      for (final deviceScale in [1.0, 2.0, 3.0]) {
        testWidgets(
          '$role routes at 320px in $language with OS $deviceScale and max app text',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final (container, _) = await seededContainer(
              prefs: {
                'ui.hasSeenOnboarding': true,
                'ui.textScale': 'xLarge',
                'ui.locale': language,
              },
            );
            if (role != 'auth') {
              await signInAs(container, switch (role) {
                'patient' => 'patient1@myhealth.demo',
                'staff' => 'staff1@myhealth.demo',
                _ => 'admin@myhealth.demo',
              });
            }
            final problems = <String>[];
            var route = 'initial';
            final previous = FlutterError.onError;
            FlutterError.onError = (details) {
              final diagnostic =
                  Platform.environment['MYHEALTH_UI_DIAGNOSTICS'];
              if (diagnostic != null)
                File(diagnostic).writeAsStringSync(
                  '$route\n${details.toString()}\n',
                  mode: FileMode.append,
                );
              problems.add(
                '$route: ${details.exceptionAsString().split('\n').first}',
              );
            };
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: TextScaler.linear(deviceScale)),
                child: UncontrolledProviderScope(
                  container: container,
                  child: const MyHealthCareApp(),
                ),
              ),
            );
            await _settle(tester);
            final router = container.read(routerProvider);
            for (final location in _routes[role]!) {
              route = location;
              router.go(location);
              await _settle(tester);
              final words = _brokenWords(tester);
              if (words.isNotEmpty) problems.add('$route: split words $words');
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
            FlutterError.onError = previous;
            expect(problems, isEmpty, reason: problems.join('\n'));
          },
        );
      }
    }
  }
}
