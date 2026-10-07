import '../../core/result.dart';

class RecordCorrection {
  const RecordCorrection({
    required this.id,
    required this.recordId,
    required this.reason,
    required this.createdAt,
    required this.status,
  });
  final String id;
  final String recordId;
  final String reason;
  final DateTime createdAt;
  final String status;
}

abstract interface class RecordActivityRepository {
  Future<Result<Set<String>>> readIds(String patientId);
  Future<Result<void>> setRead(String recordId, {required bool read});
  Future<Result<List<RecordCorrection>>> corrections(String recordId);
  Future<Result<RecordCorrection>> requestCorrection(
    String recordId,
    String reason,
  );
}
