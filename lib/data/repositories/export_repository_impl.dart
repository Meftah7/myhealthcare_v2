/// Drift-backed [ExportRepository] (Phase 5).
library;

import '../../core/result.dart';
import '../../domain/repositories/export_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl(AppDatabase db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(db);

  final AccessPolicy _access;

  @override
  Future<Result<void>> authorizeExport({
    required String patientId,
    required ExportDocument document,
    String? entityId,
  }) {
    return Result.guardAsync(() async {
      // Clinical scope: an export carries clinical content, so it needs the
      // same access as reading the chart itself.
      await _access.readPatient(
        patientId,
        entityType: 'export',
        entityId: entityId,
      );
      await _access.audit(
        'document.export',
        entityType: 'export',
        entityId: entityId,
        subjectPatientId: patientId,
        detail: document.name,
      );
    });
  }
}
