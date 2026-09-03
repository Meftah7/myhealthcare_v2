/// Staff patient search + list (P5-06).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../application/staff_providers.dart';

class StaffPatientsScreen extends ConsumerWidget {
  const StaffPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(patientSearchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: const [SignOutAction()],
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
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: patients.length,
                itemBuilder: (context, i) {
                  final p = patients[i];
                  final initials = p.fullName
                      .split(' ')
                      .where((s) => s.isNotEmpty)
                      .take(2)
                      .map((s) => s[0])
                      .join();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: AppCard(
                      padding: const EdgeInsets.all(Space.sm),
                      onTap: () =>
                          context.go(AppRoutes.staffPatientChart(p.id)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).colorScheme.secondaryContainer,
                            child: Text(
                              initials,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  [
                                    if (p.user.nationalId != null)
                                      'ID ${p.user.nationalId}',
                                    if (p.chronicConditions.isNotEmpty)
                                      p.chronicConditions.join(', '),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
