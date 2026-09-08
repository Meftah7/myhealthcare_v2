/// Allergies — a read-only, high-visibility list (P10-06).
///
/// The data lives on the patient profile (edited under Profile → Health); this
/// screen just surfaces it prominently and links back to the editor. The same
/// list is printed on every clinical PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../patient/application/patient_data_providers.dart';

class AllergiesScreen extends ConsumerWidget {
  const AllergiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(patientProfileProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: const Text('Allergies')),
      body: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your allergies.',
          onRetry: () => ref.invalidate(patientProfileProvider),
        ),
        data: (p) {
          final allergies = p.allergies;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.md,
                  gutter,
                  Space.xxl,
                ),
                children: [
                  if (allergies.isEmpty)
                    const _NoAllergiesCard()
                  else
                    _AllergyAlertCard(allergies: allergies),
                  const SizedBox(height: Space.md),
                  Text(
                    'Shown to every clinician who treats you and printed on '
                    'your reports. Keep it accurate.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.patientProfileHealth),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      allergies.isEmpty
                          ? 'Add your allergies'
                          : 'Update allergies',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AllergyAlertCard extends StatelessWidget {
  const _AllergyAlertCard({required this.allergies});

  final List<String> allergies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      color: scheme.errorContainer,
      borderColor: scheme.error.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              const SizedBox(width: Space.xs),
              Text(
                'Known allergies',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final a in allergies)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: scheme.onErrorContainer),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      a,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoAllergiesCard extends StatelessWidget {
  const _NoAllergiesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.clinicalStatus.riskLow.onContainer,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No allergies recorded',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'If you have any drug, food or other allergies, add them so '
                  'your care team can see them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
