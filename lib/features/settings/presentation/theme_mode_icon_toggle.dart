/// Icon-only dark/light mode toggle for a top bar (redesign v2 patient
/// dashboard). Flips [themeModeProvider] between light and dark explicitly —
/// [PreferencesSection] still owns the full light/dark/system picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../../l10n/app_localizations.dart';

class ThemeModeIconToggle extends ConsumerWidget {
  const ThemeModeIconToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformIsDark);

    return CircleIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? t.switchToLightMode : t.switchToDarkMode,
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
