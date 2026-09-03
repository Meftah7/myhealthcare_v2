/// Patient profile + settings (P2-17, redesign v2).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/application/session.dart';
import '../../settings/presentation/preferences_section.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);

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
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.xxl,
                ),
                children: [
                  ProfileHeader(name: u.fullName, email: u.email),
                  const SizedBox(height: Space.md),
                  const SectionHeader('Personal details', overline: true),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, (label, value)) in [
                          ('Phone', u.phone ?? '—'),
                          (
                            'Date of birth',
                            u.dob == null ? '—' : fmtDate(u.dob!),
                          ),
                          ('Gender', u.gender?.name ?? '—'),
                          ('National ID', u.nationalId ?? '—'),
                          ('Blood type', p.bloodType ?? '—'),
                          (
                            'Allergies',
                            p.allergies.isEmpty
                                ? 'None'
                                : p.allergies.join(', '),
                          ),
                          (
                            'Chronic conditions',
                            p.chronicConditions.isEmpty
                                ? 'None'
                                : p.chronicConditions.join(', '),
                          ),
                          ('Emergency contact', p.emergencyContact ?? '—'),
                        ].indexed) ...[
                          if (i > 0)
                            const Divider(height: 1, indent: Space.md),
                          _row(label, value),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: Space.md),
                  const PreferencesSection(),

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
                        unawaited(
                          ref.read(sessionProvider.notifier).logout(),
                        );
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

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}
