import 'dart:typed_data';

import '../../core/result.dart';

enum DocumentRequestStatus { draft, submitted, approved, rejected, issued }

enum DocumentValidity { legacy, valid, superseded, revoked }

enum DocumentRenderStatus { pending, ready, failed }

enum DisclosureProfile { clinic, employer, school }

class PrepareDocument {
  const PrepareDocument({
    required this.patientId,
    required this.appointmentId,
    required this.templateId,
    required this.content,
    required this.idempotencyKey,
  });
  final String patientId, appointmentId, templateId, idempotencyKey;
  final Map<String, Object?> content;
}

class DocumentRequest {
  const DocumentRequest({
    required this.id,
    required this.patientId,
    required this.templateId,
    required this.status,
    required this.version,
  });
  final String id, patientId, templateId;
  final DocumentRequestStatus status;
  final int version;
}

class IssuedDocument {
  const IssuedDocument({
    required this.id,
    required this.patientId,
    required this.verificationCode,
    required this.validity,
    required this.renderStatus,
  });
  final String id, patientId, verificationCode;
  final DocumentValidity validity;
  final DocumentRenderStatus renderStatus;
}

/// Contract for Task 4; no screen may bypass these boundaries.
abstract interface class DocumentService {
  /// Validate actual subject/visit and scoped preparation authority. Commit
  /// request and audit atomically; retry keys must match the original payload.
  Future<Result<DocumentRequest>> prepare(PrepareDocument input);

  /// Optimistic version check, current qualifications, approved template and
  /// disclosure validation. Persist approval and audit in one transaction.
  Future<Result<DocumentRequest>> approve(
    String requestId, {
    required int expectedVersion,
  });

  /// Freeze identity/content/template/qualification snapshots. Commit the
  /// issued version, verification binding, issue audit and pending delivery
  /// event together. Retries return the same version. Rendering follows commit.
  Future<Result<IssuedDocument>> issue(
    String requestId, {
    required int expectedVersion,
    required String idempotencyKey,
  });

  /// Store bytes/fingerprint atomically; failure keeps the issued identity
  /// with explicit failed render state, never a ready official copy.
  Future<Result<IssuedDocument>> render(String issuedVersionId);

  /// Self/proxy clinical access or explicit scoped reprint permission.
  /// Return stored bytes only, after fresh authorization and reprint audit.
  Future<Result<Uint8List>> download(String issuedVersionId);

  /// Scoped authority + reason; revoke verification and audit atomically.
  Future<Result<void>> revoke(String issuedVersionId, {required String reason});
}
