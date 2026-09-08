/// Visited doctors (P10-04): the patient's care team, one card per doctor they
/// have seen, with a visit count, the last visit and a "Book again" shortcut.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../booking/presentation/booking_screen.dart';
import '../application/visited_doctors_provider.dart';
import 'patient_top_actions.dart';

class VisitedDoctorsScreen extends ConsumerWidget {
  const VisitedDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(visitedDoctorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visited doctors'),
        actions: const [PatientTopActions()],
      ),
      body: doctors.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your care team.',
          onRetry: () => ref.invalidate(visitedDoctorsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              message: 'No past visits yet.\nDoctors you see will appear here.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) => _DoctorCard(doctor: list[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final VisitedDoctor doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visits =
        '${doctor.visitCount} visit${doctor.visitCount == 1 ? '' : 's'}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initials(doctor.name),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: theme.textTheme.titleMedium),
                    Text(
                      doctor.departmentName ?? 'General',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              _Fact(icon: Icons.history, label: visits),
              _Fact(
                icon: Icons.event_available_outlined,
                label: 'Last ${fmtShortDate(doctor.lastVisit)}',
              ),
              if (doctor.nextVisit != null)
                _Fact(
                  icon: Icons.upcoming_outlined,
                  label: 'Next ${fmtShortDate(doctor.nextVisit!)}',
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.patientBook}?staff=${doctor.staffId}',
                extra: BookingMode.schedule,
              ),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: const Text('Book again'),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .replaceFirst(RegExp('^Dr '), '')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: Space.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
