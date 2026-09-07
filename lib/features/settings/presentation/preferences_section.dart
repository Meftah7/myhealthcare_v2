/// Device UI preferences: theme mode, text size, language, and the alert
/// channels (P8-07, redesign v2).
///
/// A self-contained block for the profile screens — reads and writes
/// [themeModeProvider] / [textScaleProvider] / [localeProvider] /
/// [notificationPrefsProvider], which drive `MaterialApp` in `app.dart` and the
/// reminder delivery preferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/app_card.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({this.bare = false, super.key});

  /// When true, drop the section header and outer cards — the caller (e.g. an
  /// [ExpandableSection]) already provides the surrounding surface.
  final bool bare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textScaleProvider);
    final locale = ref.watch(localeProvider);
    final notify = ref.watch(notificationPrefsProvider);

    final themeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockLabel(icon: Icons.brightness_6_outlined, label: t.theme),
        const SizedBox(height: Space.sm),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem)),
            ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
            ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(themeModeProvider.notifier).set(s.first),
        ),
      ],
    );

    final textSizeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BlockLabel(icon: Icons.format_size_outlined, label: 'Text size'),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            const _FixedA(13),
            Expanded(
              child: Slider(
                value: textSize.index.toDouble(),
                max: (TextScaleLevel.values.length - 1).toDouble(),
                divisions: TextScaleLevel.values.length - 1,
                label: textSize.label,
                onChanged: (v) => ref
                    .read(textScaleProvider.notifier)
                    .set(TextScaleLevel.values[v.round()]),
              ),
            ),
            const _FixedA(24),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${textSize.label} — applies to text across the whole app',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    final languageBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockLabel(icon: Icons.translate_outlined, label: t.language),
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
        const SizedBox(height: Space.xs),
        Text(
          t.translationNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final notificationsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BlockLabel(
          icon: Icons.notifications_outlined,
          label: 'Notification channels',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('SMS'),
          value: notify.sms,
          onChanged: ref.read(notificationPrefsProvider.notifier).setSms,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Email'),
          value: notify.email,
          onChanged: ref.read(notificationPrefsProvider.notifier).setEmail,
        ),
        Text(
          'Where appointment reminders and care alerts reach you.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (bare) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          themeBlock,
          const _BlockDivider(),
          textSizeBlock,
          const _BlockDivider(),
          languageBlock,
          const _BlockDivider(),
          notificationsBlock,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(t.preferences, overline: true),
        AppCard(
          padding: const EdgeInsets.all(Space.md),
          child: themeBlock,
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: const EdgeInsets.all(Space.md),
          child: textSizeBlock,
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: const EdgeInsets.all(Space.md),
          child: languageBlock,
        ),
        const SizedBox(height: Space.sm),
        AppCard(
          padding: const EdgeInsets.all(Space.md),
          child: notificationsBlock,
        ),
      ],
    );
  }
}

class _BlockLabel extends StatelessWidget {
  const _BlockLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Text(label, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _BlockDivider extends StatelessWidget {
  const _BlockDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: Space.md),
    child: Divider(height: 1),
  );
}

/// A capital "A" at a fixed point size that ignores the app text-scale setting,
/// so the slider's end markers stay put while the sample text between them
/// changes.
class _FixedA extends StatelessWidget {
  const _FixedA(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery.withNoTextScaling(
      child: Text(
        'A',
        style: TextStyle(
          fontSize: size,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
