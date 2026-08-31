/// Patient home (P2-07): next appointment, active medications, quick actions,
/// and a slot for the AI summary card (P3-10).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../ai_summary/application/ai_summary_provider.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyHealth Care'),
        actions: [
          IconButton(
            tooltip: 'Profile & settings',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.patientSettings),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                unawaited(ref.read(sessionProvider.notifier).logout());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(patientAppointmentsProvider)
            ..invalidate(patientMedicationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text('Hello, $firstName', style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.lg),

            _NextAppointmentCard(),
            const SizedBox(height: Space.sm),
            _ActiveMedicationsCard(),
            const SizedBox(height: Space.sm),
            _AiSummaryCard(),

            const SizedBox(height: Space.lg),
            Text('Quick actions', style: theme.textTheme.titleSmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                _Action(
                  icon: Icons.event_available_outlined,
                  label: 'Book appointment',
                  onTap: () => context.go(AppRoutes.patientBook),
                ),
                _Action(
                  icon: Icons.timeline_outlined,
                  label: 'Health timeline',
                  onTap: () => context.go(AppRoutes.patientTimeline),
                ),
                _Action(
                  icon: Icons.favorite_outline,
                  label: 'Vitals',
                  onTap: () => context.go(AppRoutes.patientVitals),
                ),
                _Action(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI summary',
                  onTap: () => context.push(AppRoutes.patientSummary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = ref.watch(nextAppointmentProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: next.when(
          loading: () => const LoadingSkeleton(height: 44),
          error: (e, _) => Text(
            'Could not load appointments',
            style: theme.textTheme.bodyMedium,
          ),
          data: (appt) {
            if (appt == null) {
              return Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'No upcoming appointments',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.patientBook),
                    child: const Text('Book'),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next appointment', style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.xs),
                Text(
                  fmtRelativeDay(appt.slotStart),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  '${fmtTime(appt.slotStart)} · ${appt.visitType.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActiveMedicationsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meds = ref.watch(patientMedicationsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: meds.when(
          loading: () => const LoadingSkeleton(height: 44),
          error: (e, _) => Text(
            'Could not load medications',
            style: theme.textTheme.bodyMedium,
          ),
          data: (list) {
            final active = list.where((m) => m.isCurrent).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active medications', style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.xs),
                if (active.isEmpty)
                  Text(
                    'None on record',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...active
                      .take(4)
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• ${m.name}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                if (active.length > 4)
                  Text(
                    '+${active.length - 4} more',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AiSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(patientAiSummaryProvider);
    return Card(
      child: InkWell(
        borderRadius: Radii.card,
        onTap: () => context.push(AppRoutes.patientSummary),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: Space.xs),
                  Text('AI health summary', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: Space.xs),
              summary.when(
                loading: () => const LoadingSkeleton(height: 32),
                error: (e, _) => Text(
                  'Tap to generate',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
