/// The persistent top-bar action group for every admin screen: a light/dark
/// toggle and the account menu — always top-right, matching `StaffTopActions`
/// and `PatientTopActions`.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';

/// Drop straight into `AppBar.actions`: `actions: const [AdminTopActions()]`.
class AdminTopActions extends StatelessWidget {
  const AdminTopActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeModeIconToggle(),
        SignOutAction(),
        SizedBox(width: Space.xxs),
      ],
    );
  }
}
