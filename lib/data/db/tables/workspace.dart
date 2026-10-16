import 'package:drift/drift.dart';
import 'users.dart';
import 'appointments.dart';
import 'records.dart';

/// Physical rooms, independent of legacy appointment ticket labels.
class ClinicRooms extends Table {
  TextColumn get id => text()();
  TextColumn get displayLabel => text().withLength(min: 1, max: 80)();
  TextColumn get departmentId =>
      text().nullable().references(Departments, #id)();
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

/// Work shifts for roles that do not own appointment templates.
class StaffShifts extends Table {
  TextColumn get id => text()();
  TextColumn get staffId => text().references(Users, #id)();
  IntColumn get weekday => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get departmentId =>
      text().nullable().references(Departments, #id)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MedicationClarifications extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId => text().references(Medications, #id)();
  TextColumn get requestedBy => text().references(Users, #id)();
  TextColumn get question => text()();
  DateTimeColumn get requestedAt => dateTime()();
  TextColumn get resolvedBy => text().nullable().references(Users, #id)();
  TextColumn get resolution => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Assignment and nursing note; observations use the existing Vitals table.
class NursingIntakes extends Table {
  TextColumn get id => text()();
  TextColumn get appointmentId => text().references(Appointments, #id)();
  TextColumn get nurseId => text().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get observationNote => text().withDefault(const Constant(''))();
  TextColumn get vitalsId => text().nullable().references(Vitals, #id)();
  DateTimeColumn get assignedAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime().nullable()();
  TextColumn get recordedBy => text().nullable().references(Users, #id)();
  TextColumn get lastRequestKey => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {appointmentId, nurseId},
  ];
}

class StaffConversations extends Table {
  TextColumn get id => text()();
  TextColumn get pairKey => text().unique()();
  TextColumn get createdBy => text().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StaffConversationMembers extends Table {
  TextColumn get conversationId => text().references(StaffConversations, #id)();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get lastReadAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {conversationId, userId};
}

class StaffMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(StaffConversations, #id)();
  TextColumn get senderId => text().references(Users, #id)();
  TextColumn get body => text().withLength(min: 1, max: 4000)();
  TextColumn get requestKey => text().unique()();
  DateTimeColumn get sentAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
