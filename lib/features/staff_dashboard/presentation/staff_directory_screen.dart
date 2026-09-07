/// Staff directory (ported from the FirstSemMyHealth doctor "Staff Directory"
/// view): every clinician with their specialty, department and live presence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../domain/entities/entities.dart';
import '../application/staff_providers.dart';
import 'staff_top_actions.dart';

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final directory = ref.watch(staffDirectoryProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff directory'),
        actions: const [StaffTopActions()],
      ),
      body: directory.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load the staff directory.',
          onRetry: () => ref.invalidate(staffDirectoryProvider),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return const EmptyState(
              icon: Icons.badge_outlined,
              message: 'No staff on record.',
            );
          }
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
                  Text(
                    '${staff.length} clinicians',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  for (final s in staff) ...[
                    _StaffCard(staff: s),
                    const SizedBox(height: Space.xs),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});
  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = presenceMeta(context, staff.presence);
    final phone = staff.user.phone;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              staff.fullName
                  .split(' ')
                  .where((s) => s.isNotEmpty)
                  .take(2)
                  .map((s) => s[0])
                  .join(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: theme.textTheme.titleSmall),
                Text(
                  [
                    if (staff.specialty != null) staff.specialty,
                    if (staff.jobTitle != null) staff.jobTitle,
                  ].whereType<String>().join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: meta.color),
                    const SizedBox(width: Space.xxs),
                    Text(meta.label, style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          if (phone != null)
            Text(
              phone,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
