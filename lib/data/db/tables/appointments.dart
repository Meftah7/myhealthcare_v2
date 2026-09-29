/// Scheduling tables: appointments, schedule templates, reminders (P1-02).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

/// A recurring weekly working block for a staff member; the slot generator
/// (P4-12) expands these minus booked appointments.
@DataClassName('ScheduleTemplateRow')
class ScheduleTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// 1 = Monday … 7 = Sunday (`DateTime.weekday`).
  IntColumn get weekday => integer()();

  /// Minutes from midnight, local clinic time.
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  IntColumn get slotMinutes => integer().withDefault(const Constant(20))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AvailabilityExceptionRow')
class AvailabilityExceptions extends Table {
  TextColumn get id => text()();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get reason => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppointmentRow')
class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get staffId => text().references(Users, #id)();
  TextColumn get departmentId =>
      text().nullable().references(Departments, #id)();

  DateTimeColumn get slotStart => dateTime()();
  DateTimeColumn get slotEnd => dateTime()();
  TextColumn get visitType => textEnum<VisitType>()();
  TextColumn get status =>
      textEnum<AppointmentStatus>().withDefault(const Constant('booked'))();
  TextColumn get reasonText => text().nullable()();
  DateTimeColumn get bookedAt => dateTime().withDefault(currentDateAndTime)();

  /// Predicted no-show probability (0–1) and its band, written at booking
  /// time by the model (P4-17). Null until scored.
  RealColumn get noShowRisk => real().nullable()();
  TextColumn get riskBand => textEnum<RiskBand>().nullable()();

  IntColumn get remindersSent => integer().withDefault(const Constant(0))();

  /// When the doctor pressed "Call patient" on the schedule ticket.
  DateTimeColumn get calledInAt => dateTime().nullable()();

  /// When the doctor pressed "Patient arrived" — the visit moves to
  /// `inProgress` and the consultation page opens.
  DateTimeColumn get checkedInAt => dateTime().nullable()();

  /// The doctor's closing summary, written at "Complete consultation".
  TextColumn get outcomeNote => text().nullable()();

  /// `[Hour letter A-X]-[facility-wide ticket number for that hour today]`,
  /// assigned once at booking time (redesign v2 patient dashboard spec).
  TextColumn get ticketTag => text().nullable()();

  /// `[Department letter]-[doctor's sequence within that department]`,
  /// assigned once at booking time (redesign v2 patient dashboard spec).
  TextColumn get roomNumber => text().nullable()();

  /// The linked family member this visit is for, when the account holder booked
  /// on someone else's behalf. Null = the account holder's own visit.
  TextColumn get bookedForName => text().nullable()();

  /// The signed-in account that made the booking. Differs from [patientId]
  /// when a guardian or proxy booked for someone else. Null on rows from
  /// before this was tracked.
  TextColumn get bookedByAccountId => text().nullable()();

  /// Optimistic-concurrency version, bumped on every update by a database
  /// trigger (schema v19) so no write path can forget. A write naming a
  /// stale version is refused with a conflict.
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get appointmentId =>
      text().references(Appointments, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledFor => dateTime()();
  TextColumn get channel => textEnum<ReminderChannel>()();
  TextColumn get kind =>
      textEnum<ReminderKind>().withDefault(const Constant('standard'))();
  TextColumn get deliveryStatus => textEnum<ReminderDeliveryStatus>()
      .withDefault(const Constant('queued'))();
  IntColumn get deliveryAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// Earliest retry after a transient delivery failure (schema v24). Null
  /// means "as soon as it is due".
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
