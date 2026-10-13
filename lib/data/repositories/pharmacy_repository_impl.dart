/// Drift-backed [PharmacyRepository].
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class PharmacyRepositoryImpl implements PharmacyRepository {
  PharmacyRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<PharmacyOrder>>> queue({int limit = 100}) =>
      Result.guardAsync(() async {
        await _access.require(
          Permission.dispenseMedication,
          entityType: 'medication',
        );
        final meds =
            await (_db.select(_db.medications)
                  ..where((m) => m.isActive & m.prescriberId.isNotNull())
                  ..orderBy([(m) => OrderingTerm.desc(m.startDate)])
                  ..limit(limit))
                .get();
        if (meds.isEmpty) return const <PharmacyOrder>[];
        final people = {
          for (final u
              in await (_db.select(_db.users)..where(
                    (u) => u.id.isIn({
                      for (final m in meds) ...[m.patientId, m.prescriberId!],
                    }),
                  ))
                  .get())
            u.id: u.fullName,
        };
        final latest = <String, MedicationDispenseRow>{};
        for (final d
            in await (_db.select(_db.medicationDispenses)
                  ..where((d) => d.medicationId.isIn(meds.map((m) => m.id)))
                  ..orderBy([(d) => OrderingTerm.asc(d.recordedAt)]))
                .get()) {
          latest[d.medicationId] = d;
        }
        return [
          for (final m in meds)
            PharmacyOrder(
              medicationId: m.id,
              patientId: m.patientId,
              patientName: people[m.patientId] ?? '',
              prescriberName: people[m.prescriberId] ?? '',
              name: m.name,
              dose: m.dose,
              frequency: m.frequency,
              startDate: m.startDate,
              lastOutcome: latest[m.id]?.outcome,
              lastOutcomeAt: latest[m.id]?.recordedAt,
            ),
        ];
      });

  @override
  Future<Result<DateTime>> record(DispenseInput input) => Result.guardAsync(
    () async {
      final p = await _access.require(
        Permission.dispenseMedication,
        entityType: 'medication',
        entityId: input.medicationId,
      );
      _validate(input);
      return _db.transaction(() async {
        final prior =
            await (_db.select(_db.medicationDispenses)
                  ..where((d) => d.idempotencyKey.equals(input.idempotencyKey)))
                .getSingleOrNull();
        if (prior != null) return prior.recordedAt;
        final med = await (_db.select(
          _db.medications,
        )..where((m) => m.id.equals(input.medicationId))).getSingleOrNull();
        if (med == null || !med.isActive || med.prescriberId == null) {
          throw const ConflictFailure(
            'This order is no longer active. Ask the prescriber to review it.',
          );
        }
        final done =
            await (_db.select(_db.medicationDispenses)..where(
                  (d) =>
                      d.medicationId.equals(med.id) &
                      d.outcome.equalsValue(DispenseOutcome.dispensed),
                ))
                .get();
        if (done.isNotEmpty) {
          throw const ConflictFailure(
            'This order has already been fully dispensed.',
          );
        }
        final at = DateTime.now();
        await _db
            .into(_db.medicationDispenses)
            .insert(
              MedicationDispensesCompanion.insert(
                id: const Uuid().v4(),
                medicationId: med.id,
                patientId: med.patientId,
                pharmacistId: p?.accountId ?? 'local',
                outcome: input.outcome,
                quantity: Value(input.quantity?.trim()),
                batch: Value(_blankToNull(input.batch)),
                expiry: Value(input.expiry),
                note: Value(_blankToNull(input.note)),
                idempotencyKey: input.idempotencyKey,
                recordedAt: at,
              ),
            );
        await _access.audit(
          'pharmacy.${input.outcome.name}',
          entityType: 'medication',
          entityId: med.id,
          subjectPatientId: med.patientId,
        );
        return at;
      });
    },
  );

  static void _validate(DispenseInput input) {
    if (!input.patientVerified) {
      throw const ValidationFailure(
        "Verify the patient's identity against the order first.",
      );
    }
    final supplying =
        input.outcome == DispenseOutcome.dispensed ||
        input.outcome == DispenseOutcome.partial;
    if (supplying && (input.quantity?.trim().isEmpty ?? true)) {
      throw const ValidationFailure('Enter the quantity supplied.');
    }
    if (input.outcome != DispenseOutcome.dispensed &&
        (input.note?.trim().isEmpty ?? true)) {
      throw const ValidationFailure(
        'Record the reason for a partial supply, hold or clarification.',
      );
    }
    final expiry = input.expiry;
    if (supplying && expiry != null) {
      final today = DateTime.now();
      if (!expiry.isAfter(DateTime(today.year, today.month, today.day))) {
        throw const ValidationFailure('This batch has expired.');
      }
    }
  }

  static String? _blankToNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
