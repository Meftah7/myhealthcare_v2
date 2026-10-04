/// Clinical content tables: medical records, lab values, vitals, medications
/// (P1-03).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'appointments.dart';
import 'users.dart';

@DataClassName('MedicalRecordRow')
class MedicalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Null for patient-imported records (P2-12).
  TextColumn get authorStaffId => text().nullable().references(Users, #id)();

  /// The visit this record was produced in, if any (a consultation note, a
  /// prescription record). Kept if the appointment is later removed.
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
  )();

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

  /// True when the patient imported this themselves. Such a record has not
  /// been reviewed by a clinician and must never read as a clinic result.
  BoolColumn get uploadedByPatient =>
      boolean().withDefault(const Constant(false))();

  /// The signed-in account that created the record (a clinician, the
  /// patient, or a proxy uploading for them). Null on older rows.
  TextColumn get createdByAccountId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // --- import provenance (Phase 5) -----------------------------------------

  /// Whether a clinician has reviewed a patient import. Clinic-authored
  /// records are `notRequired`. Stored by name.
  TextColumn get reviewStatus => textEnum<ImportReviewStatus>().withDefault(
    const Constant('notRequired'),
  )();
  TextColumn get reviewedByStaffId =>
      text().nullable().references(Users, #id)();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  TextColumn get reviewNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The original file behind an imported record (Phase 5). Stored in the
/// database on every platform — web has no app file system — so the source
/// survives restarts, backups and exports. Native databases are encrypted at
/// rest; web storage follows SEC-XCUT-03.
@DataClassName('DocumentFileRow')
class DocumentFiles extends Table {
  TextColumn get id => text()();
  TextColumn get recordId => text().unique().references(
    MedicalRecords,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();

  /// Hex SHA-256 of [bytes] — proves the file shown is the one imported.
  TextColumn get sha256 => text()();
  BlobColumn get bytes => blob()();
  DateTimeColumn get storedAt => dateTime()();

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
  TextColumn get source => text().nullable()();
  TextColumn get provenance => text().nullable()();
  TextColumn get verificationStatus => textEnum<VerificationStatus>()
      .withDefault(const Constant('unverified'))();
  TextColumn get verifiedByStaffId =>
      text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Owned review of an abnormal or unjudgeable result (Phase 4). Opened when
/// the result is filed; it cannot lose its owner, only be handed to another
/// clinician. One per record.
@DataClassName('ResultReviewRow')
class ResultReviews extends Table {
  TextColumn get id => text()();
  TextColumn get recordId =>
      text().references(MedicalRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get ownerStaffId =>
      text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get coverageStaffId =>
      text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get priority =>
      textEnum<WorkPriority>().withDefault(const Constant('routine'))();
  TextColumn get status => textEnum<ResultReviewStatus>().withDefault(
    const Constant('unassigned'),
  )();
  TextColumn get escalationNote => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolvedByStaffId =>
      text().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get resolutionNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VitalsRow')
class Vitals extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
  )();

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

  /// The visit it was prescribed in, if any.
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get dose => text().nullable()();
  TextColumn get frequency => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EncounterDraftRow')
class EncounterDrafts extends Table {
  TextColumn get appointmentId =>
      text().references(Appointments, #id, onDelete: KeyAction.cascade)();
  TextColumn get patientId => text().references(Users, #id)();
  TextColumn get authorStaffId => text().references(Users, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get medicationsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get referralRequested =>
      boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {appointmentId};
}

@DataClassName('SignedNoteRow')
class SignedNotes extends Table {
  TextColumn get id => text()();
  TextColumn get appointmentId =>
      text().unique().references(Appointments, #id)();
  TextColumn get patientId => text().references(Users, #id)();
  TextColumn get authorStaffId => text().references(Users, #id)();
  TextColumn get body => text()();
  DateTimeColumn get signedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SignedNoteAmendmentRow')
class SignedNoteAmendments extends Table {
  TextColumn get id => text()();
  TextColumn get signedNoteId =>
      text().references(SignedNotes, #id, onDelete: KeyAction.cascade)();
  TextColumn get authorStaffId => text().references(Users, #id)();
  TextColumn get body => text()();
  DateTimeColumn get amendedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
