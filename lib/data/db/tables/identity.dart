/// Identity relationships kept apart from the account row: verified account
/// recovery, clinician care-team assignments and staff credentials.
library;

import 'package:drift/drift.dart';

import '../../../domain/identity/identity.dart';
import 'users.dart';

/// One verification code issued for self-service password recovery.
///
/// Only a salted hash of the code is stored. A code is single-use
/// ([consumedAt]), expires ([expiresAt]), allows a few wrong guesses
/// ([failedAttempts]) and is invalidated when a newer one is issued or the
/// password changes by any route ([invalidatedAt]).
@DataClassName('AccountRecoveryTokenRow')
class AccountRecoveryTokens extends Table {
  TextColumn get id => text()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get codeHash => text()();
  TextColumn get codeSalt => text()();

  /// Where the code was sent, masked (e.g. `p***@myhealth.demo`).
  TextColumn get sentTo => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get consumedAt => dateTime().nullable()();
  DateTimeColumn get invalidatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A clinician formally assigned to a patient's care. Together with an
/// appointment, a walk-in visit or an existing message thread, this is what
/// counts as a care relationship for clinical writes.
@DataClassName('CareTeamAssignmentRow')
class CareTeamAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => textEnum<CareTeamRole>()();
  DateTimeColumn get assignedAt => dateTime()();
  TextColumn get assignedBy => text().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A clinician's licence / registration, separate from their profile so it
/// can carry validity and verification of its own.
@DataClassName('StaffCredentialRow')
class StaffCredentials extends Table {
  TextColumn get id => text()();
  TextColumn get staffId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<CredentialKind>()();
  TextColumn get identifier => text()();
  TextColumn get issuer => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime().nullable()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
