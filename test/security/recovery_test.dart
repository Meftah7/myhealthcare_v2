// Gate 1 — verified recovery: a single-use, expiring code sent to the
// account's own email is the only self-service way back in. Expired,
// reused, guessed, superseded and unverified attempts all fail with one
// generic message, and every outcome is audited.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/repositories/auth_repository.dart';
import 'package:myhealthcare/services/auth/auth_context.dart';
import 'package:myhealthcare/services/auth/password_hasher.dart';
import 'package:myhealthcare/services/auth/recovery_delivery.dart';

import '../support/test_database.dart';

const _email = 'patient1@myhealth.demo';
const _newPassword = 'Recovered-Pass-9';

class _Clock {
  DateTime now = DateTime(2026, 9, 28, 9);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

class _Harness {
  _Harness(this.db, this.clock)
    : outbox = DemoRecoveryOutbox(),
      context = AuthContext() {
    auth = AuthRepositoryImpl(
      db,
      hasher: const PasswordHasher(iterations: 1000),
      context: context,
      recovery: outbox,
      now: clock.call,
    );
  }

  final AppDatabase db;
  final _Clock clock;
  final DemoRecoveryOutbox outbox;
  final AuthContext context;
  late final AuthRepositoryImpl auth;

  Future<RecoveryChallenge> start([String identifier = _email]) async =>
      (await auth.startRecovery(identifier)).valueOrNull!;

  String get lastCode => outbox.messages.first.code;

  Future<Result<void>> complete(
    RecoveryChallenge challenge,
    String code, [
    String password = _newPassword,
  ]) => auth.completeRecovery(
    challengeId: challenge.challengeId,
    code: code,
    newPassword: password,
  );

