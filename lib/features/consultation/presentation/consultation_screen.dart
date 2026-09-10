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
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
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
          orElse: () => const Text('Consultation'),
        ),
        orElse: () => const Text('Consultation'),
      ),
      body: appt.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load this appointment.',
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
                      const InlineBanner.error('Could not load the patient.'),
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
    final theme = Theme.of(context);
    final draft = ref.watch(consultationDraftProvider(_id));
    final referral = ref.watch(consultationReferralProvider(_id));

    return [
      const SectionHeader('Clinical note', overline: true, first: true),
      TextField(
        controller: _note,
        minLines: 4,
        maxLines: 12,
        decoration: const InputDecoration(
          hintText: 'History, examination, assessment, plan…',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: Space.xs),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.push(
            '${AppRoutes.staffScribe}?patient=${a.patientId}&appointment=$_id',
          ),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Open AI Scribe'),
        ),
      ),

      const SectionHeader('Medications', overline: true),
      if (draft.meds.isEmpty)
        Text(
          'No medications added.',
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
                    tooltip: 'Remove',
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
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _addMedication,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add medication'),
        ),
      ),

      const SectionHeader('Referral', overline: true),
      referral.maybeWhen(
        data: (req) => req != null || draft.referralRequested
            ? StatusPill(
                label: 'Referral requested — awaiting admin',
                icon: Icons.hourglass_top_outlined,
                container: theme.colorScheme.tertiaryContainer,
                onContainer: theme.colorScheme.onTertiaryContainer,
              )
            : OutlinedButton.icon(
                onPressed: _requestReferral,
                icon: const Icon(Icons.forward_to_inbox_outlined, size: 18),
                label: const Text('Request a referral'),
              ),
        orElse: () => const LoadingSkeleton(height: 40),
      ),

      const SizedBox(height: Space.lg),
      TextField(
        controller: _outcome,
        decoration: const InputDecoration(
          labelText: 'Visit summary (optional)',
          hintText: 'One line — the outcome of this visit',
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
            : const Text('Complete consultation'),
      ),
      if (draft.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(
            'Add a note, a medication or a referral request first.',
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
    await _run(() async {
      final r = await ref
          .read(consultationControllerProvider(_id))
          .requestReferral(reason.trim());
      if (r.isOk) _update(_draft.copyWith(referralRequested: true));
      return r;
    }, ok: 'Referral requested.');
  }

  Future<void> _complete() async {
    final ok = await confirm(
      context,
      title: 'Complete consultation?',
      message:
          'The note and any medications will be saved to the patient '
          'record and the visit will be closed.',
      confirmLabel: 'Complete',
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
      ok: 'Consultation completed.',
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final u = patient.user;
    final facts = [
      if (u.ageYears != null) '${u.ageYears} yrs',
      ?u.gender?.name,
      if (patient.bloodType != null) patient.bloodType!,
      if (appointment.ticketTag != null) 'Ticket ${appointment.ticketTag}',
      if (appointment.roomNumber != null) 'Room ${appointment.roomNumber}',
    ].join(' · ');

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
    final theme = Theme.of(context);
    final controller = ref.read(consultationControllerProvider(appointment.id));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appointment.wasCalledIn)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                'Patient has been called in.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => run(controller.callPatient, ok: 'Patient called.'),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Call patient'),
              ),
            ),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () =>
                      run(controller.markArrived, ok: 'Consultation started.'),
            icon: const Icon(Icons.login),
            label: const Text('Patient arrived'),
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await confirm(
                      context,
                      title: 'Mark as no-show?',
                      message: 'This records that the patient did not attend.',
                      confirmLabel: 'Mark no-show',
                      destructive: true,
                    );
                    if (!ok) return;
                    await run(
                      controller.markNoShow,
                      ok: 'Marked as no-show.',
                      popOnOk: true,
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Patient not shown'),
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
                'Consultation completed',
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add medication',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Medication name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _dose,
              decoration: const InputDecoration(labelText: 'Dose (optional)'),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _freq,
              decoration: const InputDecoration(
                labelText: 'Frequency (optional)',
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
              child: const Text('Add'),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request a referral',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xs),
            Text(
              'The admin will decide whether this is a department or an '
              'external referral, and where.',
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
              decoration: const InputDecoration(
                labelText: 'Clinical reason for referral',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_reason.text.trim()),
              child: const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}
