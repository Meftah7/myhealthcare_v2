/// Booking flow state + no-show-ranked slot suggestions (P4-12, P4-14, P4-17).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../core/capabilities/capability_registry.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../services/ml/feature_extractor.dart';
import '../../../services/ml/no_show_predictor.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
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
    this.hasRiskEstimate = true,
  });

  final OpenSlot slot;
  final double probability;
  final RiskBand band;
  final String reason;
  final bool hasRiskEstimate;
}

class BookingRequestDraft {
  const BookingRequestDraft({
    this.departmentId,
    this.staffId,
    this.date,
    this.visitType = VisitType.followUp,
    this.reason,
    this.bookedForName,
  });

  final String? departmentId;
  final String? staffId;
  final DateTime? date;
  final VisitType visitType;
  final String? reason;

  /// Null = the account holder's own visit; otherwise the household
  /// member's name, shown on the visit. The visit itself is attached to that
  /// member's own patient record (see [BookingSubjectSelector]).
  final String? bookedForName;

  static const _keep = Object();

  BookingRequestDraft copyWith({
    String? departmentId,
    String? staffId,
    DateTime? date,
    VisitType? visitType,
    String? reason,
    Object? bookedForName = _keep,
  }) => BookingRequestDraft(
    departmentId: departmentId ?? this.departmentId,
    staffId: staffId ?? this.staffId,
    date: date ?? this.date,
    visitType: visitType ?? this.visitType,
    reason: reason ?? this.reason,
    bookedForName: identical(bookedForName, _keep)
        ? this.bookedForName
        : bookedForName as String?,
  );
}

final bookingDraftProvider = StateProvider<BookingRequestDraft>(
  (_) => const BookingRequestDraft(),
);

/// null = booking for the signed-in patient themself. Otherwise, a linked
/// family account's id — set when the wizard is opened from "Book for
/// [name]" on a "manage" linked account. Re-checked at [BookingController.
/// confirm] time, never trusted from the UI alone.
final bookingTargetPatientIdProvider = StateProvider<String?>((_) => null);

/// Whoever the current draft books a visit for — the signed-in patient, or
/// the linked account being booked for.
final _bookingSubjectProvider = FutureProvider<Patient>((ref) async {
  final targetId = ref.watch(bookingTargetPatientIdProvider);
  if (targetId == null) return ref.watch(patientProfileProvider.future);
  final actingPatientId = ref.watch(currentUserProvider)?.id;
  if (targetId == actingPatientId) {
    return ref.watch(patientProfileProvider.future);
  }
  final permission = await ref.watch(linkedPermissionProvider(targetId).future);
  if (permission != FamilyLinkPermission.manage) {
    throw const AuthFailure('You do not have manage access to this account.');
  }
  return ref.watch(linkedPatientProvider(targetId).future);
});

final _bookingSubjectHistoryProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final targetId = ref.watch(bookingTargetPatientIdProvider);
  if (targetId == null) return ref.watch(ownAppointmentsProvider.future);
  final actingPatientId = ref.watch(currentUserProvider)?.id;
  if (targetId == actingPatientId) {
    return ref.watch(ownAppointmentsProvider.future);
  }
  final permission = await ref.watch(linkedPermissionProvider(targetId).future);
  if (permission != FamilyLinkPermission.manage) {
    throw const AuthFailure('You do not have manage access to this account.');
  }
  return ref.watch(linkedAppointmentsProvider(targetId).future);
});

