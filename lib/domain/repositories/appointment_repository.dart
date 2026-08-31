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
}

abstract interface class AppointmentRepository {
  Future<Result<Appointment>> byId(String id);

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

  Future<Result<Appointment>> book(BookingRequest request);

  Future<Result<Appointment>> reschedule({
    required String id,
    required DateTime newStart,
    required DateTime newEnd,
  });

  Future<Result<void>> cancel(String id);

  Future<Result<void>> updateStatus({
    required String id,
    required AppointmentStatus status,
  });

  Future<Result<void>> markCheckedIn(String id, DateTime at);
}
