/// Drift-backed [DentalChartRepository].
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/dental_chart_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';

class DentalChartRepositoryImpl implements DentalChartRepository {
  DentalChartRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<DentalEntry>>> forPatient(String patientId) =>
      Result.guardAsync(() async {
        await _access.readPatient(
          patientId,
          entityType: 'dental_chart',
          entityId: patientId,
        );
        final rows =
            await (_db.select(_db.dentalChartEntries)
                  ..where((e) => e.patientId.equals(patientId))
                  ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
                .get();
        return [for (final r in rows) _entry(r)];
      });

  @override
  Future<Result<DentalEntry>> add(NewDentalEntry input) => Result.guardAsync(
    () async {
      final p = await _access.clinicalWriteAsCurrentStaff(
        input.patientId,
        Permission.recordDentalChart,
        entityType: 'dental_chart',
      );
      final note = input.note.trim();
      if (!isFdiTooth(input.tooth)) {
        throw const ValidationFailure('Choose a valid FDI tooth number.');
      }
      if (note.isEmpty || note.length > 1000) {
        throw const ValidationFailure(
          'Describe the finding or treatment (up to 1000 characters).',
        );
      }
      return _db.transaction(() async {
        final prior =
            await (_db.select(_db.dentalChartEntries)
                  ..where((e) => e.idempotencyKey.equals(input.idempotencyKey)))
                .getSingleOrNull();
        if (prior != null) return _entry(prior);
        final visit = await (_db.select(
          _db.appointments,
        )..where((a) => a.id.equals(input.appointmentId))).getSingleOrNull();
        // The entry must belong to this patient's visit — never another
        // patient's encounter.
        if (visit == null ||
            visit.patientId != input.patientId ||
            visit.status == AppointmentStatus.cancelled) {
          throw const ValidationFailure("Choose one of this patient's visits.");
        }
        final fulfils = input.fulfilsId;
        if (fulfils != null) {
          final plan = await (_db.select(
            _db.dentalChartEntries,
          )..where((e) => e.id.equals(fulfils))).getSingleOrNull();
          if (plan == null ||
              plan.patientId != input.patientId ||
              plan.tooth != input.tooth ||
              plan.kind != DentalEntryKind.planned ||
              input.kind != DentalEntryKind.completed) {
            throw const ValidationFailure(
              'A completed entry can only fulfil a planned treatment on '
              'the same tooth.',
            );
          }
        }
        final id = const Uuid().v4();
        await _db
            .into(_db.dentalChartEntries)
            .insert(
              DentalChartEntriesCompanion.insert(
                id: id,
                patientId: input.patientId,
                appointmentId: input.appointmentId,
                tooth: input.tooth,
                kind: input.kind,
                surface: Value(
                  input.surface?.trim().isEmpty ?? true
                      ? null
                      : input.surface!.trim(),
                ),
                note: note,
                fulfilsId: Value(fulfils),
                authorId: p?.accountId ?? 'local',
                createdAt: DateTime.now(),
                idempotencyKey: input.idempotencyKey,
              ),
            );
        await _access.audit(
          'dental_chart.${input.kind.name}',
          entityType: 'dental_chart',
          entityId: id,
          subjectPatientId: input.patientId,
        );
        return _entry(
          await (_db.select(
            _db.dentalChartEntries,
          )..where((e) => e.id.equals(id))).getSingle(),
        );
      });
    },
  );

  static DentalEntry _entry(DentalChartEntryRow r) => DentalEntry(
    id: r.id,
    patientId: r.patientId,
    appointmentId: r.appointmentId,
    tooth: r.tooth,
    kind: r.kind,
    note: r.note,
    surface: r.surface,
    fulfilsId: r.fulfilsId,
    authorId: r.authorId,
    createdAt: r.createdAt,
  );
}
