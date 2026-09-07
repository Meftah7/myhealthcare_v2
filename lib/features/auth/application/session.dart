/// The signed-in user, persisted across restarts (P2-04, P2-06).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auth_repository.dart';

/// How long the app sits idle before the session ends and the user is returned
/// to sign-in.
///
/// Mirrors the FirstSemMyHealth stack, whose server sessions expire on PHP's
/// default `session.gc_maxlifetime` of 1440 seconds (24 minutes) of inactivity.
const kSessionIdleTimeout = Duration(minutes: 24);

/// When true, every sign-in / registration must pass the MFA code screen
/// before reaching a dashboard (ported from the FirstSemMyHealth `MFA.html`
/// step). Off by default so the demo and test flows aren't gated; flip on with
/// `--dart-define=REQUIRE_MFA=true`.
const kRequireMfaAtSignIn = bool.fromEnvironment('REQUIRE_MFA');

/// The demo verification code (matches `MFA.html`'s hard-coded `111111`).
const kDemoMfaCode = '111111';

class Session {
  const Session({
    this.user,
    this.isRestoring = false,
    this.endedByInactivity = false,
    this.mfaPassed = false,
  });

  final User? user;

  /// True while the persisted session is being loaded on startup.
  final bool isRestoring;

  /// Set when the last session was ended by the idle timeout — the sign-in
  /// screen shows a notice. Cleared on the next successful sign-in.
  final bool endedByInactivity;

  /// True once the MFA code screen has been cleared for this session. Only
  /// consulted when [kRequireMfaAtSignIn] is on.
  final bool mfaPassed;

  bool get isAuthenticated => user != null;

  /// True when the user is signed in but still owes the MFA step.
  bool get needsMfa => user != null && kRequireMfaAtSignIn && !mfaPassed;

  Session copyWith({
    User? user,
    bool? isRestoring,
    bool? endedByInactivity,
    bool? mfaPassed,
    bool clearUser = false,
  }) {
    return Session(
      user: clearUser ? null : (user ?? this.user),
      isRestoring: isRestoring ?? this.isRestoring,
      endedByInactivity: endedByInactivity ?? this.endedByInactivity,
      mfaPassed: mfaPassed ?? this.mfaPassed,
    );
  }
}

class SessionController extends Notifier<Session> {
  static const _prefsKey = 'session.userId';

  @override
  Session build() {
    // The session is intentionally *not* restored on startup: every cold start
    // must land on the Login screen (see `_guard` in `lib/app/router.dart`).
    unawaited(ref.read(sharedPreferencesProvider).remove(_prefsKey));
    return const Session();
  }

  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (result case Ok(:final value)) {
      await _persist(value);
      state = Session(user: value);
    }
    return result;
  }

  /// End the session and return to sign-in. [inactivity] surfaces the "your
  /// session ended after 24 minutes of inactivity" notice on the login screen.
  Future<void> endSession({bool inactivity = false}) async {
    await ref.read(sharedPreferencesProvider).remove(_prefsKey);
    state = Session(endedByInactivity: inactivity);
  }

  /// Clear the MFA challenge for this session (called by the MFA screen once
  /// the code is verified).
  void passMfa() => state = state.copyWith(mfaPassed: true);

  Future<Result<Patient>> register(PatientRegistration registration) async {
    final result = await ref
        .read(authRepositoryProvider)
        .registerPatient(registration);
    if (result case Ok(:final value)) {
      await _persist(value.user);
      state = Session(user: value.user);
    }
    return result;
  }

  Future<void> logout() => endSession();

  /// Demo convenience — jump straight into another account (P2-06).
  Future<void> switchTo(User user) async {
    await _persist(user);
    state = Session(user: user);
  }

  Future<void> _persist(User user) =>
      ref.read(sharedPreferencesProvider).setString(_prefsKey, user.id);
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

/// The current user, or null. Convenience for widgets that only read.
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(sessionProvider).user,
);
