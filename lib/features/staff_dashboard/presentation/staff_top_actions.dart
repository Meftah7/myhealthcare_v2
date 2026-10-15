import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../domain/enums.dart';
import '../../patient_home/presentation/notifications_button.dart';
import '../../settings/presentation/theme_mode_icon_toggle.dart';

/// Notifications and the persisted patient theme remain visible on phones.
class StaffTopActions extends StatelessWidget {
  const StaffTopActions({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      NotificationsButton(route: AppRoutes.staffNotifications),
      ThemeModeIconToggle(),
    ],
  );
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
