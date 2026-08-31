/// Staff task + risk flag contracts (P1-11).
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

abstract interface class TaskRepository {
  Future<Result<List<StaffTask>>> forStaff(String staffId, {bool openOnly});

  Stream<List<StaffTask>> watchForStaff(String staffId, {bool openOnly});

  Future<Result<void>> upsert(StaffTask task);

  Future<Result<void>> setStatus(String id, TaskStatus status);

  /// Writes AI priority + rationale onto an existing task (P5-10).
  Future<Result<void>> applyAiPriority({
    required String id,
    required double score,
    required String rationale,
  });
}

abstract interface class RiskRepository {
  Future<Result<List<RiskFlag>>> forPatient(String patientId);

  Future<Result<List<RiskFlag>>> unacknowledged();

  Stream<List<RiskFlag>> watchUnacknowledged();

  /// Insert or refresh a flag, keyed by [RiskFlag.dedupeKey] so the same
  /// finding isn't recorded twice (P5-02).
  Future<Result<void>> upsertByDedupeKey(RiskFlag flag);

  Future<Result<void>> acknowledge({
    required String id,
    required String staffId,
  });
}
