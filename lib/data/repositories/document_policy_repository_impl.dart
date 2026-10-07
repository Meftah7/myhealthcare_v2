import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/document_policy_repository.dart';
import '../../domain/repositories/document_service.dart';
import '../../domain/repositories/export_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class DocumentPolicyRepositoryImpl implements DocumentPolicyRepository {
  DocumentPolicyRepositoryImpl(this._db, this._access);
  final AppDatabase _db;
  final AccessPolicy _access;

  void _validateWording(DocumentPolicyDraft draft) {
    if (draft.document != ExportDocument.sickLeaveCertificate) return;
    const requiredFields = {
      'clinicName',
      'patientName',
      'visitDate',
      'leaveStart',
      'leaveEnd',
      'issuerName',
      'license',
      'verificationCode',
    };
    final fields = RegExp(
      r'\{([^{}]+)\}',
    ).allMatches(draft.wording).map((m) => m.group(1)!).toSet();
    final allowed = {
      ...requiredFields,
      if (draft.disclosure == DisclosureProfile.clinic) 'diagnosis',
    };
    if (!fields.containsAll(requiredFields) || !allowed.containsAll(fields)) {
      throw const ValidationFailure(
        'Keep the required identity, dates, signer and verification fields. Clinical fields are only allowed in the clinic copy.',
      );
    }
  }

  @override
  Future<Result<List<DocumentPolicy>>> forReview() =>
      Result.guardAsync(() async {
        await _access.require(
          Permission.manageSettings,
          entityType: 'document_template',
        );
        final rows =
            await (_db.select(_db.documentTemplates)..orderBy([
                  (t) => OrderingTerm.asc(t.documentType),
                  (t) => OrderingTerm.asc(t.language),
                  (t) => OrderingTerm.asc(t.disclosureProfile),
                  (t) => OrderingTerm.desc(t.version),
                ]))
                .get();
        final approvers =
            await (_db.selectOnly(_db.users)
                  ..addColumns([_db.users.id, _db.users.fullName])
                  ..where(
                    _db.users.id.isIn(
                      rows.map((r) => r.approvedBy).whereType<String>(),
                    ),
                  ))
                .get();
        final names = {
          for (final row in approvers)
            row.read(_db.users.id)!: row.read(_db.users.fullName)!,
        };
        return [
          for (final row in rows)
            DocumentPolicy(
              draft: DocumentPolicyDraft(
                id: row.id,
                document: ExportDocument.values.byName(row.documentType),
                version: row.version,
                language: row.language,
                disclosure: DisclosureProfile.values.byName(
                  row.disclosureProfile,
                ),
                wording: row.wording,
                clinicalSignatureRequired: row.clinicalSignatureRequired,
              ),
              approvedAt: row.approvedAt,
              approvedByName: names[row.approvedBy],
              retiredAt: row.retiredAt,
            ),
        ];
      });
  @override
  Future<Result<void>> saveDraft(
    DocumentPolicyDraft draft, {
    String? expectedWording,
    bool createOnly = false,
  }) => Result.guardAsync(() async {
    await _access.requireScoped(Permission.manageDocumentTemplates);
    _validateWording(draft);
    if (draft.id.trim().isEmpty ||
        draft.version < 1 ||
        !{'en', 'ar'}.contains(draft.language) ||
        draft.wording.trim().isEmpty ||
        draft.document == ExportDocument.originalFile ||
        (draft.document == ExportDocument.sickLeaveCertificate &&
            !draft.clinicalSignatureRequired)) {
      throw const ValidationFailure(
        'Provide a versioned template and required clinical signing rule.',
      );
    }
    await _db.transaction(() async {
      final old = await (_db.select(
        _db.documentTemplates,
      )..where((t) => t.id.equals(draft.id))).getSingleOrNull();
      if ((createOnly && old != null) ||
          (expectedWording != null && old?.wording != expectedWording)) {
        throw const ConflictFailure(
          'This policy changed. Reload before saving.',
        );
      }
      if (old?.approvedAt != null) {
        throw const ConflictFailure(
          'Approved templates require a new version.',
        );
      }
      if (old != null &&
          (old.documentType != draft.document.name ||
              old.version != draft.version ||
              old.language != draft.language ||
              old.disclosureProfile != draft.disclosure.name)) {
        throw const ConflictFailure(
          'Template identity cannot change. Create a new version.',
        );
      }
      await _db
          .into(_db.documentTemplates)
          .insertOnConflictUpdate(
            DocumentTemplatesCompanion.insert(
              id: draft.id,
              documentType: draft.document.name,
              version: draft.version,
              language: draft.language,
              disclosureProfile: draft.disclosure.name,
              wording: draft.wording.trim(),
              clinicalSignatureRequired: draft.clinicalSignatureRequired,
              requiredCredential: Value(
                draft.clinicalSignatureRequired
                    ? CredentialKind.medicalLicense.name
                    : null,
              ),
            ),
          );
      await _access.audit(
        'document.policy.draft',
        entityType: 'document_template',
        entityId: draft.id,
      );
    });
  });

  @override
  Future<Result<void>> approve(
    String templateId, {
    required DocumentPolicyDraft expectedDraft,
  }) => Result.guardAsync(() async {
    final actor = await _access.require(
      Permission.manageSettings,
      entityType: 'document_template',
      entityId: templateId,
    );
    await _access.requireScoped(Permission.manageDocumentTemplates);
    await _access.requireRecentAuthentication();
    if (actor == null || !actor.isAdmin) throw const AccessDeniedFailure();
    await _db.transaction(() async {
      final template = await (_db.select(
        _db.documentTemplates,
      )..where((t) => t.id.equals(templateId))).getSingleOrNull();
      if (template == null) throw const NotFoundFailure('Template not found.');
      _validateWording(expectedDraft);
      if (template.id != expectedDraft.id ||
          template.wording != expectedDraft.wording ||
          template.version != expectedDraft.version ||
          template.language != expectedDraft.language ||
          template.documentType != expectedDraft.document.name ||
          template.disclosureProfile != expectedDraft.disclosure.name ||
          template.clinicalSignatureRequired !=
              expectedDraft.clinicalSignatureRequired) {
        throw const ConflictFailure(
          'The policy changed after review. Reload and review again.',
        );
      }
      if (template.retiredAt != null) {
        throw const ValidationFailure('A retired template cannot be approved.');
      }
      if (template.approvedAt != null) return;
      final newer =
          await (_db.select(_db.documentTemplates)
                ..where(
                  (t) =>
                      t.documentType.equals(template.documentType) &
                      t.language.equals(template.language) &
                      t.disclosureProfile.equals(template.disclosureProfile) &
                      t.version.isBiggerThanValue(template.version) &
                      t.approvedAt.isNotNull(),
                )
                ..limit(1))
              .getSingleOrNull();
      if (newer != null) {
        throw const ConflictFailure(
          'A newer policy version is already approved.',
        );
      }
      final previous =
          await (_db.select(_db.documentTemplates)..where(
                (t) =>
                    t.documentType.equals(template.documentType) &
                    t.language.equals(template.language) &
                    t.disclosureProfile.equals(template.disclosureProfile) &
                    t.version.isSmallerThanValue(template.version) &
                    t.approvedAt.isNotNull() &
                    t.retiredAt.isNull(),
              ))
              .get();
      for (final old in previous) {
        await (_db.update(
          _db.documentTemplates,
        )..where((t) => t.id.equals(old.id))).write(
          DocumentTemplatesCompanion(retiredAt: Value(DateTime.now())),
        );
        await _access.audit(
          'document.policy.supersede',
          entityType: 'document_template',
          entityId: old.id,
          detail: template.id,
        );
      }
      await (_db.update(
        _db.documentTemplates,
      )..where((t) => t.id.equals(templateId))).write(
        DocumentTemplatesCompanion(
          approvedBy: Value(actor.accountId),
          approvedAt: Value(DateTime.now()),
        ),
      );
      await _access.audit(
        'document.policy.approve',
        entityType: 'document_template',
        entityId: templateId,
      );
    });
  });
}
