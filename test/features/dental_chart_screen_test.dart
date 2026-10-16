// The dental chart lays out at phone and desktop widths with 200% text and
// labels each tooth for screen readers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/patient_chart/presentation/dental_chart_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('dental chart at ${width.toInt()}dp', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final (c, db) = await seededContainer();
      // A visit with the dentist establishes the care relationship.
      final start = DateTime.now().add(const Duration(days: 2));
      await db
          .into(db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: 'dental-visit',
              patientId: 'patient_001',
              staffId: 'staff_dentist',
              slotStart: start,
              slotEnd: start.add(const Duration(minutes: 20)),
              visitType: VisitType.newPatient,
            ),
          );
      await signInAs(c, 'dentist@myhealth.demo');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const DentalChartScreen(patientId: 'patient_001'),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('18'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.bySemanticsLabel('Tooth 18'), findsOneWidget);
      expect(find.bySemanticsLabel('Tooth 11'), findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      c.invalidate(sessionProvider);
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
