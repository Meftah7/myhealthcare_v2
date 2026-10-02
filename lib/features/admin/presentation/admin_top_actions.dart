/// The persistent top-bar action group for every admin screen: the working-
/// status pill, notifications, a light/dark toggle, and a shortcut to Profile —
/// the same hairline-circle family as `StaffTopActions` and `PatientTopActions`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient_home/presentation/notifications_button.dart';
import 'admin_status_menu.dart';

/// Drop straight into `AppBar.actions`: `actions: const [AdminTopActions()]`.
class AdminTopActions extends ConsumerWidget {
  const AdminTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminStatusMenu(),
        const NotificationsButton(route: AppRoutes.adminNotifications),
        CircleIconButton(
          icon: Icons.settings_outlined,
          tooltip: t.preferences,
          onPressed: () => context.push(AppRoutes.adminProfilePreferences),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}
