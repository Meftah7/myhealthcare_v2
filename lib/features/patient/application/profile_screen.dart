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
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
import '../../settings/presentation/preferences_section.dart';
import '../presentation/avatar_photo_sheet.dart';
import 'patient_data_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  List<(IconData, String, String)> _sections(AppLocalizations t) => [
    (
      Icons.badge_outlined,
      t.personalInfoTitle,
      AppRoutes.patientProfilePersonal,
    ),
    (
      Icons.favorite_outline,
      t.healthDetailsTitle,
      AppRoutes.patientProfileHealth,
    ),
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
            avatarPath: p.user.avatarPath,
            avatarSize: 72,
            elevated: true,
            onEditAvatar: () => unawaited(
              showAvatarPhotoSheet(
                context,
                userId: p.user.id,
                hasPhoto: p.user.avatarPath != null,
              ),
            ),
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
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.xxs,
                ),
                leading: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  t.changePasswordTitle,
                  style: theme.textTheme.titleSmall,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: kTrailingChevronSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => unawaited(
                  _showChangePasswordDialog(context, ref, p.user.id),
                ),
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
              onPressed: () =>
                  unawaited(context.push(AppRoutes.patientProfilePreferences)),
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

Future<void> _showChangePasswordDialog(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final t = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirmNext = TextEditingController();
  var obscure = true;
  var busy = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(t.changePasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: current,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(labelText: t.currentPasswordLabel),
                validator: (v) =>
                    (v == null || v.isEmpty) ? t.passwordRequired : null,
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: next,
                obscureText: obscure,
                decoration: InputDecoration(labelText: t.newPasswordLabel),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? t.atLeast8Characters
                    : null,
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: confirmNext,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: t.confirmNewPasswordLabel,
                ),
                validator: (v) => v != next.text ? t.passwordsDoNotMatch : null,
              ),
              CheckboxListTile(
                value: !obscure,
                onChanged: (v) => setState(() => obscure = !(v ?? false)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.showPassword),
              ),
              if (error != null) ...[
                const SizedBox(height: Space.xs),
                InlineBanner.error(error!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final result = await ref
                        .read(authRepositoryProvider)
                        .changePassword(
                          userId: userId,
                          currentPassword: current.text,
                          newPassword: next.text,
                        );
                    if (!context.mounted) return;
                    switch (result) {
                      case Ok():
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.passwordChangedSnackbar)),
                        );
                      case Err(:final failure):
                        setState(() {
                          busy = false;
                          error = describeFailure(
                            AppLocalizations.of(context)!,
                            failure,
                          ).message;
                        });
                    }
                  },
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.changePasswordAction),
          ),
        ],
      ),
    ),
  );
}
