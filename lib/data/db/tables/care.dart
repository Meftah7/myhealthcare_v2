/// Care-services tables (P10 Batch B): doctor-issued sick-leave certificates,
/// patient <-> doctor messages, and home-visit requests.
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'appointments.dart';
import 'users.dart';

/// A fit-note the clinician issues after a visit. The patient can view it and
/// export it as a PDF; they can never create one themselves.
@DataClassName('SickLeaveRow')
class SickLeaveCertificates extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get issuedByStaffId => text().references(Users, #id)();

  /// The visit it was issued from, if any. Kept if the appointment is removed.
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get diagnosis => text().withLength(min: 1, max: 300)();
  DateTimeColumn get fromDate => dateTime()();
  DateTimeColumn get toDate => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get issuedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One message in a patient <-> doctor thread. A "thread" is just every row
/// sharing the same (patientId, staffId) pair — there is no thread table.
@DataClassName('CareMessageRow')
class CareMessages extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// True when the doctor sent it, false when the patient did.
  BoolColumn get fromStaff => boolean()();
  TextColumn get body => text().withLength(min: 1, max: 4000)();
  DateTimeColumn get sentAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A request for a clinician to visit the patient at home. Triaged by the
/// clinic, which schedules, declines or completes it.
@DataClassName('HomeVisitRow')
class HomeVisitRequests extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get addressText => text().withLength(min: 1, max: 500)();
  DateTimeColumn get preferredDate => dateTime()();
  TextColumn get reasonText => text().withLength(min: 1, max: 1000)();

  TextColumn get status =>
      textEnum<HomeVisitStatus>().withDefault(const Constant('requested'))();

  TextColumn get departmentId => text().nullable().references(
    Departments,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get assignedStaffId =>
      text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// The clinic's note when scheduling / declining.
  TextColumn get decisionNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get decidedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
