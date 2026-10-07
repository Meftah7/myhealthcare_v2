/// Drift-backed [RecordRepository], [VitalsRepository], [MedicationRepository]
/// (P1-14, P1-15).
library;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/clinical/lab_rules.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/record_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import '../sync/idempotency.dart';
import 'mappers.dart';
import 'result_review_repository_impl.dart';

AbnormalFlag classifyLab(
  double value, {
  double? refLow,
  double? refHigh,
  double? criticalLow,
  double? criticalHigh,
}) => LabRules.classify(
  value,
  refLow: refLow,
  refHigh: refHigh,
  criticalLow: criticalLow,
  criticalHigh: criticalHigh,
);

class RecordRepositoryImpl implements RecordRepository {
  RecordRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<MedicalRecord>>> forAppointment(
    String patientId,
    String appointmentId,
  ) => Result.guardAsync(() async {
    await _access.readPatient(patientId, entityType: 'medical_record');
    final rows =
        await (_db.select(_db.medicalRecords)
              ..where(
                (r) =>
                    r.patientId.equals(patientId) &
                    r.appointmentId.equals(appointmentId),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]))
            .get();
    return _hydrate(rows);
  });

  Future<List<MedicalRecord>> _hydrate(List<MedicalRecordRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final labs = await (_db.select(
      _db.labValues,
    )..where((l) => l.recordId.isIn(ids))).get();
    final byRecord = <String, List<LabValueRow>>{};
    for (final l in labs) {
      byRecord.putIfAbsent(l.recordId, () => []).add(l);
    }
    final files = await _sourceDocuments(ids);
    return rows
        .map(
          (r) => recordFrom(
            r,
            byRecord[r.id] ?? const [],
          ).copyWith(sourceDocument: files[r.id]),
        )
        .toList();
  }

  /// Metadata of stored originals — never the bytes, which can be large.
  Future<Map<String, SourceDocument>> _sourceDocuments(
    List<String> recordIds,
  ) async {
    final f = _db.documentFiles;
    final rows =
        await (_db.selectOnly(f)
              ..addColumns([
                f.id,
                f.recordId,
                f.fileName,
                f.mimeType,
                f.sizeBytes,
                f.sha256,
                f.storedAt,
              ])
              ..where(f.recordId.isIn(recordIds)))
            .get();
    return {
      for (final r in rows)
        r.read(f.recordId)!: SourceDocument(
          id: r.read(f.id)!,
          fileName: r.read(f.fileName)!,
          mimeType: r.read(f.mimeType)!,
          sizeBytes: r.read(f.sizeBytes)!,
          sha256: r.read(f.sha256)!,
          storedAt: r.read(f.storedAt)!,
        ),
    };
  }

  /// Checks an imported file before anything is written: size, and that a
  /// file claiming to be a PDF really is one.
  static void _validateSourceFile(NewSourceFile file) {
    if (file.bytes.isEmpty) {
      throw const FileFailure('The file is empty. Choose the file again.');
    }
    if (file.bytes.length > NewSourceFile.maxBytes) {
      throw const FileFailure(
        'That file is larger than 20 MB. Choose a smaller copy.',
      );
    }
    final b = file.bytes;
    final isPdf =
        b.length > 5 &&
        b[0] == 0x25 &&
        b[1] == 0x50 &&
        b[2] == 0x44 &&
        b[3] == 0x46 &&
        b[4] == 0x2D;
    if (file.mimeType == 'application/pdf' && !isPdf) {
      throw const FileFailure('That file is not a readable PDF.');
    }
  }

  SimpleSelectStatement<$MedicalRecordsTable, MedicalRecordRow> _timelineQuery(
    String patientId, {
    int? limit,
    int offset = 0,
    Set<RecordType>? types,
    String? textQuery,
  }) {
    final q = _db.select(_db.medicalRecords)
      ..where((r) => r.patientId.equals(patientId))
      // The id tie-breaker keeps pages stable when records share a time.
      ..orderBy([
        (r) => OrderingTerm.desc(r.occurredAt),
        (r) => OrderingTerm.desc(r.id),
      ]);
    if (types != null && types.isNotEmpty) {
      q.where((r) => r.recordType.isInValues(types.toList()));
    }
    if (textQuery != null && textQuery.trim().isNotEmpty) {
      final like = '%${textQuery.trim()}%';
      q.where((r) => r.title.like(like) | r.body.like(like));
    }
    if (limit != null) q.limit(limit, offset: offset);
    return q;
  }

  @override
  Future<Result<MedicalRecord>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No record $id.');
      await _access.readPatient(
        row.patientId,
        entityType: 'record',
        entityId: id,
      );
      final hydrated = await _hydrate([row]);
      return hydrated.single;
    });
  }

  @override
  Future<Result<List<MedicalRecord>>> timeline(
    String patientId, {
    int limit = 30,
    int offset = 0,
    Set<RecordType>? types,
    String? textQuery,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'record');
      final rows = await _timelineQuery(
        patientId,
        limit: limit,
        offset: offset,
        types: types,
        textQuery: textQuery,
      ).get();
      return _hydrate(rows);
    });
  }

  @override
  Future<Result<Page<MedicalRecord>>> timelinePage(
    String patientId, {
    PageRequest page = const PageRequest(),
    Set<RecordType>? types,
    String? textQuery,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'record');
      // One extra row tells us whether another page exists.
      final rows = await _timelineQuery(
        patientId,
        limit: page.size + 1,
        offset: page.offset,
        types: types,
        textQuery: textQuery,
      ).get();
      final hasMore = rows.length > page.size;
      return Page(
        items: await _hydrate(hasMore ? rows.sublist(0, page.size) : rows),
        offset: page.offset,
        hasMore: hasMore,
      );
    });
  }

  @override
  Stream<List<MedicalRecord>> watchTimeline(
    String patientId, {
    int limit = 30,
  }) {
    return authorizedStream(
      () => _access.readPatient(patientId, entityType: 'record'),
      () => _timelineQuery(patientId, limit: limit).watch().asyncMap(_hydrate),
    );
  }

  @override
  Future<Result<List<MedicalRecord>>> authoredBy(
    String staffId, {
    int limit = 100,
  }) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        staffId,
        Permission.viewOperationalReports,
        entityType: 'record',
      );
      final rows =
          await (_db.select(_db.medicalRecords)
                ..where((r) => r.authorStaffId.equals(staffId))
                ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)])
                ..limit(limit))
              .get();
      return _hydrate(rows);
    });
  }

  @override
  Future<Result<MedicalRecord>> add(NewRecord record) {
    return Result.guardAsync(() async {
      final createdBy = await _authorizeAdd(record);
      if (record.uploadedByPatient &&
          (record.sourceFacility == null ||
              record.sourceFacility!.trim().isEmpty)) {
        throw const ValidationFailure(
          'Say who issued this document (the lab, hospital or clinic).',
          fieldErrors: {'issuer': 'Required'},
        );
      }
      final file = record.sourceFile;
      if (file != null) _validateSourceFile(file);
      final id = await _db.transaction(() async {
        final prior = await IdempotencyGuard(_db).prior(
          record.idempotencyKey,
          scope: 'record.add',
          actorAccountId: createdBy,
        );
        if (prior != null) {
          final previous = await (_db.select(
            _db.medicalRecords,
          )..where((r) => r.id.equals(prior))).getSingle();
          if (previous.patientId != record.patientId) {
            throw const ConflictFailure(
              'This save attempt belongs to another patient.',
            );
          }
          return prior;
        }
        if (file != null && !record.allowDuplicate) {
          final duplicate =
              await (_db.select(_db.documentFiles).join([
                      innerJoin(
                        _db.medicalRecords,
                        _db.medicalRecords.id.equalsExp(
                          _db.documentFiles.recordId,
                        ),
                      ),
                    ])
                    ..where(
                      _db.medicalRecords.patientId.equals(record.patientId) &
                          _db.documentFiles.sha256.equals(
                            sha256.convert(file.bytes).toString(),
                          ),
                    )
                    ..limit(1))
                  .getSingleOrNull();
          if (duplicate != null) {
            throw DuplicateUploadFailure(
              duplicate.readTable(_db.documentFiles).recordId,
            );
          }
        }
        final id = newId('rec');
        await IdempotencyGuard(_db).remember(
          record.idempotencyKey,
          scope: 'record.add',
          actorAccountId: createdBy,
          resultRef: id,
        );
        await _db
            .into(_db.medicalRecords)
            .insert(
              MedicalRecordsCompanion.insert(
                id: id,
                patientId: record.patientId,
                recordType: record.recordType,
                title: record.title,
                occurredAt: record.occurredAt,
                authorStaffId: Value(record.authorStaffId),
                appointmentId: Value(record.appointmentId),
                body: Value(record.body),
                sourceFacility: Value(record.sourceFacility),
                referralUrgency: Value(record.referralUrgency),
                attachmentPath: Value(record.attachmentPath),
                uploadedByPatient: Value(record.uploadedByPatient),
                extractedText: Value(record.extractedText),
                createdByAccountId: Value(createdBy),
                // A patient import is never a reviewed clinic result.
                reviewStatus: Value(
                  record.uploadedByPatient
                      ? ImportReviewStatus.pendingReview
                      : ImportReviewStatus.notRequired,
                ),
              ),
            );
        final flags = <AbnormalFlag>[];
        for (final l in record.labValues) {
          final flag = classifyLab(
            l.value,
            refLow: l.refLow,
            refHigh: l.refHigh,
            criticalLow: l.criticalLow,
            criticalHigh: l.criticalHigh,
          );
          flags.add(flag);
          await _db
              .into(_db.labValues)
              .insert(
                LabValuesCompanion.insert(
                  id: newId('lab'),
                  recordId: id,
                  analyte: l.analyte,
                  value: l.value,
                  abnormalFlag: Value(flag),
                  unit: Value(l.unit),
                  refLow: Value(l.refLow),
                  refHigh: Value(l.refHigh),
                  source: Value(
                    l.source ??
                        (record.uploadedByPatient
                            ? 'Patient import'
                            : record.sourceFacility),
                  ),
                  provenance: Value(
                    l.criticalLow != null || l.criticalHigh != null
                        ? '${LabRules.version}; lab-supplied critical limits'
                        : LabRules.version,
                  ),
                ),
              );
        }
        if (file != null) {
          await _db
              .into(_db.documentFiles)
              .insert(
                DocumentFilesCompanion.insert(
                  id: newId('doc'),
                  recordId: id,
                  fileName: file.fileName,
                  mimeType: file.mimeType,
                  sizeBytes: file.bytes.length,
                  sha256: sha256.convert(file.bytes).toString(),
                  bytes: file.bytes,
                  storedAt: DateTime.now(),
                ),
              );
        }
        if (record.uploadedByPatient) {
          await _access.audit(
            'record.import',
            entityType: 'record',
            entityId: id,
            subjectPatientId: record.patientId,
            detail: file == null ? null : '${file.bytes.length} bytes',
          );
        }
        // An abnormal or unjudgeable result is owned work from the moment it
        // is filed — never a silent row in the chart.
        await openResultReviewIfNeeded(
          _db,
          recordId: id,
          flags: flags,
          ownerStaffId: record.authorStaffId,
        );
        return id;
      });
      final row = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(id))).getSingle();
      return (await _hydrate([row])).single;
    });
  }

  @override
  Future<Result<SourceFile>> sourceFile(String recordId) {
    return Result.guardAsync(() async {
      final record = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingleOrNull();
      if (record == null) throw const NotFoundFailure('Record not found.');
      await _access.readPatient(
        record.patientId,
        entityType: 'record',
        entityId: recordId,
      );
      final row = await (_db.select(
        _db.documentFiles,
      )..where((d) => d.recordId.equals(recordId))).getSingleOrNull();
      if (row == null) {
        throw const NotFoundFailure(
          'The original file for this record is not stored.',
        );
      }
      await _access.audit(
        'record.source.download',
        entityType: 'record',
        entityId: recordId,
        subjectPatientId: record.patientId,
      );
      return SourceFile(
        document: SourceDocument(
          id: row.id,
          fileName: row.fileName,
          mimeType: row.mimeType,
          sizeBytes: row.sizeBytes,
          sha256: row.sha256,
          storedAt: row.storedAt,
        ),
        bytes: row.bytes,
      );
    });
  }

  @override
  Future<Result<MedicalRecord>> reviewImport({
    required String recordId,
    required String staffId,
    required ImportReviewStatus decision,
    String? note,
  }) {
    return Result.guardAsync(() async {
      if (decision != ImportReviewStatus.reviewed &&
          decision != ImportReviewStatus.rejected) {
        throw const ValidationFailure('Choose to accept or reject the import.');
      }
      if (decision == ImportReviewStatus.rejected &&
          (note == null || note.trim().isEmpty)) {
        throw const ValidationFailure(
          'Say why the import is not accepted.',
          fieldErrors: {'note': 'Required'},
        );
      }
      final record = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingleOrNull();
      if (record == null) throw const NotFoundFailure('Record not found.');
      await _access.clinicalWrite(
        staffId: staffId,
        patientId: record.patientId,
        permission: Permission.writeClinicalRecord,
        entityType: 'record',
        entityId: recordId,
      );
      final changed =
          await (_db.update(_db.medicalRecords)..where(
                (r) =>
                    r.id.equals(recordId) &
                    r.reviewStatus.equalsValue(
                      ImportReviewStatus.pendingReview,
                    ),
              ))
              .write(
                MedicalRecordsCompanion(
                  reviewStatus: Value(decision),
                  reviewedByStaffId: Value(staffId),
                  reviewedAt: Value(DateTime.now()),
                  reviewNote: Value(note?.trim()),
                ),
              );
      if (changed != 1) {
        throw const ConflictFailure(
          'This record is not waiting for review (already reviewed?).',
        );
      }
      await _access.audit(
        'record.import.${decision.name}',
        entityType: 'record',
        entityId: recordId,
        subjectPatientId: record.patientId,
      );
      final row = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingle();
      return (await _hydrate([row])).single;
    });
  }

  /// Who may create which record:
  /// * a patient-imported document — the patient, or a proxy with a manage
  ///   grant (never marked as clinician-authored);
  /// * a clinical record — the authoring clinician, in a care relationship;
  /// * a referral letter — an administrator actioning a referral request.
  Future<String?> _authorizeAdd(NewRecord record) async {
    final actor = await _access.principal();
    if (actor == null) return null;
    if (record.uploadedByPatient) {
      if (record.authorStaffId != null) {
        throw const ValidationFailure(
          'A patient-imported record cannot name a clinician author.',
        );
      }
      final subject = await _access.actForPatient(
        record.patientId,
        Permission.uploadDocuments,
        entityType: 'record',
      );
      if (!subject.isSelf) {
        await _access.audit(
          'proxy.record.upload',
          entityType: 'record',
          subjectPatientId: record.patientId,
        );
      }
      return subject.actingAccountId;
    }
    if (actor.isAdmin && record.recordType == RecordType.referral) {
      await _access.require(Permission.decideReferrals, entityType: 'record');
      return actor.accountId;
    }
    await _access.clinicalWrite(
      staffId: record.authorStaffId ?? '',
      patientId: record.patientId,
      permission: Permission.writeClinicalRecord,
      entityType: 'record',
    );
    return actor.accountId;
  }
}

