/// The persistent top-bar action group for every admin screen: the working-
/// status pill, notifications, a light/dark toggle —
/// the same hairline-circle family as `StaffTopActions` and `PatientTopActions`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../patient_home/presentation/notifications_button.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';
import 'admin_status_menu.dart';

/// Drop straight into `AppBar.actions`: `actions: const [AdminTopActions()]`.
class AdminTopActions extends ConsumerWidget {
  const AdminTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminStatusMenu(),
        IconButton(
          tooltip: Localizations.localeOf(context).languageCode == 'ar'
              ? 'بحث'
              : 'Search',
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/admin/dashboard/search'),
        ),
        const NotificationsButton(route: AppRoutes.adminNotifications),
        if (MediaQuery.sizeOf(context).width >= 600)
          const ThemeModeIconToggle(),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}
