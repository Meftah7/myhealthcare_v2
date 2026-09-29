/// Authentication + user-account contracts (P1-11).
///
/// Interfaces only — no Drift, no Flutter. Implementations live in
/// data/repositories/ and are the single swap point for a future networked
/// backend.
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

/// Fields a patient supplies when self-registering (P2-03).
class PatientRegistration {
  const PatientRegistration({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.dob,
    this.gender,
    this.nationalId,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContact,
  });

  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final DateTime? dob;
  final Gender? gender;
  final String? nationalId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContact;
}

/// The response to starting password recovery. Identical in shape whether or
/// not the identifier matched an account, so it can't be used to discover
/// which emails or national IDs are registered.
class RecoveryChallenge {
  const RecoveryChallenge({
    required this.challengeId,
    required this.expiresAt,
    required this.selfService,
  });

  /// Quoted back with the code. Knowing it is useless without the code.
  final String challengeId;
  final DateTime expiresAt;

  /// False when no delivery channel exists: the request went to an
  /// administrator to verify in person instead, and there is no code to
  /// enter.
  final bool selfService;
}

abstract interface class AuthRepository {
  /// Verify credentials and return the account. [email] is matched against the
  /// account email *or* the national ID (the FirstSemMyHealth login accepts
  /// "email or CPR"). [AuthFailure] on mismatch or inactive account.
  ///
  /// Success establishes the authenticated principal every repository then
  /// authorizes against.
  Future<Result<User>> login({required String email, required String password});

  /// Demo builds only: sign straight into a synthetic account (the demo
  /// account switcher). Refused in production.
  Future<Result<User>> demoSignIn(String userId);

  /// Prove the signed-in account's password again before a sensitive action,
  /// or to resume after the idle warning.
  Future<Result<void>> reauthenticate(String password);

  /// End the authenticated principal. Always succeeds.
  Future<void> signOut({String reason = 'signed_out'});

  /// Create a patient account + profile, signed in.
  Future<Result<Patient>> registerPatient(PatientRegistration registration);

  /// Change the signed-in account's own password. Revokes any outstanding
  /// recovery codes.
  Future<Result<void>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Step 1 of self-service recovery: send a single-use, expiring code to
  /// the contact details already on the account. Always returns a
  /// challenge; see [RecoveryChallenge]. Throttled per device and per
  /// account.
  Future<Result<RecoveryChallenge>> startRecovery(String identifier);

  /// Step 2: redeem the code and set a new password. Fails with one generic
  /// message for a wrong, expired, reused or unknown code.
  Future<Result<void>> completeRecovery({
    required String challengeId,
    required String code,
    required String newPassword,
  });

  /// Queue a forgotten-password request for an admin to verify and resolve
  /// — the fallback when no self-service delivery channel exists.
  ///
  /// Always succeeds (an unknown identifier is silently ignored) so the
  /// response can never be used to test whether an email or national ID
  /// has an account.
  Future<Result<void>> requestPasswordReset(String identifier);
}

/// Account administration + lookups (admin screens, staff patient search).
abstract interface class UserRepository {
  Future<Result<User>> byId(String id);

  Future<Result<List<User>>> byRole(UserRole role);

  Future<Result<List<Staff>>> staffInDepartment(String departmentId);

  /// Every staff member, name-sorted — the staff directory (ported from the
  /// FirstSemMyHealth doctor "Staff Directory" view).
  Future<Result<List<Staff>>> allStaff();

  Future<Result<Staff>> staffById(String id);

  /// Set a staff member's live availability (staff dashboard presence toggle).
  Future<Result<void>> setPresence({
    required String id,
    required PresenceStatus status,
  });

  Stream<User?> watchById(String id);

  Future<Result<Staff>> createStaff({
    required String fullName,
    required String email,
    required String temporaryPassword,
    String? specialty,
    String? departmentId,
    String? licenseNo,
    String? jobTitle,
  });

  /// Create an admin account (no profile row).
  Future<Result<User>> createAdmin({
    required String fullName,
    required String email,
    required String temporaryPassword,
  });

  Future<Result<void>> setActive({required String id, required bool active});

  /// Sets or clears (pass null) the account's profile photo — a local file
  /// path, never uploaded anywhere.
  Future<Result<void>> setAvatarPath({required String id, String? avatarPath});

  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  });

  Future<Result<void>> resetPasswordAndResolve({
    required String id,
    required String newPassword,
    required String adminId,
  });

  /// User IDs with at least one unresolved [PasswordResetRequest] — an admin
  /// row shows a "reset requested" badge for these.
  Future<Result<Set<String>>> userIdsWithPendingPasswordResetRequests();

  /// Marks every unresolved password-reset request for [userId] as resolved
  /// by [staffId]. Called after the admin actually issues the new password
  /// (via [resetPassword] above) so the badge clears.
  Future<Result<void>> resolvePasswordResetRequests({
    required String userId,
    required String staffId,
  });
}
