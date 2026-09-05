/// Quick appointment — "Urgent" flow (redesign v2 patient dashboard).
///
/// Skips doctor selection entirely and auto-routes the ticket to the nearest
/// available doctor: "nearest" is interpreted as soonest-available in time,
/// across any department (not restricted to a single urgent-care/general
/// department).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';

class QuickAppointmentController {
  QuickAppointmentController(this._ref);
  final Ref _ref;

  /// How far ahead to search for the first staff member with any opening.
  static const _maxDaysAhead = 14;

  Future<Result<Appointment>> bookUrgent() {
    return Result.guardAsync(() async {
      final repo = _ref.read(appointmentRepositoryProvider);
      final staff = _unwrap(
        await _ref.read(userRepositoryProvider).byRole(UserRole.staff),
      );
      if (staff.isEmpty) {
        throw const ValidationFailure('No doctors are on the schedule.');
      }

      OpenSlot? best;
      String? bestStaffId;
      for (final s in staff) {
        final slot = await _earliestSlot(repo, s.id);
        if (slot != null && (best == null || slot.start.isBefore(best.start))) {
          best = slot;
          bestStaffId = s.id;
        }
      }
      final bestSlot = best;
      if (bestSlot == null || bestStaffId == null) {
        throw const ValidationFailure(
          'No doctors have an open slot in the next two weeks.',
        );
      }

      final staffProfile = _unwrap(
        await _ref.read(userRepositoryProvider).staffById(bestStaffId),
      );
      final patientId = _ref.read(currentUserProvider)!.id;

      final booked = _unwrap(
        await repo.book(
          BookingRequest(
            patientId: patientId,
            staffId: bestStaffId,
            start: bestSlot.start,
            end: bestSlot.end,
            visitType: VisitType.urgentCare,
            departmentId: staffProfile.departmentId,
          ),
        ),
      );

      _ref.invalidate(patientAppointmentsProvider);
      await _ref
          .read(reminderSchedulerProvider)
          .scheduleFor(
            appointmentId: booked.id,
            slotStart: booked.slotStart,
            band: booked.riskBand ?? RiskBand.low,
          );
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.book.urgent',
            entityType: 'appointment',
            entityId: booked.id,
            actorUserId: patientId,
          );
      return booked;
    });
  }

  /// The soonest open slot for [staffId] within [_maxDaysAhead] days, or null.
  Future<OpenSlot?> _earliestSlot(
    AppointmentRepository repo,
    String staffId,
  ) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < _maxDaysAhead; i++) {
      final day = dayStart.add(Duration(days: i));
      final result = await repo.openSlots(staffId, day);
      if (result case Ok(:final value) when value.isNotEmpty) {
        return value.first; // openSlots() returns slots sorted ascending.
      }
    }
    return null;
  }
}

final quickAppointmentControllerProvider =
    Provider<QuickAppointmentController>(QuickAppointmentController.new);

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
