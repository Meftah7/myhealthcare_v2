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
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';
import '../../settings/presentation/preferences_section.dart';
import '../presentation/family_network_section.dart';
import '../presentation/personal_info_section.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);
    final familyCount =
        ref.watch(patientFamilyMembersProvider).valueOrNull?.length;
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                    initiallyExpanded: true,
                    child: PersonalInfoSection(patient: p),
                  ),
                  const SizedBox(height: Space.sm),

                  ExpandableSection(
                    icon: Icons.favorite_outline,
                    title: 'Health details',
                    summary: p.bloodType ?? '—',
                    child: _HealthDetails(patient: p),
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
                    summary: familyCount == null
                        ? null
                        : familyCount == 0
                        ? 'None'
                        : '$familyCount linked',
                    child: FamilyNetworkSection(patient: p, embedded: true),
                  ),

                  const SizedBox(height: Space.lg),
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

class _HealthDetails extends StatelessWidget {
  const _HealthDetails({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final rows = <(String, String)>[
      ('Blood type', p.bloodType ?? '—'),
      ('Allergies', p.allergies.isEmpty ? 'None' : p.allergies.join(', ')),
      (
        'Chronic conditions',
        p.chronicConditions.isEmpty ? 'None' : p.chronicConditions.join(', '),
      ),
      ('Emergency contact', p.emergencyContact ?? '—'),
    ];
    return Column(
      children: [
        for (final (i, (label, value)) in rows.indexed) ...[
          if (i > 0) const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(label),
            subtitle: Text(value),
          ),
        ],
      ],
    );
  }
}
