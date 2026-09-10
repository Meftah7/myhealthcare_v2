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
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../auth/application/session.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: user == null
          ? const SkeletonList()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    Space.md,
                    gutter,
                    Space.xxl,
                  ),
                  children: [
                    ProfileHeader(
                      name: user.fullName,
                      email: user.email,
                      role: t.roleAdmin,
                    ),
                    const SizedBox(height: Space.md),

                    _AdminProfileRow(
                      icon: Icons.badge_outlined,
                      title: t.account,
                      subtitle: 'Name, email, member since',
                      route: AppRoutes.adminProfileAccount,
                    ),
                    const SizedBox(height: Space.xs),
                    const _AdminProfileRow(
                      icon: Icons.fact_check_outlined,
                      title: 'Audit log',
                      subtitle: 'Everything that has changed, newest first',
                      route: AppRoutes.adminProfileAudit,
                    ),
                    const SizedBox(height: Space.xs),
                    const _AdminProfileRow(
                      icon: Icons.insights_outlined,
                      title: 'System analytics',
                      subtitle: 'Headline counts, no-show and utilisation',
                      route: AppRoutes.adminProfileAnalytics,
                    ),
                    const SizedBox(height: Space.xs),
                    const _AdminProfileRow(
                      icon: Icons.query_stats_outlined,
                      title: 'Capacity forecast',
                      subtitle: 'Busiest hours and where demand outruns supply',
                      route: AppRoutes.adminProfileForecast,
                    ),
                    const SizedBox(height: Space.xs),
                    const _AdminProfileRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI settings',
                      subtitle: 'Features, mock mode, API key',
                      route: AppRoutes.adminProfileAiSettings,
                    ),
                    const SizedBox(height: Space.xs),
                    const _AdminProfileRow(
                      icon: Icons.history_toggle_off_outlined,
                      title: 'AI activity',
                      subtitle:
                          'Which surface answered, live model or fallback',
                      route: AppRoutes.adminProfileAiLog,
                    ),
                    const SizedBox(height: Space.xs),
                    _AdminProfileRow(
                      icon: Icons.tune,
                      title: t.preferences,
                      subtitle: 'Theme, text size, language, alerts, sounds',
                      route: AppRoutes.adminProfilePreferences,
                    ),

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
            ),
    );
  }
}

/// One tappable row — opens the section as its own page.
class _AdminProfileRow extends StatelessWidget {
  const _AdminProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
