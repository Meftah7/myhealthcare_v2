/// The bottom sheet the staff schedule opens when a doctor taps an appointment
/// block: the patient + ticket details, and the Call / Arrived / Not-shown
/// actions that lead into the consultation page.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../application/consultation_providers.dart';

Future<void> showTicketSheet(BuildContext context, Appointment appointment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TicketSheet(appointmentId: appointment.id),
  );
}

class _TicketSheet extends ConsumerStatefulWidget {
  const _TicketSheet({required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<_TicketSheet> {
  bool _busy = false;

  String get _id => widget.appointmentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appt = ref.watch(consultationAppointmentProvider(_id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: appt.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Space.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              const InlineBanner.error('Could not load this appointment.'),
          data: (a) {
            final patient = ref.watch(chartPatientProvider(a.patientId));
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: patient.maybeWhen(
                        data: (p) =>
                            Text(p.fullName, style: theme.textTheme.titleLarge),
                        orElse: () => Text(
                          visitTypeLabel(a.visitType),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    AppointmentStatusPill(a.status, dense: true),
                  ],
                ),
                const SizedBox(height: Space.xs),
                patient.maybeWhen(
                  data: (p) => _PatientFacts(patient: p),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: Space.sm),
                AppCard(
                  padding: const EdgeInsets.all(Space.sm),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    [
                      a.ticketTag == null
                          ? 'Ticket —'
                          : 'Ticket ${a.ticketTag}',
                      'Room ${a.roomNumber ?? '—'}',
                      fmtTime(a.slotStart),
                      visitTypeLabel(a.visitType),
                    ].join('  ·  '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (a.reasonText != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    'Reason: ${a.reasonText}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (a.wasCalledIn && a.status != AppointmentStatus.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      'Called at ${fmtTime(a.calledInAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: Space.md),
                ..._actions(a),
                const SizedBox(height: Space.xs),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.staffPatientChart(a.patientId));
                  },
                  child: const Text('Open chart'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _actions(Appointment a) {
    final controller = ref.read(consultationControllerProvider(_id));

    switch (a.status) {
      case AppointmentStatus.booked || AppointmentStatus.confirmed:
        return [
          if (!a.wasCalledIn)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: FilledButton.tonalIcon(
                onPressed: _busy
                    ? null
                    : () => _run(controller.callPatient, ok: 'Patient called.'),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Call patient'),
              ),
            ),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                    controller.markArrived,
                    ok: 'Consultation started.',
                    thenGoConsult: true,
                  ),
            icon: const Icon(Icons.login),
            label: const Text('Patient arrived'),
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _noShow(controller),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Patient not shown'),
          ),
        ];
      case AppointmentStatus.inProgress:
        return [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(context.push(AppRoutes.staffConsultation(_id)));
            },
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Resume consultation'),
          ),
        ];
      case AppointmentStatus.completed ||
          AppointmentStatus.cancelled ||
          AppointmentStatus.noShow:
        return [
          Text(
            'This visit is ${a.status.name == 'noShow' ? 'a no-show' : a.status.name}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ];
    }
  }

  Future<void> _noShow(ConsultationController controller) async {
    final ok = await confirm(
      context,
      title: 'Mark as no-show?',
      message: 'This records that the patient did not attend.',
      confirmLabel: 'Mark no-show',
      destructive: true,
    );
    if (!ok) return;
    await _run(
      controller.markNoShow,
      ok: 'Marked as no-show.',
      thenClose: true,
    );
  }

  Future<void> _run(
    Future<Result<void>> Function() action, {
    String? ok,
    bool thenGoConsult = false,
    bool thenClose = false,
  }) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    if (ok != null) messenger.showSnackBar(SnackBar(content: Text(ok)));
    if (thenGoConsult) {
      navigator.pop();
      if (mounted) unawaited(context.push(AppRoutes.staffConsultation(_id)));
    } else if (thenClose) {
      navigator.pop();
    }
  }
}

class _PatientFacts extends StatelessWidget {
  const _PatientFacts({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = patient.user;
    final facts = [
      if (u.ageYears != null) '${u.ageYears} yrs',
      ?u.gender?.name,
      if (patient.bloodType != null) patient.bloodType!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (facts.isNotEmpty)
          Text(
            facts,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (patient.allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(
              'Allergies: ${patient.allergies.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (patient.chronicConditions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(
              patient.chronicConditions.join(', '),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
