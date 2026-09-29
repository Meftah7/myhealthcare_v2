/// Providers for the Batch B care services: sick-leave certificates, patient
/// <-> doctor messaging, home-visit requests (P10-05, P10-07, P10-08).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/data/contracts.dart';
import '../../../core/data/data_state.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../auth/application/session.dart';
import '../../patient/application/visited_doctors_provider.dart';

// --- session helpers -------------------------------------------------------

String _requirePatient(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) {
    throw StateError('no patient in session');
  }
  return user.id;
}

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

/// Threads exist only between a patient and a clinician who has an
/// appointment with them (SEC-PAT-04, SEC-STAFF-06). Checked on read and send.
Future<void> _requireCareRelationship(
  Ref ref, {
  required String patientId,
  required String staffId,
}) async {
  final allowed = _unwrap(
    await ref
        .read(appointmentRepositoryProvider)
        .hasCareRelationship(staffId: staffId, patientId: patientId),
  );
  if (!allowed) throw const AuthFailure('You cannot message this account.');
}

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
final patientThreadProvider = FutureProvider.family<List<CareMessage>, String>((
  ref,
  staffId,
) async {
  final patientId = _requirePatient(ref);
  await _requireCareRelationship(ref, patientId: patientId, staffId: staffId);
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

/// Unread doctor replies across all of the patient's threads — null until
/// the threads have loaded (or when they failed), never a reassuring 0.
final patientUnreadCountProvider = Provider<int?>((ref) {
  final threads = ref.watch(patientThreadsProvider);
  if (threads.hasError || !threads.hasValue) return null;
  return threads.requireValue.fold<int>(
    0,
    (sum, t) => sum + t.unreadForPatient,
  );
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
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isStaff || !user.isActive) {
    throw const AuthFailure('Staff access is required.');
  }
  await _requireCareRelationship(ref, patientId: patientId, staffId: user.id);
  return _unwrap(
    await ref
        .watch(careMessageRepositoryProvider)
        .thread(patientId: patientId, staffId: user.id),
  );
});

/// Another clinician's thread with this patient, opened by the colleague
/// covering it (Phase 4 cover). Keyed by (patient, owning clinician).
final coveredThreadProvider =
    FutureProvider.family<
      List<CareMessage>,
      ({String patientId, String ownerId})
    >((ref, key) async {
      return _unwrap(
        await ref
            .watch(careMessageRepositoryProvider)
            .thread(patientId: key.patientId, staffId: key.ownerId),
      );
    });

/// Patient messages the signed-in clinician owns or covers that still await
/// a reply — overdue first (Phase 6). An error, never an empty "all
/// answered", when the read fails.
final staffAwaitingReplyProvider = FutureProvider<List<CareMessage>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isStaff) return const [];
  return _unwrap(
    await ref
        .watch(careMessageRepositoryProvider)
        .awaitingReply(staffId: user.id),
  );
});

/// Null until known (loading or failed) — see [patientUnreadCountProvider].
final staffUnreadCountProvider = Provider<int?>((ref) {
  final threads = ref.watch(staffThreadsProvider);
  if (threads.hasError || !threads.hasValue) return null;
  return threads.requireValue.fold<int>(0, (sum, t) => sum + t.unreadForStaff);
});

class MessageActions {
  MessageActions(this._ref);
  final Ref _ref;

  /// Sends as the signed-in user; the sender side and identity come from the
  /// session, never the caller (SEC-PAT-05). [counterpartId] is the staff id
  /// for a patient sender and the patient id for a staff sender.
  Future<Result<CareMessage>> sendAsCurrentUser({
    required String counterpartId,
    required String body,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isActive || !(user.isPatient || user.isStaff)) {
      return const Err(AuthFailure('Sign in to send messages.'));
    }
    final fromStaff = user.isStaff;
    final patientId = fromStaff ? counterpartId : user.id;
    final staffId = fromStaff ? user.id : counterpartId;
    try {
      await _requireCareRelationship(
        _ref,
        patientId: patientId,
        staffId: staffId,
      );
    } on Failure catch (f) {
      return Err(f);
    }
    // Same message to the same person = the same attempt until it succeeds,
    // so pressing Send again after a failure can't post it twice.
    final attempt = '$patientId|$staffId|${body.trim()}';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
    final result = await _ref
        .read(careMessageRepositoryProvider)
        .send(
          patientId: patientId,
          staffId: staffId,
          fromStaff: fromStaff,
          body: body,
          idempotencyKey: key,
          // Recorded with the message; delivered even if this app dies now.
          notify: [
            await _recipientNotice(
              patientId: patientId,
              staffId: staffId,
              fromStaff: fromStaff,
            ),
          ],
        );
    if (result.isOk) {
      _attempts.remove(attempt);
      _invalidate(patientId, staffId);
      await deliverPendingSideEffects(_ref);
    }
    return result;
  }

  final Map<String, IdempotencyKey> _attempts = {};

