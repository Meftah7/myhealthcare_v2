import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'shared_client.dart';

class RemoteVitalsRepository implements VitalsRepository {
  RemoteVitalsRepository(this.client);
  final SharedClient client;
  @override
  Future<Result<List<Vitals>>> forPatient(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) => Result.guardAsync(() async {
    final result =
        await client.request(
              '/api/workforce/vitals',
              query: {
                'patientId': patientId,
                if (from != null) 'from': from.toUtc().toIso8601String(),
                if (to != null) 'to': to.toUtc().toIso8601String(),
              },
            )
            as Map;
    return [
      for (final row in result['rows'] as List)
        Vitals(
          id: row['id'] as String,
          patientId: row['patient'] as String,
          recordedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['recorded_at'] as num).toInt(),
            isUtc: true,
          ),
          appointmentId: row['appointment'] as String?,
          recordedByStaffId: row['recorded_by'] as String?,
          tempC: (row['temp_c'] as num?)?.toDouble(),
          heartRate: row['heart_rate'] as int?,
          spo2: row['spo2'] as int?,
          systolic: row['systolic'] as int?,
          diastolic: row['diastolic'] as int?,
          weightKg: (row['weight_kg'] as num?)?.toDouble(),
          heightCm: (row['height_cm'] as num?)?.toDouble(),
          glucose: (row['glucose'] as num?)?.toDouble(),
        ),
    ];
  });
  @override
  Stream<List<Vitals>> watchForPatient(String patientId) async* {
    do {
      final result = await forPatient(patientId);
      switch (result) {
        case Ok(:final value):
          yield value;
        case Err(:final failure):
          throw failure;
      }
      await Future<void>.delayed(const Duration(seconds: 30));
    } while (client.user != null);
  }

  @override
  Future<Result<Vitals>> add(Vitals vitals) => Result.guardAsync(() async {
    final id = vitals.id.isEmpty ? newId('vit') : vitals.id;
    final result = await client.request(
      '/api/workforce/vitals',
      method: 'POST',
      body: {
        'id': id,
        'patientId': vitals.patientId,
        'appointmentId': vitals.appointmentId,
        'temperature': vitals.tempC,
        'pulse': vitals.heartRate,
        'oxygen': vitals.spo2,
        'systolic': vitals.systolic,
        'diastolic': vitals.diastolic,
        'weightKg': vitals.weightKg,
        'heightCm': vitals.heightCm,
        'glucose': vitals.glucose,
      },
    );
    final saved = Map<String, dynamic>.from(result as Map);
    return vitals.copyWith(
      id: id,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        (saved['recordedAt'] as num).toInt(),
        isUtc: true,
      ),
      recordedByStaffId: saved['recordedByStaffId'] as String?,
    );
  });
}
