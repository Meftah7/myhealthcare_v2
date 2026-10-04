/// Drift-backed [DocumentVerificationRepository].
library;

import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/result.dart';
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
      final patient = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(row.patientId))).getSingleOrNull();
      return DocumentVerification(
        code: format(row.code),
        documentType: ExportDocument.values.byName(row.documentType),
        patientName: patient?.fullName ?? '—',
        issuer: row.issuer,
        summary: row.summary.split('\n'),
        issuedAt: row.issuedAt,
      );
    });
  }
}
