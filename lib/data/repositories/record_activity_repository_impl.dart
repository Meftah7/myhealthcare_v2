import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/record_activity_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class RecordActivityRepositoryImpl implements RecordActivityRepository {
  RecordActivityRepositoryImpl(this._db, this._access);
  final AppDatabase _db;
  final AccessPolicy _access;

  Future<String> _viewer() async {
    final actor = await _access.principal();
    if (actor == null || !actor.isPatient) throw const AccessDeniedFailure();
    return actor.accountId;
  }

  Future<MedicalRecordRow> _record(String id) async {
    final row = await (_db.select(
      _db.medicalRecords,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Record not found.');
    await _access.readPatient(
      row.patientId,
      entityType: 'record',
      entityId: id,
    );
    return row;
  }

  @override
  Future<Result<Set<String>>> readIds(String patientId) => Result.guardAsync(
    () async {
      final viewer = await _viewer();
      await _access.readPatient(patientId, entityType: 'record');
      final rows =
          await (_db.select(_db.recordReads).join([
                innerJoin(
                  _db.medicalRecords,
                  _db.medicalRecords.id.equalsExp(_db.recordReads.recordId),
                ),
              ])..where(
                _db.medicalRecords.patientId.equals(patientId) &
                    _db.recordReads.accountId.equals(viewer),
              ))
              .get();
      return {for (final row in rows) row.readTable(_db.recordReads).recordId};
    },
  );

  @override
  Future<Result<void>> setRead(String recordId, {required bool read}) =>
      Result.guardAsync(() async {
        final viewer = await _viewer();
        await _record(recordId);
        if (read) {
          await _db
              .into(_db.recordReads)
              .insertOnConflictUpdate(
                RecordReadsCompanion.insert(
                  recordId: recordId,
                  accountId: viewer,
                  readAt: DateTime.now(),
                ),
              );
        } else {
          await (_db.delete(_db.recordReads)..where(
                (r) => r.recordId.equals(recordId) & r.accountId.equals(viewer),
              ))
              .go();
        }
      });

  @override
  Future<Result<List<RecordCorrection>>> corrections(String recordId) =>
      Result.guardAsync(() async {
        await _record(recordId);
        final rows =
            await (_db.select(_db.recordCorrections)
                  ..where((r) => r.recordId.equals(recordId))
                  ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
                .get();
        return [for (final row in rows) _from(row)];
      });

  RecordCorrection _from(RecordCorrectionRow row) => RecordCorrection(
    id: row.id,
    recordId: row.recordId,
    reason: row.reason,
    createdAt: row.createdAt,
    status: row.status,
  );

  @override
  Future<Result<RecordCorrection>> requestCorrection(
    String recordId,
    String reason,
  ) => Result.guardAsync(() async {
    final text = reason.trim();
    if (text.isEmpty || text.length > 2000) {
      throw const ValidationFailure(
        'Enter a correction request of 1–2000 characters.',
      );
    }
    return _db.transaction(() async {
      final record = await _record(recordId);
      final subject = await _access.actForPatient(
        record.patientId,
        Permission.requestRecordCorrection,
        entityType: 'record',
        entityId: recordId,
      );
      // A lost-response retry does not submit the same pending request twice.
      final prior =
          await (_db.select(_db.recordCorrections)
                ..where(
                  (r) =>
                      r.recordId.equals(recordId) &
                      r.requestedByAccountId.equals(subject.actingAccountId) &
                      r.reason.equals(text) &
                      r.status.equals('pending'),
                )
                ..limit(1))
              .getSingleOrNull();
      if (prior != null) return _from(prior);
      final id = newId('correction');
      await _db
          .into(_db.recordCorrections)
          .insert(
            RecordCorrectionsCompanion.insert(
              id: id,
              recordId: recordId,
              patientId: record.patientId,
              requestedByAccountId: subject.actingAccountId,
              reason: text,
              createdAt: DateTime.now(),
            ),
          );
      await _access.audit(
        'record.correction.request',
        entityType: 'record',
        entityId: recordId,
        subjectPatientId: record.patientId,
      );
      return _from(
        await (_db.select(
          _db.recordCorrections,
        )..where((r) => r.id.equals(id))).getSingle(),
      );
    });
  });
}
