/// Patient-scoped data providers, keyed to the signed-in patient (P2-07+).
///
/// Screens under /patient/* read these; a staff patient chart (P5-07) passes an
/// explicit id via the `.forPatient` family variants.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';

/// The signed-in patient's id (null if not a patient session).
final _currentPatientIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isPatient ?? false ? user!.id : null;
});

String _requirePatient(Ref ref) {
  final id = ref.watch(_currentPatientIdProvider);
  if (id == null) throw StateError('no patient in session');
  return id;
}

final patientProfileProvider = FutureProvider<Patient>((ref) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(patientRepositoryProvider).byId(id));
});

final patientTimelineProvider = FutureProvider<List<MedicalRecord>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(
    await ref.watch(recordRepositoryProvider).timeline(id, limit: 500),
  );
});

final patientVitalsProvider = FutureProvider<List<Vitals>>((ref) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(vitalsRepositoryProvider).forPatient(id));
});

final patientMedicationsProvider = FutureProvider<List<Medication>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(medicationRepositoryProvider).forPatient(id));
});

final patientAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(appointmentRepositoryProvider).forPatient(id));
});

/// staffId → display name ("Dr …") + department id, for labelling appointments.
final doctorDirectoryProvider = FutureProvider<Map<String, ({String name, String? departmentId})>>((
  ref,
) async {
  final staff = _unwrap(
    await ref.watch(userRepositoryProvider).byRole(UserRole.staff),
  );
  final out = <String, ({String name, String? departmentId})>{};
  for (final u in staff) {
    final profile = (await ref
        .watch(userRepositoryProvider)
        .staffById(u.id)).valueOrNull;
    out[u.id] = (
      name: 'Dr ${u.fullName}',
      departmentId: profile?.departmentId,
    );
  }
  return out;
});

/// departmentId → name.
final departmentDirectoryProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final depts = _unwrap(await ref.watch(departmentRepositoryProvider).all());
  return {for (final d in depts) d.id: d.name};
});

/// The soonest upcoming appointment, or null.
final nextAppointmentProvider = FutureProvider<Appointment?>((ref) async {
  final appts = await ref.watch(patientAppointmentsProvider.future);
  final upcoming = appts.where((a) => a.isUpcoming).toList()
    ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  return upcoming.firstOrNull;
});

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
