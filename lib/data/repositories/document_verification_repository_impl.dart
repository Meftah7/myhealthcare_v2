/// Drift-backed [DocumentVerificationRepository].
library;

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/document_service.dart';
import '../../domain/repositories/document_verification_repository.dart';
import '../../domain/repositories/export_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class DocumentVerificationRepositoryImpl
    implements DocumentVerificationRepository {
  DocumentVerificationRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  // No 0/O or 1/I/L, so a code read off paper is typed correctly.
  static const _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static final _random = Random.secure();

  static String _newCode() => List.generate(
    10,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();

  /// `ABCDE-FGHJK` for printing.
  static String format(String code) =>
      code.length == 10 ? '${code.substring(0, 5)}-${code.substring(5)}' : code;

  static String _normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  @override
  Future<Result<String>> issue({
    required ExportDocument document,
    required String entityId,
    required String patientId,
    required String issuer,
    required List<String> summary,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(
        patientId,
        entityType: 'document_verification',
        entityId: entityId,
      );
      final text = summary.join('\n');
      return _db.transaction(() async {
        final existing =
            await (_db.select(_db.documentVerifications)..where(
                  (v) =>
                      v.documentType.equals(document.name) &
                      v.entityId.equals(entityId),
                ))
                .getSingleOrNull();
        if (existing != null) {
          if (existing.patientId != patientId) {
            throw const AccessDeniedFailure();
          }
          if (existing.issuedVersionId != null) {
            throw const ConflictFailure(
              'Issued versions cannot be changed by a legacy export.',
            );
          }
          if (existing.summary != text || existing.issuer != issuer) {
            await (_db.update(
              _db.documentVerifications,
            )..where((v) => v.code.equals(existing.code))).write(
              DocumentVerificationsCompanion(
                summary: Value(text),
                issuer: Value(issuer),
                issuedAt: Value(DateTime.now()),
              ),
            );
          }
          return format(existing.code);
        }
        final code = _newCode();
        await _db
            .into(_db.documentVerifications)
            .insert(
              DocumentVerificationsCompanion.insert(
                code: code,
                documentType: document.name,
                entityId: entityId,
                patientId: patientId,
                issuer: issuer,
                summary: text,
                issuedAt: DateTime.now(),
              ),
            );
        return format(code);
      });
    });
  }

  @override
  Future<Result<String>> bindIssuedVersion(
    String issuedVersionId,
  ) => Result.guardAsync(() async {
    final version = await (_db.select(
      _db.issuedDocumentVersions,
    )..where((v) => v.id.equals(issuedVersionId))).getSingleOrNull();
    if (version == null) {
      throw const NotFoundFailure('Issued version not found.');
    }
    final request = await (_db.select(
      _db.documentRequests,
    )..where((r) => r.id.equals(version.requestId))).getSingle();
    final template = await (_db.select(
      _db.documentTemplates,
    )..where((t) => t.id.equals(version.templateId))).getSingle();
    final clinical = template.clinicalSignatureRequired;
    final actor = clinical
        ? await _access.requireClinicalDocumentSigner(
            patientId: version.patientId,
            appointmentId: request.appointmentId ?? '',
          )
        : await _access.requireScoped(
            Permission.issueAdministrativeDocument,
            patientId: version.patientId,
            appointmentId: request.appointmentId,
          );
    if (actor == null || actor.accountId != version.issuerAccountId) {
      throw const AccessDeniedFailure();
    }
    if (template.approvedAt == null ||
        template.approvedBy == null ||
        template.retiredAt != null ||
        request.patientId != version.patientId ||
        request.templateId != template.id ||
        !{'approved', 'issued'}.contains(request.status) ||
        version.documentType != template.documentType ||
        version.language != template.language ||
        version.disclosureProfile != template.disclosureProfile ||
        (version.documentType == ExportDocument.sickLeaveCertificate.name &&
            !clinical)) {
      throw const ValidationFailure(
        'An approved matching policy and request are required.',
      );
    }
    final patient =
        jsonDecode(version.patientSnapshotJson) as Map<String, dynamic>;
    final issuer =
        jsonDecode(version.issuerSnapshotJson) as Map<String, dynamic>;
    if (patient['id'] != version.patientId ||
        issuer['accountId'] != version.issuerAccountId ||
        patient['name'] is! String ||
        issuer['name'] is! String) {
      throw const ValidationFailure('Issued identity snapshots do not match.');
    }
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.documentVerifications)
                ..where((v) => v.issuedVersionId.equals(issuedVersionId)))
              .getSingleOrNull();
      if (existing != null) return format(existing.code);
      if (version.supersedesId case final previousId?) {
        final previous = await (_db.select(
          _db.issuedDocumentVersions,
        )..where((v) => v.id.equals(previousId))).getSingleOrNull();
        if (previous == null ||
            previous.patientId != version.patientId ||
            previous.requestId != version.requestId ||
            previous.version >= version.version) {
          throw const ValidationFailure(
            'Replacement must refer to an earlier version of the same request.',
          );
        }
        await (_db.update(_db.documentVerifications)..where(
              (v) =>
                  v.issuedVersionId.equals(previousId) &
                  v.validity.equals(DocumentValidity.valid.name),
            ))
            .write(
              const DocumentVerificationsCompanion(
                validity: Value('superseded'),
              ),
            );
      }
      final code = _newCode();
      await _db
          .into(_db.documentVerifications)
          .insert(
            DocumentVerificationsCompanion.insert(
              code: code,
              documentType: version.documentType,
              entityId: version.id,
              patientId: version.patientId,
              issuer: issuer['name'] as String,
              summary: version.contentJson,
              issuedAt: version.issuedAt,
              issuedVersionId: Value(version.id),
              validity: const Value('valid'),
            ),
          );
      await _access.audit(
        'document.verification.bind',
        entityType: 'issued_document',
        entityId: version.id,
        subjectPatientId: version.patientId,
      );
      return format(code);
    });
  });

  @override
  Future<Result<void>> revokeIssuedVersion(
    String issuedVersionId, {
    required String reason,
  }) => Result.guardAsync(() async {
    final version = await (_db.select(
      _db.issuedDocumentVersions,
    )..where((v) => v.id.equals(issuedVersionId))).getSingleOrNull();
    if (version == null) {
      throw const NotFoundFailure('Issued version not found.');
    }
    final request = await (_db.select(
      _db.documentRequests,
    )..where((r) => r.id.equals(version.requestId))).getSingle();
    final actor = await _access.requireScoped(
      Permission.revokeDocument,
      patientId: version.patientId,
      appointmentId: request.appointmentId,
    );
    await _access.requireRecentAuthentication();
    if (actor == null) throw const AccessDeniedFailure();
    if (reason.trim().isEmpty || reason.length > 2000) {
      throw const ValidationFailure('Enter a revocation reason.');
    }
    await _db.transaction(() async {
      final entry =
          await (_db.select(_db.documentVerifications)
                ..where((v) => v.issuedVersionId.equals(issuedVersionId)))
              .getSingleOrNull();
      if (entry == null) {
        throw const NotFoundFailure('Verification binding not found.');
      }
      if (entry.validity == DocumentValidity.revoked.name) return;
      await (_db.update(
        _db.documentVerifications,
      )..where((v) => v.code.equals(entry.code))).write(
        DocumentVerificationsCompanion(
          validity: const Value('revoked'),
          revokedAt: Value(DateTime.now()),
          revokedBy: Value(actor.accountId),
          revocationReason: Value(reason.trim()),
        ),
      );
      await _access.audit(
        'document.revoke',
        entityType: 'issued_document',
        entityId: version.id,
        subjectPatientId: version.patientId,
        detail: reason.trim(),
      );
    });
  });

  @override
  Future<Result<DocumentVerification?>> verify(String code) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'document_verification');
      final normalized = _normalize(code);
      final row = await (_db.select(
        _db.documentVerifications,
      )..where((v) => v.code.equals(normalized))).getSingleOrNull();
      await _access.audit(
        'document.verify',
        entityType: 'document_verification',
        entityId: normalized,
        detail: row == null ? 'not found' : row.documentType,
      );
      if (row == null) return null;
      if (row.issuedVersionId case final versionId?) {
        final version = await (_db.select(
          _db.issuedDocumentVersions,
        )..where((v) => v.id.equals(versionId))).getSingle();
        final patient =
            jsonDecode(version.patientSnapshotJson) as Map<String, dynamic>;
        // Operational verification never exposes clinical content merely
        // because the account is an administrator or document-desk worker.
        final clinical = await _access.canRead(row.patientId);
        return DocumentVerification(
          code: format(row.code),
          documentType: ExportDocument.values.byName(row.documentType),
          patientName: patient['name'] as String,
          issuer: row.issuer,
          summary: clinical ? [row.summary] : const [],
          issuedAt: row.issuedAt,
          issuedVersionId: versionId,
          validity: DocumentValidity.values.byName(row.validity),
          revocationReason: clinical ? row.revocationReason : null,
        );
      }
      final patient = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(row.patientId))).getSingleOrNull();
      return DocumentVerification(
        code: format(row.code),
        documentType: ExportDocument.values.byName(row.documentType),
        patientName: patient?.fullName ?? '—',
        issuer: row.issuer,
        summary: await _access.canRead(row.patientId)
            ? row.summary.split('\n')
            : const [],
        issuedAt: row.issuedAt,
      );
    });
  }
}
