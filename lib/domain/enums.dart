/// Shared enums used across the data and domain layers (Phase 1).
///
/// Stored in the database by name (`.textEnum`), so **renaming a value is a
/// breaking schema change** — add a migration if you do.
library;

enum UserRole { patient, staff, admin }

enum Gender { female, male, other, undisclosed }

enum AppointmentStatus { booked, confirmed, completed, cancelled, noShow }

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
enum AbnormalFlag { normal, low, high, critical }

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
