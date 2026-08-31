/// The signed-in user, persisted across restarts (P2-04, P2-06).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/auth_repository.dart';

class Session {
  const Session({this.user, this.isRestoring = false});

  final User? user;

  /// True while the persisted session is being loaded on startup.
  final bool isRestoring;

  bool get isAuthenticated => user != null;

  Session copyWith({User? user, bool? isRestoring, bool clearUser = false}) {
    return Session(
      user: clearUser ? null : (user ?? this.user),
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class SessionController extends Notifier<Session> {
  static const _prefsKey = 'session.userId';

  @override
  Session build() {
    // Deferred so we never write `state` during build().
    unawaited(Future.microtask(_restore));
    return const Session(isRestoring: true);
  }

  Future<void> _restore() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = prefs.getString(_prefsKey);
    if (id == null) {
      state = const Session();
      return;
    }
    final result = await ref.read(userRepositoryProvider).byId(id);
    state = Session(user: result.valueOrNull);
    if (result.isErr) {
      await prefs.remove(_prefsKey);
    }
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

  Future<void> logout() async {
    await ref.read(sharedPreferencesProvider).remove(_prefsKey);
    state = const Session();
  }

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
