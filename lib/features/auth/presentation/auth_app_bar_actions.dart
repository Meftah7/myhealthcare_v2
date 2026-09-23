/// Shared app-bar actions for the public auth screens (sign-in, forgot
/// password, reset password): a language pill + a bare theme icon.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../l10n/app_localizations.dart';

/// The [AppBar.actions] list every auth screen shares.
const authAppBarActions = [
  AuthLanguagePill(),
  SizedBox(width: Space.xs),
  AuthThemeIconButton(),
  SizedBox(width: Space.sm),
];

/// A minimal, sign-in-specific language switch: a pill (globe + the language
/// name a tap switches *to*) rather than the circular icon used elsewhere —
/// there's room here for the label to speak for itself, so it does.
class AuthLanguagePill extends ConsumerWidget {
  const AuthLanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // The resolved locale (not the raw provider value) so a device set to
    // Arabic — provider still `null`, "system" — still offers English.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final next = isArabic ? const Locale('en') : const Locale('ar');
    final label = isArabic ? 'English' : 'العربية';

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => ref.read(localeProvider.notifier).set(next),
        // The drawn pill reads as compact, but the tappable/semantics area
        // still meets the 48dp a11y minimum (DESIGN.md §8) via this floor
        // rather than by inflating the visible padding to match.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.language_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bare theme icon — same light/dark logic as the shared theme toggle used
/// elsewhere, but without its circular chip, to sit quietly beside the
/// language pill.
class AuthThemeIconButton extends ConsumerWidget {
  const AuthThemeIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final platformIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformIsDark);
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isDark ? t.switchToLightMode : t.switchToDarkMode,
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
