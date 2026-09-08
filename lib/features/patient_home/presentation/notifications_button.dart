/// Notifications entry point for the patient home top bar (redesign v2).
///
/// Shows an unread-count dot and opens the Notifications centre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/presentation/circle_icon_button.dart';
import '../../notifications/application/notification_providers.dart';

class NotificationsButton extends ConsumerWidget {
  const NotificationsButton({
    this.route = AppRoutes.patientNotifications,
    super.key,
  });

  /// Where the button goes — each role has its own notifications route.
  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleIconButton(
          icon: unread > 0
              ? Icons.notifications
              : Icons.notifications_outlined,
          tooltip: unread > 0
              ? 'Notifications ($unread unread)'
              : 'Notifications',
          onPressed: () => context.go(route),
        ),
        if (unread > 0)
          // Sits on the circle's top-right edge — the button draws a 40dp
          // circle centred in a 48dp tap target, so the rim is 4dp in.
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: scheme.surfaceContainerLowest,
                  width: 1.5,
                ),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
