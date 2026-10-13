/// The open encounter, kept visible across the staff workspace: patient,
/// reference, visit, appointment status, responsible clinician and the
/// note's stage (draft / awaiting signature / save failed / signed).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../staff_dashboard/application/staff_providers.dart';
import '../application/consultation_providers.dart';

/// The appointment whose consultation the clinician has open (set by the
/// consultation screen, cleared when the visit is completed or dismissed).
/// Resets whenever the signed-in account changes, so no patient context
/// survives sign-out.
final activeEncounterProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return null;
});

enum EncounterStage { notStarted, draft, awaitingSignature, saveFailed, signed }

EncounterStage encounterStage({
  required AppointmentStatus status,
  required DraftSaveState save,
  required bool canSign,
}) {
  if (status == AppointmentStatus.completed) return EncounterStage.signed;
  if (status != AppointmentStatus.inProgress) return EncounterStage.notStarted;
  if (save == DraftSaveState.failed || save == DraftSaveState.conflict) {
    return EncounterStage.saveFailed;
  }
  if (!canSign && save == DraftSaveState.saved) {
    return EncounterStage.awaitingSignature;
  }
  return EncounterStage.draft;
}

/// Label, accent and icon for a stage — meaning never by colour alone.
(String, PatientAccent, IconData) encounterStageStyle(
  AppLocalizations t,
  EncounterStage stage,
) => switch (stage) {
  EncounterStage.notStarted => (
    t.encStageNotStarted,
    PatientAccent.neutral,
    Icons.schedule,
  ),
  EncounterStage.draft => (
    t.encStageDraft,
    PatientAccent.blue,
    Icons.edit_note,
  ),
  EncounterStage.awaitingSignature => (
    t.encStageAwaitingSignature,
    PatientAccent.amber,
    Icons.hourglass_top,
  ),
  EncounterStage.saveFailed => (
    t.encStageSaveFailed,
    PatientAccent.red,
    Icons.error_outline,
  ),
  EncounterStage.signed => (
    t.encStageSigned,
    PatientAccent.green,
    Icons.verified_outlined,
  ),
};

class EncounterStageBadge extends ConsumerWidget {
  const EncounterStageBadge({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final appt = ref
        .watch(consultationAppointmentProvider(appointmentId))
        .valueOrNull;
    if (appt == null) return const SizedBox.shrink();
    final (label, accent, icon) = encounterStageStyle(
      t,
      encounterStage(
        status: appt.status,
        save: ref.watch(consultationDraftSaveStateProvider(appointmentId)),
        canSign: ref.watch(canProvider(Permission.signEncounter)),
      ),
    );
    return Semantics(
      liveRegion: true,
      child: StatusBadge(label, accent: accent, icon: icon),
    );
  }
}

/// Shell strip for the open encounter.
class EncounterContextBar extends ConsumerWidget {
  const EncounterContextBar({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appt = ref
        .watch(consultationAppointmentProvider(appointmentId))
        .valueOrNull;
    final patient = ref
        .watch(consultationPatientProvider(appointmentId))
        .valueOrNull;
    if (appt == null) return const SizedBox(height: 48);
    final me = ref.watch(currentUserProvider)?.id;
    final staff = ref.watch(staffDirectoryProvider).valueOrNull;
    final clinician = appt.staffId == me
        ? t.encYou
        : staff
                  ?.where((s) => s.id == appt.staffId)
                  .map((s) => staffDisplayName(s.fullName, s.jobTitle))
                  .firstOrNull ??
              '—';
    final reference = patient?.user.nationalId ?? appt.patientId;
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Space.md,
            Space.xs,
            Space.xs,
            Space.xs,
          ),
          child: Row(
            children: [
              const Icon(Icons.medical_information_outlined),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${patient?.fullName ?? '…'} · ${t.encPatientRef(reference)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${fmtTime(appt.slotStart)} · ${visitTypeLabel(appt.visitType)} · ${t.encResponsible(clinician)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        AppointmentStatusPill(appt.status, dense: true),
                        EncounterStageBadge(appointmentId: appointmentId),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.staffConsultation(appointmentId)),
                child: Text(t.encOpenVisit),
              ),
              IconButton(
                tooltip: t.clearSearchTooltip,
                onPressed: () =>
                    ref.read(activeEncounterProvider.notifier).state = null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
