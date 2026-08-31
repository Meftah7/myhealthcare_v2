/// Staff-facing patient chart data + write actions (P5-07, P5-08, P5-09).
///
/// All keyed by an explicit patient id (a staff member is viewing someone
/// else's record), unlike the session-scoped `/patient/*` providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../auth/application/session.dart';
import '../../staff_dashboard/application/staff_providers.dart';

final chartPatientProvider = FutureProvider.family<Patient, String>((
  ref,
  id,
) async {
  return _unwrap(await ref.watch(patientRepositoryProvider).byId(id));
});

final chartTimelineProvider =
    FutureProvider.family<List<MedicalRecord>, String>((ref, id) async {
      return _unwrap(
        await ref.watch(recordRepositoryProvider).timeline(id, limit: 500),
      );
    });

final chartVitalsProvider = FutureProvider.family<List<Vitals>, String>((
  ref,
  id,
) async {
  return _unwrap(await ref.watch(vitalsRepositoryProvider).forPatient(id));
});

final chartMedicationsProvider =
    FutureProvider.family<List<Medication>, String>((ref, id) async {
      return _unwrap(
        await ref.watch(medicationRepositoryProvider).forPatient(id),
      );
    });

final chartFlagsProvider = FutureProvider.family<List<RiskFlag>, String>((
  ref,
  id,
) async {
  return _unwrap(await ref.watch(riskRepositoryProvider).forPatient(id));
});

class ChartActions {
  ChartActions(this._ref, this._patientId);

  final Ref _ref;
  final String _patientId;

  String get _authorId => _ref.read(currentUserProvider)!.id;

  void _refresh() {
    _ref
      ..invalidate(chartTimelineProvider(_patientId))
      ..invalidate(chartMedicationsProvider(_patientId))
      ..invalidate(chartFlagsProvider(_patientId))
      ..invalidate(unacknowledgedFlagsProvider);
  }

  /// P5-08 — add a free-text clinical note as a visit-note record.
  Future<Result<MedicalRecord>> addNote({
    required String title,
    required String body,
    required DateTime occurredAt,
  }) async {
    final result = await _ref
        .read(recordRepositoryProvider)
        .add(
          NewRecord(
            patientId: _patientId,
            recordType: RecordType.visitNote,
            title: title,
            occurredAt: occurredAt,
            authorStaffId: _authorId,
            body: body,
          ),
        );
    if (result.isOk) {
      await _audit('record.note.add', result.valueOrNull!.id);
      _refresh();
    }
    return result;
  }

  /// P5-09 — prescribe a medication.
  Future<Result<Medication>> prescribe({
    required String name,
    String? dose,
    String? frequency,
  }) async {
    final result = await _ref
        .read(medicationRepositoryProvider)
        .prescribe(
          Medication(
            id: newId('med'),
            patientId: _patientId,
            name: name,
            dose: dose,
            frequency: frequency,
            prescriberId: _authorId,
            startDate: DateTime.now(),
            isActive: true,
          ),
        );
    if (result.isOk) {
      await _audit('medication.prescribe', result.valueOrNull!.id);
      _refresh();
    }
    return result;
  }

  /// P5-09 — record a lab result (a lab-result record with one value).
  Future<Result<MedicalRecord>> addLabResult({
    required String panelTitle,
    required String analyte,
    required double value,
    required DateTime occurredAt,
    String? unit,
    double? refLow,
    double? refHigh,
  }) async {
    final result = await _ref
        .read(recordRepositoryProvider)
        .add(
          NewRecord(
            patientId: _patientId,
            recordType: RecordType.labResult,
            title: panelTitle,
            occurredAt: occurredAt,
            authorStaffId: _authorId,
            labValues: [
              NewLabValue(
                analyte: analyte,
                value: value,
                unit: unit,
                refLow: refLow,
                refHigh: refHigh,
              ),
            ],
          ),
        );
    if (result.isOk) {
      await _audit('record.lab.add', result.valueOrNull!.id);
      _refresh();
    }
    return result;
  }

  /// P5-05/P5-07 — acknowledge a risk flag; keeps the dashboard list in sync.
  Future<void> acknowledgeFlag(String flagId) async {
    await _ref
        .read(riskRepositoryProvider)
        .acknowledge(id: flagId, staffId: _authorId);
    _refresh();
  }

  Future<void> _audit(String action, String entityId) async {
    await _ref
        .read(auditRepositoryProvider)
        .record(
          action: action,
          entityType: 'medical_record',
          entityId: entityId,
          actorUserId: _authorId,
        );
  }
}

final chartActionsProvider = Provider.family<ChartActions, String>(
  ChartActions.new,
);

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
