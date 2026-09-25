/// Translated, human-readable labels for the domain enums (`domain/enums.dart`)
/// — one extension per enum, each pulling its strings from [AppLocalizations]
/// so a label is never hand-rolled twice with two different English wordings.
///
/// [VisitType] is deliberately *not* here — it already has a locale-aware
/// `visitTypeLabel()` in `core/utils/format.dart`, which is called from
/// contexts that often don't have a `BuildContext` (e.g. building a
/// notification body), so duplicating it as a context-based extension would
/// just create a second source of truth.
///
/// NOTE(i18n): these are net-new (nothing consumes them yet) — the ~19
/// existing files that already turn a status enum into English text via their
/// own inline `switch` should migrate to call the matching extension here as
/// each of those screens gets translated, rather than keep a second,
/// English-only copy of the same mapping.
library;

import 'package:flutter/widgets.dart';

import '../../domain/entities/family_member.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';

extension UserRoleLabel on UserRole {
  /// [gender] picks the grammatically-agreeing Arabic form for a patient
  /// ("مريض" / "مريضة") — English has no such agreement, so it's ignored
  /// there. Leave it null for a generic/unknown-gender label.
  String label(BuildContext context, {Gender? gender}) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      UserRole.patient => switch (gender) {
        Gender.male => t.rolePatientMale,
        Gender.female => t.rolePatientFemale,
        Gender.other || Gender.undisclosed || null => t.rolePatient,
      },
      UserRole.staff => t.roleStaff,
      UserRole.admin => t.roleAdmin,
    };
  }
}

extension PresenceStatusLabel on PresenceStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      PresenceStatus.onDuty => t.presenceOnDuty,
      PresenceStatus.inConsultation => t.presenceInConsultation,
      PresenceStatus.onBreak => t.presenceOnBreak,
      PresenceStatus.offShift => t.presenceOffShift,
    };
  }
}

extension GenderLabel on Gender {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      Gender.female => t.genderFemale,
      Gender.male => t.genderMale,
      Gender.other => t.genderOther,
      Gender.undisclosed => t.genderUndisclosed,
    };
  }
}

extension AppointmentStatusLabel on AppointmentStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      AppointmentStatus.booked => t.appointmentStatusBooked,
      AppointmentStatus.confirmed => t.appointmentStatusConfirmed,
      AppointmentStatus.inProgress => t.appointmentStatusInProgress,
      AppointmentStatus.completed => t.appointmentStatusCompleted,
      AppointmentStatus.cancelled => t.appointmentStatusCancelled,
      AppointmentStatus.noShow => t.appointmentStatusNoShow,
    };
  }
}

extension WalkInStatusLabel on WalkInStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      WalkInStatus.waiting => t.walkInStatusWaiting,
      WalkInStatus.called => t.walkInStatusCalled,
      WalkInStatus.inProgress => t.walkInStatusInProgress,
      WalkInStatus.done => t.walkInStatusDone,
      WalkInStatus.cancelled => t.walkInStatusCancelled,
    };
  }
}

extension ReferralRequestStatusLabel on ReferralRequestStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      ReferralRequestStatus.pending => t.referralRequestStatusPending,
      ReferralRequestStatus.actioned => t.referralRequestStatusActioned,
      ReferralRequestStatus.rejected => t.referralRequestStatusRejected,
    };
  }
}

extension RiskBandLabel on RiskBand {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      RiskBand.low => t.riskBandLow,
      RiskBand.medium => t.riskBandMedium,
      RiskBand.high => t.riskBandHigh,
    };
  }
}

extension RecordTypeLabel on RecordType {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      RecordType.visitNote => t.recordTypeVisitNote,
      RecordType.labResult => t.recordTypeLabResult,
      RecordType.imaging => t.recordTypeImaging,
      RecordType.prescription => t.recordTypePrescription,
      RecordType.vaccination => t.recordTypeVaccination,
      RecordType.discharge => t.recordTypeDischarge,
      RecordType.referral => t.recordTypeReferral,
    };
  }
}

extension AbnormalFlagLabel on AbnormalFlag {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      AbnormalFlag.normal => t.abnormalFlagNormal,
      AbnormalFlag.low => t.abnormalFlagLow,
      AbnormalFlag.high => t.abnormalFlagHigh,
      AbnormalFlag.critical => t.abnormalFlagCritical,
    };
  }
}

extension TaskKindLabel on TaskKind {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      TaskKind.followUpDue => t.taskKindFollowUpDue,
      TaskKind.unreviewedAbnormalLab => t.taskKindUnreviewedAbnormalLab,
      TaskKind.unsignedNote => t.taskKindUnsignedNote,
      TaskKind.medicationReview => t.taskKindMedicationReview,
      TaskKind.referralAction => t.taskKindReferralAction,
      TaskKind.other => t.taskKindOther,
    };
  }
}

extension TaskStatusLabel on TaskStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      TaskStatus.open => t.taskStatusOpen,
      TaskStatus.inProgress => t.taskStatusInProgress,
      TaskStatus.done => t.taskStatusDone,
      TaskStatus.dismissed => t.taskStatusDismissed,
    };
  }
}

