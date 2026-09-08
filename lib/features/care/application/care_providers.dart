/// Providers for the Batch B care services: sick-leave certificates, patient
/// <-> doctor messaging, home-visit requests (P10-05, P10-07, P10-08).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../auth/application/session.dart';
import '../../patient/application/visited_doctors_provider.dart';

// --- session helpers -------------------------------------------------------

String _requirePatient(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) throw StateError('no patient in session');
  return user.id;
}

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

// --- sick leave -----------------------------------------------------------

/// The signed-in patient's sick-leave certificates, newest first.
final patientSickLeaveProvider = FutureProvider<List<SickLeaveCertificate>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(sickLeaveRepositoryProvider).forPatient(id));
});

// --- messaging ----------------------------------------------------------

/// One thread per doctor the patient has messaged.
final patientThreadsProvider = FutureProvider<List<CareThread>>((ref) async {
  final id = _requirePatient(ref);
  return _unwrap(
    await ref.watch(careMessageRepositoryProvider).threadsForPatient(id),
  );
});

/// Messages in one patient thread (keyed by the doctor's id).
final patientThreadProvider =
    FutureProvider.family<List<CareMessage>, String>((ref, staffId) async {
      final patientId = _requirePatient(ref);
      return _unwrap(
        await ref
            .watch(careMessageRepositoryProvider)
            .thread(patientId: patientId, staffId: staffId),
      );
    });

/// Doctors the patient can start a thread with (everyone they have seen).
final messageableDoctorsProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
      final visited = await ref.watch(visitedDoctorsProvider.future);
      return [for (final d in visited) (id: d.staffId, name: d.name)];
    });

/// Unread doctor replies across all of the patient's threads.
final patientUnreadCountProvider = Provider<int>((ref) {
  final threads = ref.watch(patientThreadsProvider).valueOrNull ?? const [];
  return threads.fold(0, (sum, t) => sum + t.unreadForPatient);
});

/// Staff inbox — one thread per patient who has messaged this clinician.
final staffThreadsProvider = FutureProvider<List<CareThread>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isStaff) return const [];
  return _unwrap(
    await ref.watch(careMessageRepositoryProvider).threadsForStaff(user.id),
  );
});

final staffThreadProvider = FutureProvider.family<List<CareMessage>, String>((
  ref,
  patientId,
) async {
  final user = ref.watch(currentUserProvider)!;
  return _unwrap(
    await ref
        .watch(careMessageRepositoryProvider)
        .thread(patientId: patientId, staffId: user.id),
  );
});

final staffUnreadCountProvider = Provider<int>((ref) {
  final threads = ref.watch(staffThreadsProvider).valueOrNull ?? const [];
  return threads.fold(0, (sum, t) => sum + t.unreadForStaff);
});

class MessageActions {
  MessageActions(this._ref);
  final Ref _ref;

  Future<Result<CareMessage>> send({
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
  }) async {
    final result = await _ref
        .read(careMessageRepositoryProvider)
        .send(
          patientId: patientId,
          staffId: staffId,
          fromStaff: fromStaff,
          body: body,
        );
    if (result.isOk) _invalidate(patientId, staffId);
    return result;
  }

  Future<void> markRead({
    required String patientId,
    required String staffId,
    required bool readerIsStaff,
  }) async {
    await _ref
        .read(careMessageRepositoryProvider)
        .markRead(
          patientId: patientId,
          staffId: staffId,
          readerIsStaff: readerIsStaff,
        );
    _invalidate(patientId, staffId);
  }

  void _invalidate(String patientId, String staffId) {
    _ref
      ..invalidate(patientThreadsProvider)
      ..invalidate(patientThreadProvider(staffId))
      ..invalidate(staffThreadsProvider)
      ..invalidate(staffThreadProvider(patientId));
  }
}

final messageActionsProvider = Provider<MessageActions>(MessageActions.new);

// --- home visits ------------------------------------------------------

final patientHomeVisitsProvider = FutureProvider<List<HomeVisitRequest>>((
  ref,
) async {
  final id = _requirePatient(ref);
  return _unwrap(await ref.watch(homeVisitRepositoryProvider).forPatient(id));
});

/// The whole home-visit queue for admin triage; optionally filtered.
final homeVisitQueueProvider =
    FutureProvider.family<List<HomeVisitRequest>, HomeVisitStatus?>((
      ref,
      status,
    ) async {
      return _unwrap(
        await ref.watch(homeVisitRepositoryProvider).all(status: status),
      );
    });

/// patientId -> full name, for the admin queue.
final patientDirectoryProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final users = _unwrap(
    await ref.watch(userRepositoryProvider).byRole(UserRole.patient),
  );
  return {for (final u in users) u.id: u.fullName};
});

final openHomeVisitCountProvider = Provider<int>((ref) {
  final list =
      ref.watch(homeVisitQueueProvider(HomeVisitStatus.requested)).valueOrNull ??
      const [];
  return list.length;
});

class HomeVisitActions {
  HomeVisitActions(this._ref);
  final Ref _ref;

  Future<Result<HomeVisitRequest>> request({
    required String address,
    required DateTime preferredDate,
    required String reason,
    String? departmentId,
  }) async {
    final id = _requirePatient(_ref);
    final result = await _ref
        .read(homeVisitRepositoryProvider)
        .create(
          NewHomeVisitRequest(
            patientId: id,
            addressText: address,
            preferredDate: preferredDate,
            reasonText: reason,
            departmentId: departmentId,
          ),
        );
    if (result.isOk) _invalidate();
    return result;
  }

  Future<Result<HomeVisitRequest>> cancel(String id) async {
    final patientId = _requirePatient(_ref);
    final result = await _ref
        .read(homeVisitRepositoryProvider)
        .cancel(id: id, patientId: patientId);
    if (result.isOk) _invalidate();
    return result;
  }

  Future<Result<HomeVisitRequest>> decide({
    required String id,
    required HomeVisitStatus status,
    String? assignedStaffId,
    String? decisionNote,
  }) async {
    final result = await _ref
        .read(homeVisitRepositoryProvider)
        .decide(
          id: id,
          status: status,
          assignedStaffId: assignedStaffId,
          decisionNote: decisionNote,
        );
    if (result.isOk) _invalidate();
    return result;
  }

  void _invalidate() {
    _ref.invalidate(patientHomeVisitsProvider);
    for (final s in [null, ...HomeVisitStatus.values]) {
      _ref.invalidate(homeVisitQueueProvider(s));
    }
  }
}

final homeVisitActionsProvider = Provider<HomeVisitActions>(
  HomeVisitActions.new,
);
