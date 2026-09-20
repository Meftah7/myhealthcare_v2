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
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../settings/presentation/preferences_section.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  List<(IconData, String, String)> _sections(AppLocalizations t) => [
    (Icons.badge_outlined, t.account, AppRoutes.adminProfileAccount),
    (Icons.fact_check_outlined, t.auditLogTitle, AppRoutes.adminProfileAudit),
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
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
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
                avatarSize: 72,
                elevated: true,
              ),
              SectionHeader(t.accountSection, overline: true),
              ListCard(
                elevated: true,
                children: [
                  for (final (icon, title, route) in sections)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.xxs,
                      ),
                      leading: Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(title, style: theme.textTheme.titleSmall),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: kTrailingChevronSize,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => unawaited(context.push(route)),
                    ),
                ],
              ),

              SectionHeader(t.settingsSection, overline: true),
              AppCard(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PillLabel(t.language),
                    const SizedBox(height: Space.sm),
                    PillSegmented<String>(
                      segments: [
                        ('en', t.languageEnglish),
                        ('ar', t.languageArabic),
                      ],
                      selected: locale?.languageCode == 'ar' ? 'ar' : 'en',
                      onChanged: (v) =>
                          ref.read(localeProvider.notifier).set(Locale(v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              const PreferencesSection(
                showHeader: false,
                blocks: {PrefsBlock.theme},
              ),
              const SizedBox(height: Space.md),

              // Preferences (text size, notifications) stays its own page.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(
                    context.push(AppRoutes.adminProfilePreferences),
                  ),
                  icon: const Icon(Icons.tune),
                  label: Text(t.preferences),
                ),
              ),

              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.light.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: Space.md),
                    shape: const StadiumBorder(),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(t.signOut),
                ),
              ),
            ],
    );
  }
}
