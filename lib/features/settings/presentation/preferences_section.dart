/// Device UI preferences: theme mode + language (P8-07).
///
/// A self-contained block for the profile screens — reads and writes
/// [themeModeProvider] / [localeProvider], which drive `MaterialApp` in
/// `app.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, 0),
          child: Text(t.preferences, style: theme.textTheme.titleSmall),
        ),

        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: Text(t.theme),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(t.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(t.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t.themeDark),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.translate_outlined),
          title: Text(t.language),
        ),
        _LanguageOption(
          label: t.languageSystem,
          selected: locale == null,
          onTap: () => ref.read(localeProvider.notifier).set(null),
        ),
        _LanguageOption(
          label: t.languageEnglish,
          selected: locale?.languageCode == 'en',
          onTap: () =>
              ref.read(localeProvider.notifier).set(const Locale('en')),
        ),
        _LanguageOption(
          label: t.languageArabic,
          selected: locale?.languageCode == 'ar',
          onTap: () =>
              ref.read(localeProvider.notifier).set(const Locale('ar')),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.xs,
            Space.md,
            Space.md,
          ),
          child: Text(
            t.translationNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
