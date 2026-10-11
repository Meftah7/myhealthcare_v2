// Patient rebuild (approved blue design, updated spec): theme tokens, the
// signed-in route policy, catalogue scope (Future work), the five-tab shell,
// Home section order and the native drawer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/ui/patient/patient_bottom_navigation.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/health_tools/presentation/health_tools_screens.dart';
import 'package:myhealthcare/features/service_catalog/domain/patient_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/mfa.dart';
import '../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
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
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
  return container;
}

String _location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  group('blue patient theme', () {
    test('patient themes use the approved tokens', () {
      final light = AppTheme.patientLight;
      Color filled(ThemeData t) =>
          t.filledButtonTheme.style!.backgroundColor!.resolve(<WidgetState>{})!;
      expect(filled(light), const Color(0xFF246BFD));
      expect(light.scaffoldBackgroundColor, const Color(0xFFF7F7F8));
      expect(light.colorScheme.onSurface, const Color(0xFF2D333C));
      expect(
        light.extension<PatientPalette>()!.softAccent,
        const Color(0xFFE9F0FF),
      );

      final dark = AppTheme.patientDark;
      expect(dark.scaffoldBackgroundColor, const Color(0xFF111B28));
      expect(dark.extension<PatientPalette>()!.card, const Color(0xFF1C2839));
      expect(filled(dark), const Color(0xFF246BFD));
      // Readable light blue for small links/icons on navy.
      expect(dark.extension<PatientPalette>()!.link, const Color(0xFF9ABEFF));
    });

    test('staff/admin themes keep their own palette', () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF4275A3));
      expect(AppTheme.light.extension<PatientPalette>(), isNull);
    });
  });

  group('route policy', () {
    test('only internal routes are resumed after sign-in', () {
      expect(isSafeReturnRoute('/patient/timeline/documents'), isTrue);
      expect(isSafeReturnRoute('/patient/appointments/book?dept=d1'), isTrue);
      expect(isSafeReturnRoute('https://evil.example'), isFalse);
      expect(isSafeReturnRoute('//evil.example/x'), isFalse);
      expect(isSafeReturnRoute(AppRoutes.login), isFalse);
      expect(isSafeReturnRoute('/'), isFalse);
    });
  });

  group('catalogue scope', () {
    final all = {
      ...PatientCatalog.quickAccess.values.expand((g) => g),
      ...PatientCatalog.services.values.expand((g) => g),
      ...PatientCatalog.quickTools,
      ...PatientCatalog.moreTools,
      ...PatientCatalog.promotions,
      ...PatientCatalog.drawerTools,
    };

    test('Quick Access keeps the daily-care features, records first', () {
      final ids = PatientCatalog.quickAccess.values
          .expand((g) => g)
          .map((i) => i.id)
          .toSet();
      expect(
        ids,
        containsAll([
          'records',
          'medications',
          'documents',
          'sick-leave',
          'imaging',
          'allergies',
          'vitals',
          'summary',
          'explain-report',
          'nutrition',
          'appointments',
          'book-appointment',
          'visited-doctors',
          'messages',
          'notifications',
          'home-visits',
        ]),
      );
      expect(
        PatientCatalog.quickAccess[QuickAccessGroup.records]!
            .take(4)
            .map((i) => i.id),
        ['records', 'documents', 'explain-report', 'nutrition'],
      );
      // Account administration moved to the drawer.
      expect(ids, isNot(contains('billing')));
      expect(PatientCatalog.drawerTools.map((i) => i.id), [
        'family',
        'billing',
        'feedback',
      ]);
    });

    test('everything outside the proposal is labelled Future work', () {
      for (final id in [
        'nutrition',
        'vitals',
        'summary',
        'messages',
        'notifications',
        'home-visits',
        'billing',
        'family',
        'feedback',
        'calculators',
        'converters',
        'emergency',
        'specialty-guide',
        'virtual-care',
        'weather',
        'news',
        'wearables',
        'water-tracking',
        'pharmacy',
      ]) {
        expect(
          all.firstWhere((i) => i.id == id).isFutureWork,
          isTrue,
          reason: id,
        );
      }
      // Core proposal features are never relabelled — including the report
      // chatbot while its live model is pending.
      for (final id in [
        'records',
        'documents',
        'explain-report',
        'book-appointment',
        'appointments',
      ]) {
        expect(
          all.firstWhere((i) => i.id == id).isFutureWork,
          isFalse,
          reason: id,
        );
      }
    });

    test('supplementary features stay working; planned ones only explain', () {
      for (final item in all) {
        switch (item.scope) {
          case CatalogScope.supplementary:
            expect(item.isAvailable, isTrue, reason: item.id);
            expect(item.action, isNot(CatalogActionKind.futureWork));
          case CatalogScope.planned:
            expect(item.action, CatalogActionKind.futureWork, reason: item.id);
            expect(item.route, isNull, reason: item.id);
          case CatalogScope.core:
            if (item.action == CatalogActionKind.route) {
              expect(item.route, startsWith('/patient/'), reason: item.id);
            }
        }
      }
      // Weather and News: explanation only, no source or tab.
      expect(PatientCatalog.weather.scope, CatalogScope.planned);
      expect(PatientCatalog.news.scope, CatalogScope.planned);
    });
  });

  group('health tools', () {
    test('validated inputs and standard formulas', () {
      expect(parseInRange('70', 2, 400), 70);
      expect(parseInRange('70,5', 2, 400), 70.5);
      expect(parseInRange('-1', 2, 400), isNull);
      expect(parseInRange('abc', 2, 400), isNull);
      expect(bmi(70, 175), closeTo(22.86, 0.01));
      expect(bodySurfaceArea(70, 175), closeTo(1.84, 0.01));
    });
  });

  testWidgets('signed-in shell: tabs, Home order, drawer and sign-out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = await _pumpApp(tester);

    // Signed out: sign-in is required (no guest Home).
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    c.read(routerProvider).go(AppRoutes.patientHome);
    await _settle(tester);
    expect(_location(c), AppRoutes.login);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'patient3@myhealth.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      Seeder.demoPassword,
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await passMfa(tester);
    await _settle(tester);
    expect(_location(c), AppRoutes.patientHome);

    // The patient bar (or its large-text menu fallback) is in place.
    expect(find.byType(PatientBottomNavigation), findsOneWidget);

    // Quick Access sits directly below the Services carousel.
    final servicesY = tester.getTopLeft(find.text('View All').last).dy;
    final quickY = tester
        .getTopLeft(find.byKey(const ValueKey('quick-access')))
        .dy;
    expect(quickY, greaterThan(servicesY));
    // Supplementary features carry a visible Future work label.
    expect(find.text('Future work'), findsWidgets);

    // Messages is its own branch at its preserved path.
    c.read(routerProvider).go(AppRoutes.patientMessages);
    await _settle(tester);
    expect(_location(c), AppRoutes.patientMessages);
    c.read(routerProvider).go(AppRoutes.patientHome);
    await _settle(tester);

    // The native drawer holds the account actions.
    await tester.tap(find.byTooltip('Open navigation menu').first);
    await _settle(tester);
    expect(find.byType(Drawer), findsOneWidget);
    for (final key in [
      'drawer-profile',
      'drawer-personal',
      'drawer-health',
      'drawer-preferences',
      'drawer-family',
      'drawer-billing',
      'drawer-feedback',
      'drawer-about',
      'drawer-sign-out',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }

    // A drawer row closes the drawer, then navigates.
    await tester.tap(find.byKey(const ValueKey('drawer-billing')));
    await _settle(tester);
    expect(find.byType(Drawer), findsNothing);
    expect(_location(c), AppRoutes.patientBilling);

    // Sign-out is confirmed and ends the session.
    c.read(routerProvider).go(AppRoutes.patientHome);
    await _settle(tester);
    await tester.tap(find.byTooltip('Open navigation menu').first);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('drawer-sign-out')));
    await _settle(tester);
    expect(c.read(sessionProvider).isAuthenticated, isTrue);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out').last);
    await _settle(tester);
    expect(c.read(sessionProvider).isAuthenticated, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
