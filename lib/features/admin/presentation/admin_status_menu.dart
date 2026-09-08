/// The admin's working-status pill for the app bar — visually the staff
/// [PresenceMenu], but the status is a device-local preference
/// ([adminStatusProvider]), not shared DB state.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/audio/app_sounds.dart';

/// Dot colour + icon for an [AdminStatus].
({Color color, IconData icon}) _meta(BuildContext context, AdminStatus status) {
  final scheme = Theme.of(context).colorScheme;
  final ramp = Theme.of(context).clinicalStatus;
  return switch (status) {
    AdminStatus.available => (
      color: ramp.riskLow.onContainer,
      icon: Icons.check_circle,
    ),
    AdminStatus.meeting => (
      color: ramp.riskHigh.onContainer,
      icon: Icons.do_not_disturb_on,
    ),
    AdminStatus.away => (
      color: ramp.riskMedium.onContainer,
      icon: Icons.coffee,
    ),
    AdminStatus.off => (
      color: scheme.onSurfaceVariant,
      icon: Icons.nightlight_round,
    ),
  };
}

class AdminStatusMenu extends ConsumerWidget {
  const AdminStatusMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(adminStatusProvider);
    final meta = _meta(context, current);

    return PopupMenuButton<AdminStatus>(
      tooltip: 'Set your status',
      position: PopupMenuPosition.under,
      onSelected: (status) {
        unawaited(ref.read(adminStatusProvider.notifier).set(status));
        unawaited(
          ref.read(soundPlayerProvider).play(AppSound.forAdminStatus(status)),
        );
      },
      itemBuilder: (context) => [
        for (final status in AdminStatus.values)
          PopupMenuItem(
            value: status,
            child: Row(
              children: [
                Icon(
                  _meta(context, status).icon,
                  size: 18,
                  color: _meta(context, status).color,
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(status.label)),
                if (status == current)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
      ],
      // 40dp pill (matching the circle buttons beside it) centred in a 48dp
      // tap target — PopupMenuButton hit-tests its child (DESIGN.md §8).
      child: SizedBox(
        height: 48,
        child: Center(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 48, maxWidth: 156),
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: Radii.pill,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(meta.icon, size: 15, color: meta.color),
                const SizedBox(width: Space.xs),
                Flexible(
                  child: Text(
                    current.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
