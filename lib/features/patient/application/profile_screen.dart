/// Patient profile + settings (P2-17, redesign v2).
///
/// Every section is a collapsible panel — the page opens compact and the
/// patient expands only what they need.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../presentation/patient_top_actions.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [PatientTopActions()],
      ),
      body: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(patientProfileProvider),
        ),
        data: (p) {
          final u = p.user;
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
                  ProfileHeader(name: u.fullName, email: u.email),
                  const SizedBox(height: Space.md),

                  const _ProfileRow(
                    icon: Icons.badge_outlined,
                    title: 'Personal info',
                    subtitle: 'Name, contact, date of birth',
                    route: AppRoutes.patientProfilePersonal,
                  ),
                  const SizedBox(height: Space.xs),
                  const _ProfileRow(
                    icon: Icons.favorite_outline,
                    title: 'Health details',
                    subtitle: 'Blood type, allergies, conditions',
                    route: AppRoutes.patientProfileHealth,
                  ),
                  const SizedBox(height: Space.xs),
                  const _ProfileRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    subtitle: 'Saved cards and payment history',
                    route: AppRoutes.patientProfileWallet,
                  ),
                  const SizedBox(height: Space.xs),
                  const _ProfileRow(
                    icon: Icons.tune,
                    title: 'Preferences',
                    subtitle: 'Theme, text size, language, alerts',
                    route: AppRoutes.patientProfilePreferences,
                  ),
                  const SizedBox(height: Space.xs),
                  const _ProfileRow(
                    icon: Icons.family_restroom_outlined,
                    title: 'Family network',
                    subtitle: 'People linked to your account',
                    route: AppRoutes.patientProfileFamily,
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
                        title: 'Sign out?',
                        message: 'You can sign back in any time.',
                        confirmLabel: 'Sign out',
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
                    label: const Text('Sign out'),
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

/// One tappable row in the profile list — opens the section as its own page.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
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

