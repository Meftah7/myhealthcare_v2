/// Appointment + scheduling contracts (P1-11).
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

/// A bookable time window produced by the slot generator (P4-12).
class OpenSlot {
  const OpenSlot({
    required this.staffId,
    required this.start,
    required this.end,
  });

  final String staffId;
  final DateTime start;
  final DateTime end;
}

class BookingRequest {
  const BookingRequest({
    required this.patientId,
    required this.staffId,
    required this.start,
    required this.end,
    required this.visitType,
    this.departmentId,
    this.reasonText,
    this.noShowRisk,
    this.riskBand,
    this.bookedForName,
  });

  final String patientId;
  final String staffId;
  final DateTime start;
  final DateTime end;
  final VisitType visitType;
  final String? departmentId;
  final String? reasonText;
  final double? noShowRisk;
  final RiskBand? riskBand;

  /// A linked family member's name when the visit is for someone other than
  /// the account holder.
  final String? bookedForName;
}

abstract interface class AppointmentRepository {
  Future<Result<Appointment>> byId(String id);

  /// Whether this clinician has an established appointment relationship with
  /// the patient. Used as the minimum chart-access boundary.
  Future<Result<bool>> hasCareRelationship({
    required String staffId,
    required String patientId,
  });

  Future<Result<List<Appointment>>> forPatient(
    String patientId, {
    bool upcomingOnly,
  });

  Future<Result<List<Appointment>>> forStaffOnDay(String staffId, DateTime day);

  /// Every appointment for [staffId] in `[from, to)` — the staff week grid
  /// (P5-12).
  Future<Result<List<Appointment>>> forStaffInRange(
    String staffId,
    DateTime from,
    DateTime to,
  );

  /// Every appointment in `[from, to)`, any staff — panel + system analytics
  /// (P5-13, P5-17).
  Future<Result<List<Appointment>>> inRange(DateTime from, DateTime to);

  Stream<List<Appointment>> watchForStaffOnDay(String staffId, DateTime day);

  /// Free slots for a staff member on [day], derived from their schedule
  /// templates minus booked appointments.
  Future<Result<List<OpenSlot>>> openSlots(String staffId, DateTime day);

  /// [staffId]'s recurring weekly working blocks, ordered by weekday.
  Future<Result<List<ScheduleTemplate>>> templatesFor(String staffId);

  /// Replaces every schedule-template row for [staffId] with [templates] in
  /// one transaction — the admin schedule editor saves the whole week at once.
  Future<Result<List<ScheduleTemplate>>> setTemplates({
    required String staffId,
    required List<NewScheduleTemplate> templates,
  });

  Future<Result<Appointment>> book(BookingRequest request);

  /// [patientId] must match the appointment's own patient — the repository
  /// verifies this itself rather than trusting the caller, since a caller
  /// with permission to manage one patient's appointments must not be able
  /// to reach a *different* patient's appointment by ID alone.
  ///
  /// Rejects an interval that overlaps another active appointment for the
  /// same clinician, a past time, or an appointment that isn't in a
  /// reschedulable status. Rebuilds that appointment's reminders for the new
  /// time on success.
  Future<Result<Appointment>> reschedule({
    required String id,
    required String patientId,
    required DateTime newStart,
    required DateTime newEnd,
    Set<ReminderChannel>? enabledChannels,
  });

  /// [patientId] must match the appointment's own patient (see [reschedule]).
  /// Clears its unsent reminders. Cancelling an already-cancelled or
  /// completed appointment fails cleanly rather than silently no-op'ing.
  Future<Result<void>> cancel(String id, {required String patientId});

  /// [staffId] must match the appointment's own clinician — a staff member
  /// must not be able to change the status of a visit assigned to a
  /// different clinician just by knowing its ID. After [transfer], the
  /// appointment's staffId is the new clinician, who can then act on it.
  Future<Result<void>> updateStatus({
    required String id,
    required String staffId,
    required AppointmentStatus status,
  });

  Future<Result<void>> markCheckedIn(
    String id, {
    required String staffId,
    required DateTime at,
  });

  /// "Call patient" — stamps `calledInAt`; the status is unchanged.
  Future<Result<void>> markCalledIn(
    String id, {
    required String staffId,
    required DateTime at,
  });

  /// "Patient arrived" — stamps `checkedInAt` and moves the visit to
  /// [AppointmentStatus.inProgress].
  Future<Result<void>> markArrived(
    String id, {
    required String staffId,
    required DateTime at,
  });

  /// "Complete consultation" — [AppointmentStatus.completed] plus the doctor's
  /// closing summary.
  Future<Result<void>> completeVisit({
    required String id,
    required String staffId,
    String? outcomeNote,
  });

  /// Creates an in-progress visit for a walk-in ticket — no slot picking, the
  /// patient is already here. Returns the new appointment.
  Future<Result<Appointment>> openWalkInVisit({
    required String patientId,
    required String staffId,
    required String departmentId,
    required String ticketTag,
    String? reasonText,
  });

  /// Reassign an appointment to another staff member. The visit goes back to
  /// [AppointmentStatus.booked] so the receiving clinician re-accepts it, and
  /// the room number is recomputed for the new staff member's department
  /// (ported from the FirstSemMyHealth "transfer_appointment" action).
  ///
  /// [fromStaffId] must match the appointment's current clinician — the same
  /// ownership guarantee as [updateStatus] and friends.
  Future<Result<Appointment>> transfer({
    required String id,
    required String fromStaffId,
    required String toStaffId,
  });
}
