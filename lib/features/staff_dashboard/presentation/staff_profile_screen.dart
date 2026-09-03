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

              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 0),
                child: Text(t.account, style: theme.textTheme.titleSmall),
              ),
              _row(t.specialty, s.specialty ?? t.none),
              _row(t.jobTitle, s.jobTitle ?? t.none),
              _row(t.licenseNo, s.licenseNo ?? t.none),
              _row(
                t.department,
                deptName.maybeWhen(
                  data: (n) => n ?? t.none,
                  orElse: () => '…',
                ),
              ),
              _row(t.memberSince, fmtDate(u.createdAt)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.xs,
                  Space.md,
                  0,
                ),
                child: Text(
                  t.managedByAdmin,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const Divider(height: Space.xl),
              const PreferencesSection(),

              const Divider(height: Space.xl),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  t.signOut,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
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
              ),
              const SizedBox(height: Space.lg),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}
