/// Appointment entity (P1-09).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'appointment.freezed.dart';

@freezed
abstract class Appointment with _$Appointment {
  const factory Appointment({
    required String id,
    required String patientId,
    required String staffId,
    required DateTime slotStart,
    required DateTime slotEnd,
    required VisitType visitType,
    required AppointmentStatus status,
    required DateTime bookedAt,
    required int remindersSent,
    String? departmentId,
    String? reasonText,
    double? noShowRisk,
    RiskBand? riskBand,
    DateTime? checkedInAt,

    /// `[Hour letter A-X]-[facility-wide ticket number for that hour today]`,
    /// assigned once at booking time from [slotStart] (redesign v2 patient
    /// dashboard spec).
    String? ticketTag,

    /// `[Department letter]-[doctor's sequence within that department]`,
    /// assigned once at booking time (redesign v2 patient dashboard spec).
    String? roomNumber,
  }) = _Appointment;

  const Appointment._();

  bool get isUpcoming =>
      slotStart.isAfter(DateTime.now()) &&
      (status == AppointmentStatus.booked ||
          status == AppointmentStatus.confirmed);

  bool get isPast =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.noShow ||
      slotEnd.isBefore(DateTime.now());

  Duration get duration => slotEnd.difference(slotStart);
}
