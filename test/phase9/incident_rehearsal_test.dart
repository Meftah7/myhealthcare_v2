/// Phase 9 staging rehearsals that can run without people: a provider outage
/// is detected by the operational signals, breaches its threshold, is
/// recovered by retry, and leaves a privacy-safe evidence export.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/observability/operational_metrics.dart';
import 'package:myhealthcare/data/sync/idempotency.dart';
import 'package:myhealthcare/data/sync/outbox.dart';

import '../support/test_database.dart';

void main() {
  test(
    'provider outage: detect, breach, recover by retry, export evidence',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      var clock = DateTime(2026, 9, 29, 10);
      final metrics = InMemoryOperationalMetrics();
      var providerUp = false;
      final delivered = <String>[];

      final dispatcher =
          OutboxDispatcher(
              db,
              now: () => clock,
              handlers: {
                'rehearsal.notify': (event, payload) async {
                  if (!providerUp) throw StateError('provider down');
                  delivered.add(event.id);
                },
              },
            )
            ..onFailure = ({required exhausted}) => recordSafely(
              metrics,
              OperationalSignal.deliveryFailed,
              workflow: 'outbox',
              reasonCode: exhausted ? 'exhausted' : 'retrying',
              at: clock,
            );

      final eventId = await Outbox(
        db,
        now: () => clock,
      ).enqueue('rehearsal.notify', {'marker': 'synthetic'});

      // Detection: the outage is a recorded signal and breaches its threshold.
      expect(await dispatcher.drain(), 0);
      final breaches = evaluateThresholds(metrics.snapshot(), now: clock);
      expect(
        breaches.map((b) => b.threshold.id),
        contains('delivery_failures'),
      );
      final owner = breaches
          .firstWhere((b) => b.threshold.id == 'delivery_failures')
          .threshold
          .owner;
      expect(owner, isNotEmpty);

      // Recovery: provider returns, the retry delivers exactly once.
      providerUp = true;
      clock = clock.add(const Duration(minutes: 1));
      expect(await dispatcher.drain(), 1);
      expect(delivered, [eventId]);
      clock = clock.add(const Duration(minutes: 1));
      expect(await dispatcher.drain(), 0, reason: 'no duplicate delivery');

      // Once the window passes, the breach clears.
      clock = clock.add(const Duration(hours: 2));
      expect(evaluateThresholds(metrics.snapshot(), now: clock), isEmpty);

      // Evidence: export carries signal and tokens, never the payload.
      final evidence = exportOperationalEvents(metrics.snapshot());
      expect(evidence, contains('deliveryFailed'));
      expect(evidence, isNot(contains('synthetic')));
    },
  );

  test('duplicate submission is answered once and recorded', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final metrics = InMemoryOperationalMetrics();
    IdempotencyGuard.onDuplicatePrevented = (scope) => recordSafely(
      metrics,
      OperationalSignal.duplicatePrevented,
      workflow: scope,
    );
    addTearDown(() => IdempotencyGuard.onDuplicatePrevented = null);

    final guard = IdempotencyGuard(db);
    const key = IdempotencyKey('idem-rehearsal');
    expect(
      await guard.prior(key, scope: 'appointment.book', actorAccountId: 'u1'),
      isNull,
    );
    await guard.remember(
      key,
      scope: 'appointment.book',
      actorAccountId: 'u1',
      resultRef: 'appt-1',
    );
    expect(
      await guard.prior(key, scope: 'appointment.book', actorAccountId: 'u1'),
      'appt-1',
    );

    final events = metrics.snapshot();
    expect(events, hasLength(1));
    expect(events.single.signal, OperationalSignal.duplicatePrevented);
    expect(events.single.workflow, 'appointment.book');
  });

  test('throttled signals count a condition once per interval', () {
    final metrics = InMemoryOperationalMetrics();
    final t0 = DateTime(2026, 9, 29, 9);
    for (var i = 0; i < 10; i++) {
      recordThrottled(
        metrics,
        OperationalSignal.staleDataShown,
        workflow: 'rehearsal.view',
        now: t0.add(Duration(seconds: i)),
      );
    }
    recordThrottled(
      metrics,
      OperationalSignal.staleDataShown,
      workflow: 'rehearsal.view',
      now: t0.add(const Duration(minutes: 6)),
    );
    expect(metrics.snapshot(), hasLength(2));
  });
}
