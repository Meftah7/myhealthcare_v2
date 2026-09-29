/// Idempotent mutations (Phase 2).
///
/// A consequential write (booking, payment, message, request) carries an
/// [IdempotencyKey]. Inside the write's own transaction the repository asks
/// [IdempotencyGuard.prior] whether that key already committed; if so it
/// returns the original result instead of doing the work again, and if not
/// it does the work and [IdempotencyGuard.remember]s the key in the same
/// transaction. A response lost on the network, a double tap, or an app
/// killed mid-request therefore cannot book twice or charge twice.
library;

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../db/app_database.dart';

class IdempotencyGuard {
  IdempotencyGuard(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// The result id an earlier commit with [key] produced, or null if the key
  /// is new. A key used for a different kind of mutation, or by a different
  /// account, is refused rather than silently reused.
  Future<String?> prior(
    IdempotencyKey? key, {
    required String scope,
    required String? actorAccountId,
  }) async {
    if (key == null) return null;
    final row = await (_db.select(
      _db.idempotencyRecords,
    )..where((r) => r.key.equals(key.value))).getSingleOrNull();
    if (row == null) return null;
    if (row.scope != scope || row.actorAccountId != actorAccountId) {
      throw const ValidationFailure(
        'This request was already used for something else. Start again.',
      );
    }
    onDuplicatePrevented?.call(scope);
    return row.resultRef;
  }

  /// Told when a repeated request is answered with its original result.
  /// Set once at app start for operational metrics; receives the scope only.
  static void Function(String scope)? onDuplicatePrevented;

  /// Record that [key] committed [resultRef]. Call inside the same
  /// transaction as the mutation.
  Future<void> remember(
    IdempotencyKey? key, {
    required String scope,
    required String? actorAccountId,
    required String resultRef,
  }) async {
    if (key == null) return;
    await _db
        .into(_db.idempotencyRecords)
        .insert(
          IdempotencyRecordsCompanion.insert(
            key: key.value,
            scope: scope,
            actorAccountId: Value(actorAccountId),
            resultRef: resultRef,
            createdAt: _now(),
          ),
        );
  }
}
