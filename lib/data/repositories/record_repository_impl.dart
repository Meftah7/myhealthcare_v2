/// Drift-backed [RecordRepository], [VitalsRepository], [MedicationRepository]
/// (P1-14, P1-15).
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/record_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

AbnormalFlag classifyLab(double value, {double? refLow, double? refHigh}) {
  if (refLow != null && value < refLow) {
    return value < refLow * 0.75 ? AbnormalFlag.critical : AbnormalFlag.low;
  }
  if (refHigh != null && value > refHigh) {
    return value > refHigh * 1.5 ? AbnormalFlag.critical : AbnormalFlag.high;
  }
  return AbnormalFlag.normal;
}

class RecordRepositoryImpl implements RecordRepository {
  RecordRepositoryImpl(this._db);

  final AppDatabase _db;

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
    return rows.map((r) => recordFrom(r, byRecord[r.id] ?? const [])).toList();
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
      ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]);
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
  Stream<List<MedicalRecord>> watchTimeline(
    String patientId, {
    int limit = 30,
  }) {
    return _timelineQuery(patientId, limit: limit).watch().asyncMap(_hydrate);
  }

  @override
  Future<Result<MedicalRecord>> add(NewRecord record) {
    return Result.guardAsync(() async {
      final id = newId('rec');
      await _db.transaction(() async {
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
                body: Value(record.body),
                sourceFacility: Value(record.sourceFacility),
                attachmentPath: Value(record.attachmentPath),
                extractedText: Value(record.extractedText),
              ),
            );
        for (final l in record.labValues) {
          await _db
              .into(_db.labValues)
              .insert(
                LabValuesCompanion.insert(
                  id: newId('lab'),
                  recordId: id,
                  analyte: l.analyte,
                  value: l.value,
                  abnormalFlag: Value(
                    classifyLab(l.value, refLow: l.refLow, refHigh: l.refHigh),
                  ),
                  unit: Value(l.unit),
                  refLow: Value(l.refLow),
                  refHigh: Value(l.refHigh),
                ),
              );
        }
      });
      final row = await (_db.select(
        _db.medicalRecords,
      )..where((r) => r.id.equals(id))).getSingle();
      return (await _hydrate([row])).single;
    });
  }
}

class VitalsRepositoryImpl implements VitalsRepository {
  VitalsRepositoryImpl(this._db);

  final AppDatabase _db;

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
      final rows = await _query(patientId, from: from, to: to).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Stream<List<Vitals>> watchForPatient(String patientId) {
    return _query(
      patientId,
    ).watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<Vitals>> add(Vitals v) {
    return Result.guardAsync(() async {
      final id = v.id.isEmpty ? newId('vit') : v.id;
      await _db
          .into(_db.vitals)
          .insert(
            VitalsCompanion.insert(
              id: id,
              patientId: v.patientId,
              recordedAt: v.recordedAt,
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
  MedicationRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<Medication>>> forPatient(
    String patientId, {
    bool activeOnly = false,
  }) {
    return Result.guardAsync(() async {
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
  Future<Result<void>> discontinue(String id, DateTime endDate) {
    return Result.guardAsync(() async {
      await (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
        MedicationsCompanion(
          isActive: const Value(false),
          endDate: Value(endDate),
        ),
      );
    });
  }
}
