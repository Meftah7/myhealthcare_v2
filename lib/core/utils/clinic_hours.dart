/// Clinic opening hours — the single source of truth shared by the booking
/// wizard and the reschedule flow. Defaults mirror the seeded schedule
/// templates (`Seeder`: Sun–Thu, 08:00–20:00); admin-editable via
/// [ClinicSchedule] (see `app/settings/ui_prefs.dart`).
library;

import '../../app/settings/ui_prefs.dart';

/// True when [d] falls on one of [schedule]'s open days.
bool isClinicDay(DateTime d, ClinicSchedule schedule) =>
    schedule.openDays.contains(d.weekday);

/// The next open day strictly after [from].
DateTime nextClinicDay(DateTime from, ClinicSchedule schedule) {
  var d = from.add(const Duration(days: 1));
  while (!isClinicDay(d, schedule)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// True when [t] falls inside [schedule]'s opening hours.
bool isWithinClinicHours(DateTime t, ClinicSchedule schedule) =>
    t.hour >= schedule.openHour &&
    (t.hour < schedule.closeHour ||
        (t.hour == schedule.closeHour && t.minute == 0));
