/// Notifications entry point for the patient home top bar (redesign v2).
///
/// Button only for now — no click behaviour or unread badge defined yet.
library;

import 'package:flutter/material.dart';

import '../../../core/presentation/circle_icon_button.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleIconButton(
      icon: Icons.notifications_outlined,
      tooltip: 'Notifications',
      onPressed: _noop,
    );
  }
}

void _noop() {}
