/// Persistent notifications and preferences actions for patient screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient_home/presentation/notifications_button.dart';

/// Drop straight into `AppBar.actions`: `actions: const [PatientTopActions()]`.
class PatientTopActions extends ConsumerWidget {
  const PatientTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NotificationsButton(),
        CircleIconButton(
          icon: Icons.settings_outlined,
          tooltip: t.preferences,
          onPressed: () => context.push(AppRoutes.patientProfilePreferences),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
  }
}
