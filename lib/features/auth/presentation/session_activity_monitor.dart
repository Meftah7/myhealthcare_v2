/// Idle auto-sign-out. Wraps the whole app: while someone is signed in, any
/// pointer or key activity resets a [kSessionIdleTimeout] countdown; if it
/// fires, the session ends and the router returns to sign-in with a notice.
///
/// This is the client-side equivalent of the FirstSemMyHealth server session
/// expiring after PHP's default 24 minutes of inactivity.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session.dart';

class SessionActivityMonitor extends ConsumerStatefulWidget {
  const SessionActivityMonitor({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionActivityMonitor> createState() =>
      _SessionActivityMonitorState();
}

class _SessionActivityMonitorState
    extends ConsumerState<SessionActivityMonitor> {
  Timer? _timer;
  DateTime _lastBump = DateTime.fromMillisecondsSinceEpoch(0);

  void _restart() {
    _timer?.cancel();
    _timer = Timer(kSessionIdleTimeout, _expire);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Debounced — a stream of pointer moves only pushes the deadline once a
  /// second, not on every frame.
  void _bump([_]) {
    if (_timer == null) return; // not signed in
    final now = DateTime.now();
    if (now.difference(_lastBump) < const Duration(seconds: 1)) return;
    _lastBump = now;
    _restart();
  }

  Future<void> _expire() async {
    _stop();
    if (!mounted) return;
    await ref.read(sessionProvider.notifier).endSession(inactivity: true);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start / stop the countdown as auth state changes.
    ref.listen<Session>(sessionProvider, (prev, next) {
      if (next.isAuthenticated) {
        _restart();
      } else {
        _stop();
      }
    });
    // Cover the case where we're already signed in on first build.
    if (_timer == null && ref.read(sessionProvider).isAuthenticated) {
      _restart();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _bump,
      onPointerMove: _bump,
      onPointerSignal: _bump,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, _) {
          _bump();
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
