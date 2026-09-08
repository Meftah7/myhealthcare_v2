/// The persistent top-bar action group for every admin screen: the working-
/// status pill, notifications, a light/dark toggle, and a shortcut to Profile —
/// the same hairline-circle family as `StaffTopActions` and `PatientTopActions`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../patient_home/presentation/notifications_button.dart';
import 'admin_status_menu.dart';

/// Drop straight into `AppBar.actions`: `actions: const [AdminTopActions()]`.
class AdminTopActions extends ConsumerWidget {
  const AdminTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformIsDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminStatusMenu(),
        const NotificationsButton(route: AppRoutes.adminNotifications),
        CircleIconButton(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () => ref
              .read(themeModeProvider.notifier)
              .set(isDark ? ThemeMode.light : ThemeMode.dark),
        ),
        CircleIconButton(
          icon: Icons.account_circle_outlined,
          tooltip: 'Profile',
          onPressed: () => context.go(AppRoutes.adminProfile),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}
