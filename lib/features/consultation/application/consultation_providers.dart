/// The consultation flow: an in-memory draft that survives navigating away and
/// back, and the controller that walks an appointment call → arrive →
/// (notes / meds / referral request) → complete.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/consultation_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../auth/application/session.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../../staff_dashboard/application/staff_providers.dart';

// --- draft (in-memory, keyed by appointment id) ---------------------------

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
  });

  final String note;
  final List<DraftMed> meds;

  /// True once the doctor has submitted a referral request from this page.
  final bool referralRequested;

  bool get isEmpty => note.trim().isEmpty && meds.isEmpty && !referralRequested;

  ConsultationDraft copyWith({
    String? note,
    List<DraftMed>? meds,
    bool? referralRequested,
  }) => ConsultationDraft(
    note: note ?? this.note,
    meds: meds ?? this.meds,
    referralRequested: referralRequested ?? this.referralRequested,
  );
}

/// Survives leaving and returning to the consultation page during the session;
/// [ConsultationController.complete] clears it.
final consultationDraftProvider =
    StateProvider.family<ConsultationDraft, String>(
      (ref, _) => const ConsultationDraft(),
    );

// --- reads --------------------------------------------------------------

final consultationAppointmentProvider =
    FutureProvider.family<Appointment, String>((ref, appointmentId) async {
      return _unwrap(
        await ref.watch(appointmentRepositoryProvider).byId(appointmentId),
      );
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
        .markCalledIn(appointmentId, DateTime.now());
    if (r.isOk) {
      await _audit('appointment.call');
      await _ref
          .read(notificationRepositoryProvider)
          .send(
            NewNotification(
              recipientId: appt.patientId,
              category: NotificationCategory.appointment,
              title: 'You have been called in',
              body: appt.roomNumber == null
                  ? 'Please make your way to the consultation room.'
                  : 'Please proceed to room ${appt.roomNumber}.',
            ),
          );
      _refreshQueue();
    }
    return r;
  }

  /// "Patient arrived" — the visit goes in-progress and the consultation opens.
  Future<Result<void>> markArrived() async {
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .markArrived(appointmentId, DateTime.now());
    if (r.isOk) {
      await _audit('appointment.arrive');
      _refreshQueue();
    }
    return r;
  }

  Future<Result<void>> markNoShow() async {
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .updateStatus(id: appointmentId, status: AppointmentStatus.noShow);
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

  /// "Complete consultation" — commit the draft to the record and close the
  /// visit. Everything in [draft] is written; the draft is then cleared.
  Future<Result<void>> complete(
    ConsultationDraft draft, {
    String? outcomeNote,
  }) async {
    final appt = await _ref.read(
      consultationAppointmentProvider(appointmentId).future,
    );
    return Result.guardAsync(() async {
      final records = _ref.read(recordRepositoryProvider);
      final meds = _ref.read(medicationRepositoryProvider);

      if (draft.note.trim().isNotEmpty) {
        _throwIfErr(
          await records.add(
            NewRecord(
              patientId: appt.patientId,
              recordType: RecordType.visitNote,
              title: 'Consultation note',
              occurredAt: DateTime.now(),
              authorStaffId: _doctorId,
              appointmentId: appointmentId,
              body: draft.note.trim(),
            ),
          ),
        );
      }

      for (final m in draft.meds) {
        _throwIfErr(
          await meds.prescribe(
            Medication(
              id: newId('med'),
              patientId: appt.patientId,
              name: m.name,
              dose: m.dose,
              frequency: m.frequency,
              prescriberId: _doctorId,
              appointmentId: appointmentId,
              startDate: DateTime.now(),
              isActive: true,
            ),
          ),
        );
        await _ref
            .read(notificationRepositoryProvider)
            .send(
              NewNotification(
                recipientId: appt.patientId,
                category: NotificationCategory.prescription,
                title: 'New prescription',
                body: [m.name, ?m.dose, ?m.frequency].join(' · '),
              ),
            );
      }

      _throwIfErr(
        await _ref
            .read(appointmentRepositoryProvider)
            .completeVisit(id: appointmentId, outcomeNote: outcomeNote),
      );
      // If this visit came from a department walk-in, close that ticket too.
      await _ref
          .read(walkInTicketRepositoryProvider)
          .resolveByAppointment(appointmentId);

      await _audit('appointment.complete');

      _ref
        ..invalidate(consultationDraftProvider(appointmentId))
        ..invalidate(chartTimelineProvider(appt.patientId))
        ..invalidate(chartMedicationsProvider(appt.patientId));
      _refreshQueue();
    });
  }
}

final consultationControllerProvider =
    Provider.family<ConsultationController, String>(ConsultationController.new);

// --- helpers ----------------------------------------------------------

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

void _throwIfErr(Result<Object?> r) {
  if (r case Err(:final failure)) throw failure;
}
