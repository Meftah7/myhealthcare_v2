/// Notifications centre — the patient's in-app messages, grouped by recency,
/// with mark-as-read and a detail view.
///
/// Adaptive: full-width rows on compact, centred and capped at the shared max
/// content width from medium up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({
    this.topActions = const PatientTopActions(),
    super.key,
  });

  /// The role's persistent top-bar group — patient, staff or admin.
  final Widget topActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(myNotificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationControllerProvider).markAllRead(),
              child: const Text('Mark all read'),
            ),
          topActions,
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: feed.when(
            loading: () => const SkeletonList(),
            error: (e, _) => ErrorStateView(
              message: 'Could not load your notifications.',
              onRetry: () => ref.invalidate(myNotificationsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(gutter),
                  children: const [
                    SizedBox(height: Space.xxl),
                    EmptyState(
                      icon: Icons.notifications_none_outlined,
                      message: "You're all caught up.\nNothing new here.",
                    ),
                  ],
                );
              }

              final now = DateTime.now();
              final recent = list
                  .where((n) => now.difference(n.createdAt).inHours < 24)
                  .toList();
              final earlier = list
                  .where((n) => now.difference(n.createdAt).inHours >= 24)
                  .toList();

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.xxl,
                ),
                children: [
                  if (recent.isNotEmpty) ...[
                    const SectionHeader('Last 24 hours', overline: true),
                    for (final n in recent) _NotificationTile(n),
                    const SizedBox(height: Space.md),
                  ],
                  if (earlier.isNotEmpty) ...[
                    const SectionHeader('Earlier', overline: true),
                    for (final n in earlier) _NotificationTile(n),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Icon + accent for each category.
({IconData icon, Color Function(ColorScheme) color}) _style(
  NotificationCategory c,
) {
  return switch (c) {
    NotificationCategory.appointment => (
      icon: Icons.event_outlined,
      color: (s) => s.primary,
    ),
    NotificationCategory.billing => (
      icon: Icons.receipt_long_outlined,
      color: (s) => s.tertiary,
    ),
    NotificationCategory.labResult => (
      icon: Icons.science_outlined,
      color: (s) => s.secondary,
    ),
    NotificationCategory.prescription => (
      icon: Icons.medication_outlined,
      color: (s) => s.primary,
    ),
    NotificationCategory.message => (
      icon: Icons.chat_bubble_outline,
      color: (s) => s.primary,
    ),
    NotificationCategory.system => (
      icon: Icons.info_outline,
      color: (s) => s.onSurfaceVariant,
    ),
  };
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile(this.notification);

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = _style(notification.category);
    final accent = style.color(scheme);
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        color: unread ? scheme.surfaceContainerHighest : null,
        onTap: () => _open(context, ref),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, size: 18, color: accent),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        fmtTimeAgo(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: Space.xs, top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      await ref.read(notificationControllerProvider).markRead(notification.id);
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _NotificationDetailSheet(notification: notification),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = _style(notification.category);
    final accent = style.color(scheme);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, size: 20, color: accent),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    notification.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(
              fmtDateTime(notification.createdAt),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(notification.body, style: theme.textTheme.bodyLarge),
            if (notification.deepLink != null) ...[
              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(notification.deepLink!);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Open'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
