/// Family Network account-linking state: requests, accepted links, and the
/// permission-gated read (and, for "manage", write) access into a linked
/// account's own data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
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

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

/// A family link paired with the other account's basic profile, for display.
class FamilyLinkView {
  const FamilyLinkView({required this.link, required this.counterpart});
  final FamilyLink link;
  final Patient counterpart;
}

Future<List<FamilyLinkView>> _withCounterparts(
  Ref ref,
  List<FamilyLink> links,
  String Function(FamilyLink) counterpartId,
) async {
  final repo = ref.watch(patientRepositoryProvider);
  final views = <FamilyLinkView>[];
  for (final link in links) {
    final patient = await repo.byId(counterpartId(link));
    if (patient case Ok(:final value)) {
      views.add(FamilyLinkView(link: link, counterpart: value));
    }
  }
  return views;
}

/// Requests for *my* data, waiting on me to accept or decline.
final incomingFamilyRequestsProvider = FutureProvider<List<FamilyLinkView>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final links = _unwrap(
    await ref.watch(familyLinkRepositoryProvider).incomingRequests(id),
  );
  return _withCounterparts(ref, links, (l) => l.viewerPatientId);
});

/// Requests I sent, waiting on the other side.
final outgoingFamilyRequestsProvider = FutureProvider<List<FamilyLinkView>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final links = _unwrap(
    await ref.watch(familyLinkRepositoryProvider).outgoingRequests(id),
  );
  return _withCounterparts(ref, links, (l) => l.ownerPatientId);
});

/// Accounts I've been granted access to.
final linkedAccountsProvider = FutureProvider<List<FamilyLinkView>>((
  ref,
) async {
  final id = _requirePatient(ref);
  final links = _unwrap(
    await ref.watch(familyLinkRepositoryProvider).linkedAccounts(id),
  );
  return _withCounterparts(ref, links, (l) => l.ownerPatientId);
});

/// Accounts that have been granted access to me.
final viewersOfMeProvider = FutureProvider<List<FamilyLinkView>>((ref) async {
  final id = _requirePatient(ref);
  final links = _unwrap(
    await ref.watch(familyLinkRepositoryProvider).viewersOfMe(id),
  );
  return _withCounterparts(ref, links, (l) => l.viewerPatientId);
});

/// Live search for an account to link with, excluding the signed-in patient.
final familyLinkSearchQueryProvider = StateProvider.autoDispose<String>(
  (_) => '',
);

final familyLinkSearchResultsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
      final query = ref.watch(familyLinkSearchQueryProvider).trim();
      if (query.length < 2) return const [];
      final me = _requirePatient(ref);
      final results = _unwrap(
        await ref.watch(patientRepositoryProvider).search(query, limit: 15),
      );
      return results.where((p) => p.user.id != me).toList();
    });

/// The accepted link granting me access to [ownerPatientId]'s data, or a
/// thrown [AuthFailure] if there isn't one — every read/write into a linked
/// account goes through this, not just a UI flag.
Future<FamilyLink> _requireActiveLink(Ref ref, String ownerPatientId) async {
  final me = _requirePatient(ref);
  final link = _unwrap(
    await ref
        .watch(familyLinkRepositoryProvider)
        .activeLink(viewerPatientId: me, ownerPatientId: ownerPatientId),
  );
  if (link == null) {
    throw const AuthFailure('You do not have access to this account.');
  }
  return link;
}

final linkedPatientProvider = FutureProvider.family<Patient, String>((
  ref,
  ownerId,
) async {
  await _requireActiveLink(ref, ownerId);
  return _unwrap(await ref.watch(patientRepositoryProvider).byId(ownerId));
});

final linkedPermissionProvider = FutureProvider.family<
  FamilyLinkPermission,
  String
>((ref, ownerId) async {
  final link = await _requireActiveLink(ref, ownerId);
  return link.permission;
});

final linkedAppointmentsProvider =
    FutureProvider.family<List<Appointment>, String>((ref, ownerId) async {
      await _requireActiveLink(ref, ownerId);
      return _unwrap(
        await ref.watch(appointmentRepositoryProvider).forPatient(ownerId),
      );
    });

