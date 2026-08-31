/// Clinical content tables: medical records, lab values, vitals, medications
/// (P1-03).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

@DataClassName('MedicalRecordRow')
class MedicalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Null for patient-imported records (P2-12).
  TextColumn get authorStaffId => text().nullable().references(Users, #id)();

  TextColumn get recordType => textEnum<RecordType>()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get sourceFacility => text().nullable()();

  /// Local path to an imported file (PDF, image), copied into app storage.
  TextColumn get attachmentPath => text().nullable()();

  /// Text pulled out of [attachmentPath] by the PDF extractor (P2-11), fed to
  /// the AI context builder (P3-02).
  TextColumn get extractedText => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Individual analyte results attached to a `labResult` [MedicalRecords] row.
@DataClassName('LabValueRow')
class LabValues extends Table {
  TextColumn get id => text()();
  TextColumn get recordId =>
      text().references(MedicalRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get analyte => text()();
  RealColumn get value => real()();
  TextColumn get unit => text().nullable()();
  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();
  TextColumn get abnormalFlag =>
      textEnum<AbnormalFlag>().withDefault(const Constant('normal'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VitalsRow')
class Vitals extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get recordedAt => dateTime()();

  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get tempC => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  IntColumn get spo2 => integer().nullable()();
  RealColumn get glucose => real().nullable()();

  /// Null for self-entered vitals (P2-14).
  TextColumn get recordedByStaffId =>
      text().nullable().references(Users, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get prescriberId => text().nullable().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get dose => text().nullable()();
  TextColumn get frequency => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
