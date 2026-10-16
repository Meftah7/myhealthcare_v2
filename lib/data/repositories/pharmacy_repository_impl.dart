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
                  ..where(
                    (m) =>
                        m.isActive &
                        (m.endDate.isNull() |
                            m.endDate.isBiggerThanValue(DateTime.now())) &
                        m.prescriberId.isNotNull() &
                        existsQuery(
                          _db.select(_db.signedNotes)..where(
                            (s) =>
                                s.appointmentId.equalsExp(m.appointmentId) &
                                s.patientId.equalsExp(m.patientId) &
                                s.authorStaffId.equalsExp(m.prescriberId),
                          ),
                        ),
                  )
                  ..orderBy([(m) => OrderingTerm.desc(m.startDate)])
                  ..limit(limit))
                .get();
        if (meds.isEmpty) return const <PharmacyOrder>[];
        final pending =
            (await (_db.select(
                  _db.medicationClarifications,
                )..where((c) => c.resolvedAt.isNull())).get())
                .map((c) => c.medicationId)
                .toSet();
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
              clarificationPending: pending.contains(m.id),
              orderedUnits: m.orderedUnits,
            ),
        ];
      });

  @override
  Future<Result<DateTime>> record(
    DispenseInput input,
  ) => Result.guardAsync(() async {
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
      if (prior != null) {
        if (prior.pharmacistId != (p?.accountId ?? 'local') ||
            prior.medicationId != input.medicationId ||
            prior.outcome != input.outcome ||
            prior.quantity != input.quantity?.trim() ||
            prior.note != _blankToNull(input.note) ||
            prior.stockBatchId != input.stockBatchId ||
            prior.units != (input.stockBatchId == null ? null : input.units)) {
          throw const ConflictFailure(
            'This retry key belongs to a different dispensing request.',
          );
        }
        return prior.recordedAt;
      }
      final med = await (_db.select(
        _db.medications,
      )..where((m) => m.id.equals(input.medicationId))).getSingleOrNull();
      if (med == null ||
          !med.isActive ||
          med.prescriberId == null ||
          med.endDate?.isBefore(DateTime.now()) == true) {
        throw const ConflictFailure(
          'This order is no longer active. Ask the prescriber to review it.',
        );
      }
      final signed =
          await (_db.select(_db.signedNotes)..where(
                (s) =>
                    s.appointmentId.equals(med.appointmentId ?? '') &
                    s.patientId.equals(med.patientId) &
                    s.authorStaffId.equals(med.prescriberId!),
              ))
              .getSingleOrNull();
      if (signed == null)
        throw const ConflictFailure(
          'Only a signed, prescriber-attributed order can be reviewed.',
        );
      final supplying =
          input.outcome == DispenseOutcome.dispensed ||
          input.outcome == DispenseOutcome.partial;
      final clarification =
          await (_db.select(_db.medicationClarifications)..where(
                (c) => c.medicationId.equals(med.id) & c.resolvedAt.isNull(),
              ))
              .get();
      if (supplying && clarification.isNotEmpty)
        throw const ConflictFailure(
          'The responsible prescriber must resolve the outstanding clarification before supply.',
        );
      if (!supplying && input.stockBatchId != null)
        throw const ValidationFailure(
          'A hold or clarification cannot consume stock.',
        );
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
      if (supplying && input.stockBatchId == null)
        throw const ValidationFailure(
          'Choose a recorded stock batch before supplying medication.',
        );
      if (supplying && med.orderedUnits != null) {
        final used = await (_db.select(
          _db.medicationDispenses,
        )..where((d) => d.medicationId.equals(med.id))).get();
        final total = used.fold<int>(0, (sum, d) => sum + (d.units ?? 0));
        if (input.units == null ||
            input.units! <= 0 ||
            total + input.units! > med.orderedUnits!)
          throw const ConflictFailure(
            'Supply exceeds the remaining ordered units.',
          );
        if (input.stockBatchId == null)
          throw const ValidationFailure(
            'Choose the recorded stock batch for this supply.',
          );
      }
      var batchText = _blankToNull(input.batch);
      var expiry = input.expiry;
      final batchId = input.stockBatchId;
      if (batchId != null) {
        final units = input.units;
        if (units == null || units <= 0) {
          throw const ValidationFailure(
            'Enter how many units leave the selected batch.',
          );
        }
        final stock = await (_db.select(
          _db.pharmacyStockBatches,
        )..where((b) => b.id.equals(batchId))).getSingleOrNull();
        if (stock == null) {
          throw const ConflictFailure('That stock batch no longer exists.');
        }
        if (stock.itemName.trim().toLowerCase() !=
            med.name.trim().toLowerCase())
          throw const ValidationFailure(
            'The selected stock item does not match the signed order.',
          );
        final today = DateTime(at.year, at.month, at.day);
        if (!stock.expiry.isAfter(today)) {
          throw const ValidationFailure('This batch has expired.');
        }
        if (stock.quantity < units) {
          throw ConflictFailure(
            'Only ${stock.quantity} ${stock.unit} left in batch '
            '${stock.batch}.',
          );
        }
        // Optimistic version check: two dispenses racing on one batch
        // cannot both decrement from the same starting quantity.
        final changed =
            await (_db.update(_db.pharmacyStockBatches)..where(
                  (b) => b.id.equals(batchId) & b.version.equals(stock.version),
                ))
                .write(
                  PharmacyStockBatchesCompanion(
                    quantity: Value(stock.quantity - units),
                    version: Value(stock.version + 1),
                  ),
                );
        if (changed != 1) {
          throw const ConflictFailure(
            'Stock changed while you were recording. Reload and retry.',
          );
        }
        batchText = stock.batch;
        expiry = stock.expiry;
      }
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
              batch: Value(batchText),
              expiry: Value(expiry),
              stockBatchId: Value(batchId),
              units: Value(batchId == null ? null : input.units),
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
      if (input.outcome == DispenseOutcome.clarificationRequested) {
        await _db
            .into(_db.medicationClarifications)
            .insert(
              MedicationClarificationsCompanion.insert(
                id: const Uuid().v4(),
                medicationId: med.id,
                requestedBy: p?.accountId ?? 'local',
                question: input.note!.trim(),
                requestedAt: at,
              ),
            );
      }
      return at;
    });
  });

  @override
  Future<Result<List<StockBatch>>> stock() => Result.guardAsync(() async {
    await _access.require(
      Permission.dispenseMedication,
      entityType: 'pharmacy_stock',
    );
    final rows = await (_db.select(
      _db.pharmacyStockBatches,
    )..orderBy([(b) => OrderingTerm.asc(b.expiry)])).get();
    return [for (final r in rows) _batch(r)];
  });

  @override
  Future<Result<StockBatch>> receive(ReceiveStockInput input) =>
      Result.guardAsync(() async {
        final p = await _access.require(
          Permission.dispenseMedication,
          entityType: 'pharmacy_stock',
        );
        final name = input.itemName.trim();
        final batch = input.batch.trim();
        if (name.isEmpty || batch.isEmpty) {
          throw const ValidationFailure('Enter the item and batch number.');
        }
        if (input.quantity <= 0 || input.quantity > 100000) {
          throw const ValidationFailure('Enter a quantity from 1 to 100000.');
        }
        final now = DateTime.now();
        if (!input.expiry.isAfter(DateTime(now.year, now.month, now.day))) {
          throw const ValidationFailure('This batch has already expired.');
        }
        return _db.transaction(() async {
          final prior =
              await (_db.select(_db.pharmacyStockBatches)..where(
                    (b) => b.idempotencyKey.equals(input.idempotencyKey),
                  ))
                  .getSingleOrNull();
          if (prior != null) return _batch(prior);
          final id = const Uuid().v4();
          await _db
              .into(_db.pharmacyStockBatches)
              .insert(
                PharmacyStockBatchesCompanion.insert(
                  id: id,
                  itemName: name,
                  batch: batch,
                  expiry: input.expiry,
                  quantity: input.quantity,
                  unit: Value(
                    input.unit.trim().isEmpty ? 'units' : input.unit.trim(),
                  ),
                  receivedBy: p?.accountId ?? 'local',
                  receivedAt: now,
                  idempotencyKey: input.idempotencyKey,
                ),
              );
          await _access.audit(
            'pharmacy.stock_received',
            entityType: 'pharmacy_stock',
            entityId: id,
          );
          return _batch(
            await (_db.select(
              _db.pharmacyStockBatches,
            )..where((b) => b.id.equals(id))).getSingle(),
          );
        });
      });

  static StockBatch _batch(StockBatchRow r) => StockBatch(
    id: r.id,
    itemName: r.itemName,
    batch: r.batch,
    expiry: r.expiry,
    quantity: r.quantity,
    unit: r.unit,
    receivedAt: r.receivedAt,
    version: r.version,
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