extension RiskFlagKindLabel on RiskFlagKind {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      RiskFlagKind.abnormalVitals => t.riskFlagKindAbnormalVitals,
      RiskFlagKind.abnormalLab => t.riskFlagKindAbnormalLab,
      RiskFlagKind.medicationGap => t.riskFlagKindMedicationGap,
      RiskFlagKind.overdueFollowUp => t.riskFlagKindOverdueFollowUp,
      RiskFlagKind.other => t.riskFlagKindOther,
    };
  }
}

extension SeverityLabel on Severity {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      Severity.info => t.severityInfo,
      Severity.warning => t.severityWarning,
      Severity.urgent => t.severityUrgent,
    };
  }
}

extension FlagSourceLabel on FlagSource {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FlagSource.rule => t.flagSourceRule,
      FlagSource.ai => t.flagSourceAi,
    };
  }
}

extension ReminderKindLabel on ReminderKind {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      ReminderKind.standard => t.reminderKindStandard,
      ReminderKind.escalated => t.reminderKindEscalated,
      ReminderKind.confirmRequest => t.reminderKindConfirmRequest,
    };
  }
}

extension ReminderChannelLabel on ReminderChannel {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      ReminderChannel.push => t.reminderChannelPush,
      ReminderChannel.inApp => t.reminderChannelInApp,
      ReminderChannel.sms => t.reminderChannelSms,
      ReminderChannel.email => t.reminderChannelEmail,
    };
  }
}

extension InvoiceStatusLabel on InvoiceStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      InvoiceStatus.pending => t.invoiceStatusPending,
      InvoiceStatus.paid => t.invoiceStatusPaid,
      InvoiceStatus.cancelled => t.invoiceStatusCancelled,
    };
  }
}

extension HomeVisitStatusLabel on HomeVisitStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      HomeVisitStatus.requested => t.homeVisitStatusRequested,
      HomeVisitStatus.scheduled => t.homeVisitStatusScheduled,
      HomeVisitStatus.completed => t.homeVisitStatusCompleted,
      HomeVisitStatus.declined => t.homeVisitStatusDeclined,
      HomeVisitStatus.cancelled => t.homeVisitStatusCancelled,
    };
  }
}

extension NotificationCategoryLabel on NotificationCategory {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      NotificationCategory.appointment => t.notificationCategoryAppointment,
      NotificationCategory.billing => t.notificationCategoryBilling,
      NotificationCategory.labResult => t.notificationCategoryLabResult,
      NotificationCategory.prescription => t.notificationCategoryPrescription,
      NotificationCategory.message => t.notificationCategoryMessage,
      NotificationCategory.system => t.notificationCategorySystem,
    };
  }
}

extension FeedbackCategoryLabel on FeedbackCategory {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FeedbackCategory.bug => t.feedbackCategoryBug,
      FeedbackCategory.featureRequest => t.feedbackCategoryFeatureRequest,
      FeedbackCategory.generalFeedback => t.feedbackCategoryGeneralFeedback,
      FeedbackCategory.complaint => t.feedbackCategoryComplaint,
    };
  }
}

extension FeedbackStatusLabel on FeedbackStatus {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FeedbackStatus.open => t.feedbackStatusOpen,
      FeedbackStatus.resolved => t.feedbackStatusResolved,
    };
  }
}

extension AiFeatureLabel on AiFeature {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      AiFeature.careNavigator => t.aiFeatureCareNavigator,
      AiFeature.clinicalScribe => t.aiFeatureClinicalScribe,
      AiFeature.patientSummary => t.aiFeaturePatientSummary,
    };
  }
}

/// [InvoiceStatus] doesn't store "overdue" — it's derived at read time from
/// the due date — so it has no enum value of its own. Callers that already
/// compute "is this invoice overdue?" pass that alongside the stored status.
String invoiceStatusLabel(
  BuildContext context,
  InvoiceStatus status, {
  required bool overdue,
}) {
  if (overdue && status == InvoiceStatus.pending) {
    return AppLocalizations.of(context)!.invoiceStatusOverdue;
  }
  return status.label(context);
}

extension FamilyLinkPermissionLabel on FamilyLinkPermission {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FamilyLinkPermission.viewOnly => t.viewOnlyPermissionLabel,
      FamilyLinkPermission.manage => t.managePermissionLabel,
    };
  }

  String description(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FamilyLinkPermission.viewOnly => t.viewOnlyPermissionDescription,
      FamilyLinkPermission.manage => t.managePermissionDescription,
    };
  }
}

extension FamilyRelationshipLabel on FamilyRelationship {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return switch (this) {
      FamilyRelationship.spouse => t.familyRelationshipSpouse,
      FamilyRelationship.child => t.familyRelationshipChild,
      FamilyRelationship.parent => t.familyRelationshipParent,
      FamilyRelationship.sibling => t.familyRelationshipSibling,
      FamilyRelationship.guardian => t.familyRelationshipGuardian,
      FamilyRelationship.other => t.familyRelationshipOther,
    };
  }
}