/// Ranked open slots for the current draft (staff + date), best first.
final rankedSlotsProvider = FutureProvider<List<RankedSlot>>((ref) async {
  final draft = ref.watch(bookingDraftProvider);
  if (draft.staffId == null || draft.date == null) return const [];

  // Authorize the booking subject before anything else, whether or not
  // risk ranking is enabled.
  final patient = await ref.watch(_bookingSubjectProvider.future);

  final appts = ref.watch(appointmentRepositoryProvider);
  final slots = _unwrap(await appts.openSlots(draft.staffId!, draft.date!));
  if (slots.isEmpty) return const [];

  final riskEnabled = phase8Capabilities
      .singleWhere((capability) => capability.id == 'no-show-risk')
      .mayShip;
  if (!riskEnabled) {
    return [
      for (final slot in slots..sort((a, b) => a.start.compareTo(b.start)))
        RankedSlot(
          slot: slot,
          probability: 0,
          band: RiskBand.low,
          reason:
              'Earliest available time; risk ranking is disabled pending validation.',
          hasRiskEstimate: false,
        ),
    ];
  }

  final history = await ref.watch(_bookingSubjectHistoryProvider.future);
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

  /// One idempotency key per (patient, clinician, slot) booking attempt,
  /// kept until it succeeds: tapping Confirm again after a failure or a lost
  /// response retries the *same* booking and can never book it twice.
  final Map<String, IdempotencyKey> _attempts = {};

  Future<Result<Appointment>> confirm(RankedSlot slot) async {
    final draft = _ref.read(bookingDraftProvider);
    final actingPatientId = _ref.read(currentUserProvider)!.id;
    final targetId = _ref.read(bookingTargetPatientIdProvider);

    String patientId;
    if (targetId != null && targetId != actingPatientId) {
      final guard = await _ref
          .read(familyLinkRepositoryProvider)
          .activeLink(
            viewerPatientId: actingPatientId,
            ownerPatientId: targetId,
          );
      if (guard case Err(:final failure)) return Err(failure);
      final link = guard.valueOrNull;
      if (link == null || !link.canManage) {
        return const Err(
          AuthFailure('You do not have manage access to this account.'),
        );
      }
      patientId = targetId;
    } else {
      patientId = actingPatientId;
    }

    final attempt =
        '$patientId|${slot.slot.staffId}|${slot.slot.start.toIso8601String()}';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
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
            noShowRisk: slot.hasRiskEstimate ? slot.probability : null,
            riskBand: slot.hasRiskEstimate ? slot.band : null,
            bookedForName: draft.bookedForName,
            idempotencyKey: key,
            enabledReminderChannels: _ref
                .read(notificationPrefsProvider)
                .enabledChannels,
          ),
        );
    if (result case Ok(:final value)) {
      _attempts.remove(attempt);
      _ref.invalidate(rankedSlotsProvider);
      // A household member's visit also shows in the account holder's list.
      _ref.invalidate(patientAppointmentsProvider);
      if (patientId != actingPatientId) {
        _ref.invalidate(linkedAppointmentsProvider(patientId));
      }
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.book',
            entityType: 'appointment',
            entityId: value.id,
            actorUserId: actingPatientId,
          );
    }
    return result;
  }
}

/// Who the visit is for. A household member is booked under their own
/// patient record (created on first use and reached through the account
/// holder's proxy grant), so the visit, its notes and its invoice land on
/// the right chart — the account holder and the patient stay distinct.
class BookingSubjectSelector {
  BookingSubjectSelector(this._ref);
  final Ref _ref;

  void selectSelf() {
    _ref.read(bookingTargetPatientIdProvider.notifier).state = null;
    final draft = _ref.read(bookingDraftProvider);
    _ref.read(bookingDraftProvider.notifier).state = draft.copyWith(
      bookedForName: null,
    );
  }

  Future<Result<String>> selectMember(FamilyMember member) async {
    final guardianId = _ref.read(currentUserProvider)?.id;
    if (guardianId == null) return const Err(SessionExpiredFailure());
    final result = await _ref
        .read(patientRepositoryProvider)
        .ensureDependentRecord(guardianId: guardianId, memberId: member.id);
    if (result case Ok(:final value)) {
      _ref.invalidate(patientFamilyMembersProvider);
      _ref.read(bookingTargetPatientIdProvider.notifier).state = value;
      final draft = _ref.read(bookingDraftProvider);
      _ref.read(bookingDraftProvider.notifier).state = draft.copyWith(
        bookedForName: member.fullName,
      );
    }
    return result;
  }
}

final bookingSubjectSelectorProvider = Provider<BookingSubjectSelector>(
  BookingSubjectSelector.new,
);

final bookingControllerProvider = Provider<BookingController>(
  BookingController.new,
);

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
