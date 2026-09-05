/// Patient + department contracts (P1-11).
library;

import '../../core/result.dart';
import '../entities/entities.dart';

abstract interface class PatientRepository {
  Future<Result<Patient>> byId(String id);

  /// Free-text search over name / national id (staff patient search, P5-06).
  Future<Result<List<Patient>>> search(String query, {int limit});

  Future<Result<List<Patient>>> all({int limit, int offset});

  Future<Result<void>> updateProfile(Patient patient);

  /// Linked family members (redesign v2 patient dashboard: Family Network).
  Future<Result<List<FamilyMember>>> familyMembers(String patientId);

  Future<Result<void>> addFamilyMember(String patientId, FamilyMember member);

  Future<Result<void>> updateFamilyMember(
    String patientId,
    FamilyMember member,
  );

  Future<Result<void>> removeFamilyMember(String patientId, String memberId);
}

abstract interface class DepartmentRepository {
  Future<Result<List<Department>>> all();

  Future<Result<Department>> byId(String id);

  Future<Result<void>> upsert(Department department);

  /// Remove a department. Fails with [ValidationFailure] while staff or
  /// appointments are still assigned to it.
  Future<Result<void>> delete(String id);
}
