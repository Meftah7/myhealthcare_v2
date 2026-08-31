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

abstract interface class AuthRepository {
  /// Verify credentials and return the account. [AuthFailure] on mismatch or
  /// inactive account.
  Future<Result<User>> login({required String email, required String password});

  /// Create a patient account + profile.
  Future<Result<Patient>> registerPatient(PatientRegistration registration);

  Future<Result<void>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });
}

/// Account administration + lookups (admin screens, staff patient search).
abstract interface class UserRepository {
  Future<Result<User>> byId(String id);

  Future<Result<List<User>>> byRole(UserRole role);

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

  Future<Result<void>> setActive({required String id, required bool active});

  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  });
}
