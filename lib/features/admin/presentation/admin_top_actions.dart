/// The persistent top-bar action group for every admin screen: the working-
/// status pill, notifications, a light/dark toggle —
/// the same hairline-circle family as `StaffTopActions` and `PatientTopActions`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminStatusMenu(),
        NotificationsButton(route: AppRoutes.adminNotifications),
        ThemeModeIconToggle(),
        SizedBox(width: Space.xs),
      ],
    );
  }
}
