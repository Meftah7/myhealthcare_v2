/// Device UI preferences: theme mode + language (P8-07, redesign v2).
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
import '../../../core/presentation/app_card.dart';

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
        SectionHeader(t.preferences, overline: true),
        AppCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.brightness_6_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Text(t.theme, style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<ThemeMode>(
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
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.sm),
                    Text(t.language, style: theme.textTheme.titleSmall),
                  ],
                ),
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
                  0,
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
