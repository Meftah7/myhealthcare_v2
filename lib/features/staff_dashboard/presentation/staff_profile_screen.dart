/// Staff profile — a hub of tappable rows. Each section (account details, my
/// activity, staff directory, panel analytics, preferences) is its own page,
/// reached from here and returned from with a back button. Mirrors the patient
/// app's Profile screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../application/staff_providers.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(staffProfileProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (s) {
          final u = s.user;
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
                  ProfileHeader(
                    name: u.fullName,
                    email: u.email,
                    role: t.roleStaff,
                  ),
                  const SizedBox(height: Space.md),

                  _StaffProfileRow(
                    icon: Icons.badge_outlined,
                    title: t.account,
                    subtitle: 'Specialty, department, licence',
                    route: AppRoutes.staffProfileAccount,
                  ),
                  const SizedBox(height: Space.xs),
                  const _StaffProfileRow(
                    icon: Icons.history_outlined,
                    title: 'My activity',
                    subtitle: 'Notes and prescriptions you have authored',
                    route: AppRoutes.staffProfileActivity,
                  ),
                  const SizedBox(height: Space.xs),
                  const _StaffProfileRow(
                    icon: Icons.badge_outlined,
                    title: 'Staff directory',
                    subtitle: 'Clinicians, specialties and live presence',
                    route: AppRoutes.staffProfileDirectory,
                  ),
                  const SizedBox(height: Space.xs),
                  const _StaffProfileRow(
                    icon: Icons.insights_outlined,
                    title: 'Panel analytics',
                    subtitle: 'No-show rate, cancellations, utilisation',
                    route: AppRoutes.staffProfileAnalytics,
                  ),
                  const SizedBox(height: Space.xs),
                  _StaffProfileRow(
                    icon: Icons.tune,
                    title: t.preferences,
                    subtitle: 'Theme, text size, language, alerts',
                    route: AppRoutes.staffProfilePreferences,
                  ),

                  const SizedBox(height: Space.lg),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(showFeedbackSheet(context, ref)),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Send feedback'),
                  ),
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: t.signOutConfirmTitle,
                        message: t.signOutConfirmBody,
                        confirmLabel: t.signOut,
                        destructive: true,
                      );
                      if (ok) {
                        unawaited(ref.read(sessionProvider.notifier).logout());
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(t.signOut),
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

/// One tappable row — opens the section as its own page.
class _StaffProfileRow extends StatelessWidget {
  const _StaffProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
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
