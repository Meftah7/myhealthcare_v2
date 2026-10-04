/// Appointment + scheduling contracts (P1-11).
library;

import '../../core/data/contracts.dart';
import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';
import 'notification_repository.dart';

/// A bookable time window produced by the slot generator (P4-12).
/// How one weekday × hour has gone in the past: counts and averages only,
/// never individual appointments — so a patient may read it to rank slots.
class SlotDemandStat {
  const SlotDemandStat({
    required this.weekday,
    required this.hour,
    required this.booked,
    required this.attended,
    required this.noShows,
    this.avgWaitMinutes,
  });

  /// `DateTime.weekday` (1 = Monday).
  final int weekday;
  final int hour;

  /// Past visits in this cell, cancelled ones included.
  final int booked;
  final int attended;
  final int noShows;

  /// Mean minutes from the booked time to being called in, when known.
  final double? avgWaitMinutes;

  /// Share of resolved visits (attended + missed) that were attended.
  double? get attendanceRate {
    final resolved = attended + noShows;
    return resolved == 0 ? null : attended / resolved;
  }
}

class OpenSlot {
  const OpenSlot({
    required this.staffId,
    required this.start,
    required this.end,
    this.resourceId,
    this.capacity = 1,
    this.version = 1,
  });

  final String staffId;
  final DateTime start;
  final DateTime end;
  final String? resourceId;
  final int capacity;
  final int version;
}

class ScheduleResource {
  const ScheduleResource({
    required this.id,
    required this.staffId,
    required this.slotDuration,
    required this.capacity,
    required this.version,
  });

  final String id;
  final String staffId;
  final Duration slotDuration;
  final int capacity;
  final int version;
}

class AvailabilityException {
  const AvailabilityException({
    required this.id,
    required this.staffId,
    required this.start,
    required this.end,
    this.reason,
    this.version = 1,
  });

  final String id;
  final String staffId;
  final DateTime start;
  final DateTime end;
  final String? reason;
  final int version;
}

class BookingReservation {
  const BookingReservation({
    required this.resourceId,
    required this.start,
    required this.end,
    required this.capacity,
    required this.resourceVersion,
  });

  final String resourceId;
  final DateTime start;
  final DateTime end;
  final int capacity;
  final int resourceVersion;
}

class AppointmentChangePolicy {
  const AppointmentChangePolicy({
    this.minimumNotice = const Duration(hours: 2),
  });

  final Duration minimumNotice;
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
    this.idempotencyKey,
    this.enabledReminderChannels,
    this.notify = const [],
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

  /// Reuse across retries of the same booking: a retry returns the
  /// appointment the first attempt committed instead of booking again.
  final IdempotencyKey? idempotencyKey;

  /// Channels enabled for this patient. These reminders commit atomically
  /// with the booking.
  final Set<ReminderChannel>? enabledReminderChannels;

  /// Notifications to deliver (through the outbox) if — and only if — the
  /// booking commits.
  final List<NewNotification> notify;
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

  /// Past demand by weekday × hour over the last [lookback] — for one
  /// clinician, or the whole clinic when [staffId] is null. Cells with fewer
  /// than [minSample] visits are left out, so no answer can point at a
  /// single person's visit. Any signed-in user may read it.
  Future<Result<List<SlotDemandStat>>> slotDemandStats({
    String? staffId,
    Duration lookback = const Duration(days: 365),
    int minSample = 5,
  });

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

  Future<Result<AvailabilityException>> addAvailabilityException({
    required String staffId,
    required DateTime start,
    required DateTime end,
    String? reason,
  });

  Future<Result<List<AvailabilityException>>> availabilityExceptions(
    String staffId,
    DateTime from,
    DateTime to,
  );

  Future<Result<Appointment>> book(BookingRequest request);

  // Every change below takes an optional `expectedVersion`: the
  // [Appointment.version] the caller's decision was based on. If the
  // appointment changed since, the call fails with `ConflictFailure` instead
  // of overwriting the newer state.

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
    int? expectedVersion,
  });

  /// [patientId] must match the appointment's own patient (see [reschedule]).
  /// Clears its unsent reminders. Cancelling an already-cancelled or
  /// completed appointment fails cleanly rather than silently no-op'ing.
  Future<Result<void>> cancel(
    String id, {
    required String patientId,
    int? expectedVersion,
  });

  /// [staffId] must match the appointment's own clinician — a staff member
  /// must not be able to change the status of a visit assigned to a
  /// different clinician just by knowing its ID. After [transfer], the
  /// appointment's staffId is the new clinician, who can then act on it.
  Future<Result<void>> updateStatus({
    required String id,
    required String staffId,
    required AppointmentStatus status,
    int? expectedVersion,
  });

  /// Updates the operational no-show band and rebuilds queued reminders in
  /// the same transaction.
  Future<Result<void>> updateRiskBand({
    required String id,
    required String staffId,
    required RiskBand riskBand,
    Set<ReminderChannel>? enabledChannels,
    int? expectedVersion,
  });

  Future<Result<void>> markCheckedIn(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
  });

  /// "Call patient" — stamps `calledInAt`; the status is unchanged.
  /// [notify] is delivered through the outbox if the call-in commits.
  Future<Result<void>> markCalledIn(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
    List<NewNotification> notify,
  });

  /// "Patient arrived" — stamps `checkedInAt` and moves the visit to
  /// [AppointmentStatus.inProgress].
  Future<Result<void>> markArrived(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
  });

  /// "Complete consultation" — [AppointmentStatus.completed] plus the doctor's
  /// closing summary.
  Future<Result<void>> completeVisit({
    required String id,
    required String staffId,
    String? outcomeNote,
    int? expectedVersion,
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
    int? expectedVersion,
  });
}
