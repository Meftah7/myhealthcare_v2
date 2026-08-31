/// Patient profile + settings (P2-17).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/application/session.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: profile.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(patientProfileProvider),
        ),
        data: (p) {
          final u = p.user;
          return ListView(
            children: [
              const SizedBox(height: Space.md),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0] : '?',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Center(
                child: Text(u.fullName, style: theme.textTheme.titleLarge),
              ),
              Center(
                child: Text(
                  u.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              _row('Phone', u.phone ?? '—'),
              _row('Date of birth', u.dob == null ? '—' : fmtDate(u.dob!)),
              _row('Gender', u.gender?.name ?? '—'),
              _row('National ID', u.nationalId ?? '—'),
              _row('Blood type', p.bloodType ?? '—'),
              _row(
                'Allergies',
                p.allergies.isEmpty ? 'None' : p.allergies.join(', '),
              ),
              _row(
                'Chronic conditions',
                p.chronicConditions.isEmpty
                    ? 'None'
                    : p.chronicConditions.join(', '),
              ),
              _row('Emergency contact', p.emergencyContact ?? '—'),
              const Divider(height: Space.xl),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}
