/// UI preferences (P8-07, redesign v2, Phase 6), grouped by where they are
/// kept: "On this device" (theme, text size, language, motion, contrast —
/// shared by anyone using this browser) and "For your account" (alert
/// channels — per signed-in person on this device). Each group has its own
/// reset, and a setting that fails to save says so. Clinic-wide settings
/// (hours, AI) are administrator pages, not here.
///
/// A self-contained block for the profile screens — reads and writes
/// [themeModeProvider] / [textScaleProvider] / [localeProvider] /
/// [notificationPrefsProvider], which drive `MaterialApp` in `app.dart` and the
/// reminder delivery preferences.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/notifications/device_notifier.dart';

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
enum PrefsBlock { theme, textSize, language, notifications, accessibility }

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({
    this.showHeader = true,
    this.blocks = const {
      PrefsBlock.theme,
      PrefsBlock.textSize,
      PrefsBlock.language,
      PrefsBlock.notifications,
      PrefsBlock.accessibility,
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
    final motionPref = ref.watch(motionPreferenceProvider);
    final highContrast = ref.watch(highContrastProvider);
    // A preference that failed to save has already been rolled back to its
    // previous value; say so rather than let the control silently snap back.
    ref.listen(settingsSaveFailureProvider, (_, _) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.settingSaveFailedMessage)));
    });

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
        // SMS and email have no delivery provider in this prototype: shown
        // (so the choice is visible) but off and disabled, never pretending
        // to send.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.smsLabel),
          subtitle: Text(
            '${t.smsChannelSubtitle} · ${t.channelNotAvailableInPrototype}',
          ),
          value: false,
          onChanged: null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.emailLabel),
          subtitle: Text(
            '${t.emailChannelSubtitle} · ${t.channelNotAvailableInPrototype}',
          ),
          value: false,
          onChanged: null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.pushLabel),
          subtitle: Text(t.pushChannelSubtitle),
          value: notify.push,
          onChanged: ref.read(notificationPrefsProvider.notifier).setPush,
        ),
        if (notify.push) const _AlertPermissionStatus(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.soundsLabel),
          subtitle: Text(t.soundsSubtitle),
          value: soundsOn,
          onChanged: (v) =>
              ref.read(soundsEnabledProvider.notifier).set(enabled: v),
        ),
        Text(
          t.notificationChannelsCaption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          t.inAppAlwaysOnNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: t.resetNotificationsTitle,
                message: t.resetNotificationsMessage,
                confirmLabel: t.resetAction,
              );
              if (!ok) return;
              await ref.read(notificationPrefsProvider.notifier).reset();
              await ref.read(soundsEnabledProvider.notifier).reset();
            },
            child: Text(t.resetNotificationsTitle),
          ),
        ),
      ],
    );

    final accessibilityBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockLabel(
          icon: Icons.accessibility_new_outlined,
          label: t.motionLabel,
        ),
        const SizedBox(height: Space.sm),
        PillSegmented<MotionPreference>(
          segments: [
            (MotionPreference.system, t.motionSystem),
            (MotionPreference.reduced, t.motionReduced),
            (MotionPreference.full, t.motionFull),
          ],
          selected: motionPref,
          onChanged: (v) => ref.read(motionPreferenceProvider.notifier).set(v),
        ),
        const SizedBox(height: Space.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.highContrastLabel),
          subtitle: Text(t.highContrastSubtitle),
          value: highContrast,
          onChanged: (v) =>
              ref.read(highContrastProvider.notifier).set(enabled: v),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: t.resetAppearanceTitle,
                message: t.resetAppearanceMessage,
                confirmLabel: t.resetAction,
              );
              if (!ok) return;
              await ref.read(themeModeProvider.notifier).reset();
              await ref.read(textScaleProvider.notifier).reset();
              await ref.read(motionPreferenceProvider.notifier).reset();
              await ref.read(highContrastProvider.notifier).reset();
            },
            child: Text(t.resetAppearanceTitle),
          ),
        ),
      ],
    );

    final byBlock = {
      PrefsBlock.theme: themeBlock,
      PrefsBlock.textSize: textSizeBlock,
      PrefsBlock.language: languageBlock,
      PrefsBlock.notifications: notificationsBlock,
      PrefsBlock.accessibility: accessibilityBlock,
    };
    // Grouped by where each setting lives (Phase 6), so nobody expects a
    // device choice to follow their account, or one person's alert choices
    // to change another's.
    const deviceBlocks = [
      PrefsBlock.theme,
      PrefsBlock.textSize,
      PrefsBlock.language,
      PrefsBlock.accessibility,
    ];
    const accountBlocks = [PrefsBlock.notifications];
    Widget group(String title, String caption, List<PrefsBlock> which) {
      final cards = [
        for (final b in which)
          if (blocks.contains(b)) byBlock[b]!,
      ];
      if (cards.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xxs),
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final card in cards) ...[
            const SizedBox(height: Space.sm),
            AppCard(padding: const EdgeInsets.all(Space.md), child: card),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) SectionHeader(t.preferences, overline: true),
        group(
          t.settingsDeviceScope,
          t.settingsDeviceScopeCaption,
          deviceBlocks,
        ),
        group(
          t.settingsAccountScope,
          t.settingsAccountScopeCaption,
          accountBlocks,
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

/// What the browser will actually do with alerts, with a way to ask when it
/// hasn't been asked yet. The in-app inbox is the fallback in every case.
class _AlertPermissionStatus extends ConsumerStatefulWidget {
  const _AlertPermissionStatus();

  @override
  ConsumerState<_AlertPermissionStatus> createState() =>
      _AlertPermissionStatusState();
}

class _AlertPermissionStatusState
    extends ConsumerState<_AlertPermissionStatus> {
  AlertPermission? _permission;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final p = await ref.read(deviceNotifierProvider).permission();
    if (mounted) setState(() => _permission = p);
  }

  Future<void> _request() async {
    final p = await ref.read(deviceNotifierProvider).requestPermission();
    if (mounted) setState(() => _permission = p);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final p = _permission;
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: switch (p) {
        AlertPermission.granted => Text(t.alertsAllowed, style: style),
        AlertPermission.denied => Text(t.alertsBlocked, style: style),
        AlertPermission.unsupported => Text(t.alertsUnsupported, style: style),
        AlertPermission.notRequested => Row(
          children: [
            Expanded(child: Text(t.alertsNotRequested, style: style)),
            TextButton(onPressed: _request, child: Text(t.allowAlertsAction)),
          ],
        ),
      },
    );
  }
}
