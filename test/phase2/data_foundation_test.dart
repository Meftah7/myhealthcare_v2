import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/data/data_state.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/tables/sync.dart';
import 'package:myhealthcare/data/repositories/task_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/data/sync/idempotency.dart';
import 'package:myhealthcare/data/sync/outbox.dart';
import 'package:myhealthcare/domain/entities/staff_task.dart';
import 'package:myhealthcare/domain/enums.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed and stale reads cannot masquerade as authoritative empty data',
    () {
      final offline = DataState<List<String>>.fromAsync(
        const AsyncError(OfflineFailure(), StackTrace.empty),
      );
      expect(offline, isA<DataOffline<List<String>>>());
      expect(offline.isAuthoritative, isFalse);

      final stale = DataState<List<String>>.fromAsync(
        const AsyncData(<String>[]),
        freshness: Freshness(fetchedAt: DateTime(2020), fromCache: true),
      );
      expect(stale, isA<DataStale<List<String>>>());
      expect(stale.isAuthoritative, isFalse);
    },
  );

  test('idempotency record returns the original committed result', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final guard = IdempotencyGuard(db);
    const key = IdempotencyKey('same-logical-request');

    await guard.remember(
      key,
      scope: 'test.create',
      actorAccountId: 'actor-1',
      resultRef: 'result-1',
    );

    expect(
      await guard.prior(key, scope: 'test.create', actorAccountId: 'actor-1'),
      'result-1',
    );
    expect(
      () => guard.prior(
        key,
        scope: 'different.operation',
        actorAccountId: 'actor-1',
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'outbox retries a failed side effect without duplicating its event',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      var now = DateTime(2026, 1, 1);
      var calls = 0;
      final outbox = Outbox(db, now: () => now);
      final dispatcher = OutboxDispatcher(
        db,
        now: () => now,
        handlers: {
          'test.deliver': (_, __) async {
            calls++;
            if (calls == 1) throw StateError('temporary failure');
          },
        },
      );

      final eventId = await outbox.enqueue('test.deliver', {'safe': true});
      expect(await dispatcher.drain(), 0);
      now = now.add(const Duration(seconds: 3));
      expect(await dispatcher.drain(), 1);

      final rows = await db.select(db.outboxEvents).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, eventId);
      expect(rows.single.attempts, 2);
      expect(rows.single.status, OutboxStatus.delivered);
    },
  );

  test(
    'stale task update returns a conflict and preserves newer state',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      final staff = (await db.select(db.staffProfiles).get()).first;
      final repo = TaskRepositoryImpl(db);
      expect(
        (await repo.upsert(
          StaffTask(
            id: 'task-conflict-test',
            staffId: staff.userId,
            title: 'Review result',
            kind: TaskKind.other,
            status: TaskStatus.open,
            ruleScore: 0.5,
            createdAt: DateTime(2026),
          ),
        )).isOk,
        isTrue,
      );
      final original = (await db.select(db.staffTasks).get()).first;

      final first = await repo.setStatus(
        id: original.id,
        staffId: original.staffId,
        status: TaskStatus.inProgress,
        expectedVersion: original.version,
      );
      expect(first.isOk, isTrue);

      final stale = await repo.setStatus(
        id: original.id,
        staffId: original.staffId,
        status: TaskStatus.done,
        expectedVersion: original.version,
      );
      expect(stale.failureOrNull, isA<ConflictFailure>());

      final stored = await (db.select(
        db.staffTasks,
      )..where((task) => task.id.equals(original.id))).getSingle();
      expect(stored.status, TaskStatus.inProgress);
    },
  );
}
