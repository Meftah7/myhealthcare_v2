// Non-clinical staff roles land on their own Today workspace (never the
// clinical dashboard) and it lays out at phone and desktop widths, in
// English and Arabic, at 200% text.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/role_workspaces.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/staff_dashboard_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  const cases = {
    'reception@myhealth.demo': FrontDeskWorkspace,
    'pharmacy@myhealth.demo': PharmacyWorkspace,
    'staff1@myhealth.demo': null, // unknown title, set below
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
          final (container, db) = await seededContainer();
          if (expected == null) {
            await (db.update(db.staffProfiles)
                  ..where((s) => s.userId.equals('staff_01')))
                .write(const StaffProfilesCompanion(jobTitle: Value('Porter')));
          }
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
          expect(
            find.byType(expected ?? UnassignedRoleWorkspace),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }
}