class VitalsRepositoryImpl implements VitalsRepository {
  VitalsRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  SimpleSelectStatement<$VitalsTable, VitalsRow> _query(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) {
    final q = _db.select(_db.vitals)
      ..where((v) => v.patientId.equals(patientId))
      ..orderBy([(v) => OrderingTerm(expression: v.recordedAt)]);
    if (from != null) q.where((v) => v.recordedAt.isBiggerOrEqualValue(from));
    if (to != null) q.where((v) => v.recordedAt.isSmallerOrEqualValue(to));
    return q;
  }

  @override
  Future<Result<List<Vitals>>> forPatient(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'vitals');
      final rows = await _query(patientId, from: from, to: to).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<Vitals>> watchForPatient(String patientId) {
    return authorizedStream(
      () => _access.readPatient(patientId, entityType: 'vitals'),
      () => _query(
        patientId,
      ).watch().map((rows) => rows.map((r) => r.toEntity()).toList()),
    );
  }

  @override
  Future<Result<Vitals>> add(Vitals v) {
    return Result.guardAsync(() async {
      // A clinician records vitals in a care relationship; a patient (or a
      // managing proxy) may log home readings, never as a clinician.
      final actor = await _access.principal();
      if (actor != null && actor.isPatient) {
        if (v.recordedByStaffId != null || v.appointmentId != null) {
          throw const ValidationFailure(
            'Home readings cannot name a clinician or clinic appointment.',
          );
        }
        await _access.actForPatient(
          v.patientId,
          Permission.uploadDocuments,
          entityType: 'vitals',
        );
      } else if (actor != null) {
        await _access.clinicalWrite(
          staffId: v.recordedByStaffId ?? '',
          patientId: v.patientId,
          permission: Permission.writeClinicalRecord,
          entityType: 'vitals',
        );
      }
      final id = v.id.isEmpty ? newId('vit') : v.id;
      if (v.appointmentId case final appointmentId?) {
        final appointment = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(appointmentId))).getSingleOrNull();
        if (appointment == null || appointment.patientId != v.patientId) {
          throw const ValidationFailure(
            'The appointment must belong to this patient.',
          );
        }
      }
      await _db
          .into(_db.vitals)
          .insert(
            VitalsCompanion.insert(
              id: id,
              patientId: v.patientId,
              recordedAt: v.recordedAt,
              appointmentId: Value(v.appointmentId),
              systolic: Value(v.systolic),
              diastolic: Value(v.diastolic),
              heartRate: Value(v.heartRate),
              tempC: Value(v.tempC),
              weightKg: Value(v.weightKg),
              heightCm: Value(v.heightCm),
              spo2: Value(v.spo2),
              glucose: Value(v.glucose),
              recordedByStaffId: Value(v.recordedByStaffId),
            ),
          );
      final row = await (_db.select(
        _db.vitals,
      )..where((r) => r.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }
}

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<Medication>>> forPatient(
    String patientId, {
    bool activeOnly = false,
  }) {
    return Result.guardAsync(() async {
      await _access.readPatient(patientId, entityType: 'medication');
      final q = _db.select(_db.medications)
        ..where((m) => m.patientId.equals(patientId))
        ..orderBy([(m) => OrderingTerm.desc(m.startDate)]);
      if (activeOnly) q.where((m) => m.isActive.equals(true));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Medication>> prescribe(Medication m) {
    return Result.guardAsync(() async {
      await _access.clinicalWrite(
        staffId: m.prescriberId ?? '',
        patientId: m.patientId,
        permission: Permission.prescribe,
        entityType: 'medication',
      );
      final id = m.id.isEmpty ? newId('med') : m.id;
      await _db
          .into(_db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: id,
              patientId: m.patientId,
              name: m.name,
              startDate: m.startDate,
              prescriberId: Value(m.prescriberId),
              appointmentId: Value(m.appointmentId),
              dose: Value(m.dose),
              frequency: Value(m.frequency),
              endDate: Value(m.endDate),
              isActive: Value(m.isActive),
            ),
          );
      final row = await (_db.select(
        _db.medications,
      )..where((r) => r.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<List<Medication>>> prescribedBy(
    String staffId, {
    int limit = 100,
  }) {
    return Result.guardAsync(() async {
      await _access.selfOrAdmin(
        staffId,
        Permission.viewOperationalReports,
        entityType: 'medication',
      );
      final rows =
          await (_db.select(_db.medications)
                ..where((m) => m.prescriberId.equals(staffId))
                ..orderBy([(m) => OrderingTerm.desc(m.startDate)])
                ..limit(limit))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<void>> discontinue(String id, DateTime endDate) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.medications,
      )..where((m) => m.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No medication $id.');
      await _access.clinicalWriteAsCurrentStaff(
        row.patientId,
        Permission.prescribe,
        entityType: 'medication',
        entityId: id,
      );
      await (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
        MedicationsCompanion(
          isActive: const Value(false),
          endDate: Value(endDate),
        ),
      );
    });
  }
}
