/// Persistent notifications action for patient screens. Theme, language and
/// other settings live in the drawer's Settings & Preferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../patient_home/presentation/notifications_button.dart';

/// Drop straight into `AppBar.actions`: `actions: const [PatientTopActions()]`.
class PatientTopActions extends ConsumerWidget {
  const PatientTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationsButton(),
        SizedBox(width: Space.xs),
      ],
    );
  }
}
