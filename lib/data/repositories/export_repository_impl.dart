/// Drift-backed [ExportRepository] (Phase 5).
library;

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/repositories/export_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl(AppDatabase db, {AccessPolicy? access})
    : _db = db,
      _access = access ?? AccessPolicy.unenforced(db);

  final AppDatabase _db;
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
      if (document != ExportDocument.vitalsReport) {
        if (entityId == null) {
          throw const ValidationFailure('Choose the document to export.');
        }
        final String? owner;
        switch (document) {
          case ExportDocument.sickLeaveCertificate:
            owner =
                (await (_db.select(
                      _db.sickLeaveCertificates,
                    )..where((r) => r.id.equals(entityId))).getSingleOrNull())
                    ?.patientId;
          case ExportDocument.visitSummary:
            owner =
                (await (_db.select(
                      _db.appointments,
                    )..where((r) => r.id.equals(entityId))).getSingleOrNull())
                    ?.patientId;
          default:
            owner =
                (await (_db.select(
                      _db.medicalRecords,
                    )..where((r) => r.id.equals(entityId))).getSingleOrNull())
                    ?.patientId;
        }
        if (owner != patientId) {
          throw const AccessDeniedFailure(
            'This document does not belong to the intended patient.',
          );
        }
      }
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
