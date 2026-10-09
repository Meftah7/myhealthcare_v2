/// The persistent top-bar action group for every staff screen (staff-dashboard
/// rebuild): a live presence menu, notifications and a light/dark toggle,
/// always top-right, in the same place, on every page.
///
/// Mirrors the patient app's `PatientTopActions` and the FirstSemMyHealth
/// doctor header (presence dropdown + dark-mode + account).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient_home/presentation/notifications_button.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';
import '../application/staff_providers.dart';

/// Drop straight into `AppBar.actions`: `actions: const [StaffTopActions()]`.
///
/// Same hairline-circle family as the patient app's [PatientTopActions], with
/// the staff-only presence pill in front of them.
class StaffTopActions extends ConsumerWidget {
  const StaffTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width < 360) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceMenu(showNotifications: true),
          ThemeModeIconToggle(),
        ],
      );
    }
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceMenu(),
        NotificationsButton(route: AppRoutes.staffNotifications),
        ThemeModeIconToggle(),
        SizedBox(width: Space.xs),
      ],
    );
  }
}

/// Presentation metadata for a [PresenceStatus] — dot colour, icon, label.
({Color color, IconData icon, String label}) presenceMeta(
  BuildContext context,
  PresenceStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  final ramp = Theme.of(context).clinicalStatus;
  return switch (status) {
    PresenceStatus.onDuty => (
      color: ramp.riskLow.onContainer,
      icon: Icons.check_circle,
      label: status.label(context),
    ),
    PresenceStatus.inConsultation => (
      color: ramp.riskHigh.onContainer,
      icon: Icons.do_not_disturb_on,
      label: status.label(context),
    ),
    PresenceStatus.onBreak => (
      color: ramp.riskMedium.onContainer,
      icon: Icons.coffee,
      label: status.label(context),
    ),
    PresenceStatus.offShift => (
      color: scheme.onSurfaceVariant,
      icon: Icons.nightlight_round,
      label: status.label(context),
    ),
  };
}

/// A compact pill in the app bar showing the signed-in clinician's presence,
/// tap to change it.
class PresenceMenu extends ConsumerWidget {
  const PresenceMenu({this.showNotifications = false, super.key});

  final bool showNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = ref.watch(staffProfileProvider);
    final current = profile.valueOrNull?.presence ?? PresenceStatus.offShift;
    final meta = presenceMeta(context, current);
    final compact = WindowSize.of(context).isCompact;

    return PopupMenuButton<Object>(
      tooltip: showNotifications
          ? t.moreActionsTooltip
          : t.setYourAvailabilityTooltip,
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'profile') {
          await context.push(AppRoutes.staffProfile);
          return;
        }
        if (value == 'notifications') {
          await context.push(AppRoutes.staffNotifications);
          return;
        }
        final result = await ref
            .read(staffOpsProvider)
            .setPresence(value as PresenceStatus);
        if (context.mounted && result.isErr) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.couldNotUpdatePresence)));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'profile', child: Text(t.profile)),
        const PopupMenuDivider(),
        if (showNotifications) ...[
          PopupMenuItem(
            value: 'notifications',
            child: Text(t.notificationsTooltip),
          ),
          const PopupMenuDivider(),
        ],
        for (final status in PresenceStatus.values)
          PopupMenuItem(
            value: status,
            child: Row(
              children: [
                Icon(
                  presenceMeta(context, status).icon,
                  size: 18,
                  color: presenceMeta(context, status).color,
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(presenceMeta(context, status).label)),
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
                if (!compact) ...[
                  const SizedBox(width: Space.xs),
                  Flexible(
                    child: Text(
                      meta.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
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
