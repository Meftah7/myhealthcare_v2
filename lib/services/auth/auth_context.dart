/// Holds the authenticated [Principal] for the running app.
///
/// Only a successful password check (`AuthRepository.login`,
/// `registerPatient`, demo sign-in, or `reauthenticate`) establishes one;
/// signing out, idle expiry and account deactivation clear it. Repositories
/// read it through `AccessPolicy` on every call, so a request made after the
/// session ended fails even if some screen still has the old user in memory.
library;

import 'package:flutter/foundation.dart';

import '../../core/failures.dart';
import '../../domain/identity/principal.dart';

/// How long the app sits idle before the session ends and the user is
/// returned to sign-in.
///
/// Mirrors the FirstSemMyHealth stack, whose server sessions expire on PHP's
/// default `session.gc_maxlifetime` of 1440 seconds (24 minutes) of
/// inactivity.
const kSessionIdleTimeout = Duration(minutes: 24);

/// How long before the idle timeout the "you're about to be signed out"
/// warning appears.
const kSessionWarningLead = Duration(minutes: 2);

/// A session ends after this long no matter how active it is.
const kSessionAbsoluteLifetime = Duration(hours: 12);

/// A sensitive action (password change, account administration) needs the
/// password to have been proven within this window.
const kReauthWindow = Duration(minutes: 15);

class AuthContext extends ChangeNotifier {
  AuthContext({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Principal? _principal;
  DateTime? _establishedAt;
  DateTime? _lastActivity;

  /// Repository-side idle check allows a little slack over the UI timer, so
  /// the UI is always the one that ends a session and shows the notice.
  static const _idleGrace = Duration(seconds: 30);

  Principal? get principal => _principal;

  DateTime now() => _now();

  void establish(Principal principal) {
    _principal = principal;
    _establishedAt = _now();
    _lastActivity = _establishedAt;
    notifyListeners();
  }

  void clear() {
    if (_principal == null) return;
    _principal = null;
    _establishedAt = null;
    _lastActivity = null;
    notifyListeners();
  }

  /// Record user interaction (pointer/key), pushing the idle deadline back.
  void touch() {
    if (_principal != null) _lastActivity = _now();
  }

  void markReauthenticated() {
    final p = _principal;
    if (p == null) return;
    _principal = p.reauthenticated(_now());
    _lastActivity = _now();
    notifyListeners();
  }

  /// Why the current session can no longer act, or null while it is valid.
  SessionExpiredFailure? get expiry {
    final p = _principal;
    if (p == null) return const SessionExpiredFailure();
    final now = _now();
    if (now.difference(_establishedAt!) > kSessionAbsoluteLifetime) {
      return const SessionExpiredFailure(
        'Your session reached its time limit. Please sign in again.',
      );
    }
    if (now.difference(_lastActivity!) > kSessionIdleTimeout + _idleGrace) {
      return const SessionExpiredFailure();
    }
    return null;
  }

  /// The principal, or a thrown [SessionExpiredFailure].
  Principal requireActive() {
    final failure = expiry;
    if (failure != null) throw failure;
    return _principal!;
  }

  bool get recentlyAuthenticated {
    final p = _principal;
    return p != null && _now().difference(p.authenticatedAt) <= kReauthWindow;
  }
}