  Future<List<String>> auditActions() async =>
      (await db.select(db.auditLog).get()).map((a) => a.action).toList();
}

Future<_Harness> _harness() async {
  final db = newTestDatabase();
  addTearDown(db.close);
  await Seeder(db).run();
  return _Harness(db, _Clock());
}

String _wrong(String code) => code == '000000' ? '111111' : '000000';

void main() {
  test('a verified code resets the password once; the old password stops '
      'working and the new one signs in', () async {
    final h = await _harness();
    final challenge = await h.start();
    expect(challenge.selfService, isTrue);
    expect(h.outbox.messages, hasLength(1));
    // The code goes to the address on file, masked when shown.
    expect(h.outbox.messages.first.sentTo, 'p***@myhealth.demo');

    final done = await h.complete(challenge, h.lastCode);
    expect(done, isA<Ok<void>>());

    expect(
      await h.auth.login(email: _email, password: Seeder.demoPassword),
      isA<Err<dynamic>>(),
    );
    expect(
      await h.auth.login(email: _email, password: _newPassword),
      isA<Ok<dynamic>>(),
    );
    expect(await h.auditActions(), contains('recovery.completed'));
    // The simulated inbox forgets a used code.
    expect(h.outbox.messages, isEmpty);
  });

  test('a code cannot be reused', () async {
    final h = await _harness();
    final challenge = await h.start();
    final code = h.lastCode;
    expect(await h.complete(challenge, code), isA<Ok<void>>());

    final again = await h.complete(challenge, code, 'Another-Pass-77');
    expect(again.failureOrNull, isA<AuthFailure>());
    expect(
      await h.auth.login(email: _email, password: 'Another-Pass-77'),
      isA<Err<dynamic>>(),
    );
  });

  test('an expired code fails', () async {
    final h = await _harness();
    final challenge = await h.start();
    h.clock.advance(
      AuthRepositoryImpl.recoveryCodeLifetime + const Duration(seconds: 1),
    );
    final r = await h.complete(challenge, h.lastCode);
    expect(r.failureOrNull, isA<AuthFailure>());
    expect(
      await h.auth.login(email: _email, password: Seeder.demoPassword),
      isA<Ok<dynamic>>(),
    );
  });

  test(
    'wrong guesses burn the code — even the right code fails after',
    () async {
      final h = await _harness();
      final challenge = await h.start();
      final code = h.lastCode;
      for (var i = 0; i < AuthRepositoryImpl.maxRecoveryCodeAttempts; i++) {
        expect((await h.complete(challenge, _wrong(code))).isErr, isTrue);
      }
      expect(
        (await h.complete(challenge, code)).failureOrNull,
        isA<AuthFailure>(),
      );
    },
  );

  test('a newer code supersedes the older one', () async {
    final h = await _harness();
    final first = await h.start();
    final firstCode = h.lastCode;
    await h.start();
    expect((await h.complete(first, firstCode)).isErr, isTrue);
  });

  test(
    'an unknown identifier gets the same answer and nothing is sent',
    () async {
      final h = await _harness();
      final real = await h.start();
      final fake = await h.start('nobody@myhealth.demo');
      expect(fake.selfService, real.selfService);
      expect(
        fake.expiresAt.difference(real.expiresAt).inSeconds.abs(),
        lessThan(2),
      );
      expect(h.outbox.messages, hasLength(1)); // only the real one
      final r = await h.complete(fake, '123456');
      final realWrong = await h.complete(real, _wrong(h.lastCode));
      // One message for "no such challenge" and "wrong code".
      expect(r.failureOrNull!.message, realWrong.failureOrNull!.message);
    },
  );

  test('unverified: a challenge cannot be redeemed without the code', () async {
    final h = await _harness();
    final challenge = await h.start();
    for (final code in ['', '12345', 'abcdef', '1234567']) {
      expect((await h.complete(challenge, code)).isErr, isTrue);
    }
  });

  test('recovery is rate-limited per account and per device', () async {
    final h = await _harness();
    for (var i = 0; i < AuthRepositoryImpl.maxRecoveryCodesPerHour; i++) {
      await h.start();
    }
    expect(
      h.outbox.messages,
      hasLength(AuthRepositoryImpl.maxRecoveryCodesPerHour),
    );
    // Past the per-account limit the answer looks the same, but no code goes
    // out.
    final limited = await h.start();
    expect(limited.selfService, isTrue);
    expect(
      h.outbox.messages,
      hasLength(AuthRepositoryImpl.maxRecoveryCodesPerHour),
    );
    expect(await h.auditActions(), contains('recovery.rate_limited'));

    // Past the per-device limit the request itself is refused.
    await h.start('patient2@myhealth.demo');
    final refused = await h.auth.startRecovery('patient3@myhealth.demo');
    expect(refused.failureOrNull, isA<ValidationFailure>());
  });

  test('changing the password revokes outstanding codes', () async {
    final h = await _harness();
    final challenge = await h.start();
    final code = h.lastCode;
    await h.auth.login(email: _email, password: Seeder.demoPassword);
    final user = h.context.principal!.accountId;
    expect(
      await h.auth.changePassword(
        userId: user,
        currentPassword: Seeder.demoPassword,
        newPassword: 'Changed-Pass-33',
      ),
      isA<Ok<void>>(),
    );
    expect((await h.complete(challenge, code)).isErr, isTrue);
  });

  test('without a delivery channel, recovery queues an admin-verified '
      'request instead of issuing a code', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final auth = AuthRepositoryImpl(db);
    final r = await auth.startRecovery(_email);
    expect(r.valueOrNull!.selfService, isFalse);
    final queued = await db.select(db.passwordResetRequests).get();
    expect(queued, hasLength(1));
    expect(await db.select(db.accountRecoveryTokens).get(), isEmpty);
  });

  test('only a salted hash of the code is stored', () async {
    final h = await _harness();
    await h.start();
    final row = (await h.db.select(h.db.accountRecoveryTokens).get()).single;
    expect(row.codeHash, isNot(contains(h.lastCode)));
    expect(row.codeSalt, isNotEmpty);
  });

  test(
    'a dependent record (no login) can neither sign in nor recover',
    () async {
      final h = await _harness();
      final dependent = (await (h.db.select(
        h.db.users,
      )..limit(1)).get()).single;
      await (h.db.update(h.db.users)..where((u) => u.id.equals(dependent.id)))
          .write(const UsersCompanion(hasLogin: Value(false)));
      expect(
        await h.auth.login(
          email: dependent.email,
          password: Seeder.demoPassword,
        ),
        isA<Err<dynamic>>(),
      );
      await h.start(dependent.email);
      expect(h.outbox.messages, isEmpty);
    },
  );
}
