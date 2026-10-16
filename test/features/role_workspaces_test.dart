// Non-clinical staff roles land on their own Today workspace (never the
// clinical dashboard) and it lays out at phone and desktop widths, in
// English and Arabic, at 200% text.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/role_workspaces.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_dashboard_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:myhealthcare/features/workforce/workforce_home.dart';
import 'package:myhealthcare/features/auth/application/session.dart';

import '../support/sessions.dart';

void main() {
  const cases = {
    'reception@myhealth.demo': FrontDeskWorkspace,
    'pharmacy@myhealth.demo': PharmacyWorkspace,
    'nurse@myhealth.demo': NurseWorkspace,
    'dentist@myhealth.demo': StaffDashboardScreen,
    'staff1@myhealth.demo': StaffDashboardScreen,
  };

  for (final MapEntry(key: email, value: expected) in cases.entries) {
    for (final width in [320.0, 1440.0]) {
      for (final language in ['en', 'ar']) {
        testWidgets('$email workspace at ${width.toInt()}dp in $language', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final (container, _) = await seededContainer();
          await signInAs(container, email);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.light,
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: const StaffDashboardScreen(),
              ),
            ),
          );
          for (var i = 0; i < 24; i++) {
            await tester.pump(const Duration(milliseconds: 80));
          }
          expect(tester.takeException(), isNull);
          expect(find.byType(expected), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          container.invalidate(sessionProvider);
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }
}
