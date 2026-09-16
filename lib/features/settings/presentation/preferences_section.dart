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
import '../../../core/presentation/app_card.dart';
import '../../../l10n/app_localizations.dart';

/// Translated label for a [TextScaleLevel] — a device-local UI preference,
/// not a domain enum, so its label lives here rather than in
/// `enum_labels.dart` (mirrors `_statusLabel` in `admin_status_menu.dart`).
String _textScaleLabel(BuildContext context, TextScaleLevel level) {
  final t = AppLocalizations.of(context)!;
  return switch (level) {
    TextScaleLevel.xSmall => t.textScaleSmaller,
    TextScaleLevel.small => t.textScaleSmall,
    TextScaleLevel.medium => t.textScaleDefault,
    TextScaleLevel.large => t.textScaleLarge,
    TextScaleLevel.xLarge => t.textScaleLarger,
  };
}

/// One togglable block inside [PreferencesSection]. Lets a caller — the
/// compact Profile page vs. the full Preferences page — show only the blocks
/// it needs from the one implementation, instead of two copies drifting apart.
enum PrefsBlock { theme, textSize, language, notifications }

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({
    this.showHeader = true,
    this.blocks = const {
      PrefsBlock.theme,
      PrefsBlock.textSize,
      PrefsBlock.language,
      PrefsBlock.notifications,
    },
    super.key,
  });

  /// Drops the "Preferences" [SectionHeader] — for a caller (a profile hub,
  /// or a dedicated Preferences page with its own AppBar title) that already
  /// has a heading above these cards.
  final bool showHeader;

  /// Which blocks to render, in their fixed order (theme, text size,
  /// language, notifications). Defaults to all four.
  final Set<PrefsBlock> blocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textScaleProvider);
    final locale = ref.watch(localeProvider);
    final notify = ref.watch(notificationPrefsProvider);
    final soundsOn = ref.watch(soundsEnabledProvider);

    final themeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillLabel(t.theme),
        const SizedBox(height: Space.sm),
        PillSegmented<ThemeMode>(
          segments: [
            (ThemeMode.light, t.themeLight),
            (ThemeMode.dark, t.themeDark),
            (ThemeMode.system, t.themeSystem),
          ],
          selected: mode,
          onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
        ),
      ],
    );

    final textSizeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockLabel(icon: Icons.format_size_outlined, label: t.textSizeLabel),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            const _FixedA(13),
            Expanded(
              child: Slider(
                value: textSize.index.toDouble(),
                max: (TextScaleLevel.values.length - 1).toDouble(),
                divisions: TextScaleLevel.values.length - 1,
                label: _textScaleLabel(context, textSize),
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
            t.textSizeCaption(_textScaleLabel(context, textSize)),
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
        PillLabel(t.language),
        const SizedBox(height: Space.sm),
        PillSegmented<String>(
          segments: [
            ('system', t.languageSystem),
            ('en', t.languageEnglish),
            ('ar', t.languageArabic),
          ],
          selected: locale == null ? 'system' : locale.languageCode,
          onChanged: (v) => ref
              .read(localeProvider.notifier)
              .set(v == 'system' ? null : Locale(v)),
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
        _BlockLabel(
          icon: Icons.notifications_outlined,
          label: t.notificationChannelsLabel,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.smsLabel),
          value: notify.sms,
          onChanged: ref.read(notificationPrefsProvider.notifier).setSms,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.emailLabel),
          value: notify.email,
          onChanged: ref.read(notificationPrefsProvider.notifier).setEmail,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.soundsLabel),
          subtitle: Text(t.soundsSubtitle),
          value: soundsOn,
          onChanged: (v) => ref
              .read(soundsEnabledProvider.notifier)
              .set(enabled: v),
        ),
        Text(
          t.notificationChannelsCaption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final byBlock = {
      PrefsBlock.theme: themeBlock,
      PrefsBlock.textSize: textSizeBlock,
      PrefsBlock.language: languageBlock,
      PrefsBlock.notifications: notificationsBlock,
    };
    final shown = [
      for (final b in PrefsBlock.values)
        if (blocks.contains(b)) byBlock[b]!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) SectionHeader(t.preferences, overline: true),
        for (final (i, block) in shown.indexed) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          AppCard(padding: const EdgeInsets.all(Space.md), child: block),
        ],
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
