/// Contracts for the consultation flow: the department walk-in queue and the
/// doctor→admin referral request.
library;

import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

class NewWalkInTicket {
  const NewWalkInTicket({
    required this.patientId,
    required this.departmentId,
    required this.createdByStaffId,
    this.reason,
    this.sourceAppointmentId,
  });

  final String patientId;
  final String departmentId;
  final String createdByStaffId;
  final String? reason;
  final String? sourceAppointmentId;
}

abstract interface class WalkInTicketRepository {
  /// Creates the ticket, assigning `[department letter]-[per-department count
  /// that day]` as the tag.
  Future<Result<WalkInTicket>> create(NewWalkInTicket request);

  Future<Result<List<WalkInTicket>>> forDepartment(
    String departmentId, {
    bool openOnly,
  });

  Future<Result<List<WalkInTicket>>> forPatient(String patientId);

  Future<Result<WalkInTicket>> byId(String id);

  /// A doctor picks the ticket up: `status = inProgress`, records who claimed
  /// it and the [Appointment] created for the visit.
  Future<Result<WalkInTicket>> claim({
    required String id,
    required String doctorId,
    required String resultAppointmentId,
  });

  Future<Result<WalkInTicket>> resolve(String id);

  /// Marks the walk-in behind [appointmentId] done, if there is one — called
  /// when the consultation for that visit completes. A no-op otherwise.
  Future<Result<void>> resolveByAppointment(String appointmentId);

  Future<Result<WalkInTicket>> cancel(String id);
}

class NewReferralRequest {
  const NewReferralRequest({
    required this.patientId,
    required this.requestedByStaffId,
    required this.reason,
    this.appointmentId,
  });

  final String patientId;
  final String requestedByStaffId;
  final String reason;
  final String? appointmentId;
}

abstract interface class ReferralRequestRepository {
  Future<Result<ReferralRequest>> create(NewReferralRequest request);

  Future<Result<List<ReferralRequest>>> pending();

  Future<Result<List<ReferralRequest>>> forPatient(String patientId);

  /// The pending request tied to one appointment, if any — the consultation
  /// page shows "Referral requested" when this is non-null.
  Future<Result<ReferralRequest?>> pendingForAppointment(String appointmentId);

  Future<Result<ReferralRequest>> decide({
    required String id,
    required ReferralRequestStatus status,
    required String adminId,
    String? note,
  });
}
