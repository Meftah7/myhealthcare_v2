/// Contracts for the consultation flow: the department walk-in queue and the
/// doctor→admin referral request.
library;

import '../../core/data/contracts.dart';
import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

class DraftMedicationData {
  const DraftMedicationData({required this.name, this.dose, this.frequency});

  final String name;
  final String? dose;
  final String? frequency;
}

class EncounterDraftData {
  const EncounterDraftData({
    required this.appointmentId,
    required this.patientId,
    required this.authorStaffId,
    this.note = '',
    this.medications = const [],
    this.referralRequested = false,
    this.version = 1,
    this.updatedAt,
  });

  final String appointmentId;
  final String patientId;
  final String authorStaffId;
  final String note;
  final List<DraftMedicationData> medications;
  final bool referralRequested;
  final int version;
  final DateTime? updatedAt;
}

abstract interface class EncounterDraftRepository {
  Future<Result<EncounterDraftData?>> forAppointment(String appointmentId);

  Future<Result<EncounterDraftData>> save(
    EncounterDraftData draft, {
    int? expectedVersion,
  });

  Future<Result<void>> discard(String appointmentId);
}

/// A finalized encounter note (Phase 4). Immutable once signed — the
/// database rejects updates and deletes; corrections are [NoteAmendment]s.
class SignedNote {
  const SignedNote({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.authorStaffId,
    required this.body,
    required this.signedAt,
    this.amendments = const [],
  });

  final String id;
  final String appointmentId;
  final String patientId;
  final String authorStaffId;
  final String body;
  final DateTime signedAt;

  /// Oldest first.
  final List<NoteAmendment> amendments;
}

class NoteAmendment {
  const NoteAmendment({
    required this.id,
    required this.signedNoteId,
    required this.authorStaffId,
    required this.body,
    required this.amendedAt,
  });

  final String id;
  final String signedNoteId;
  final String authorStaffId;
  final String body;
  final DateTime amendedAt;
}

/// What a clinician signs when completing a visit.
class FinalizeEncounter {
  const FinalizeEncounter({
    required this.appointmentId,
    required this.staffId,
    this.note = '',
    this.medications = const [],
    this.outcomeNote,
  });

  final String appointmentId;
  final String staffId;
  final String note;
  final List<DraftMedicationData> medications;
  final String? outcomeNote;
}

abstract interface class EncounterRepository {
  /// Signs the note, files the visit note and medication orders, queues the
  /// patient's prescription notices, closes the visit and any walk-in, and
  /// clears the draft — all in one transaction. Finalization happens at most
  /// once per appointment: a retry (same key, a new key after a crash, or a
  /// second tap) returns the note already signed and writes nothing more.
  Future<Result<SignedNote>> finalize(
    FinalizeEncounter request, {
    IdempotencyKey? idempotencyKey,
  });

  Future<Result<SignedNote?>> signedNoteFor(String appointmentId);

  /// Appends a correction to a signed note; the original never changes.
  Future<Result<NoteAmendment>> amend({
    required String signedNoteId,
    required String staffId,
    required String body,
  });
}

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
  Future<Result<WalkInTicket>> create(
    NewWalkInTicket request, {
    IdempotencyKey? idempotencyKey,
  });

  Future<Result<List<WalkInTicket>>> forDepartment(
    String departmentId, {
    bool openOnly,
  });

  Future<Result<List<WalkInTicket>>> forPatient(String patientId);

  Future<Result<WalkInTicket>> byId(String id);

  /// A doctor picks the ticket up: `status = inProgress`, records who claimed
  /// it and the [Appointment] created for the visit.
  ///
  /// Only an open, unclaimed ticket can be claimed: when two clinicians race,
  /// exactly one wins and the other gets `ConflictFailure`.
  /// [expectedVersion] additionally pins the ticket state the caller saw.
  Future<Result<WalkInTicket>> claim({
    required String id,
    required String doctorId,
    required String resultAppointmentId,
    int? expectedVersion,
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
  Future<Result<ReferralRequest>> create(
    NewReferralRequest request, {
    IdempotencyKey? idempotencyKey,
  });

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
    int? expectedVersion,
  });

  /// Moves a referral along send → clarify → accept → arrange → close (or
  /// rejects it). Every step names an owner; the owner can change but a
  /// referral can never become unowned. Asking for clarification notifies
  /// the requesting clinician.
  Future<Result<ReferralRequest>> transition({
    required String id,
    required ReferralRequestStatus status,
    required String actorId,
    required String ownerStaffId,
    String? coverageStaffId,
    String? handoverNote,
    DateTime? dueAt,
    WorkPriority? priority,
    int? expectedVersion,
  });

  /// Hands an open referral to [newOwnerId] without changing its state — a
  /// shift change. Needs a handover note; the old owner stays on record in
  /// the audit log.
  Future<Result<ReferralRequest>> handover({
    required String id,
    required String actorId,
    required String newOwnerId,
    required String note,
    int? expectedVersion,
  });
}
