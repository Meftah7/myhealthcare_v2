// Patient rebuild (approved blue design): theme tokens, guest access rules,
// the catalogue's feature preservation, and Home's section order.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/ui/patient/patient_bottom_navigation.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
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

Future<void> _pumpApp(WidgetTester tester) async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MyHealthCareApp(),
    ),
  );
  await _settle(tester);
}

void main() {
  group('blue patient theme', () {
    test('patient themes use the approved tokens', () {
      final light = AppTheme.patientLight;
      expect(
        light.filledButtonTheme.style!.backgroundColor!.resolve(
          <WidgetState>{},
        ),
        const Color(0xFF246BFD),
      );
      expect(light.scaffoldBackgroundColor, const Color(0xFFF7F7F8));
      expect(light.colorScheme.onSurface, const Color(0xFF2D333C));
      expect(
        light.extension<PatientPalette>()!.softAccent,
        const Color(0xFFE9F0FF),
      );

      final dark = AppTheme.patientDark;
      expect(dark.scaffoldBackgroundColor, const Color(0xFF111B28));
      expect(dark.extension<PatientPalette>()!.card, const Color(0xFF1C2839));
      // Filled actions stay #246BFD in dark mode.
      final filled = dark.filledButtonTheme.style!.backgroundColor!.resolve(
        <WidgetState>{},
      );
      expect(filled, const Color(0xFF246BFD));
    });

    test('staff/admin themes keep their own palette', () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF4275A3));
    });
  });

  group('guest access', () {
    test('public patient routes are explicitly allowlisted', () {
      for (final route in [
        AppRoutes.patientHome,
        AppRoutes.patientWeather,
        AppRoutes.patientNews,
        AppRoutes.patientServices,
        AppRoutes.patientAppointments,
        AppRoutes.patientBookLanding,
        AppRoutes.patientFindDoctor,
        AppRoutes.patientCalculators,
      ]) {
        expect(isPublicPatientRoute(route), isTrue, reason: route);
      }
      for (final route in [
        AppRoutes.patientTimeline,
        AppRoutes.patientDocuments,
        AppRoutes.patientMessages,
        AppRoutes.patientBook,
        AppRoutes.patientSettings,
        AppRoutes.patientProfileFamily,
        AppRoutes.patientNutrition,
        AppRoutes.patientVitals,
        '/patient/booking',
      ]) {
        expect(isPublicPatientRoute(route), isFalse, reason: route);
      }
    });

    test('only internal routes are resumed after sign-in', () {
      expect(isSafeReturnRoute('/patient/timeline/documents'), isTrue);
      expect(isSafeReturnRoute('/patient/appointments/book?dept=d1'), isTrue);
      expect(isSafeReturnRoute('https://evil.example'), isFalse);
      expect(isSafeReturnRoute('//evil.example/x'), isFalse);
      expect(isSafeReturnRoute(AppRoutes.login), isFalse);
      expect(isSafeReturnRoute('/'), isFalse);
    });
  });

  group('catalogue', () {
    test('Quick Access preserves every relocated patient feature', () {
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
          'book',
          'visited-doctors',
          'messages',
          'notifications',
          'home-visits',
          'billing',
          'profile',
          'personal',
          'health-details',
          'family',
          'preferences',
          'feedback',
        ]),
      );
      // Records, Documents, Explain a Report and Nutrition lead.
      expect(
        PatientCatalog.quickAccess[QuickAccessGroup.records]!
            .take(4)
            .map((i) => i.id),
        ['records', 'documents', 'explain-report', 'nutrition'],
      );
    });

    test('every available item has a working action', () {
      final all = [
        ...PatientCatalog.quickAccess.values.expand((g) => g),
        ...PatientCatalog.services.values.expand((g) => g),
        ...PatientCatalog.quickTools,
        ...PatientCatalog.moreTools,
        ...PatientCatalog.promotions,
      ];
      for (final item in all) {
        if (item.action == CatalogActionKind.route) {
          expect(item.route, isNotNull, reason: item.id);
          expect(item.route, startsWith('/patient/'), reason: item.id);
        }
        if (!item.isAvailable) {
          expect(item.action, CatalogActionKind.unavailable, reason: item.id);
        }
      }
      // Existing care features are never replaced with placeholders.
      for (final item in PatientCatalog.quickAccess.values.expand((g) => g)) {
        expect(item.isAvailable, isTrue, reason: item.id);
      }
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

  testWidgets('guest Home: Quick Access sits directly below Services', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    // Sign-in offers guest browsing; guests reach Home without an account.
    await tester.ensureVisible(find.byKey(const ValueKey('browse-as-guest')));
    await tester.tap(find.byKey(const ValueKey('browse-as-guest')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('guest-login')), findsOneWidget);
    expect(find.text('Services'), findsWidgets);
    // The patient bar (or its large-text menu fallback) is in place.
    expect(find.byType(PatientBottomNavigation), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quick-access')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await _settle(tester);
    final servicesY = tester.getTopLeft(find.text('View All').last).dy;
    final quickY = tester
        .getTopLeft(find.byKey(const ValueKey('quick-access')))
        .dy;
    expect(quickY, greaterThan(servicesY));

    // A private tile sends a guest to the real sign-in screen.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('catalog-documents')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('catalog-documents')));
    await _settle(tester);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    // Signing in resumes the gated destination.
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
    final router = GoRouterProbe.of(tester);
    expect(router, AppRoutes.patientDocuments);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

/// Reads the current router location from the running app.
abstract final class GoRouterProbe {
  static String of(WidgetTester tester) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyHealthCareApp)),
    );
    return container
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
  }
}
