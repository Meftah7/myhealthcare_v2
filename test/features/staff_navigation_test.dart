// Every staff role signs in to the same five tabs — Home, Schedule, Patients,
// Chat, Settings — on the patient bar, each one tap away (the old reception /
// pharmacy "Today ⇕" destination selector is gone).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/shell/app_shell.dart';
import 'package:myhealthcare/core/ui/patient/patient_bottom_navigation.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_navigation.dart';

import '../support/sessions.dart';

const _tabs = ['Home', 'Schedule', 'Patients', 'Chat', 'Settings'];
const _roots = [
  AppRoutes.staffDashboard,
  AppRoutes.staffSchedule,
  AppRoutes.staffPatients,
  AppRoutes.staffChat,
  AppRoutes.staffProfile,
];

Future<void> _settle(WidgetTester tester, [int frames = 16]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  String email, {
  Size size = const Size(390, 844),
  String locale = 'en',
  String textScale = 'small',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final (c, _) = await seededContainer(
    prefs: {
      'ui.hasSeenOnboarding': true,
      'ui.locale': locale,
      'ui.textScale': textScale,
    },
  );
  await signInAs(c, email);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
  );
  await _settle(tester, 24);
  return c;
}

/// The labels the bar renders, in visual order.
List<String> _barLabels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(PatientBottomNavigation),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data ?? '')
    .toList();

/// The destination the bar marks as selected (its Semantics `selected`).
String? _selected(WidgetTester tester) {
  for (final s in tester.widgetList<Semantics>(
    find.descendant(
      of: find.byType(PatientBottomNavigation),
      matching: find.byType(Semantics),
    ),
  )) {
    if (s.properties.selected == true) return s.properties.label;
  }
  return null;
}

String _path(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final account in ['reception', 'pharmacy', 'staff1', 'nurse']) {
    testWidgets('$account: five patient-style tabs, each one tap away', (
      tester,
    ) async {
      final c = await _pumpApp(tester, '$account@myhealth.demo');

      // Immediately after sign-in: the patient bar, five labels, no selector.
      expect(_path(c), AppRoutes.staffDashboard);
      expect(find.byType(PatientBottomNavigation), findsOneWidget);
      expect(find.byType(CompactNavigation), findsNothing);
      expect(find.byIcon(Icons.unfold_more), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(StaffSidebar), findsNothing);
      expect(_barLabels(tester), _tabs);
      expect(_selected(tester), 'Home');

      for (final (i, label) in _tabs.indexed) {
        await tester.tap(
          find.descendant(
            of: find.byType(PatientBottomNavigation),
            matching: find.text(label),
          ),
        );
        await _settle(tester);
        expect(_path(c), _roots[i], reason: 'tapping $label');
        expect(_selected(tester), label, reason: 'highlight after $label');
        expect(find.byType(PatientBottomNavigation), findsOneWidget);
      }
      await _teardown(tester);
    });
  }

  testWidgets('team chat keeps Chat selected and returns to the list', (
    tester,
  ) async {
    final c = await _pumpApp(tester, 'reception@myhealth.demo');
    c.read(routerProvider).go(AppRoutes.staffChat);
    await _settle(tester);
    c.read(routerProvider).push(AppRoutes.staffTeamDirectory);
    await _settle(tester);
    expect(_selected(tester), 'Chat');
    // Legacy links land in the same place.
    c.read(routerProvider).go('/staff/team');
    await _settle(tester);
    expect(_path(c), AppRoutes.staffTeamDirectory);
    expect(_selected(tester), 'Chat');
    await _teardown(tester);
  });

  testWidgets('Arabic, right-to-left: same five tabs, mirrored', (
    tester,
  ) async {
    await _pumpApp(tester, 'pharmacy@myhealth.demo', locale: 'ar');
    expect(find.byType(CompactNavigation), findsNothing);
    expect(_barLabels(tester), [
      'الرئيسية',
      'الجدول',
      'المرضى',
      'المحادثات',
      'الإعدادات',
    ]);
    final home = tester.getCenter(find.text('الرئيسية'));
    final settings = tester.getCenter(find.text('الإعدادات'));
    expect(home.dx, greaterThan(settings.dx), reason: 'RTL starts at right');
    await _teardown(tester);
  });

  testWidgets('largest text setting on a 320px phone keeps all five tabs', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      'reception@myhealth.demo',
      size: const Size(320, 640),
      textScale: 'medium',
    );
    expect(find.byType(CompactNavigation), findsNothing);
    expect(_barLabels(tester), _tabs);
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });

  for (final (width, rail, sidebar) in [
    (800.0, true, false),
    (1280.0, false, true),
  ]) {
    testWidgets('${width.toInt()}px: one navigation control with five tabs', (
      tester,
    ) async {
      await _pumpApp(tester, 'reception@myhealth.demo', size: Size(width, 900));
      expect(find.byType(PatientBottomNavigation), findsNothing);
      expect(find.byType(CompactNavigation), findsNothing);
      expect(find.byType(NavigationRail), rail ? findsOneWidget : findsNothing);
      expect(
        find.byType(StaffSidebar),
        sidebar ? findsOneWidget : findsNothing,
      );
      for (final label in _tabs) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await _teardown(tester);
    });
  }
}
