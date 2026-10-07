import '../../core/result.dart';
import 'document_service.dart';
import 'export_repository.dart';

class DocumentPolicyDraft {
  const DocumentPolicyDraft({
    required this.id,
    required this.document,
    required this.version,
    required this.language,
    required this.disclosure,
    required this.wording,
    required this.clinicalSignatureRequired,
  });
  final String id, language, wording;
  final ExportDocument document;
  final int version;
  final DisclosureProfile disclosure;
  final bool clinicalSignatureRequired;
}

class DocumentPolicy {
  const DocumentPolicy({
    required this.draft,
    this.approvedAt,
    this.approvedByName,
    this.retiredAt,
  });
  final DocumentPolicyDraft draft;
  final DateTime? approvedAt, retiredAt;
  final String? approvedByName;
}

abstract interface class DocumentPolicyRepository {
  /// Administrators may review proposals before requesting a template grant.
  Future<Result<List<DocumentPolicy>>> forReview();

  /// Explicit clinic template grant. New versions start unapproved.
  /// expectedWording protects edited drafts; createOnly prevents overwriting
  /// another administrator's concurrently created version.
  Future<Result<void>> saveDraft(
    DocumentPolicyDraft draft, {
    String? expectedWording,
    bool createOnly = false,
  });

  /// Clinic administrator, clinic template grant and recent authentication.
  /// Records acceptance; approval never alters an already-approved version.
  /// The reviewed snapshot must still match. Superseding an older policy and
  /// appending approval/retirement audits commit in the same transaction.
  Future<Result<void>> approve(
    String templateId, {
    required DocumentPolicyDraft expectedDraft,
  });
}
