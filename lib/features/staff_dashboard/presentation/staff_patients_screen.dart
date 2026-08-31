/// Staff patient search + list (P5-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../application/staff_providers.dart';

class StaffPatientsScreen extends ConsumerWidget {
  const StaffPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(patientSearchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: SearchBar(
              hintText: 'Search by name or national ID',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  ref.read(patientSearchQueryProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: results.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load patients.',
          onRetry: () => ref.invalidate(patientSearchResultsProvider),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return const EmptyState(
              icon: Icons.person_search_outlined,
              message: 'No patients match that search.',
            );
          }
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, i) {
              final p = patients[i];
              final initials = p.fullName
                  .split(' ')
                  .where((s) => s.isNotEmpty)
                  .take(2)
                  .map((s) => s[0])
                  .join();
              return ListTile(
                leading: CircleAvatar(child: Text(initials)),
                title: Text(p.fullName),
                subtitle: Text(
                  [
                    if (p.user.nationalId != null) 'ID ${p.user.nationalId}',
                    if (p.chronicConditions.isNotEmpty)
                      p.chronicConditions.join(', '),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.staffPatientChart(p.id)),
              );
            },
          );
        },
      ),
    );
  }
}
