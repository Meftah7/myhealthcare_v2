import 'package:drift/drift.dart';
import 'users.dart';
import 'appointments.dart';

/// Physical rooms, independent of legacy appointment ticket labels.
class ClinicRooms extends Table {
  TextColumn get id => text()();
  TextColumn get displayLabel => text().withLength(min: 1, max: 80)();
  TextColumn get departmentId => text().nullable().references(Departments, #id)();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Explicit personal participation; never inferred from care assignments.
class EncounterParticipants extends Table {
  TextColumn get appointmentId => text().references(Appointments, #id)();
  TextColumn get staffId => text().references(Users, #id)();
  DateTimeColumn get participatedAt => dateTime()();
  TextColumn get recordedBy => text().references(Users, #id)();
  @override
  Set<Column<Object>> get primaryKey => {appointmentId, staffId};
}
