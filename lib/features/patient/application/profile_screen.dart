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
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../presentation/patient_top_actions.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _sections = [
    (
      Icons.badge_outlined,
      'Personal info',
      'Name, contact, date of birth',
      AppRoutes.patientProfilePersonal,
    ),
    (
      Icons.favorite_outline,
      'Health details',
      'Blood type, allergies, conditions',
      AppRoutes.patientProfileHealth,
    ),
    (
      Icons.account_balance_wallet_outlined,
      'Wallet',
      'Saved cards and payment history',
      AppRoutes.patientProfileWallet,
    ),
    (
      Icons.tune,
      'Preferences',
      'Theme, text size, language, alerts',
      AppRoutes.patientProfilePreferences,
    ),
    (
      Icons.family_restroom_outlined,
      'Family network',
      'People linked to your account',
      AppRoutes.patientProfileFamily,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);

    return AppScaffold(
      title: 'Profile',
      actions: const [PatientTopActions()],
      onRefresh: () async => ref.invalidate(patientProfileProvider),
      children: profile.when(
        loading: () => const [SkeletonList()],
        error: (e, _) => [
          const SizedBox(height: Space.xl),
          ErrorStateView(
            message: 'Could not load your profile.',
            onRetry: () => ref.invalidate(patientProfileProvider),
          ),
        ],
        data: (p) => [
          ProfileHeader(name: p.user.fullName, email: p.user.email),
          const SizedBox(height: Space.md),

          for (final (i, (icon, title, subtitle, route)) in _sections.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.xs),
              child: NavRow(
                icon: icon,
                title: title,
                subtitle: subtitle,
                onTap: () => unawaited(context.push(route)),
              ),
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
    );
  }
}
