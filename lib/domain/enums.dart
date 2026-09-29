/// Shared enums used across the data and domain layers (Phase 1).
///
/// Stored in the database by name (`.textEnum`), so **renaming a value is a
/// breaking schema change** — add a migration if you do.
library;

enum UserRole { patient, staff, admin }

/// A staff member's live availability, shown on the staff dashboard and in the
/// staff directory (ported from the FirstSemMyHealth doctor "presence" toggle).
enum PresenceStatus { onDuty, inConsultation, onBreak, offShift }

enum Gender { female, male, other, undisclosed }

/// booked → confirmed (accepted) → inProgress (patient in the room) →
/// completed. `cancelled` / `noShow` are terminal from any pre-completion
/// state.
enum AppointmentStatus {
  booked,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

/// A walk-in ticket's lifecycle (`WalkInTickets`) — a patient sent to a
/// department's desk without a scheduled slot, e.g. after a department
/// referral. `inProgress` once a doctor there has started the visit.
enum WalkInStatus { waiting, called, inProgress, done, cancelled }

/// A doctor's request for the admin to refer a patient out (`ReferralRequests`).
/// The doctor supplies only the reason; the admin decides where and executes.
enum ReferralRequestStatus {
  pending,
  clarificationRequested,
  accepted,
  arranged,
  actioned,
  rejected,
  closed,
}

/// How soon owned clinical work (a result review, referral, task) is due.
enum WorkPriority { routine, priority, urgent }

/// A result review's lifecycle (Phase 4). unassigned → assigned → inReview →
/// resolved; any open state may be escalated to a covering clinician, and an
/// escalated review goes back into review or is resolved.
enum ResultReviewStatus { unassigned, assigned, inReview, resolved, escalated }

/// Whether a clinician has confirmed an observation's value (Phase 4).
enum VerificationStatus { unverified, verified, corrected }

/// Why the patient is coming in — a feature of the no-show model (P4-03).
enum VisitType {
  newPatient,
  followUp,
  routineCheckup,
  chronicCareReview,
  urgentCare,
  procedure,
  vaccination,
  labOnly,
}

/// No-show risk band (DESIGN.md §2.2 thresholds: <0.33 / 0.33–0.66 / >0.66).
enum RiskBand { low, medium, high }

enum RecordType {
  visitNote,
  labResult,
  imaging,
  prescription,
  vaccination,
  discharge,
  referral,
}

/// A lab value's position relative to its reference range (DESIGN.md §2.2).
/// `unknown` — no reference range was supplied, so the value cannot be
/// judged; it is never shown as normal (Phase 4).
enum AbnormalFlag { normal, low, high, critical, unknown }

enum TaskKind {
  followUpDue,
  unreviewedAbnormalLab,
  unsignedNote,
  medicationReview,
  referralAction,
  other,
}

enum TaskStatus { open, inProgress, done, dismissed }

enum RiskFlagKind {
  abnormalVitals,
  abnormalLab,
  medicationGap,
  overdueFollowUp,
  other,
}

/// Clinical flag severity (DESIGN.md §2.2 severity ramp).
enum Severity { info, warning, urgent }

/// Whether a risk flag came from the deterministic rule engine or the LLM.
enum FlagSource { rule, ai }

enum ReminderKind { standard, escalated, confirmRequest }

enum ReminderChannel { push, inApp, sms, email }

/// queued → delivered | failed | suppressed. A queued reminder with
/// attempts > 0 is waiting to retry after a transient failure.
enum ReminderDeliveryStatus { queued, delivered, failed, suppressed }

/// Lifecycle of a patient invoice. `overdue` is derived at read time from the
/// due date rather than stored, so it never goes stale in the database.
///
/// pending → paid (a settled payment only) → refunded (fully refunded);
/// pending → cancelled. The database rejects every other change (schema v24).
enum InvoiceStatus { pending, paid, cancelled, refunded }

/// What a payment transaction does (Phase 5).
enum PaymentKind { invoiceCharge, walletTopUp, refund }

/// How the money moved.
enum PaymentMethodKind { card, savedCard, wallet, offline }

/// A payment transaction's lifecycle (Phase 5).
///
/// `initiated` — recorded before the provider was asked; the outcome is not
/// known yet. `authorized` — the provider approved but has not captured.
/// `settled` — the provider (or the wallet ledger) confirmed the money moved;
/// only this marks an invoice paid. `failed` — declined, or the provider never
/// received it. `voided` — an authorization released without capture.
enum PaymentStatus { initiated, authorized, settled, failed, voided }

/// Whether a clinician has looked at a patient-imported document (Phase 5).
/// Clinic-authored records are `notRequired`.
enum ImportReviewStatus { notRequired, pendingReview, reviewed, rejected }

/// Lifecycle of a home-visit request (P10-08). `requested` is the patient's
/// submission; the clinic moves it from there.
enum HomeVisitStatus { requested, scheduled, completed, declined, cancelled }

/// A movement in the patient's wallet balance: money added, or money spent
/// settling an invoice. The balance itself is never stored — it's the sum of
/// these entries, so it can never drift from its history.
enum WalletTransactionType { topUp, redemption, refund }

/// What a linked family account can do with the owner's data.
enum FamilyLinkPermission { viewOnly, manage }

/// A family-link request's lifecycle. The owner must accept before the
/// viewer gets any access — declining or unlinking just removes the row.
enum FamilyLinkStatus { pending, accepted }

/// What a patient notification is about — drives its icon and accent.
enum NotificationCategory {
  appointment,
  billing,
  labResult,
  prescription,
  message,
  system,
}

/// What a piece of user feedback is about (ported from the FirstSemMyHealth
/// admin "Reports" / `feedback_reports.type`).
enum FeedbackCategory { bug, featureRequest, generalFeedback, complaint }

enum FeedbackStatus { open, resolved }

/// Which AI surface produced a log entry (admin "AI Logs" view).
enum AiFeature { careNavigator, clinicalScribe, patientSummary }
