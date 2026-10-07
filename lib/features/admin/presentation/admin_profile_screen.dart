/// Admin profile — a hub of tappable rows. Each section (account, audit log,
/// analytics, forecast, AI settings, AI activity, preferences) is its own page,
/// reached from here and returned from with a back button. Mirrors the patient
/// and staff Profile screens.
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
import '../../../core/presentation/profile_navigation.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  List<(IconData, String, String)> _sections(AppLocalizations t) => [
    (Icons.badge_outlined, t.account, AppRoutes.adminProfileAccount),
    (Icons.fact_check_outlined, t.auditLogTitle, AppRoutes.adminProfileAudit),
    (
      Icons.description_outlined,
      t.documentPoliciesTitle,
      AppRoutes.adminDocumentPolicies,
    ),
    (
      Icons.insights_outlined,
      t.systemAnalyticsTitle,
      AppRoutes.adminProfileAnalytics,
    ),
    (
      Icons.query_stats_outlined,
      t.capacityForecastTitle,
      AppRoutes.adminProfileForecast,
    ),
    (
      Icons.auto_awesome_outlined,
      t.aiSettingsTitle,
      AppRoutes.adminProfileAiSettings,
    ),
    (
      Icons.history_toggle_off_outlined,
      t.aiActivityTitle,
      AppRoutes.adminProfileAiLog,
    ),
    (
      Icons.schedule_outlined,
      t.clinicHoursTitle,
      AppRoutes.adminProfileClinicHours,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final sections = _sections(t);

    return AppScaffold(
      title: t.profile,
      children: user == null
          ? const [SkeletonList()]
          : [
              ProfileHeader(
                name: user.fullName,
                email: user.email,
                phone: user.phone,
                role: t.roleAdmin,
                avatarPath: user.avatarPath,
                avatarSize: 52,
              ),
              SectionHeader(t.accountSection, overline: true),
              ProfileNavigationGroup(
                items: [
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
                    icon: Icons.tune,
                    label: t.preferences,
                    subtitle: t.preferencesSubtitleAdmin,
                    onTap: () => unawaited(
                      context.push(AppRoutes.adminProfilePreferences),
                    ),
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
                      if (ok) {
                        unawaited(ref.read(sessionProvider.notifier).logout());
                      }
                    },
                  ),
                ],
              ),
            ],
    );
  }
}
