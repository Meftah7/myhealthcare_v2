/// Plays the arrival cue when a new notification lands for the signed-in user.
///
/// Mounted once, above the router, so it hears arrivals on every screen and in
/// every role — a patient reminder, or an admin broadcast reaching staff.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/app_sounds.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';
import '../application/notification_providers.dart';

class NotificationSoundCue extends ConsumerStatefulWidget {
  const NotificationSoundCue({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationSoundCue> createState() =>
      _NotificationSoundCueState();
}

class _NotificationSoundCueState extends ConsumerState<NotificationSoundCue> {
  /// The newest notification we have already accounted for. Null means the
  /// feed for the current user hasn't been seen yet.
  String? _newestSeenId;
  String? _forUserId;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;

    ref.listen<AsyncValue<List<AppNotification>>>(myNotificationsProvider, (
      _,
      next,
    ) {
      final feed = next.valueOrNull;
      if (feed == null) return;
      final newest = feed.isEmpty ? null : feed.first; // repo sorts newest-first

      // The first delivery after a sign-in only primes the marker: we announce
      // arrivals, never the backlog that was already waiting.
      if (_forUserId != userId) {
        _forUserId = userId;
        _newestSeenId = newest?.id;
        return;
      }

      if (newest == null || newest.id == _newestSeenId) return;
      _newestSeenId = newest.id;
      if (!newest.isRead) {
        unawaited(ref.read(soundPlayerProvider).play(AppSound.notification));
      }
    });

    return widget.child;
  }
}
