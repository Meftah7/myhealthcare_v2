/// Idle auto-sign-out. Wraps the whole app: while someone is signed in, any
/// pointer or key activity resets a [kSessionIdleTimeout] countdown.
/// [kSessionWarningLead] before it runs out a "Still there?" card offers to
/// keep the session; if the countdown ends, the session ends, user state is
/// discarded, and the router returns to sign-in with a notice. Signing back
/// in as the same account returns to the screen it was on.
///
/// Activity also feeds `AuthContext`, so repositories refuse calls from a
/// session that has gone idle even if this widget's timer were somehow
/// delayed.
///
/// This is the client-side equivalent of the FirstSemMyHealth server session
/// expiring after PHP's default 24 minutes of inactivity.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../l10n/app_localizations.dart';
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
  Timer? _warningTimer;
  Timer? _expireTimer;
  Timer? _ticker;
  DateTime _lastBump = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _expiresAt;
  bool _warning = false;

  bool get _running => _expireTimer != null;

  void _restart() {
    _cancelTimers();
    _expiresAt = DateTime.now().add(kSessionIdleTimeout);
    _warningTimer = Timer(
      kSessionIdleTimeout - kSessionWarningLead,
      _showWarning,
    );
    _expireTimer = Timer(kSessionIdleTimeout, _expire);
    if (_warning) setState(() => _warning = false);
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _expireTimer?.cancel();
    _ticker?.cancel();
    _warningTimer = null;
    _expireTimer = null;
    _ticker = null;
  }

  void _stop() {
    _cancelTimers();
    _expiresAt = null;
    if (_warning && mounted) setState(() => _warning = false);
  }

  void _showWarning() {
    if (!mounted) return;
    setState(() => _warning = true);
    // Repaint the countdown once a second while the card is up.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Debounced — a stream of pointer moves only pushes the deadline once a
  /// second, not on every frame.
  void _bump([_]) {
    if (!_running) return; // not signed in
    final now = DateTime.now();
    if (!_warning && now.difference(_lastBump) < const Duration(seconds: 1)) {
      return;
    }
    _lastBump = now;
    ref.read(authContextProvider).touch();
    _restart();
  }

  Future<void> _expire() async {
    _stop();
    if (!mounted) return;
    String? location;
    try {
      location = ref
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
    } on Object {
      location = null;
    }
    await ref
        .read(sessionProvider.notifier)
        .endSession(inactivity: true, location: location);
  }

  Future<void> _signOutNow() async {
    _stop();
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start / stop the countdown as auth state changes.
    ref.listen<Session>(sessionProvider, (prev, next) {
      if (next.isAuthenticated) {
        if (prev?.user?.id != next.user?.id) _restart();
      } else {
        _stop();
      }
    });
    // Cover the case where we're already signed in on first build.
    if (!_running && ref.read(sessionProvider).isAuthenticated) {
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
        child: Stack(
          children: [
            widget.child,
            if (_warning && _expiresAt != null)
              _TimeoutWarning(
                remaining: _expiresAt!.difference(DateTime.now()),
                onStay: _bump,
                onSignOut: _signOutNow,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeoutWarning extends StatelessWidget {
  const _TimeoutWarning({
    required this.remaining,
    required this.onStay,
    required this.onSignOut,
  });

  final Duration remaining;
  final VoidCallback onStay;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final left = remaining.isNegative ? Duration.zero : remaining;
    final time =
        '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Positioned(
      left: Space.md,
      right: Space.md,
      bottom: Space.lg,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Semantics(
              liveRegion: true,
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              t.sessionWarningTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        t.sessionWarningBody(time),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: Space.sm),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Space.xs,
                        children: [
                          TextButton(
                            onPressed: onSignOut,
                            child: Text(t.signOut),
                          ),
                          FilledButton(
                            onPressed: onStay,
                            child: Text(t.staySignedIn),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
