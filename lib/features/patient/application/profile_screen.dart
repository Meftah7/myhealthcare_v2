/// Patient profile + settings (P2-17, redesign v2).
///
/// Identity and photo editing, followed by account and settings destinations.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/profile_navigation.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../feedback/presentation/feedback_sheet.dart';
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
    final profile = ref.watch(patientProfileProvider);
    final sections = _sections(t);

    return AppScaffold(
      hero: true,
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
            elevated: false,
            onEditAvatar: () => unawaited(
              showAvatarPhotoSheet(
                context,
                userId: p.user.id,
                hasPhoto: p.user.avatarPath != null,
              ),
            ),
          ),
          SectionHeader(t.accountSection, overline: true),
          ProfileNavigationGroup(
            items: [
              ProfileNavigationItem(
                icon: Icons.photo_camera_outlined,
                label: t.profilePhotoTitle,
                onTap: () => unawaited(
                  showAvatarPhotoSheet(
                    context,
                    userId: p.user.id,
                    hasPhoto: p.user.avatarPath != null,
                  ),
                ),
              ),
              for (final (icon, title, route) in sections)
                ProfileNavigationItem(
                  icon: icon,
                  label: title,
                  onTap: () => unawaited(context.push(route)),
                ),
              ProfileNavigationItem(
                icon: Icons.lock_outline,
                label: t.changePasswordTitle,
                onTap: () => unawaited(
                  _showChangePasswordDialog(context, ref, p.user.id),
                ),
              ),
            ],
          ),
          SectionHeader(t.settingsSection, overline: true),
          ProfileNavigationGroup(
            items: [
              ProfileNavigationItem(
                icon: Icons.tune,
                label: t.preferences,
                subtitle: t.preferencesSubtitle,
                onTap: () => unawaited(
                  context.push(AppRoutes.patientProfilePreferences),
                ),
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
