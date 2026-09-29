import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/observability/operational_metrics.dart';

void main() {
  test('operational events accept only bounded non-clinical tokens', () {
    expect(
      () => OperationalEvent(
        signal: OperationalSignal.saveFailed,
        at: DateTime(2026, 9, 29),
        workflow: 'booking.confirm',
        reasonCode: 'conflict',
      ),
      returnsNormally,
    );
    expect(
      () => OperationalEvent(
        signal: OperationalSignal.saveFailed,
        at: DateTime(2026, 9, 29),
        reasonCode: 'Patient said chest pain in a private note',
      ),
      throwsArgumentError,
    );
  });

  test('metrics snapshot is immutable', () {
    final metrics = InMemoryOperationalMetrics();
    metrics.record(
      OperationalEvent(
        signal: OperationalSignal.duplicatePrevented,
        at: DateTime(2026, 9, 29),
        workflow: 'booking.confirm',
      ),
    );
    expect(metrics.snapshot(), hasLength(1));
    expect(() => metrics.snapshot().clear(), throwsUnsupportedError);
  });

  test('buffer keeps only the most recent events', () {
    final metrics = InMemoryOperationalMetrics(maxEvents: 3);
    for (var i = 0; i < 5; i++) {
      metrics.record(
        OperationalEvent(
          signal: OperationalSignal.appCrash,
          at: DateTime(2026, 9, 29, 0, i),
        ),
      );
    }
    expect(metrics.snapshot().map((e) => e.at.minute), [2, 3, 4]);
  });

  test('recordSafely drops invalid tokens instead of throwing', () {
    final metrics = InMemoryOperationalMetrics();
    recordSafely(
      metrics,
      OperationalSignal.saveFailed,
      reasonCode: 'Free text with a Name',
    );
    expect(metrics.snapshot(), isEmpty);
  });

  test('export contains only allowlisted fields', () {
    final json = exportOperationalEvents([
      OperationalEvent(
        signal: OperationalSignal.deliveryFailed,
        at: DateTime.utc(2026, 9, 29),
        workflow: 'outbox',
        count: 2,
      ),
    ]);
    expect(json, contains('"signal": "deliveryFailed"'));
    expect(json, contains('"count": 2'));
    expect(json, isNot(contains('reasonCode')));
  });

  test('crash-free rate needs sessions and caps at zero', () {
    final at = DateTime(2026, 9, 29);
    expect(crashFreeSessionRate([]), isNull);
    expect(
      crashFreeSessionRate([
        OperationalEvent(
          signal: OperationalSignal.sessionStarted,
          at: at,
          count: 4,
        ),
        OperationalEvent(signal: OperationalSignal.appCrash, at: at),
      ]),
      0.75,
    );
  });

  test('thresholds breach only inside their window', () {
    final now = DateTime(2026, 9, 29, 12);
    final breaches = evaluateThresholds([
      OperationalEvent(
        signal: OperationalSignal.saveFailed,
        at: now.subtract(const Duration(minutes: 10)),
      ),
      OperationalEvent(
        signal: OperationalSignal.deliveryFailed,
        at: now.subtract(const Duration(hours: 2)),
      ),
    ], now: now);
    expect(breaches.map((b) => b.threshold.id), ['failed_saves']);
    expect(breaches.single.observed, 1);
  });

  test('every prototype threshold has an owner and response', () {
    for (final threshold in prototypeServiceThresholds) {
      expect(threshold.owner.trim(), isNotEmpty, reason: threshold.id);
      expect(threshold.response.trim(), isNotEmpty, reason: threshold.id);
      expect(threshold.window, isNot(Duration.zero), reason: threshold.id);
    }
  });
}
