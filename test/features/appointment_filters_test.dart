import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/appointments/presentation/appointments_screen.dart';
import 'package:myhealthcare/features/notifications/application/notification_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('visit filters separate cancelled visits from history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    Appointment visit(String id, AppointmentStatus status, DateTime start) =>
        Appointment(
          id: id,
          patientId: 'patient',
          staffId: id,
          slotStart: start,
          slotEnd: start.add(const Duration(minutes: 30)),
          visitType: VisitType.routineCheckup,
          status: status,
          bookedAt: now.subtract(const Duration(days: 7)),
          remindersSent: 0,
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          unreadNotificationCountProvider.overrideWithValue(null),
          patientAppointmentsProvider.overrideWith(
            (ref) async => [
              visit(
                'upcoming',
                AppointmentStatus.confirmed,
                now.add(const Duration(days: 1)),
              ),
              visit(
                'active',
                AppointmentStatus.inProgress,
                now.subtract(const Duration(minutes: 5)),
              ),
              visit(
                'past',
                AppointmentStatus.completed,
                now.subtract(const Duration(days: 1)),
              ),
              visit(
                'cancelled',
                AppointmentStatus.cancelled,
                now.add(const Duration(days: 2)),
              ),
            ],
          ),
          doctorDirectoryProvider.overrideWith(
            (ref) async => {
              'upcoming': (name: 'Upcoming clinician', departmentId: null),
              'active': (name: 'Active clinician', departmentId: null),
              'past': (name: 'Past clinician', departmentId: null),
              'cancelled': (name: 'Cancelled clinician', departmentId: null),
            },
          ),
          departmentDirectoryProvider.overrideWith(
            (ref) async => <String, String>{},
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppointmentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Upcoming clinician'), findsOneWidget);
    expect(find.text('Active clinician'), findsOneWidget);
    expect(find.text('Cancelled clinician'), findsNothing);
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('Past clinician'), findsOneWidget);
    expect(find.text('Upcoming clinician'), findsNothing);
    expect(find.text('Active clinician'), findsNothing);
    expect(find.text('Cancelled clinician'), findsNothing);
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled clinician'), findsOneWidget);
    expect(find.text('Past clinician'), findsNothing);
  });
}
