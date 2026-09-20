// Admin-editable clinic schedule (P-clinic-hours): the pure clinic_hours
// helpers respect a custom schedule, the provider persists it, and the admin
// screen lets a day be toggled off.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/utils/clinic_hours.dart';
import 'package:myhealthcare/features/admin/presentation/clinic_hours_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('clinic_hours pure functions', () {
    const weekdaysOnly = ClinicSchedule(openDays: {1, 2, 3, 4, 5});

    test('isClinicDay follows the schedule, not a hardcoded weekend', () {
      final saturday = DateTime(2024, 1, 6); // weekday 6
      final monday = DateTime(2024, 1, 8); // weekday 1
      expect(isClinicDay(saturday, weekdaysOnly), isFalse);
      expect(isClinicDay(monday, weekdaysOnly), isTrue);
    });

    test('nextClinicDay skips closed days', () {
      final friday = DateTime(2024, 1, 5); // weekday 5, last open day
      expect(
        nextClinicDay(friday, weekdaysOnly),
        DateTime(2024, 1, 8), // next Monday
      );
    });

    test('isWithinClinicHours respects custom open/close hours', () {
      const schedule = ClinicSchedule(openHour: 9, closeHour: 17);
      expect(isWithinClinicHours(DateTime(2024, 1, 1, 8, 30), schedule), isFalse);
      expect(isWithinClinicHours(DateTime(2024, 1, 1, 9), schedule), isTrue);
      expect(isWithinClinicHours(DateTime(2024, 1, 1, 17), schedule), isTrue);
      expect(isWithinClinicHours(DateTime(2024, 1, 1, 17, 1), schedule), isFalse);
    });
  });

  test('ClinicScheduleController defaults to every day, 08:00-20:00', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final schedule = container.read(clinicScheduleProvider);
    expect(schedule.openDays, {1, 2, 3, 4, 5, 6, 7});
    expect(schedule.openHour, 8);
    expect(schedule.closeHour, 20);
  });

  test('ClinicScheduleController.set persists across a rebuild', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container
        .read(clinicScheduleProvider.notifier)
        .set(const ClinicSchedule(openDays: {1, 2, 3, 4, 5}, openHour: 9, closeHour: 17));

    final reread = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reread.dispose);
    final schedule = reread.read(clinicScheduleProvider);
    expect(schedule.openDays, {1, 2, 3, 4, 5});
    expect(schedule.openHour, 9);
    expect(schedule.closeHour, 17);
  });

  testWidgets('ClinicHoursScreen: turning a day off persists it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ClinicHoursScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The chip labels are locale-formatted weekday names (e.g. "Sun"); find
    // the chip for today rather than assuming a fixed label set.
    final sundayChip = find.widgetWithText(FilterChip, 'Sun');
    expect(sundayChip, findsOneWidget);
    await tester.tap(sundayChip);
    await tester.pumpAndSettle();

    expect(prefs.getStringList('clinic.openDays'), isNot(contains('7')));
  });
}
