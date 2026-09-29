/// Document export contract (Phase 5): every PDF or original-file export is
/// authorized against the signed-in account and recorded in the audit log.
library;

import '../../core/result.dart';

enum ExportDocument {
  vitalsReport,
  radiologyReport,
  referralLetter,
  sickLeaveCertificate,
  recordSummary,
  originalFile,
}

abstract interface class ExportRepository {
  /// Confirms the signed-in account may export [document] about
  /// [patientId] — the patient, a proxy with access, or a clinician with a
  /// care relationship — and audits it. Call before building the document;
  /// a denial means nothing is built.
  Future<Result<void>> authorizeExport({
    required String patientId,
    required ExportDocument document,
    String? entityId,
  });
}
