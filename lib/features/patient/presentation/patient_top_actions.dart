/// The three persistent top-bar actions for every patient screen (redesign v3):
/// notifications, a light/dark toggle, and a shortcut to Profile — always in
/// the same place, top-right, on every page the patient can open.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../patient_home/presentation/notifications_button.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';

/// Drop straight into `AppBar.actions`: `actions: const [PatientTopActions()]`.
class PatientTopActions extends ConsumerWidget {
  const PatientTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NotificationsButton(),
        const ThemeModeIconToggle(),
        CircleIconButton(
          icon: Icons.account_circle_outlined,
          tooltip: 'Profile',
          onPressed: () => context.go(AppRoutes.patientSettings),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}
