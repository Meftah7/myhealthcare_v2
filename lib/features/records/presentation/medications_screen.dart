/// Medications list — active vs past (P2-16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
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
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            children: [
              if (active.isNotEmpty) ...[
                const _Header('Current'),
                ...active.map(_MedTile.new),
              ],
              if (past.isNotEmpty) ...[
                const _Header('Past'),
                ...past.map(_MedTile.new),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
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
