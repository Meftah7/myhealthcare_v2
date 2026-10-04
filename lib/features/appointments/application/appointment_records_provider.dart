/// Encounter history is linked by ID, never inferred from dates.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/application/patient_data_providers.dart';

class AppointmentRecords {
  const AppointmentRecords({
    required this.records,
    required this.vitals,
    required this.medications,
  });
  final List<MedicalRecord> records;
  final List<Vitals> vitals;
  final List<Medication> medications;
  bool get isEmpty => records.isEmpty && vitals.isEmpty && medications.isEmpty;
}

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final appointmentRecordsProvider = FutureProvider.autoDispose
    .family<AppointmentRecords, String>((ref, id) async {
      final appointments = await ref.watch(patientAppointmentsProvider.future);
      final appointment = appointments.where((a) => a.id == id).firstOrNull;
      if (appointment == null ||
          appointment.status != AppointmentStatus.completed) {
        throw const AccessDeniedFailure(
          'Completed appointment access is required.',
        );
      }
      final patientId = appointment.patientId;
      final records = _unwrap(
        await ref.watch(recordRepositoryProvider).forAppointment(patientId, id),
      );
      final vitals = _unwrap(
        await ref.watch(vitalsRepositoryProvider).forPatient(patientId),
      );
      final medications = _unwrap(
        await ref
            .watch(medicationRepositoryProvider)
            .forPatient(patientId, activeOnly: false),
      );
      return AppointmentRecords(
        records: records,
        vitals: vitals.where((v) => v.appointmentId == id).toList(),
        medications: medications.where((m) => m.appointmentId == id).toList(),
      );
    });