final linkedTimelineProvider =
    FutureProvider.family<List<MedicalRecord>, String>((ref, ownerId) async {
      await _requireActiveLink(ref, ownerId);
      return _unwrap(
        await ref
            .watch(recordRepositoryProvider)
            .timeline(ownerId, limit: 200),
      );
    });

final linkedVitalsProvider = FutureProvider.family<List<Vitals>, String>((
  ref,
  ownerId,
) async {
  await _requireActiveLink(ref, ownerId);
  return _unwrap(await ref.watch(vitalsRepositoryProvider).forPatient(ownerId));
});

final linkedMedicationsProvider =
    FutureProvider.family<List<Medication>, String>((ref, ownerId) async {
      await _requireActiveLink(ref, ownerId);
      return _unwrap(
        await ref.watch(medicationRepositoryProvider).forPatient(ownerId),
      );
    });

class FamilyLinkController {
  FamilyLinkController(this._ref);
  final Ref _ref;

  String? get _me {
    final user = _ref.read(currentUserProvider);
    return (user != null && user.isPatient) ? user.id : null;
  }

  void _invalidateAll() {
    _ref
      ..invalidate(incomingFamilyRequestsProvider)
      ..invalidate(outgoingFamilyRequestsProvider)
      ..invalidate(linkedAccountsProvider)
      ..invalidate(viewersOfMeProvider);
  }

  Future<Result<FamilyLink>> request({
    required String ownerPatientId,
    required FamilyLinkPermission permission,
  }) async {
    final me = _me;
    if (me == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(familyLinkRepositoryProvider)
        .request(
          ownerPatientId: ownerPatientId,
          viewerPatientId: me,
          permission: permission,
        );
    if (result case Ok()) _invalidateAll();
    return result;
  }

  Future<Result<FamilyLink>> accept(String linkId) async {
    final me = _me;
    if (me == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(familyLinkRepositoryProvider)
        .accept(linkId: linkId, actingPatientId: me);
    if (result case Ok()) _invalidateAll();
    return result;
  }

  Future<Result<void>> decline(String linkId) async {
    final me = _me;
    if (me == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(familyLinkRepositoryProvider)
        .decline(linkId: linkId, actingPatientId: me);
    if (result case Ok()) _invalidateAll();
    return result;
  }

  Future<Result<void>> unlink(String linkId) async {
    final me = _me;
    if (me == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(familyLinkRepositoryProvider)
        .unlink(linkId: linkId, actingPatientId: me);
    if (result case Ok()) _invalidateAll();
    return result;
  }

  /// Cancels [appointmentId] belonging to [ownerPatientId] — only allowed
  /// when I hold a "manage" link over that account.
  Future<Result<void>> cancelForLinkedAccount({
    required String ownerPatientId,
    required String appointmentId,
  }) async {
    final link = await _guardManage(ownerPatientId);
    if (link case Err(:final failure)) return Err(failure);
    final result = await _ref
        .read(appointmentRepositoryProvider)
        .cancel(appointmentId);
    if (result case Ok()) {
      _ref.invalidate(linkedAppointmentsProvider(ownerPatientId));
    }
    return result;
  }

  Future<Result<Appointment>> rescheduleForLinkedAccount({
    required String ownerPatientId,
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final link = await _guardManage(ownerPatientId);
    if (link case Err(:final failure)) return Err(failure);
    final result = await _ref
        .read(appointmentRepositoryProvider)
        .reschedule(id: appointmentId, newStart: newStart, newEnd: newEnd);
    if (result case Ok()) {
      _ref.invalidate(linkedAppointmentsProvider(ownerPatientId));
    }
    return result;
  }

  Future<Result<FamilyLink>> _guardManage(String ownerPatientId) async {
    final me = _me;
    if (me == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(familyLinkRepositoryProvider)
        .activeLink(viewerPatientId: me, ownerPatientId: ownerPatientId);
    return switch (result) {
      Ok(value: final link?) when link.canManage => Ok(link),
      Ok() => const Err(
        AuthFailure('You only have view access to this account.'),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}

final familyLinkControllerProvider = Provider<FamilyLinkController>(
  FamilyLinkController.new,
);
