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

    /// When the doctor pressed "Call patient" on the schedule ticket.
    DateTime? calledInAt,

    /// When the doctor pressed "Patient arrived" — the visit is `inProgress`.
    DateTime? checkedInAt,

    /// The doctor's closing summary, written at "Complete consultation".
    String? outcomeNote,

    /// `[Hour letter A-X]-[facility-wide ticket number for that hour today]`,
    /// assigned once at booking time from [slotStart] (redesign v2 patient
    /// dashboard spec).
    String? ticketTag,

    /// `[Department letter]-[doctor's sequence within that department]`,
    /// assigned once at booking time (redesign v2 patient dashboard spec).
    String? roomNumber,

    /// The linked family member this visit was booked for, or null for the
    /// account holder's own visit.
    String? bookedForName,
  }) = _Appointment;

  const Appointment._();

  bool get isUpcoming =>
      slotStart.isAfter(DateTime.now()) &&
      (status == AppointmentStatus.booked ||
          status == AppointmentStatus.confirmed);

  bool get isPast =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.noShow ||
      (status != AppointmentStatus.inProgress &&
          slotEnd.isBefore(DateTime.now()));

  /// The patient is in the room — the consultation page is live.
  bool get isInProgress => status == AppointmentStatus.inProgress;

  bool get wasCalledIn => calledInAt != null;

  Duration get duration => slotEnd.difference(slotStart);
}
