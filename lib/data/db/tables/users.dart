/// Identity + org tables: departments, users, patient/staff profiles (P1-01).
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import '../converters.dart';

@DataClassName('DepartmentRow')
class Departments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('UserRow')
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

  /// Local file path to the account's profile photo, or null for the
  /// generated-monogram fallback. Never a remote URL — the app is
  /// offline-first, so the image lives on-device alongside the database.
  TextColumn get avatarPath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Consecutive wrong-password attempts since the last success — backs
  /// login throttling. Reset to 0 on a successful login.
  IntColumn get failedLoginAttempts =>
      integer().withDefault(const Constant(0))();

  /// Set once [failedLoginAttempts] crosses the threshold; login is refused
  /// (with a generic message) while this is in the future.
  DateTimeColumn get lockedUntil => dateTime().nullable()();

  /// False for a dependent patient (a child, or an adult someone cares for)
  /// who has a patient record but no login of their own. Sign-in and
  /// recovery always refuse such a row; a guardian reaches it through a
  /// proxy grant.
  BoolColumn get hasLogin => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A patient's request to reset a forgotten password. There is no email/SMS
/// delivery in this app, so a self-service "click a link" reset can't prove
/// the requester owns the account — instead the request is queued for an
/// authenticated admin to verify the person and issue a new password
/// (resolving it), the same trust boundary the admin's existing per-user
/// "Reset password" action already relies on.
@DataClassName('PasswordResetRequestRow')
class PasswordResetRequests extends Table {
  TextColumn get id => text()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// What the requester typed (email or national ID) — shown to the admin
  /// for context; never used to bypass looking the account up server-side.
  TextColumn get identifierEntered => text()();
  DateTimeColumn get requestedAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolvedByStaffId =>
      text().nullable().references(Users, #id)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per patient, keyed by [Users.id].
@DataClassName('PatientProfileRow')
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

  /// Linked family members (redesign v2 patient dashboard: Family Network).
  /// The whole list round-trips as one JSON blob — no table of its own.
  TextColumn get familyMembers => text()
      .map(const FamilyMemberListConverter())
      .withDefault(const Constant('[]'))();

  /// Optimistic-concurrency version (trigger-bumped, schema v19): two
  /// devices editing one profile can't silently overwrite each other.
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// One row per staff member, keyed by [Users.id].
@DataClassName('StaffProfileRow')
class StaffProfiles extends Table {
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get specialty => text().nullable()();
  TextColumn get departmentId =>
      text().nullable().references(Departments, #id)();
  TextColumn get licenseNo => text().nullable()();
  TextColumn get jobTitle => text().nullable()();

  /// Live availability shown on the staff dashboard + directory. Null rows
  /// (pre-migration) read as [PresenceStatus.offShift].
  TextColumn get presence => textEnum<PresenceStatus>().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
