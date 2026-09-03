/// Medications list — active vs past (P2-16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../patient/application/patient_data_providers.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(patientMedicationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: meds.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load medications.',
          onRetry: () => ref.invalidate(patientMedicationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.medication_outlined,
              message: 'No medications on record.',
            );
          }
          final active = list.where((m) => m.isCurrent).toList();
          final past = list.where((m) => !m.isCurrent).toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.xxl,
                ),
                children: [
                  if (active.isNotEmpty) ...[
                    const SectionHeader('Current', overline: true),
                    _group(active),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: Space.md),
                    const SectionHeader('Past', overline: true),
                    _group(past),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _group(List<Medication> meds) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < meds.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: Space.md),
          _MedTile(meds[i]),
        ],
      ],
    ),
  );
}

class _MedTile extends StatelessWidget {
  const _MedTile(this.m);
  final Medication m;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = [
      if (m.dose != null) m.dose!,
      if (m.frequency != null) m.frequency!,
      'from ${fmtDate(m.startDate)}',
      if (m.endDate != null) 'to ${fmtDate(m.endDate!)}',
    ].join(' · ');
    return ListTile(
      leading: Icon(
        m.isCurrent ? Icons.medication : Icons.medication_outlined,
        color: m.isCurrent ? theme.colorScheme.primary : null,
      ),
      title: Text(m.name),
      subtitle: Text(sub, style: theme.textTheme.bodySmall),
    );
  }
}
