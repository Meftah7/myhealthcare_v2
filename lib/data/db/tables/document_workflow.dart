import 'package:drift/drift.dart';

import 'ai.dart';
import 'appointments.dart';
import 'users.dart';

@DataClassName('ScopedGrantRow')
class ScopedGrants extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Users, #id)();
  TextColumn get permission => text()();
  TextColumn get scope => text()();

  /// Empty only for clinic scope; otherwise a patient or department id.
  TextColumn get scopeId => text()();
  TextColumn get grantedBy => text().references(Users, #id)();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();
  TextColumn get revokedBy => text().nullable().references(Users, #id)();
  TextColumn get reason => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DocumentTemplateRow')
class DocumentTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get documentType => text()();
  IntColumn get version => integer()();
  TextColumn get language => text()();
  TextColumn get disclosureProfile => text()();
  TextColumn get wording => text()();
  BoolColumn get clinicalSignatureRequired => boolean()();
  TextColumn get requiredCredential => text().nullable()();
  TextColumn get approvedBy => text().nullable().references(Users, #id)();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  DateTimeColumn get retiredAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {documentType, version, language, disclosureProfile},
  ];
}

@DataClassName('DocumentRequestRow')
class DocumentRequests extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Users, #id)();
  TextColumn get appointmentId =>
      text().nullable().references(Appointments, #id)();
  TextColumn get templateId => text().references(DocumentTemplates, #id)();
  TextColumn get requestedBy => text().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get contentJson => text()();
  TextColumn get idempotencyKey => text().unique()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Content snapshots are insert-only. Revocation and rendering are separate.
@DataClassName('IssuedDocumentVersionRow')
class IssuedDocumentVersions extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text().references(DocumentRequests, #id)();
  TextColumn get patientId => text().references(Users, #id)();
  TextColumn get templateId => text().references(DocumentTemplates, #id)();
  IntColumn get version => integer()();
  TextColumn get documentType => text()();
  TextColumn get language => text()();
  TextColumn get disclosureProfile => text()();
  TextColumn get patientSnapshotJson => text()();
  TextColumn get issuerSnapshotJson => text()();
  TextColumn get contentJson => text()();
  TextColumn get templateSnapshotJson => text()();
  TextColumn get issuerAccountId => text().references(Users, #id)();
  TextColumn get supersedesId =>
      text().nullable().references(IssuedDocumentVersions, #id)();
  TextColumn get idempotencyKey => text().unique()();
  DateTimeColumn get issuedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {requestId, version},
  ];
}

@DataClassName('DocumentArtifactRow')
class DocumentArtifacts extends Table {
  TextColumn get issuedVersionId =>
      text().references(IssuedDocumentVersions, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  BlobColumn get bytes => blob().nullable()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get failure => text().nullable()();
  DateTimeColumn get renderedAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {issuedVersionId};
}

@DataClassName('DocumentDeliveryEventRow')
class DocumentDeliveryEvents extends Table {
  TextColumn get id => text()();
  TextColumn get issuedVersionId =>
      text().references(IssuedDocumentVersions, #id)();
  TextColumn get recipientAccountId => text().references(Users, #id)();
  TextColumn get channel => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  TextColumn get failure => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get attemptedAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {issuedVersionId, recipientAccountId, channel},
  ];
}

@DataClassName('TaskSourceRow')
class TaskSources extends Table {
  TextColumn get taskId => text().references(StaffTasks, #id)();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  TextColumn get episodeKey => text()();
  DateTimeColumn get recordedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {
    taskId,
    sourceType,
    sourceId,
    episodeKey,
  };
}

@DataClassName('TaskHistoryRow')
class TaskHistory extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(StaffTasks, #id)();
  TextColumn get actorAccountId => text().nullable().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get beforeJson => text()();
  TextColumn get afterJson => text()();
  TextColumn get outcome => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
