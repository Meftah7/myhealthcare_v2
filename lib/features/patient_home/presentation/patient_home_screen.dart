/// Patient home (P2-07, redesign v2): a calm at-a-glance screen — greeting,
/// next appointment, a health snapshot, the AI summary, quick actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../ai_summary/application/ai_summary_provider.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../../patient/application/patient_data_providers.dart';

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
        actions: const [SignOutAction()],
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

                _NextAppointmentCard(),
                const SizedBox(height: Space.md),

                const SectionHeader('Your health', overline: true),
                _HealthSnapshot(),
                const SizedBox(height: Space.md),

                _AiSummaryCard(),
                const SizedBox(height: Space.md),

                const SectionHeader('Quick actions', overline: true),
                const _QuickActions(),
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

class _NextAppointmentCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final next = ref.watch(nextAppointmentProvider);
    final doctors = ref.watch(doctorDirectoryProvider).valueOrNull ?? const {};

    return next.when(
      loading: () => const LoadingSkeleton(height: 96),
      error: (e, _) => const InlineBanner.error('Could not load appointments.'),
      data: (appt) {
        if (appt == null) {
          return AppCard(
            onTap: () => context.go(AppRoutes.patientBook),
            child: Row(
              children: [
                const _RoundIcon(Icons.event_available_outlined),
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
        return AppCard(
          elevated: true,
          onTap: () => context.go(AppRoutes.patientAppointments),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NEXT APPOINTMENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                '${fmtRelativeDay(appt.slotStart)} · ${fmtTime(appt.slotStart)}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.xxs),
              Text(
                [
                  visitTypeLabel(appt.visitType),
                  ?doctors[appt.staffId]?.name,
                ].join('  ·  '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
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
            onTap: () => context.push(AppRoutes.patientMedications),
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

class _AiSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ref.watch(patientAiSummaryProvider);

    return AppCard(
      onTap: () => context.push(AppRoutes.patientSummary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: Radii.chip,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'AI health summary',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: Space.sm),
          summary.when(
            loading: () => const LoadingSkeleton(height: 32),
            error: (e, _) => Text(
              'Tap to generate a plain-language summary of your record.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            data: (s) => Text(
              s.summaryMarkdown,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.event_available_outlined, 'Book\nappointment', AppRoutes.patientBook),
      (Icons.timeline_outlined, 'Health\ntimeline', AppRoutes.patientTimeline),
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

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
    );
  }
}
