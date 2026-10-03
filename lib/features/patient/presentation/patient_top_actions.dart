/// Persistent notifications and light/dark actions for patient screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../patient_home/presentation/notifications_button.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';

/// Drop straight into `AppBar.actions`: `actions: const [PatientTopActions()]`.
class PatientTopActions extends ConsumerWidget {
  const PatientTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationsButton(),
        ThemeModeIconToggle(),
        SizedBox(width: Space.xs),
      ],
    );
  }
}
