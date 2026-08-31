/// Scheduling tables: appointments, schedule templates, reminders (P1-02).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

/// A recurring weekly working block for a staff member; the slot generator
/// (P4-12) expands these minus booked appointments.
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

class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get staffId => text().references(Users, #id)();
  TextColumn get departmentId => text().nullable().references(Departments, #id)();

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
  DateTimeColumn get checkedInAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get appointmentId =>
      text().references(Appointments, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledFor => dateTime()();
  TextColumn get channel => textEnum<ReminderChannel>()();
  TextColumn get kind =>
      textEnum<ReminderKind>().withDefault(const Constant('standard'))();
  DateTimeColumn get sentAt => dateTime().nullable()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
