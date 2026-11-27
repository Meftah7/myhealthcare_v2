import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/document_service.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/features/appointments/presentation/appointment_detail_screen.dart';
import 'package:myhealthcare/features/appointments/presentation/appointments_screen.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/presentation/book_appointment_landing.dart';
import 'package:myhealthcare/features/care/presentation/issued_documents_screen.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/service_catalog/domain/patient_catalog.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/navigation.dart';
import '../support/sessions.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('booking navigation and history at $width dp', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final now = DateTime.now();
      final visit = Appointment(
        id: 'booking-navigation',
        patientId: 'patient_003',
        staffId: 'staff_01',
        bookedAt: now,
        slotStart: now.add(const Duration(days: 1)),
        slotEnd: now.add(const Duration(days: 1, minutes: 30)),
        visitType: VisitType.followUp,
        status: AppointmentStatus.checkedIn,
        remindersSent: 0,
      );
      final (c, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
        overrides: [
          patientAppointmentsProvider.overrideWith((ref) async => [visit]),
          doctorDirectoryProvider.overrideWith(
            (ref) async => {
              'staff_01': (name: 'Fixture clinician', departmentId: null),
            },
          ),
          patientAppointmentByIdProvider(
            visit.id,
          ).overrideWith((ref) async => visit),
        ],
      );
      await signInAs(c, 'patient3@myhealth.demo');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
      );
      await _settle(tester);
      final router = c.read(routerProvider);
      if (width < 600) {
        await selectCompactDestination(tester, 'Appointment');
      } else {
        await tester.tap(find.text('Appointment').first.hitTestable());
        await _settle(tester);
      }
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.patientBookLanding,
      );
      expect(find.byType(BookAppointmentLandingScreen), findsOneWidget);
      expect(find.text('Select Hospital'), findsNothing);
      expect(find.text('Region'), findsNothing);
      expect(find.byKey(const ValueKey('discover-clinic')), findsOneWidget);
      expect(find.byKey(const ValueKey('discover-doctor')), findsOneWidget);
      final card = find.text('Fixture clinician');
      final help = find.byType(HelpChoosingCard);
      expect(tester.getTopLeft(card).dy, lessThan(tester.getTopLeft(help).dy));
      expect(find.text('Checked in'), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'View all appointments'),
      );
      await tester.tap(
        find.widgetWithText(TextButton, 'View all appointments'),
      );
      await _settle(tester);
      expect(find.byType(AppointmentsScreen), findsOneWidget);
      expect(find.text('Checked in'), findsOneWidget);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await _settle(tester);
      expect(
        tester
            .widget<AppointmentDetailScreen>(
              find.byType(AppointmentDetailScreen),
            )
            .appointmentId,
        visit.id,
      );
      expect(find.text('Checked in'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in ['en', 'ar']) {
    testWidgets(
      'department arrows work at both boundaries and resize ($locale)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 600);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DepartmentChipScroller(
                child: ExcludeFocus(
                  child: Row(
                    children: [
                      for (var i = 0; i < 8; i++)
                        SizedBox(
                          width: 110,
                          height: 48,
                          child: Text('Department $i'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toolbar = tester.element(find.byType(DepartmentChipScroller));
        final t = AppLocalizations.of(toolbar)!;
        final previous = find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == t.previousDepartments,
        );
        final next = find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == t.nextDepartments,
        );
        IconButton button(Finder finder) => tester.widget<IconButton>(finder);
        expect(button(previous).onPressed, isNull);
        expect(button(next).onPressed, isNotNull);
        expect(
          (button(next).icon as Icon).icon,
          locale == 'ar' ? Icons.chevron_left : Icons.chevron_right,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(button(previous).onPressed, isNotNull);
        for (var i = 0; i < 5 && button(next).onPressed != null; i++) {
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(button(next).onPressed, isNull);
        for (var i = 0; i < 5 && button(previous).onPressed != null; i++) {
          await tester.tap(previous);
          await tester.pumpAndSettle();
        }
        expect(button(previous).onPressed, isNull);
        tester.view.physicalSize = const Size(1440, 600);
        await tester.pumpAndSettle();
        expect(previous, findsNothing);
        expect(next, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('clinic guide displays localized Dental guidance ($locale)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            departmentsProvider.overrideWith(
              (ref) async => [
                const Department(id: 'dept_dental', name: 'Dental'),
              ],
            ),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SpecialtyGuideScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = AppLocalizations.of(
        tester.element(find.byType(SpecialtyGuideScreen)),
      )!;
      expect(find.text(t.dentalDepartmentDescription), findsOneWidget);
      expect(find.text(t.paSpecialtyEmergencyNote), findsNothing);
    });
  }

  testWidgets(
    'Records and Services open the same authorized Documents destination',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const patientId = 'patient_003';
      const types = [
        ExportDocument.completedVisitReport,
        ExportDocument.sickLeaveCertificate,
        ExportDocument.releasedLabReport,
        ExportDocument.releasedImagingReport,
        ExportDocument.referralLetter,
        ExportDocument.prescriptionCopy,
        ExportDocument.attendanceCertificate,
      ];
      final (c, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
        overrides: [
          issuedDocumentsProvider(patientId).overrideWith(
            (ref) => Stream.value([
              for (final type in types)
                IssuedDocument(
                  id: type.name,
                  patientId: patientId,
                  verificationCode: 'code-${type.name}',
                  validity: DocumentValidity.valid,
                  renderStatus: DocumentRenderStatus.ready,
                  documentType: type,
                  issuedAt: DateTime(2026),
                  issuerName: 'Issuing clinician',
                ),
            ]),
          ),
        ],
      );
      await signInAs(c, 'patient3@myhealth.demo');
      expect(c.read(currentUserProvider)?.id, patientId);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
      );
      await _settle(tester);
      final router = c.read(routerProvider);
      router.go(AppRoutes.patientTimeline);
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Documents'));
      await _settle(tester);
      expect(find.byType(IssuedDocumentsScreen), findsOneWidget);
      expect(find.text('Visit report'), findsOneWidget);
      expect(find.text('Released lab report'), findsOneWidget);
      expect(find.textContaining('Issuing clinician'), findsWidgets);
      expect(PatientCatalog.documents.route, AppRoutes.patientDocuments);
      router.go(AppRoutes.patientSickLeave);
      await _settle(tester);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.patientDocuments,
      );
      expect(find.byType(IssuedDocumentsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
