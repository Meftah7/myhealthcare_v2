/// Booking flow state + no-show-ranked slot suggestions (P4-12, P4-14, P4-17).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../services/ml/feature_extractor.dart';
import '../../../services/ml/no_show_predictor.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';

/// The trained no-show model, loaded once from the bundled asset.
final noShowModelProvider = FutureProvider<NoShowModel>(
  (ref) => NoShowModel.load(),
);

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return _unwrap(await ref.watch(departmentRepositoryProvider).all());
});

/// Staff in a department (id) — for the "choose a doctor" step.
final departmentStaffProvider = FutureProvider.family<List<Staff>, String>((
  ref,
  departmentId,
) async {
  return _unwrap(
    await ref.watch(userRepositoryProvider).staffInDepartment(departmentId),
  );
});

/// A candidate slot with its predicted no-show risk and a plain-language reason.
class RankedSlot {
  const RankedSlot({
    required this.slot,
    required this.probability,
    required this.band,
    required this.reason,
  });

  final OpenSlot slot;
  final double probability;
  final RiskBand band;
  final String reason;
}

class BookingRequestDraft {
  const BookingRequestDraft({
    this.departmentId,
    this.staffId,
    this.date,
    this.visitType = VisitType.followUp,
    this.reason,
  });

  final String? departmentId;
  final String? staffId;
  final DateTime? date;
  final VisitType visitType;
  final String? reason;

  BookingRequestDraft copyWith({
    String? departmentId,
    String? staffId,
    DateTime? date,
    VisitType? visitType,
    String? reason,
  }) => BookingRequestDraft(
    departmentId: departmentId ?? this.departmentId,
    staffId: staffId ?? this.staffId,
    date: date ?? this.date,
    visitType: visitType ?? this.visitType,
    reason: reason ?? this.reason,
  );
}

final bookingDraftProvider = StateProvider<BookingRequestDraft>(
  (_) => const BookingRequestDraft(),
);

/// Ranked open slots for the current draft (staff + date), best first.
final rankedSlotsProvider = FutureProvider<List<RankedSlot>>((ref) async {
  final draft = ref.watch(bookingDraftProvider);
  if (draft.staffId == null || draft.date == null) return const [];

  final appts = ref.watch(appointmentRepositoryProvider);
  final slots = _unwrap(await appts.openSlots(draft.staffId!, draft.date!));
  if (slots.isEmpty) return const [];

  final patient = await ref.watch(patientProfileProvider.future);
  final history = await ref.watch(patientAppointmentsProvider.future);
  final model = await ref.watch(noShowModelProvider.future);

  final resolved = history.where(
    (a) =>
        a.status == AppointmentStatus.completed ||
        a.status == AppointmentStatus.noShow ||
        a.status == AppointmentStatus.cancelled,
  );
  final priorNoShowRate = resolved.isEmpty
      ? 0.0
      : resolved.where((a) => a.status == AppointmentStatus.noShow).length /
            resolved.length;

  final ranked = <RankedSlot>[];
  for (final s in slots) {
    final features = NoShowFeatureInput(
      leadTimeDays: s.start.difference(DateTime.now()).inHours / 24.0,
      priorNoShowRate: priorNoShowRate,
      priorAppointmentCount: resolved.length,
      ageYears: patient.user.ageYears ?? 40,
      visitType: draft.visitType,
      dayOfWeek: s.start.weekday,
      hourOfDay: s.start.hour,
      hasChronicCondition: patient.hasChronicCondition,
      remindersAcknowledged: 0,
    );
    final pred = model.predict(features.toVector());
    ranked.add(
      RankedSlot(
        slot: s,
        probability: pred.probability,
        band: pred.band,
        reason: _reasonFor(pred, s),
      ),
    );
  }

  // Best = lowest predicted no-show risk, earliest as the tie-breaker.
  ranked.sort((a, b) {
    final r = a.probability.compareTo(b.probability);
    return r != 0 ? r : a.slot.start.compareTo(b.slot.start);
  });
  return ranked;
});

String _reasonFor(NoShowPrediction pred, OpenSlot slot) {
  final top = pred.contributions.first;
  final direction = top.contribution > 0 ? 'raises' : 'lowers';
  final label = switch (top.name) {
    'lead_time_days' => 'the wait until this slot',
    'prior_no_show_rate' => 'your past attendance',
    'is_first_visit' => 'this being an early visit',
    'has_chronic_condition' => 'your ongoing care',
    'hour_of_day' => 'the time of day',
    _ => top.name.replaceAll('_', ' '),
  };
  return switch (pred.band) {
    RiskBand.low => 'Good attendance odds — $label $direction the estimate.',
    RiskBand.medium => 'Moderate risk — mainly $label.',
    RiskBand.high => 'Higher no-show risk — driven by $label.',
  };
}

class BookingController {
  BookingController(this._ref);
  final Ref _ref;

  Future<Result<Appointment>> confirm(RankedSlot slot) async {
    final draft = _ref.read(bookingDraftProvider);
    final patientId = _ref.read(currentUserProvider)!.id;
    final result = await _ref
        .read(appointmentRepositoryProvider)
        .book(
          BookingRequest(
            patientId: patientId,
            staffId: slot.slot.staffId,
            start: slot.slot.start,
            end: slot.slot.end,
            visitType: draft.visitType,
            departmentId: draft.departmentId,
            reasonText: draft.reason,
            noShowRisk: slot.probability,
            riskBand: slot.band,
          ),
        );
    if (result case Ok(:final value)) {
      _ref
        ..invalidate(patientAppointmentsProvider)
        ..invalidate(rankedSlotsProvider);
      await _ref
          .read(reminderSchedulerProvider)
          .scheduleFor(
            appointmentId: value.id,
            slotStart: value.slotStart,
            band: value.riskBand ?? RiskBand.low,
          );
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.book',
            entityType: 'appointment',
            entityId: value.id,
            actorUserId: patientId,
          );
    }
    return result;
  }
}

final bookingControllerProvider = Provider<BookingController>(
  BookingController.new,
);

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
