import 'dart:typed_data';

import '../../core/result.dart';
import 'export_repository.dart';

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
    this.documentType = ExportDocument.sickLeaveCertificate,
  });
  final String patientId, appointmentId, templateId, idempotencyKey;
  final Map<String, Object?> content;
  final ExportDocument documentType;
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
    this.deliveryStatus = 'pending',
    this.deliveryAttempts = 0,
    this.requestId = '',
    this.supersedesId,
    this.documentType = ExportDocument.sickLeaveCertificate,
    this.language = 'en',
    this.issuedAt,
  });
  final String id, patientId, verificationCode;
  final DocumentValidity validity;
  final DocumentRenderStatus renderStatus;
  final String deliveryStatus;
  final int deliveryAttempts;
  final String requestId;
  final String? supersedesId;
  final ExportDocument documentType;
  final String language;
  final DateTime? issuedAt;
}

class DocumentVisit {
  const DocumentVisit(this.id, this.date);
  final String id;
  final DateTime date;
}

class DocumentTemplateChoice {
  const DocumentTemplateChoice(
    this.id,
    this.language,
    this.disclosure,
    this.approved, {
    this.documentType = ExportDocument.sickLeaveCertificate,
  });
  final String id, language;
  final DisclosureProfile disclosure;
  final bool approved;
  final ExportDocument documentType;
}

class DocumentReviewItem {
  const DocumentReviewItem(this.request, this.visitId, this.content);
  final DocumentRequest request;
  final String visitId;
  final Map<String, Object?> content;
}

class DocumentWorkspace {
  const DocumentWorkspace({
    required this.patientName,
    required this.visits,
    required this.templates,
    required this.requests,
    required this.issued,
    this.sources = const [],
  });
  final String patientName;
  final List<DocumentVisit> visits;
  final List<DocumentTemplateChoice> templates;
  final List<DocumentReviewItem> requests;
  final List<IssuedDocument> issued;
  final List<DocumentSourceChoice> sources;
}

class DocumentSourceChoice {
  const DocumentSourceChoice(
    this.id,
    this.visitId,
    this.documentType,
    this.title, {
    this.released = false,
  });
  final String id, visitId, title;
  final ExportDocument documentType;
  final bool released;
}

/// Contract for Task 4; no screen may bypass these boundaries.
abstract interface class DocumentService {
  Future<Result<void>> releaseSource(
    String recordId, {
    required bool released,
    required String reason,
  });
  Future<Result<Uint8List>> exportVerificationManifest();
  Stream<List<IssuedDocument>> watchForPatient(String patientId);
  Future<Result<DocumentWorkspace>> workspace(String patientId);
  Future<Result<Uint8List>> preview(String requestId);
  Future<Result<DocumentRequest>> prepareReplacement(
    String issuedVersionId, {
    required int expectedVersion,
    required Map<String, Object?> content,
    required String reason,
    String? templateId,
  });
  Future<Result<void>> deliver(String issuedVersionId);
  Future<Result<DocumentRequest>> submit(
    String requestId, {
    required int expectedVersion,
  });

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
