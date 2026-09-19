/// Clinic opening hours — the single source of truth shared by the booking
/// wizard and the reschedule flow. Mirrors the seeded schedule templates
/// (`Seeder`: Sun–Thu, 08:00–20:00).
library;

const clinicOpenHour = 8;
const clinicCloseHour = 20; // last slot starts before this

/// The clinic is open every day of the week.
bool isClinicDay(DateTime d) => true;

/// The next clinic day strictly after [from].
DateTime nextClinicDay(DateTime from) {
  var d = from.add(const Duration(days: 1));
  while (!isClinicDay(d)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// True when [t] falls inside opening hours.
bool isWithinClinicHours(DateTime t) =>
    t.hour >= clinicOpenHour &&
    (t.hour < clinicCloseHour ||
        (t.hour == clinicCloseHour && t.minute == 0));
