/// Care-team assignments and staff credentials — identity relationships kept
/// apart from the account record (see `domain/identity/identity.dart`).
library;

import '../../core/result.dart';
import '../identity/identity.dart';

abstract interface class CareTeamRepository {
  /// Active and past assignments for one patient, newest first.
  Future<Result<List<CareTeamAssignment>>> forPatient(String patientId);

  /// A clinician's active assignments.
  Future<Result<List<CareTeamAssignment>>> activeForStaff(String staffId);

  /// Administrators assign a clinician to a patient's care.
  Future<Result<CareTeamAssignment>> assign({
    required String patientId,
    required String staffId,
    required CareTeamRole role,
  });

  /// End an assignment. Access that depended on it stops immediately.
  Future<Result<void>> end(String assignmentId);
}

abstract interface class StaffCredentialRepository {
  Future<Result<List<StaffCredential>>> forStaff(String staffId);

  Future<Result<StaffCredential>> record({
    required String staffId,
    required CredentialKind kind,
    required String identifier,
    String? issuer,
    DateTime? validUntil,
  });

  Future<Result<void>> revoke(String credentialId);
}
