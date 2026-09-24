/// Patient profile + settings (P2-17, redesign v2).
///
/// Every section is a collapsible panel — the page opens compact and the
/// patient expands only what they need.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../../settings/presentation/preferences_section.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  List<(IconData, String, String)> _sections(AppLocalizations t) => [
    (Icons.badge_outlined, t.personalInfoTitle, AppRoutes.patientProfilePersonal),
    (Icons.favorite_outline, t.healthDetailsTitle, AppRoutes.patientProfileHealth),
    (Icons.payments_outlined, t.paymentsTitle, AppRoutes.patientBilling),
    (
      Icons.family_restroom_outlined,
      t.familyNetworkTitle,
      AppRoutes.patientProfileFamily,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = ref.watch(patientProfileProvider);
    final sections = _sections(t);
    final locale = ref.watch(localeProvider);

    return AppScaffold(
      title: t.profile,
      actions: [
        TextButton(
          onPressed: () =>
              unawaited(context.push(AppRoutes.patientProfilePersonal)),
          child: Text(t.editProfile),
        ),
      ],
      onRefresh: () async => ref.invalidate(patientProfileProvider),
      children: profile.when(
        loading: () => const [SkeletonList()],
        error: (e, _) => [
          const SizedBox(height: Space.xl),
          ErrorStateView(
            message: t.couldNotLoadYourProfile,
            onRetry: () => ref.invalidate(patientProfileProvider),
          ),
        ],
        data: (p) => [
          ProfileHeader(
            name: p.user.fullName,
            email: p.user.email,
            phone: p.user.phone,
            role: p.user.role.label(context, gender: p.user.gender),
            avatarSize: 72,
            elevated: true,
            onEditAvatar: () =>
                unawaited(context.push(AppRoutes.patientProfilePersonal)),
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
                  leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
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
                context.push(AppRoutes.patientProfilePreferences),
              ),
              icon: const Icon(Icons.tune),
              label: Text(t.preferences),
            ),
          ),

          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => unawaited(showFeedbackSheet(context, ref)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                shape: const StadiumBorder(),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.forum_outlined),
              label: Text(t.sendFeedbackTitle),
            ),
          ),
          const SizedBox(height: Space.sm),
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
                // Fixed to the light scheme's red in both modes — dark mode's
                // `error` role is a pale pink meant for text-on-surface, not a
                // button fill, and looked washed out.
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
      ),
    );
  }
}
