/// The consultation flow: a draft persisted to the database as the clinician
/// types (so it survives a crash, a closed tab or re-authentication), and the
/// controller that walks an appointment call → arrive → (notes / meds /
/// referral request) → complete.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/consultation_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../auth/application/session.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../../staff_dashboard/application/staff_providers.dart';

// --- draft (mirrors the saved draft, keyed by appointment id) ------------

class DraftMed {
  const DraftMed({required this.name, this.dose, this.frequency});

  final String name;
  final String? dose;
  final String? frequency;
}

class ConsultationDraft {
  const ConsultationDraft({
    this.note = '',
    this.meds = const [],
    this.referralRequested = false,
    this.version,
  });

  final String note;
  final List<DraftMed> meds;

  /// True once the doctor has submitted a referral request from this page.
  final bool referralRequested;
  final int? version;

  bool get isEmpty => note.trim().isEmpty && meds.isEmpty && !referralRequested;

  ConsultationDraft copyWith({
    String? note,
    List<DraftMed>? meds,
    bool? referralRequested,
    int? version,
  }) => ConsultationDraft(
    note: note ?? this.note,
    meds: meds ?? this.meds,
    referralRequested: referralRequested ?? this.referralRequested,
    version: version ?? this.version,
  );
}

/// Where the draft stands against the saved copy. There is no "offline"
/// state: the store is on this device (see release scope).
enum DraftSaveState { idle, saving, saved, failed, conflict }

/// The working copy on screen. The database holds the authoritative draft;
/// [ConsultationController.loadDraft] restores it after a restart.
final consultationDraftProvider =
    StateProvider.family<ConsultationDraft, String>(
      (ref, _) => const ConsultationDraft(),
    );

final consultationDraftSaveStateProvider =
    StateProvider.family<DraftSaveState, String>(
      (ref, _) => DraftSaveState.idle,
    );

// --- reads --------------------------------------------------------------

final consultationAppointmentProvider =
    FutureProvider.family<Appointment, String>((ref, appointmentId) async {
      final appointment = _unwrap(
        await ref.watch(appointmentRepositoryProvider).byId(appointmentId),
      );
      final actor = ref.watch(currentUserProvider);
      if (actor == null ||
          !actor.isStaff ||
          !actor.isActive ||
          appointment.staffId != actor.id) {
        throw const AuthFailure('This consultation is not assigned to you.');
      }
      return appointment;
    });

/// The patient of the appointment under consultation.
final consultationPatientProvider = FutureProvider.family<Patient, String>((
  ref,
  appointmentId,
) async {
  final appt = await ref.watch(
    consultationAppointmentProvider(appointmentId).future,
  );
  return ref.watch(chartPatientProvider(appt.patientId).future);
});

/// The pending referral request tied to this appointment, if any.
final consultationReferralProvider =
    FutureProvider.family<ReferralRequest?, String>((ref, appointmentId) async {
      return _unwrap(
        await ref
            .watch(referralRequestRepositoryProvider)
            .pendingForAppointment(appointmentId),
      );
    });

// --- controller --------------------------------------------------------

class ConsultationController {
  ConsultationController(this._ref, this.appointmentId);

  final Ref _ref;
  final String appointmentId;

  String get _doctorId => _ref.read(currentUserProvider)!.id;

