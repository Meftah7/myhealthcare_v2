/// Patient-scoped data providers, keyed to the signed-in patient (P2-07+).
///
/// Screens under /patient/* read these; a staff patient chart (P5-07) passes an
/// explicit id via the `.forPatient` family variants.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
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

/// Pages of the timeline shown; "Load more" adds one.
final patientTimelinePagesProvider = StateProvider<int>((ref) => 1);

/// The patient's timeline, paged — the source; invalidate this to reload.
final patientTimelinePageProvider = FutureProvider<Page<MedicalRecord>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final repo = ref.watch(recordRepositoryProvider);
  return loadPages(
    ref.watch(patientTimelinePagesProvider),
    (page) async => _unwrap(await repo.timelinePage(id, page: page)),
  );
});

final patientTimelineProvider = FutureProvider<List<MedicalRecord>>(
  (ref) async => (await ref.watch(patientTimelinePageProvider.future)).items,
);

/// Search must include older records, not just the pages already displayed.
/// Every additional page goes through the repository's authorization checks.
final patientRecordHistoryProvider = FutureProvider<List<MedicalRecord>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final repo = ref.watch(recordRepositoryProvider);
  var page = await ref.watch(patientTimelinePageProvider.future);
  final records = [...page.items];
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  while (page.hasMore) {
    if (cancelled) throw StateError('Record history request cancelled');
    page = _unwrap(
      await repo.timelinePage(
        id,
        page: PageRequest(offset: records.length, size: PageLimits.maxSize),
      ),
    );
    records.addAll(page.items);
  }
  return records;
});

final patientVitalsProvider = FutureProvider<List<Vitals>>((ref) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(vitalsRepositoryProvider).forPatient(id));
});

/// The patient's diagnostic-imaging records, newest first (P10-03).
final patientImagingProvider = FutureProvider<List<MedicalRecord>>((ref) async {
  final id = _requirePatient(ref);
  final recs = _unwrap(
    await ref
        .watch(recordRepositoryProvider)
        // Imaging studies are few; the stated cap is the page maximum.
        .timeline(id, limit: PageLimits.maxSize, types: {RecordType.imaging}),
  );
  return recs..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
});

final patientMedicationsProvider = FutureProvider<List<Medication>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(medicationRepositoryProvider).forPatient(id));
});

/// The signed-in patient's visits plus those of household members they
/// book for. Each member's visits live on the member's own patient record
/// (read through the proxy grant); `bookedForName` labels them here.
final patientAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final repo = ref.watch(appointmentRepositoryProvider);
  final own = _unwrap(await repo.forPatient(id));
  final members = await ref.watch(patientFamilyMembersProvider.future);
  final dependents = [
    for (final member in members)
      if (member.patientId case final memberId?)
        ..._unwrap(await repo.forPatient(memberId)),
  ];
  if (dependents.isEmpty) return own;
  return [...own, ...dependents]
    ..sort((a, b) => b.slotStart.compareTo(a.slotStart));
});

/// The signed-in patient's own visits only (no household members).
final ownAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final id = _requirePatient(ref);
  final all = await ref.watch(patientAppointmentsProvider.future);
  return [
    for (final a in all)
      if (a.patientId == id) a,
  ];
});

/// Loads a visit through current self or proxy authorization.
final patientAppointmentByIdProvider =
    FutureProvider.family<Appointment?, String>((ref, id) async {
      _requirePatient(ref);
      final result = await ref.watch(appointmentRepositoryProvider).byId(id);
      return switch (result) {
        Ok(:final value) => value,
        Err(failure: NotFoundFailure()) => null,
        Err(:final failure) => throw failure,
      };
    });

/// staffId → display name ("Dr …") + department id, for labelling appointments.
final doctorDirectoryProvider =
    FutureProvider<Map<String, ({String name, String? departmentId})>>((
      ref,
    ) async {
      final staff = _unwrap(
        await ref.watch(userRepositoryProvider).byRole(UserRole.staff),
      );
      final out = <String, ({String name, String? departmentId})>{};
      for (final u in staff) {
        final profile =
            (await ref.watch(userRepositoryProvider).staffById(u.id))
                .valueOrNull;
        out[u.id] = (
          name: clinicianName(u.fullName),
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

/// Linked family members (redesign v2 patient dashboard: Family Network).
final patientFamilyMembersProvider = FutureProvider<List<FamilyMember>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(patientRepositoryProvider).familyMembers(id));
});

class FamilyMemberController {
  FamilyMemberController(this._ref);
  final Ref _ref;

  Future<Result<void>> add(FamilyMember member) async {
    final id = _requirePatient(_ref);
    final result = await _ref
        .read(patientRepositoryProvider)
        .addFamilyMember(id, member);
    if (result case Ok()) _ref.invalidate(patientFamilyMembersProvider);
    return result;
  }

  Future<Result<void>> update(FamilyMember member) async {
    final id = _requirePatient(_ref);
    final result = await _ref
        .read(patientRepositoryProvider)
        .updateFamilyMember(id, member);
    if (result case Ok()) _ref.invalidate(patientFamilyMembersProvider);
    return result;
  }

  Future<Result<void>> remove(String memberId) async {
    final id = _requirePatient(_ref);
    final result = await _ref
        .read(patientRepositoryProvider)
        .removeFamilyMember(id, memberId);
    if (result case Ok()) _ref.invalidate(patientFamilyMembersProvider);
    return result;
  }
}

class PatientProfileController {
  PatientProfileController(this._ref);
  final Ref _ref;

  Future<Result<void>> update(Patient patient) async {
    final id = _requirePatient(_ref);
    if (patient.id != id) {
      return const Err(AuthFailure('You can only update your own profile.'));
    }
    final result = await _ref
        .read(patientRepositoryProvider)
        .updateProfile(patient);
    if (result case Ok()) _ref.invalidate(patientProfileProvider);
    return result;
  }
}

final patientProfileControllerProvider = Provider<PatientProfileController>(
  PatientProfileController.new,
);

final familyMemberControllerProvider = Provider<FamilyMemberController>(
  FamilyMemberController.new,
);

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
