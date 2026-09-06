/// Patient home (P2-07, redesign v3 — patient dashboard rebuild): a calm
/// at-a-glance screen — greeting, quick appointment, a health snapshot,
/// quick actions, live appointment ticket(s).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../../booking/application/appointment_confirmation.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../quick_appointment/application/quick_appointment_providers.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';
import 'notifications_button.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    final size = WindowSize.of(context);
    final gutter = size.gutter;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: gutter,
        title: const _AppBarLockup(),
        actions: const [
          NotificationsButton(),
          ThemeModeIconToggle(),
          SignOutAction(),
          SizedBox(width: Space.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(patientAppointmentsProvider)
            ..invalidate(patientMedicationsProvider)
            ..invalidate(patientVitalsProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                Space.md,
                gutter,
                Space.xxl,
              ),
              children: [
                Text(greeting(firstName), style: theme.textTheme.headlineSmall),
                const SizedBox(height: Space.xxs),
                Text(
                  fmtDate(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),

                const _QuickAppointmentAction(),
                const SizedBox(height: Space.lg),

                const SectionHeader('Your health', overline: true),
                _HealthSnapshot(),
                const SizedBox(height: Space.md),

                const SectionHeader('Quick actions', overline: true),
                const _QuickActions(),
                const SizedBox(height: Space.md),

                const SectionHeader('Upcoming appointment(s)', overline: true),
                const _UpcomingTickets(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarLockup extends StatelessWidget {
  const _AppBarLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 26),
        const SizedBox(width: Space.xs),
        Text(
          'MyHealth Care',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

enum _QuickChoice { urgent, normal }

/// The Home "Quick Appointment" action: choose Urgent (auto-routed to the
/// nearest — i.e. soonest-available — doctor, any department) or Normal
/// (the standard booking flow).
class _QuickAppointmentAction extends ConsumerWidget {
  const _QuickAppointmentAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      color: scheme.primaryContainer,
      onTap: () => _chooseUrgency(context, ref),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.bolt, color: scheme.onPrimary),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick appointment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Urgent or normal — get seen sooner',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
        ],
      ),
    );
  }

  Future<void> _chooseUrgency(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_QuickChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick appointment',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'How urgent is this visit?',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.lg),
              _ChoiceTile(
                icon: Icons.bolt,
                title: 'Urgent',
                subtitle: 'Auto-route me to the soonest available doctor',
                onTap: () => Navigator.of(sheetContext).pop(_QuickChoice.urgent),
              ),
              const SizedBox(height: Space.sm),
              _ChoiceTile(
                icon: Icons.event_available_outlined,
                title: 'Normal',
                subtitle: 'Choose a department, doctor and time myself',
                onTap: () => Navigator.of(sheetContext).pop(_QuickChoice.normal),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == _QuickChoice.normal) {
      context.go(AppRoutes.patientAppointments);
      return;
    }
    await _bookUrgent(context, ref);
  }

  Future<void> _bookUrgent(BuildContext context, WidgetRef ref) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    final result = await ref.read(quickAppointmentControllerProvider).bookUrgent();
    if (!context.mounted) return;
    // The loader sits on the root navigator — close it there, not on the shell
    // branch's navigator (which would pop Home and leave a blank screen).
    Navigator.of(context, rootNavigator: true).pop();

    switch (result) {
      case Ok():
        ref.invalidate(patientAppointmentsProvider);
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show("You're on the schedule");
      case Err(:final failure):
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _HealthSnapshot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(patientAppointmentsProvider);
    final meds = ref.watch(patientMedicationsProvider);
    final vitals = ref.watch(patientVitalsProvider);

    final upcoming = appts.valueOrNull?.where((a) => a.isUpcoming).length ?? 0;
    final activeMeds =
        meds.valueOrNull?.where((m) => m.isCurrent).length ?? 0;
    final lastVital = vitals.valueOrNull?.isNotEmpty ?? false
        ? vitals.valueOrNull!
              .map((v) => v.recordedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    final vitalAge = lastVital == null
        ? '—'
        : '${DateTime.now().difference(lastVital).inDays}d';

    if (appts.isLoading && meds.isLoading) {
      return const LoadingSkeleton(height: 92);
    }

    return Row(
      children: [
        Expanded(
          child: MetricTile(
            value: '$upcoming',
            label: 'Upcoming',
            icon: Icons.event_outlined,
            onTap: () => context.go(AppRoutes.patientAppointments),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: '$activeMeds',
            label: 'Active meds',
            icon: Icons.medication_outlined,
            onTap: () => context.go(AppRoutes.patientMedications),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: MetricTile(
            value: vitalAge,
            label: 'Last vitals',
            icon: Icons.favorite_outline,
            onTap: () => context.go(AppRoutes.patientVitals),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.event_available_outlined, 'Book\nappointment', AppRoutes.patientBook),
      (Icons.folder_shared_outlined, 'Health\nrecords', AppRoutes.patientTimeline),
      (Icons.favorite_outline, 'Vitals', AppRoutes.patientVitals),
      (Icons.medication_outlined, 'Medications', AppRoutes.patientMedications),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
      childAspectRatio: 2.6,
      children: [
        for (final (icon, label, route) in items)
          _ActionTile(icon: icon, label: label, route: route),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      onTap: () => context.go(route),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              label.replaceAll('\n', ' '),
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live appointment ticket card(s) — the patient's booked appointment(s),
/// each showing its ticket tag, date, time, doctor and room number.
class _UpcomingTickets extends ConsumerWidget {
  const _UpcomingTickets();

  /// At-a-glance cap; the full list lives on the Appointments screen.
  static const _maxShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appts = ref.watch(patientAppointmentsProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return appts.when(
      loading: () => const LoadingSkeleton(height: 96),
      error: (e, _) => const InlineBanner.error('Could not load appointments.'),
      data: (list) {
        final upcoming = list.where((a) => a.isUpcoming).toList()
          ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
        if (upcoming.isEmpty) {
          return AppCard(
            onTap: () => context.go(AppRoutes.patientBook),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming appointments',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Tap to book a visit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final appt in upcoming.take(_maxShown))
              _TicketCard(appt: appt, doctorName: doctors[appt.staffId]?.name),
          ],
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.appt, this.doctorName});

  final Appointment appt;
  final String? doctorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (appt.ticketTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: Radii.pill,
                    ),
                    child: Text(
                      appt.ticketTag!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                  ),
                const Spacer(),
                if (appt.roomNumber != null)
                  Text(
                    'Room ${appt.roomNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              '${fmtRelativeDay(appt.slotStart)} · ${fmtTime(appt.slotStart)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Space.xxs),
            Text(
              [visitTypeLabel(appt.visitType), ?doctorName].join('  ·  '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.patientAppointments),
                child: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