  Future<Result<ConsultationDraft>> loadDraft() async {
    final result = await _ref
        .read(encounterDraftRepositoryProvider)
        .forAppointment(appointmentId);
    return switch (result) {
      Ok(:final value) => Ok(
        value == null
            ? const ConsultationDraft()
            : ConsultationDraft(
                note: value.note,
                meds: [
                  for (final medication in value.medications)
                    DraftMed(
                      name: medication.name,
                      dose: medication.dose,
                      frequency: medication.frequency,
                    ),
                ],
                referralRequested: value.referralRequested,
                version: value.version,
              ),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<ConsultationDraft>> saveDraft(ConsultationDraft draft) async {
    final state = _ref.read(
      consultationDraftSaveStateProvider(appointmentId).notifier,
    );
    state.state = DraftSaveState.saving;
    final appt = await _ref.read(
      consultationAppointmentProvider(appointmentId).future,
    );
    final result = await _ref
        .read(encounterDraftRepositoryProvider)
        .save(
          EncounterDraftData(
            appointmentId: appointmentId,
            patientId: appt.patientId,
            authorStaffId: _doctorId,
            note: draft.note,
            medications: [
              for (final medication in draft.meds)
                DraftMedicationData(
                  name: medication.name,
                  dose: medication.dose,
                  frequency: medication.frequency,
                ),
            ],
            referralRequested: draft.referralRequested,
            version: draft.version ?? 1,
          ),
          expectedVersion: draft.version,
        );
    switch (result) {
      case Ok(:final value):
        state.state = DraftSaveState.saved;
        return Ok(draft.copyWith(version: value.version));
      case Err(:final failure):
        state.state = failure is ConflictFailure
            ? DraftSaveState.conflict
            : DraftSaveState.failed;
        return Err(failure);
    }
  }

  void _refreshQueue() {
    _ref
      ..invalidate(consultationAppointmentProvider(appointmentId))
      ..invalidate(staffTodayProvider)
      ..invalidate(staffQueueProvider)
      ..invalidate(staffMonthProvider);
  }

  Future<void> _audit(String action, {String? detail}) {
    return _ref
        .read(auditRepositoryProvider)
        .record(
          action: action,
          entityType: 'appointment',
          entityId: appointmentId,
          actorUserId: _doctorId,
          detail: detail,
        );
  }

  /// "Call patient" — stamps the time and pings the patient's notifications.
  Future<Result<void>> callPatient() async {
    final appt = await _ref.read(
      consultationAppointmentProvider(appointmentId).future,
    );
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .markCalledIn(
          appointmentId,
          staffId: _doctorId,
          at: DateTime.now(),
          // Recorded with the call-in, delivered through the outbox.
          notify: [
            NewNotification(
              recipientId: appt.patientId,
              category: NotificationCategory.appointment,
              title: 'You have been called in',
              body: appt.roomNumber == null
                  ? 'Please make your way to the consultation room.'
                  : 'Please proceed to room ${appt.roomNumber}.',
            ),
          ],
        );
    if (r.isOk) {
      await _audit('appointment.call');
      await deliverPendingSideEffects(_ref);
      _refreshQueue();
    }
    return r;
  }

  /// "Patient arrived" — stamps the check-in time and moves the visit to
  /// `inProgress`. [fromNoShow] is set when this is correcting an earlier
  /// "Patient not arrived": the visit was `noShow` and is being reinstated, so
  /// the audit trail records the reversal rather than a plain arrival.
  Future<Result<void>> markArrived({bool fromNoShow = false}) async {
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .markArrived(appointmentId, staffId: _doctorId, at: DateTime.now());
    if (r.isOk) {
      await _audit(
        fromNoShow ? 'appointment.noshow_cleared' : 'appointment.arrive',
      );
      _refreshQueue();
    }
    return r;
  }

  Future<Result<void>> markNoShow() async {
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .updateStatus(
          id: appointmentId,
          staffId: _doctorId,
          status: AppointmentStatus.noShow,
        );
    if (r.isOk) {
      await _audit('appointment.noshow');
      _refreshQueue();
    }
    return r;
  }

  /// Ask the admin to refer this patient out. The admin decides where.
  Future<Result<ReferralRequest>> requestReferral(String reason) async {
    final appt = await _ref.read(
      consultationAppointmentProvider(appointmentId).future,
    );
    final r = await _ref
        .read(referralRequestRepositoryProvider)
        .create(
          NewReferralRequest(
            patientId: appt.patientId,
            requestedByStaffId: _doctorId,
            reason: reason,
            appointmentId: appointmentId,
          ),
        );
    if (r case Ok(:final value)) {
      await _audit('referral.request', detail: value.id);
      _ref
        ..invalidate(consultationReferralProvider(appointmentId))
        ..invalidate(
          consultationDraftProvider(appointmentId),
        ); // caller also flips the flag
    }
    return r;
  }

  /// "Complete consultation" — sign the note and close the visit.
  ///
  /// The draft is saved first so what is signed is exactly what is on file,
  /// then the encounter repository finalizes everything in one transaction.
  /// Finalizing is at most once per appointment: a retry after a failure or
  /// a lost response returns the note already signed and writes nothing
  /// twice.
  Future<Result<SignedNote>> complete(
    ConsultationDraft draft, {
    String? outcomeNote,
  }) async {
    final appt = await _ref.read(
      consultationAppointmentProvider(appointmentId).future,
    );
    final result = await _ref
        .read(encounterRepositoryProvider)
        .finalize(
          FinalizeEncounter(
            appointmentId: appointmentId,
            staffId: _doctorId,
            note: draft.note,
            medications: [
              for (final m in draft.meds)
                DraftMedicationData(
                  name: m.name,
                  dose: m.dose,
                  frequency: m.frequency,
                ),
            ],
            outcomeNote: outcomeNote,
          ),
          idempotencyKey: _ref.read(_finalizeKeyProvider(appointmentId)),
        );
    if (result.isOk) {
      _ref
        ..invalidate(consultationDraftProvider(appointmentId))
        ..invalidate(consultationDraftSaveStateProvider(appointmentId))
        ..invalidate(chartTimelinePageProvider(appt.patientId))
        ..invalidate(chartMedicationsProvider(appt.patientId));
      _refreshQueue();
      await deliverPendingSideEffects(_ref);
    }
    return result;
  }
}

/// One idempotency key per appointment for this session's finalize attempts,
/// so a retry after a lost response is recognised as the same request.
final _finalizeKeyProvider = Provider.family<IdempotencyKey, String>(
  (ref, _) => IdempotencyKey.generate(),
);

final consultationControllerProvider =
    Provider.family<ConsultationController, String>(ConsultationController.new);

// --- helpers ----------------------------------------------------------

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
