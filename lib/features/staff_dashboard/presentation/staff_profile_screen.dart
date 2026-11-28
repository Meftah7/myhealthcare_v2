/// Staff Settings (the fifth tab) — the patient Profile / settings screen's
/// rows and spacing: who is signed in (name, role, department), the shared
/// preference controls (appearance, language, text size, notifications,
/// accessibility — stored by the app's settings providers, so a change
/// applies everywhere and survives a restart), account pages, and sign out.
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
import '../../admin/presentation/verify_document_screen.dart';
import '../../settings/presentation/preferences_section.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import 'staff_navigation.dart';
import 'staff_top_actions.dart';

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
    final line = ref.watch(staffRoleLineProvider);

    return AppScaffold(
      hero: true,
      title: workText(context, 'Settings', 'الإعدادات'),
      actions: const [StaffTopActions()],
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
              name: staffDisplayName(u.fullName, s.jobTitle),
              email: u.email,
              role: line == null
                  ? t.roleStaff
                  : [
                      staffRoleLabel(context, line.role),
                      line.department ??
                          workText(
                            context,
                            'Department not assigned',
                            'القسم غير مسند',
                          ),
                    ].where((s) => s.isNotEmpty).join(' · '),
              avatarPath: u.avatarPath,
              avatarSize: 52,
              elevated: false,
            ),
            SectionHeader(t.preferences, overline: true),
            const PreferencesSection(showHeader: false),
            SectionHeader(t.accountSection, overline: true),
            ProfileNavigationGroup(
              items: [
                ProfileNavigationItem(
                  icon: Icons.checklist_outlined,
                  label: t.tasksHeader,
                  onTap: () => context.push(AppRoutes.staffTasks),
                ),
                for (final (icon, title, route) in sections)
                  ProfileNavigationItem(
                    icon: icon,
                    label: title,
                    onTap: () => unawaited(context.push(route)),
                  ),
              ],
            ),
            SectionHeader(t.settingsSection, overline: true),
            ProfileNavigationGroup(
              items: [
                ProfileNavigationItem(
                  icon: Icons.verified_outlined,
                  label: t.verifyDocumentTitle,
                  onTap: () => unawaited(openVerifyDocument(context)),
                ),
                ProfileNavigationItem(
                  icon: Icons.forum_outlined,
                  label: t.sendFeedbackTitle,
                  onTap: () => unawaited(showFeedbackSheet(context, ref)),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            ProfileNavigationGroup(
              items: [
                ProfileNavigationItem(
                  icon: Icons.logout,
                  label: t.signOut,
                  destructive: true,
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: t.signOutConfirmTitle,
                      message: t.signOutConfirmBody,
                      confirmLabel: t.signOut,
                      destructive: true,
                    );
                    if (ok)
                      unawaited(ref.read(sessionProvider.notifier).logout());
                  },
                ),
              ],
            ),
          ];
        },
      ),
    );
  }
}