  /// Replies in [ownerId]'s thread as the colleague covering it. The
  /// repository checks the cover and audits the reply.
  Future<Result<CareMessage>> sendAsCover({
    required String patientId,
    required String ownerId,
    required String body,
  }) async {
    final attempt = 'cover|$patientId|$ownerId|${body.trim()}';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
    final result = await _ref
        .read(careMessageRepositoryProvider)
        .send(
          patientId: patientId,
          staffId: ownerId,
          fromStaff: true,
          body: body,
          idempotencyKey: key,
          notify: [
            await _recipientNotice(
              patientId: patientId,
              staffId: ownerId,
              fromStaff: true,
            ),
          ],
        );
    if (result.isOk) {
      _attempts.remove(attempt);
      _invalidate(patientId, ownerId);
      _ref.invalidate(coveredThreadProvider);
      await deliverPendingSideEffects(_ref);
    }
    return result;
  }

  /// An in-app notification for the other side — this drives the bell badge
  /// and the arrival sound cue, which a bare `care_messages` row does not.
  Future<NewNotification> _recipientNotice({
    required String patientId,
    required String staffId,
    required bool fromStaff,
  }) async {
    final recipientId = fromStaff ? patientId : staffId;
    final senderId = fromStaff ? staffId : patientId;
    final sender =
        (await _ref.read(userRepositoryProvider).byId(senderId)).valueOrNull;
    final senderName = sender == null
        ? (fromStaff ? 'your clinician' : 'a patient')
        : (fromStaff ? clinicianName(sender.fullName) : sender.fullName);
    return NewNotification(
      recipientId: recipientId,
      category: NotificationCategory.message,
      title: 'New message from $senderName',
      body: 'Open MyHealth Care to read your secure message.',
      deepLink: fromStaff
          ? '${AppRoutes.patientMessages}/$staffId'
          : AppRoutes.staffInbox,
    );
  }

  /// The reader side is checked against the signed-in account by the
  /// repository; a failure is returned so the screen can say so rather than
  /// leaving the unread badge silently wrong.
  Future<Result<void>> markRead({
    required String patientId,
    required String staffId,
    required bool readerIsStaff,
  }) async {
    final result = await _ref
        .read(careMessageRepositoryProvider)
        .markRead(
          patientId: patientId,
          staffId: staffId,
          readerIsStaff: readerIsStaff,
        );
    if (result.isOk) _invalidate(patientId, staffId);
    return result;
  }

  void _invalidate(String patientId, String staffId) {
    _ref
      ..invalidate(staffAwaitingReplyProvider)
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

/// Open home-visit requests, or null while unknown (loading / failed).
final openHomeVisitCountProvider = Provider<int?>(
  (ref) =>
      ref.watch(homeVisitQueueProvider(HomeVisitStatus.requested)).countOrNull,
);

class HomeVisitActions {
  HomeVisitActions(this._ref);
  final Ref _ref;
  final Map<String, IdempotencyKey> _attempts = {};

  Future<Result<HomeVisitRequest>> request({
    required String address,
    required DateTime preferredDate,
    required String reason,
    String? departmentId,
  }) async {
    final id = _requirePatient(_ref);
    // Resubmitting the same request after a failure is the same attempt.
    final attempt = '$id|$address|$reason|${preferredDate.toIso8601String()}';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
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
          idempotencyKey: key,
        );
    if (result.isOk) {
      _attempts.remove(attempt);
      _invalidate();
    }
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
    int? expectedVersion,
  }) async {
    final current = _unwrap(
      await _ref.read(homeVisitRepositoryProvider).byId(id),
    );
    final notice = _patientNotice(
      patientId: current.patientId,
      status: status,
      decisionNote: decisionNote?.trim(),
    );
    final result = await _ref
        .read(homeVisitRepositoryProvider)
        .decide(
          id: id,
          status: status,
          // The admin decided on what they saw; if another admin acted in
          // between, this is a conflict, not an overwrite.
          expectedVersion: expectedVersion ?? current.version,
          notify: [?notice],
          assignedStaffId: assignedStaffId,
          decisionNote: decisionNote,
        );
    if (result.isOk) {
      _invalidate();
      await deliverPendingSideEffects(_ref);
    }
    return result;
  }

  /// An in-app notification for the patient when their home-visit request
  /// is scheduled, declined or completed — a bare row update otherwise gives
  /// them no signal that a decision was made. Recorded with the decision.
  NewNotification? _patientNotice({
    required String patientId,
    required HomeVisitStatus status,
    String? decisionNote,
  }) {
    final (String, String)? content = switch (status) {
      HomeVisitStatus.scheduled => (
        'Home visit scheduled',
        decisionNote ?? 'Your home visit request has been scheduled.',
      ),
      HomeVisitStatus.declined => (
        'Home visit request declined',
        decisionNote ?? 'Your home visit request was declined.',
      ),
      HomeVisitStatus.completed => (
        'Home visit completed',
        'Your home visit has been marked complete.',
      ),
      HomeVisitStatus.requested || HomeVisitStatus.cancelled => null,
    };
    if (content == null) return null;
    final (title, body) = content;
    return NewNotification(
      recipientId: patientId,
      category: NotificationCategory.system,
      title: title,
      body: body,
      deepLink: AppRoutes.patientHomeVisit,
    );
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
