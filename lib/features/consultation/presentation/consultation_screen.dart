/// The consultation page for one appointment. Reached from the schedule ticket
/// sheet ("Patient arrived") or the department walk-in queue ("Start"), and
/// re-openable to continue — the note and medications are held in an in-memory
/// draft that survives leaving the page.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/consultation_providers.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final _note = TextEditingController();
  final _outcome = TextEditingController();
  bool _busy = false;
  bool _seeded = false;

  String get _id => widget.appointmentId;
  ConsultationDraft get _draft => ref.read(consultationDraftProvider(_id));

  @override
  void initState() {
    super.initState();
    // Seed the field from the draft once, then keep the draft in step.
    final draft = ref.read(consultationDraftProvider(_id));
    _note.text = draft.note;
    _seeded = true;
    _note.addListener(_flushNote);
  }

  @override
  void dispose() {
    _note
      ..removeListener(_flushNote)
      ..dispose();
    _outcome.dispose();
    super.dispose();
  }

  void _flushNote() {
    if (!_seeded) return;
    ref.read(consultationDraftProvider(_id).notifier).state = _draft.copyWith(
      note: _note.text,
    );
  }

  void _update(ConsultationDraft next) =>
      ref.read(consultationDraftProvider(_id).notifier).state = next;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appt = ref.watch(consultationAppointmentProvider(_id));
    final patient = ref.watch(consultationPatientProvider(_id));

    return AppScaffold(
      titleWidget: appt.maybeWhen(
        data: (a) => patient.maybeWhen(
          data: (p) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  p.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: Space.sm),
              AppointmentStatusPill(a.status, dense: true),
            ],
          ),
          orElse: () => Text(t.consultationFallbackTitle),
        ),
        orElse: () => Text(t.consultationFallbackTitle),
      ),
      body: appt.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadThisAppointment,
          onRetry: () => ref.invalidate(consultationAppointmentProvider(_id)),
        ),
        data: (a) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                Space.xxl,
              ),
              children: [
                patient.when(
                  loading: () => const LoadingSkeleton(height: 96),
                  error: (e, _) =>
                      InlineBanner.error(t.couldNotLoadThePatient),
                  data: (p) => _PatientHeader(patient: p, appointment: a),
                ),
                const SizedBox(height: Space.md),
                if (a.status == AppointmentStatus.completed)
                  _CompletedCard(appointment: a)
                else if (a.status != AppointmentStatus.inProgress)
                  _PreVisitActions(appointment: a, busy: _busy, run: _run)
                else
                  ..._workingBody(a),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _workingBody(Appointment a) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = ref.watch(consultationDraftProvider(_id));
    final referral = ref.watch(consultationReferralProvider(_id));

    return [
      SectionHeader(t.clinicalNoteHeader, overline: true, first: true),
      TextField(
        controller: _note,
        minLines: 4,
        maxLines: 12,
        decoration: InputDecoration(
          hintText: t.historyExamHint,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: Space.xs),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => context.push(
            '${AppRoutes.staffScribe}?patient=${a.patientId}&appointment=$_id',
          ),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(t.openAiScribeAction),
        ),
      ),

      SectionHeader(t.quickActionMedications, overline: true),
      if (draft.meds.isEmpty)
        Text(
          t.noMedicationsAdded,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < draft.meds.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: Space.md),
                ListTile(
                  title: Text(draft.meds[i].name),
                  subtitle: Text(
                    [?draft.meds[i].dose, ?draft.meds[i].frequency].join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: t.removeTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: () => _update(
                      draft.copyWith(meds: [...draft.meds]..removeAt(i)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      const SizedBox(height: Space.xs),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: _addMedication,
          icon: const Icon(Icons.add, size: 18),
          label: Text(t.addMedicationAction),
        ),
      ),

      SectionHeader(t.referralHeader, overline: true),
      referral.maybeWhen(
        data: (req) => req != null || draft.referralRequested
            ? StatusPill(
                label: t.referralRequestedAwaitingAdmin,
                icon: Icons.hourglass_top_outlined,
                container: theme.colorScheme.tertiaryContainer,
                onContainer: theme.colorScheme.onTertiaryContainer,
              )
            : OutlinedButton.icon(
                onPressed: _requestReferral,
                icon: const Icon(Icons.forward_to_inbox_outlined, size: 18),
                label: Text(t.requestAReferralAction),
              ),
        orElse: () => const LoadingSkeleton(height: 40),
      ),

      const SizedBox(height: Space.lg),
      TextField(
        controller: _outcome,
        decoration: InputDecoration(
          labelText: t.visitSummaryOptionalLabel,
          hintText: t.visitSummaryHint,
        ),
      ),
      const SizedBox(height: Space.md),
      FilledButton(
        onPressed: (_busy || draft.isEmpty) ? null : _complete,
        child: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(t.completeConsultationAction),
      ),
      if (draft.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(
            t.addNoteMedOrReferralFirst,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }

  Future<void> _addMedication() async {
    final added = await showModalBottomSheet<DraftMed>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _AddMedicationSheet(),
      ),
    );
    if (added == null) return;
    _update(_draft.copyWith(meds: [..._draft.meds, added]));
  }

  Future<void> _requestReferral() async {
    final t = AppLocalizations.of(context)!;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _ReferralReasonSheet(),
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;
    if (!mounted) return;
    await _run(() async {
      final r = await ref
          .read(consultationControllerProvider(_id))
          .requestReferral(reason.trim());
      if (r.isOk) _update(_draft.copyWith(referralRequested: true));
      return r;
    }, ok: t.referralRequestedSnackbar);
  }

  Future<void> _complete() async {
    final t = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      title: t.completeConsultationTitle,
      message: t.completeConsultationBody,
      confirmLabel: t.completeAction,
    );
    if (!ok) return;
    await _run(
      () async {
        final r = await ref
            .read(consultationControllerProvider(_id))
            .complete(
              _draft,
              outcomeNote: _outcome.text.trim().isEmpty
                  ? null
                  : _outcome.text.trim(),
            );
        return r;
      },
      ok: t.consultationCompletedSnackbar,
      popOnOk: true,
    );
  }

  /// Runs a controller call with the busy flag + a result SnackBar.
  Future<void> _run(
    Future<Result<Object?>> Function() action, {
    String? ok,
    bool popOnOk = false,
  }) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (result) {
      Ok() => ok,
      Err(:final failure) => failure.message,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
    if (result.isOk && popOnOk && mounted) context.pop();
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.patient, required this.appointment});

  final Patient patient;
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final u = patient.user;
    final facts = [
      if (u.ageYears != null) t.ageYearsAbbrev(u.ageYears!),
      u.gender?.label(context),
      if (patient.bloodType != null) patient.bloodType!,
      if (appointment.ticketTag != null) t.ticketLabel(appointment.ticketTag!),
      if (appointment.roomNumber != null)
        t.roomNumber('${appointment.roomNumber}'),
    ].whereType<String>().join(' · ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(patient.fullName, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.xxs),
          Text(
            facts,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (patient.allergies.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                const SizedBox(width: Space.xxs),
                Expanded(
                  child: Text(
                    'Allergies: ${patient.allergies.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (patient.chronicConditions.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xxs,
              children: [
                for (final c in patient.chronicConditions)
                  Chip(label: Text(c), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
          if (appointment.reasonText != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Reason: ${appointment.reasonText}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreVisitActions extends ConsumerWidget {
  const _PreVisitActions({
    required this.appointment,
    required this.busy,
    required this.run,
  });

  final Appointment appointment;
  final bool busy;
  final Future<void> Function(
    Future<Result<Object?>> Function() action, {
    String? ok,
    bool popOnOk,
  })
  run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ramp = theme.clinicalStatus;
    final controller = ref.read(consultationControllerProvider(appointment.id));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appointment.wasCalledIn)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                t.patientCalledInNote,
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              // Violet, tonal — same weight and colour as "Call patient" on
              // the schedule card; "Patient arrived" below is the stronger
              // solid action.
              child: FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => run(
                        controller.callPatient,
                        ok: t.patientCalledSnackbar,
                      ),
                icon: const Icon(Icons.campaign_outlined),
                label: Text(t.callPatientAction),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                ),
              ),
            ),
          // Solid green — matches the "Arrived" action on the schedule card.
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    controller.markArrived,
                    ok: t.consultationStartedSnackbar,
                  ),
            icon: const Icon(Icons.login),
            label: Text(t.patientArrivedAction),
            style: FilledButton.styleFrom(
              backgroundColor: ramp.riskLow.onContainer,
              foregroundColor: ramp.riskLow.container,
            ),
          ),
          const SizedBox(height: Space.sm),
          // Outlined red — matches "Not arrived" on the schedule card.
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await confirm(
                      context,
                      title: t.markAsNoShowTitle,
                      message: t.recordsPatientDidNotAttend,
                      confirmLabel: t.markNoShowAction,
                      destructive: true,
                    );
                    if (!ok) return;
                    await run(
                      controller.markNoShow,
                      ok: t.markedAsNoShowSnackbar,
                      popOnOk: true,
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: ramp.riskHigh.onContainer,
              side: BorderSide(
                color: ramp.riskHigh.onContainer.withValues(alpha: 0.5),
              ),
            ),
            icon: const Icon(Icons.person_off_outlined),
            label: Text(t.patientNotShownAction),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.clinicalStatus.riskLow.onContainer,
              ),
              const SizedBox(width: Space.xs),
              Text(
                t.consultationCompletedHeader,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          if (appointment.outcomeNote != null) ...[
            const SizedBox(height: Space.sm),
            Text(appointment.outcomeNote!, style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

// --- sub-sheets --------------------------------------------------------

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _freq = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _freq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.addMedicationAction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: t.medicationNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _dose,
              decoration: InputDecoration(labelText: t.doseOptionalLabel),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _freq,
              decoration: InputDecoration(
                labelText: t.frequencyOptionalLabel,
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _name.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      DraftMed(
                        name: _name.text.trim(),
                        dose: _dose.text.trim().isEmpty
                            ? null
                            : _dose.text.trim(),
                        frequency: _freq.text.trim().isEmpty
                            ? null
                            : _freq.text.trim(),
                      ),
                    ),
              child: Text(t.addButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralReasonSheet extends StatefulWidget {
  const _ReferralReasonSheet();

  @override
  State<_ReferralReasonSheet> createState() => _ReferralReasonSheetState();
}

class _ReferralReasonSheetState extends State<_ReferralReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.requestAReferralAction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xs),
            Text(
              t.adminWillDecideReferralNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: t.clinicalReasonForReferralLabel,
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_reason.text.trim()),
              child: Text(t.sendRequestButton),
            ),
          ],
        ),
      ),
    );
  }
}
