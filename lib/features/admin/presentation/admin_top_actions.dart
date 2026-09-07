/// The persistent top-bar action group for every admin screen: a light/dark
/// toggle and the account menu — always top-right, matching `StaffTopActions`
/// and `PatientTopActions`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../auth/presentation/sign_out_action.dart';

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
        IconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () => ref
              .read(themeModeProvider.notifier)
              .set(isDark ? ThemeMode.light : ThemeMode.dark),
        ),
        const SignOutAction(),
        const SizedBox(width: Space.xxs),
      ],
    );
  }
}
