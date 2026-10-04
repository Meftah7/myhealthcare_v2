/// Verification codes for issued documents: each sick-leave certificate or
/// referral letter carries a short code (and QR) that clinic staff can look
/// up to confirm the paper is genuine and says what the record says.
library;

import '../../core/result.dart';
import 'export_repository.dart';

/// What a genuine document states, as recorded when it was issued.
class DocumentVerification {
  const DocumentVerification({
    required this.code,
    required this.documentType,
    required this.patientName,
    required this.issuer,
    required this.summary,
    required this.issuedAt,
  });

  final String code;
  final ExportDocument documentType;
  final String patientName;
  final String issuer;

  /// One fact per line (dates, reason, destination…).
  final List<String> summary;
  final DateTime issuedAt;
}

abstract interface class DocumentVerificationRepository {
  /// Records an issued document and returns its code. Exporting the same
  /// document again returns the same code; if its content changed, the
  /// record is updated so a lookup always shows the current version.
  /// Allowed for anyone who may export the document.
  Future<Result<String>> issue({
    required ExportDocument document,
    required String entityId,
    required String patientId,
    required String issuer,
    required List<String> summary,
  });

  /// Looks up [code] (case and dashes ignored). Null when no such document
  /// was issued. Clinic staff and admins only.
  Future<Result<DocumentVerification?>> verify(String code);
}
