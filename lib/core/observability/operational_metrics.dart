/// Privacy-safe operational signals for the synthetic-data prototype.
///
/// Events carry an allowlisted signal, a timestamp and optional short
/// tokens — never notes, messages, document contents, credentials or names.
library;

import 'dart:convert';

enum OperationalSignal {
  sessionStarted,
  sessionEndedCleanly,
  appCrash,
  saveFailed,
  duplicatePrevented,
  deliveryFailed,
  staleDataShown,
  followUpOverdue,
  reconciliationPending,
  workResolved,
}

class OperationalEvent {
  OperationalEvent({
    required this.signal,
    required this.at,
    this.workflow,
    this.reasonCode,
    this.durationMs,
    this.count = 1,
  }) {
    _validateToken(workflow, 'workflow');
    _validateToken(reasonCode, 'reasonCode');
    if (durationMs != null && durationMs! < 0) {
      throw ArgumentError.value(durationMs, 'durationMs');
    }
    if (count < 1) throw ArgumentError.value(count, 'count');
  }

  final OperationalSignal signal;
  final DateTime at;
  final String? workflow;
  final String? reasonCode;
  final int? durationMs;
  final int count;

  static final _safeToken = RegExp(r'^[a-z0-9_.-]{1,48}$');

  static void _validateToken(String? value, String field) {
    if (value != null && !_safeToken.hasMatch(value)) {
      throw ArgumentError(
        '$field must be a short allowlisted token, never free text or patient data.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'signal': signal.name,
    'at': at.toUtc().toIso8601String(),
    if (workflow != null) 'workflow': workflow,
    if (reasonCode != null) 'reasonCode': reasonCode,
    if (durationMs != null) 'durationMs': durationMs,
    'count': count,
  };
}

abstract interface class OperationalMetrics {
  void record(OperationalEvent event);
  List<OperationalEvent> snapshot();
}

/// Keeps the most recent [maxEvents] so a crash loop cannot grow memory
/// without bound.
class InMemoryOperationalMetrics implements OperationalMetrics {
  InMemoryOperationalMetrics({this.maxEvents = 1000});

  final int maxEvents;
  final List<OperationalEvent> _events = [];

  @override
  void record(OperationalEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeRange(0, _events.length - maxEvents);
    }
  }

  @override
  List<OperationalEvent> snapshot() => List.unmodifiable(_events);
}

/// Records without ever failing the caller: instrumentation must not turn a
/// handled failure into a crash.
void recordSafely(
  OperationalMetrics metrics,
  OperationalSignal signal, {
  String? workflow,
  String? reasonCode,
  int count = 1,
  DateTime? at,
}) {
  try {
    metrics.record(
      OperationalEvent(
        signal: signal,
        at: at ?? DateTime.now(),
        workflow: workflow,
        reasonCode: reasonCode,
        count: count,
      ),
    );
  } on Object {
    // Dropped: an invalid token is a programming error, not a user failure.
  }
}

final _lastRecorded = <String, DateTime>{};

/// [recordSafely] at most once per [every] for the same signal and workflow —
/// for conditions noticed on rebuild (stale views, overdue queues), so one
/// condition is not counted once per frame.
void recordThrottled(
  OperationalMetrics metrics,
  OperationalSignal signal, {
  required String workflow,
  int count = 1,
  Duration every = const Duration(minutes: 5),
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final key = '${signal.name}/$workflow';
  final last = _lastRecorded[key];
  if (last != null && at.difference(last) < every) return;
  _lastRecorded[key] = at;
  recordSafely(metrics, signal, workflow: workflow, count: count, at: at);
}

/// Evidence export for rehearsals and pilot review. Contains only the
/// allowlisted fields of [OperationalEvent].
String exportOperationalEvents(List<OperationalEvent> events) =>
    const JsonEncoder.withIndent(
      '  ',
    ).convert([for (final e in events) e.toJson()]);

/// Share of sessions in [events] with no crash, or null when no session was
/// recorded (no denominator — do not report 100%).
double? crashFreeSessionRate(List<OperationalEvent> events) {
  var sessions = 0;
  var crashes = 0;
  for (final e in events) {
    if (e.signal == OperationalSignal.sessionStarted) sessions += e.count;
    if (e.signal == OperationalSignal.appCrash) crashes += e.count;
  }
  if (sessions == 0) return null;
  final crashed = crashes > sessions ? sessions : crashes;
  return (sessions - crashed) / sessions;
}

enum ThresholdDirection { atLeast, atMost }

class ServiceThreshold {
  const ServiceThreshold({
    required this.id,
    required this.signal,
    required this.direction,
    required this.value,
    required this.window,
    required this.owner,
    required this.response,
  });

  final String id;
  final OperationalSignal signal;
  final ThresholdDirection direction;
  final double value;
  final Duration window;
  final String owner;
  final String response;
}

class ThresholdBreach {
  const ThresholdBreach(this.threshold, this.observed);

  final ServiceThreshold threshold;
  final int observed;
}

/// Every threshold whose signal total inside its window (ending at [now])
/// is outside the allowed value.
List<ThresholdBreach> evaluateThresholds(
  List<OperationalEvent> events, {
  required DateTime now,
  List<ServiceThreshold> thresholds = prototypeServiceThresholds,
}) {
  final breaches = <ThresholdBreach>[];
  for (final threshold in thresholds) {
    final since = now.subtract(threshold.window);
    var observed = 0;
    for (final e in events) {
      if (e.signal == threshold.signal &&
          e.at.isAfter(since) &&
          !e.at.isAfter(now)) {
        observed += e.count;
      }
    }
    final breached = switch (threshold.direction) {
      ThresholdDirection.atMost => observed > threshold.value,
      ThresholdDirection.atLeast => observed < threshold.value,
    };
    if (breached) breaches.add(ThresholdBreach(threshold, observed));
  }
  return breaches;
}

/// Thresholds only for signals the app actually records. Stale-data and
/// overdue follow-up thresholds are deferred until a usability baseline
/// exists (see docs/phase9_release_readiness.md).
const prototypeServiceThresholds = <ServiceThreshold>[
  ServiceThreshold(
    id: 'app_crashes',
    signal: OperationalSignal.appCrash,
    direction: ThresholdDirection.atMost,
    value: 0,
    window: Duration(days: 1),
    owner: 'Workspace owner',
    response: 'Stop the demonstration, preserve diagnostics, and rollback.',
  ),
  ServiceThreshold(
    id: 'payment_uncertain',
    signal: OperationalSignal.reconciliationPending,
    direction: ThresholdDirection.atMost,
    value: 0,
    window: Duration(days: 1),
    owner: 'Workspace owner',
    response: 'Reconcile the payment before telling anyone it succeeded.',
  ),
  ServiceThreshold(
    id: 'failed_saves',
    signal: OperationalSignal.saveFailed,
    direction: ThresholdDirection.atMost,
    value: 0,
    window: Duration(hours: 1),
    owner: 'Workspace owner',
    response:
        'Keep the draft, show recovery, and investigate before continuing.',
  ),
  ServiceThreshold(
    id: 'delivery_failures',
    signal: OperationalSignal.deliveryFailed,
    direction: ThresholdDirection.atMost,
    value: 0,
    window: Duration(hours: 1),
    owner: 'Clinic operations reviewer',
    response: 'Retry the outbox and inspect undelivered work.',
  ),
];
