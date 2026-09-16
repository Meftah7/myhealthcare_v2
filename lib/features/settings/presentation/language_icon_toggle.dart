/// Icon-only language switch for a top bar — the [LocaleController] sibling of
/// [ThemeModeIconToggle]. Only English and Arabic are supported (no "system"
/// option here — [PreferencesSection] still owns the full picker with its
/// translation note, "system default" included, for anyone who wants that);
/// this is a one-tap flip between the two for screens that only have room for
/// an icon. The label shows the language a tap switches *to*.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';

class LanguageIconToggle extends ConsumerWidget {
  const LanguageIconToggle({super.key});

  static const double _diameter = 40;
  static const double _target = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // The resolved locale (not the raw provider value) so a device set to
    // Arabic — provider still `null`, "system" — still flips to English.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final next = isArabic ? const Locale('en') : const Locale('ar');

    return IconButton(
      tooltip: isArabic ? 'Switch to English' : 'Switch to Arabic',
      onPressed: () => ref.read(localeProvider.notifier).set(next),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _target,
        height: _target,
      ),
      icon: Container(
        width: _diameter,
        height: _diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          isArabic ? 'EN' : 'ع',
          style: TextStyle(
            fontSize: isArabic ? 13 : 17,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
            height: 1,
          ),
        ),
      ),
    );
  }
}
