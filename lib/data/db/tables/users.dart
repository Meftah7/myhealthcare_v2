/// Identity + org tables: departments, users, patient/staff profiles (P1-01).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import '../converters.dart';

class Departments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get role => textEnum<UserRole>()();
  TextColumn get fullName => text().withLength(min: 1, max: 160)();
  TextColumn get email => text().withLength(min: 3, max: 254).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get dob => dateTime().nullable()();
  TextColumn get gender => textEnum<Gender>().nullable()();
  TextColumn get nationalId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per patient, keyed by [Users.id].
class PatientProfiles extends Table {
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get bloodType => text().nullable()();
  TextColumn get allergies => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get chronicConditions => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get emergencyContact => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// One row per staff member, keyed by [Users.id].
class StaffProfiles extends Table {
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get specialty => text().nullable()();
  TextColumn get departmentId =>
      text().nullable().references(Departments, #id)();
  TextColumn get licenseNo => text().nullable()();
  TextColumn get jobTitle => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
