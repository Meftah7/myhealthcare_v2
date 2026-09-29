/// The signed-in user and the session lifecycle (P2-04, P2-06).
///
/// The account shown here mirrors the principal in `AuthContext`, which is
/// what repositories actually authorize against. Every change of account —
/// sign-in, sign-out, idle expiry, demo switch, deactivation — discards all
/// user-scoped state (see `app/session_scope.dart`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/session_scope.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../services/auth/recovery_delivery.dart';
import '../../nutrition/application/nutrition_providers.dart';

export '../../../services/auth/auth_context.dart'
    show kSessionIdleTimeout, kSessionWarningLead;

class Session {
  const Session({
    this.user,
    this.isRestoring = false,
    this.endedByInactivity = false,
    this.resumeAccountId,
    this.resumeLocation,
  });

  final User? user;

  /// True while the persisted session is being loaded on startup.
  final bool isRestoring;

  /// Set when the last session was ended by the idle timeout — the sign-in
  /// screen shows a notice. Cleared on the next successful sign-in.
  final bool endedByInactivity;

  /// After an idle timeout: the account that timed out and where it was.
  /// Signing back in as *that* account returns there; any other account
  /// starts at its own home.
  final String? resumeAccountId;
  final String? resumeLocation;

  bool get isAuthenticated => user != null;
}

class SessionController extends Notifier<Session> {
  /// Written by older builds; removed so no account ID lingers on disk.
  static const _legacyPrefsKey = 'session.userId';
  StreamSubscription<User?>? _accountChanges;

  @override
  Session build() {
    // The session is intentionally *not* restored on startup: every cold start
    // must land on the Login screen (see `_guard` in `lib/app/router.dart`).
    unawaited(ref.read(sharedPreferencesProvider).remove(_legacyPrefsKey));
    // If a repository finds the account gone or deactivated it clears the
    // principal; end the visible session to match.
    final context = ref.read(authContextProvider);
    void onContextChanged() {
      if (context.principal == null && state.user != null) {
        unawaited(endSession());
      }
    }

    context.addListener(onContextChanged);
    ref.onDispose(() {
      context.removeListener(onContextChanged);
      unawaited(_accountChanges?.cancel());
    });
    return const Session();
  }

  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final previous = state;
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (result case Ok(:final value)) {
      _begin(value, resumeFrom: previous);
    }
    return result;
  }

  Future<Result<Patient>> register(PatientRegistration registration) async {
    final result = await ref
        .read(authRepositoryProvider)
        .registerPatient(registration);
    if (result case Ok(:final value)) _begin(value.user);
    return result;
  }

  /// Demo builds: jump straight into another account (P2-06). Goes through
  /// the auth repository, which refuses in production.
  Future<Result<User>> switchTo(User user) async {
    final result = await ref.read(authRepositoryProvider).demoSignIn(user.id);
    if (result case Ok(:final value)) _begin(value);
    return result;
  }

  /// Prove the password again (sensitive actions, or after the idle
  /// warning).
  Future<Result<void>> reauthenticate(String password) =>
      ref.read(authRepositoryProvider).reauthenticate(password);

  /// End the session and return to sign-in. [inactivity] surfaces the "your
  /// session ended after 24 minutes of inactivity" notice on the login screen
  /// and remembers [location] so the same account can resume there.
  Future<void> endSession({bool inactivity = false, String? location}) async {
    final accountId = state.user?.id;
    final accountChanges = _accountChanges;
    _accountChanges = null;
    // Lock the UI before waiting on storage/stream cleanup. A slow plugin or
    // database listener must never extend an expired session.
    state = Session(
      endedByInactivity: inactivity,
      resumeAccountId: inactivity ? accountId : null,
      resumeLocation: inactivity ? location : null,
    );
    await ref
        .read(authRepositoryProvider)
        .signOut(reason: inactivity ? 'idle_timeout' : 'signed_out');
    await accountChanges?.cancel();
    try {
      await _discardUserState(accountId);
    } on StateError {
      // The container was disposed while signing out (app shutdown) —
      // nothing is left to discard.
    }
  }

  Future<void> logout() => endSession();

  void _begin(User user, {Session? resumeFrom}) {
    final previousUser = state.user;
    // A different account on this device must never see the last one's
    // state — even a session that ended without a clean sign-out.
    unawaited(_discardUserState(previousUser?.id));
    final resume = resumeFrom != null && resumeFrom.resumeAccountId == user.id
        ? resumeFrom.resumeLocation
        : null;
    state = Session(
      user: user,
      resumeAccountId: resume == null ? null : user.id,
      resumeLocation: resume,
    );
    _watchAccount(user.id);
  }

  Future<void> _discardUserState(String? accountId) async {
    discardUserScopedState(ref.container);
    final recovery = ref.read(recoveryDeliveryProvider);
    if (recovery is DemoRecoveryOutbox) recovery.clear();
    await clearNutritionState(ref.read(sharedPreferencesProvider), accountId);
  }

  void _watchAccount(String userId) {
    unawaited(_accountChanges?.cancel());
    final role = state.user?.role;
    _accountChanges = ref
        .read(userRepositoryProvider)
        .watchById(userId)
        .listen(
          // The query re-emits whenever *any* user row changes; only the
          // account disappearing, being deactivated or changing role ends
          // the session.
          (user) {
            final stillValid =
                user != null && user.isActive && user.role == role;
            if (!stillValid && state.user?.id == userId) {
              unawaited(endSession());
            }
          },
          // An authorization or storage error on this watch means the
          // account can no longer be confirmed — fail closed.
          onError: (Object _) {
            if (state.user?.id == userId) unawaited(endSession());
          },
        );
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

/// The current user, or null. Convenience for widgets that only read.
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(sessionProvider).user,
);

/// What the signed-in principal may attempt, from the same role grants the
/// repositories enforce. Use it to decide what to *offer* (hide a nurse's
/// "Prescribe"); it is never the enforcement — repositories re-check every
/// call.
final permissionsProvider = Provider<Set<Permission>>((ref) {
  ref.watch(sessionProvider);
  return ref.read(authContextProvider).principal?.permissions ??
      const <Permission>{};
});

final canProvider = Provider.family<bool, Permission>(
  (ref, permission) => ref.watch(permissionsProvider).contains(permission),
);
