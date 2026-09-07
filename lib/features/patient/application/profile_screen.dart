/// Patient profile + settings (P2-17, redesign v2).
///
/// Every section is a collapsible panel — the page opens compact and the
/// patient expands only what they need.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/expandable_section.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';
import '../../billing/presentation/wallet_section.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../../settings/presentation/preferences_section.dart';
import '../presentation/family_network_section.dart';
import '../presentation/health_details_section.dart';
import '../presentation/patient_top_actions.dart';
import '../presentation/personal_info_section.dart';
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

                  ExpandableSection(
                    icon: Icons.badge_outlined,
                    title: 'Personal info',
                    child: PersonalInfoSection(patient: p),
                  ),
                  const SizedBox(height: Space.sm),

                  ExpandableSection(
                    icon: Icons.favorite_outline,
                    title: 'Health details',
                    child: HealthDetailsSection(patient: p),
                  ),
                  const SizedBox(height: Space.sm),

                  const ExpandableSection(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    child: WalletSection(),
                  ),
                  const SizedBox(height: Space.sm),

                  const ExpandableSection(
                    icon: Icons.tune,
                    title: 'Preferences',
                    child: PreferencesSection(bare: true),
                  ),
                  const SizedBox(height: Space.sm),

                  const ExpandableSection(
                    icon: Icons.notifications_outlined,
                    title: 'Notification channels',
                    child: NotificationChannelsSection(),
                  ),
                  const SizedBox(height: Space.sm),

                  ExpandableSection(
                    icon: Icons.family_restroom_outlined,
                    title: 'Family network',
                    child: FamilyNetworkSection(patient: p, embedded: true),
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

