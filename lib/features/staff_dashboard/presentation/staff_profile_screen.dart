/// Staff profile + device preferences (P8-07).
///
/// Read-only account details (specialty, department, licence — maintained by
/// an administrator) plus the theme / language controls and sign out.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../auth/application/session.dart';
import '../../settings/presentation/preferences_section.dart';
import '../application/staff_providers.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(staffProfileProvider);

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
          final deptName = ref.watch(departmentNameProvider(s.departmentId));
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
                  ProfileHeader(
                    name: u.fullName,
                    email: u.email,
                    role: t.roleStaff,
                  ),
                  const SizedBox(height: Space.md),
                  SectionHeader(t.account, overline: true),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _row(t.specialty, s.specialty ?? t.none),
                        const Divider(height: 1, indent: Space.md),
                        _row(t.jobTitle, s.jobTitle ?? t.none),
                        const Divider(height: 1, indent: Space.md),
                        _row(t.licenseNo, s.licenseNo ?? t.none),
                        const Divider(height: 1, indent: Space.md),
                        _row(
                          t.department,
                          deptName.maybeWhen(
                            data: (n) => n ?? t.none,
                            orElse: () => '…',
                          ),
                        ),
                        const Divider(height: 1, indent: Space.md),
                        _row(t.memberSince, fmtDate(u.createdAt)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xs,
                      Space.xs,
                      Space.xs,
                      0,
                    ),
                    child: Text(
                      t.managedByAdmin,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: Space.md),
                  const PreferencesSection(),

                  const SizedBox(height: Space.lg),
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

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}
