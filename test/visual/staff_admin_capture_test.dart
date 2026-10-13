// Real Flutter renders of the redesigned staff and admin Today screens, the
// role workspaces and the existing schedule, with bundled fonts. Writes PNGs
// only when CAPTURE_DIR is set; otherwise skipped.
//
//   CAPTURE_DIR=docs/rebuild_screenshots/staff_admin \
//     flutter test test/visual/staff_admin_capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/admin/presentation/admin_clinic_documents.dart';
import 'package:myhealthcare/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:myhealthcare/features/admin/presentation/admin_finance_report.dart';
import 'package:myhealthcare/features/admin/presentation/departments_screen.dart';
import 'package:myhealthcare/features/admin/presentation/system_analytics_screen.dart';
import 'package:myhealthcare/features/shared/presentation/shared_workspace_app.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_dashboard_screen.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_schedule_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

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
  const shots = [
    ('doctor_today', 'staff1@myhealth.demo', 'today'),
    ('nurse_today', 'nurse@myhealth.demo', 'today'),
    ('dentist_today', 'dentist@myhealth.demo', 'today'),
    ('reception_today', 'reception@myhealth.demo', 'today'),
    ('pharmacy_today', 'pharmacy@myhealth.demo', 'today'),
    ('admin_overview', 'admin@myhealth.demo', 'admin'),
    ('admin_documents', 'admin@myhealth.demo', 'documents'),
    ('admin_finance', 'admin@myhealth.demo', 'finance'),
    ('admin_departments', 'admin@myhealth.demo', 'departments'),
    ('admin_form_dialog', 'admin@myhealth.demo', 'dialog'),
    ('admin_charts', 'admin@myhealth.demo', 'charts'),
    ('shared_login', 'staff1@myhealth.demo', 'shared'),
    ('schedule_day', 'staff1@myhealth.demo', 'day'),
    ('schedule_month', 'staff1@myhealth.demo', 'month'),
    ('schedule_year', 'staff1@myhealth.demo', 'year'),
  ];
  const sizes = [
    ('phone', Size(390, 844), 'en', ThemeMode.light),
    ('phone_ar_dark', Size(390, 844), 'ar', ThemeMode.dark),
    ('phone_dark', Size(390, 844), 'en', ThemeMode.dark),
    ('tablet_ar', Size(800, 1000), 'ar', ThemeMode.light),
    ('tablet_dark', Size(800, 1000), 'en', ThemeMode.dark),
    ('desktop', Size(1440, 900), 'en', ThemeMode.light),
    ('desktop_ar_dark', Size(1440, 900), 'ar', ThemeMode.dark),
  ];

  for (final (name, email, screen) in shots) {
    for (final (tag, size, lang, mode) in sizes) {
      testWidgets(
        '$name $tag',
        skip: _dir == null,
        tags:
            [
              'year',
              'month',
              'day',
              'shared',
              'dialog',
              'charts',
            ].contains(screen)
            ? ['final-colours']
            : null,
        (tester) async {
          await tester.runAsync(_loadFonts);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final (c, _) = await seededContainer();
          await signInAs(c, email);
          if (['year', 'month', 'day'].contains(screen)) {
            c.read(scheduleViewProvider.notifier).state = switch (screen) {
              'year' => ScheduleView.year,
              'month' => ScheduleView.month,
              _ => ScheduleView.day,
            };
          }
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('capture'),
              child: UncontrolledProviderScope(
                container: c,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: mode,
                  locale: Locale(lang),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: switch (screen) {
                    'today' => const StaffDashboardScreen(),
                    'admin' => const AdminDashboardScreen(),
                    'documents' => const AdminDocumentRegistryScreen(),
                    'finance' => const AdminFinanceReportScreen(),
                    'departments' => const DepartmentsScreen(),
                    'dialog' => const DepartmentsScreen(),
                    'charts' => const SystemAnalyticsScreen(),
                    'shared' => SharedWorkspaceApp(
                      origin: 'http://localhost:8787',
                      themeMode: mode,
                    ),
                    _ => const StaffScheduleScreen(),
                  },
                ),
              ),
            ),
          );
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 80));
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await tester.pump();
          if (screen == 'shared' && lang == 'ar') {
            await tester.tap(find.byIcon(Icons.language));
            await tester.pumpAndSettle();
          }
          if (screen == 'dialog') {
            await tester.tap(find.byType(FloatingActionButton));
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')),
          );
          late final ui.Image image;
          await tester.runAsync(() async => image = await boundary.toImage());
          final bytes = await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          );
          File('$_dir/${name}_$tag.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }
}
