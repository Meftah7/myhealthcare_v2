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
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/profile_navigation.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../application/staff_providers.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  List<(IconData, String, String)> _sections(AppLocalizations t) => [
    (Icons.badge_outlined, t.account, AppRoutes.staffProfileAccount),
    (Icons.history_outlined, t.myActivityTitle, AppRoutes.staffProfileActivity),
    (
      Icons.groups_outlined,
      t.staffDirectoryTitle,
      AppRoutes.staffProfileDirectory,
    ),
    (
      Icons.insights_outlined,
      t.panelAnalyticsTitle,
      AppRoutes.staffProfileAnalytics,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final profile = ref.watch(staffProfileProvider);
    final sections = _sections(t);

    return AppScaffold(
      hero: true,
      title: t.profile,
      onRefresh: () async => ref.invalidate(staffProfileProvider),
      children: profile.when(
        loading: () => const [SkeletonList()],
        error: (e, _) => [
          const SizedBox(height: Space.xl),
          ErrorStateView(
            message: t.couldNotLoadYourProfile,
            onRetry: () => ref.invalidate(staffProfileProvider),
          ),
        ],
        data: (s) {
          final u = s.user;
          return [
            ProfileHeader(
              name: clinicianName(u.fullName),
              email: u.email,
              role: t.roleStaff,
              avatarPath: u.avatarPath,
              avatarSize: 52,
              elevated: false,
            ),
            SectionHeader(t.accountSection, overline: true),
            ProfileNavigationGroup(items: [
              for (final (icon, title, route) in sections)
                ProfileNavigationItem(icon: icon, label: title,
                  onTap: () => unawaited(context.push(route))),
            ]),
            SectionHeader(t.settingsSection, overline: true),
            ProfileNavigationGroup(items: [
              ProfileNavigationItem(icon: Icons.tune,
                label: t.preferences, subtitle: t.preferencesSubtitleAdmin,
                onTap: () => unawaited(context.push(AppRoutes.staffProfilePreferences))),
              ProfileNavigationItem(icon: Icons.forum_outlined,
                label: t.sendFeedbackTitle,
                onTap: () => unawaited(showFeedbackSheet(context, ref))),
            ]),
            const SizedBox(height: Space.lg),
            ProfileNavigationGroup(items: [
              ProfileNavigationItem(icon: Icons.logout, label: t.signOut,
                destructive: true, onTap: () async {
                  final ok = await confirm(context,
                    title: t.signOutConfirmTitle, message: t.signOutConfirmBody,
                    confirmLabel: t.signOut, destructive: true);
                  if (ok) unawaited(ref.read(sessionProvider.notifier).logout());
                }),
            ]),
          ];
        },
      ),
    );
  }
}
