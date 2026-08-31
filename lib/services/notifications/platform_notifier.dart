/// Notification delivery abstraction (P4-18).
///
/// One capability check, notifications where the OS supports them, in-app
/// banners everywhere else (web included) — so this never leaks into feature
/// code. The `flutter_local_notifications` wiring for Android/Windows is added
/// during device QA (P6-06); until then every platform uses the in-app
/// fallback, which the app already surfaces from the `reminders` table.
library;

import 'package:flutter/foundation.dart';

abstract interface class PlatformNotifier {
  /// True when the OS can show a scheduled local notification.
  bool get supportsScheduledNotifications;

  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);
}

/// No-op OS layer — reminders are shown in-app from the `reminders` table
/// instead. Replaced by a real implementation during device QA.
class InAppOnlyNotifier implements PlatformNotifier {
  const InAppOnlyNotifier();

  @override
  bool get supportsScheduledNotifications => false;

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (kDebugMode) {
      debugPrint('[reminder] $when · $title — $body (in-app only)');
    }
  }

  @override
  Future<void> cancel(int id) async {}
}
