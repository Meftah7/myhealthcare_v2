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
}

abstract interface class DepartmentRepository {
  Future<Result<List<Department>>> all();

  Future<Result<Department>> byId(String id);

  Future<Result<void>> upsert(Department department);
}
