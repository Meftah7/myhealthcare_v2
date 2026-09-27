import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/auth/password_hasher.dart';

void main() {
  const hasher = PasswordHasher(iterations: 1000);

  test('verifies a correct password and rejects a wrong one', () {
    final h = hasher.hashNew('correct horse battery staple');
    expect(
      hasher.verify('correct horse battery staple', hash: h.hash, salt: h.salt),
      isTrue,
    );
    expect(hasher.verify('wrong', hash: h.hash, salt: h.salt), isFalse);
  });

  test('same password hashes differently each time (random salt)', () {
    final a = hasher.hashNew('pw');
    final b = hasher.hashNew('pw');
    expect(a.hash, isNot(b.hash));
    expect(a.salt, isNot(b.salt));
  });

  test('a hash made with a different work factor still verifies', () {
    // 1000 — the seeder's own deliberately-cheap work factor for bulk demo
    // data — not an arbitrary number below verify()'s minimum-iterations
    // floor (see the next test).
    final cheap = const PasswordHasher(iterations: 1000).hashNew('pw');
    // A hasher configured for more iterations reads the count from the string.
    const strict = PasswordHasher(iterations: 50000);
    expect(strict.verify('pw', hash: cheap.hash, salt: cheap.salt), isTrue);
    expect(cheap.hash.startsWith('1000:'), isTrue);
  });

  test('verify rejects an out-of-range iteration count embedded in the hash', () {
    const hasher = PasswordHasher();
    // A tampered/corrupted row could embed an absurd count; verify() must
    // reject it outright rather than actually running that many rounds.
    expect(
      hasher.verify('pw', hash: '999999999:AAAA=', salt: 'AAAA='),
      isFalse,
    );
    expect(hasher.verify('pw', hash: '0:AAAA=', salt: 'AAAA='), isFalse);
    expect(hasher.verify('pw', hash: '-5:AAAA=', salt: 'AAAA='), isFalse);
  });
}
