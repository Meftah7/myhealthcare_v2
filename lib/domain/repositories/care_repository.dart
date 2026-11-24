/// Care-services contracts (P10 Batch B): sick-leave certificates, patient
/// <-> doctor messaging, home-visit requests.
library;

import '../../core/data/contracts.dart';
import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';
import 'notification_repository.dart';

class NewSickLeave {
  const NewSickLeave({
    required this.patientId,
    required this.issuedByStaffId,
    required this.diagnosis,
    required this.fromDate,
    required this.toDate,
    this.appointmentId,
    this.notes,
  });

  final String patientId;
  final String issuedByStaffId;
  final String diagnosis;
  final DateTime fromDate;
  final DateTime toDate;
  final String? appointmentId;
  final String? notes;
}

/// Sick leave is requested by a doctor (or dentist) and approved or rejected
/// by an administrator. Only approved certificates are the patient's: they
/// are all [forPatient] and [issuedBy] ever return.
abstract interface class SickLeaveRepository {
  /// The patient's approved certificates.
  Future<Result<List<SickLeaveCertificate>>> forPatient(String patientId);

  /// Approved certificates a clinician requested.
  Future<Result<List<SickLeaveCertificate>>> issuedBy(String staffId);

  Future<Result<SickLeaveCertificate>> byId(String id);

  /// Every request made from one visit, whatever its status — so the
  /// consultation screen can show "awaiting approval", "approved" or
  /// "rejected".
  Future<Result<List<SickLeaveCertificate>>> forAppointment(
    String appointmentId,
  );

  /// A clinician asks for a certificate; it waits for an administrator.
  Future<Result<SickLeaveCertificate>> request(NewSickLeave certificate);

  /// Administrators: requests with [status] (default: awaiting a decision),
  /// oldest first.
  Future<Result<List<SickLeaveCertificate>>> requests({
    SickLeaveStatus status = SickLeaveStatus.requested,
  });

  /// Administrators: approve a request — it becomes the patient's
  /// certificate, issued now, and the patient is told.
  Future<Result<SickLeaveCertificate>> approve(String id);

  /// Administrators: reject a request with a reason the clinician is told.
  Future<Result<SickLeaveCertificate>> reject(
    String id, {
    required String reason,
  });
}

abstract interface class CareMessageRepository {
  /// One [CareThread] per doctor the patient has messaged, newest activity
  /// first.
  Future<Result<List<CareThread>>> threadsForPatient(String patientId);

  /// One [CareThread] per patient who has messaged this doctor.
  Future<Result<List<CareThread>>> threadsForStaff(String staffId);

  /// Every message in one thread, oldest first.
  Future<Result<List<CareMessage>>> thread({
    required String patientId,
    required String staffId,
  });

  /// A retry with the same [idempotencyKey] returns the message already
  /// sent instead of sending it twice. [notify] goes through the outbox, in
  /// the same transaction as the message.
  Future<Result<CareMessage>> send({
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
    IdempotencyKey? idempotencyKey,
    List<NewNotification> notify,
  });

  /// Patient messages still waiting for a clinician's reply that [staffId]
  /// owns or covers — oldest due first. With [staffId] null, every waiting
  /// message (administrator oversight).
  Future<Result<List<CareMessage>>> awaitingReply({String? staffId});

  /// Marks the counterpart's messages in a thread as read.
  Future<Result<void>> markRead({
    required String patientId,
    required String staffId,
    required bool readerIsStaff,
  });
}

class NewHomeVisitRequest {
  const NewHomeVisitRequest({
    required this.patientId,
    required this.addressText,
    required this.preferredDate,
    required this.reasonText,
    this.departmentId,
  });

  final String patientId;
  final String addressText;
  final DateTime preferredDate;
  final String reasonText;
  final String? departmentId;
}

abstract interface class HomeVisitRepository {
  Future<Result<List<HomeVisitRequest>>> forPatient(String patientId);
  Future<Result<List<HomeVisitRequest>>> all({HomeVisitStatus? status});
  Future<Result<HomeVisitRequest>> byId(String id);
  Future<Result<HomeVisitRequest>> create(
    NewHomeVisitRequest request, {
    IdempotencyKey? idempotencyKey,
  });

  Future<Result<HomeVisitRequest>> decide({
    required String id,
    required HomeVisitStatus status,
    int? expectedVersion,
    List<NewNotification> notify,
    String? assignedStaffId,
    String? decisionNote,
  });

  /// Patient-initiated withdrawal of an open request.
  Future<Result<HomeVisitRequest>> cancel({
    required String id,
    required String patientId,
    int? expectedVersion,
  });
}
