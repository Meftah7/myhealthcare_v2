/// The card-payment provider boundary (Phase 5).
///
/// The billing repository never decides on its own that money moved: it asks
/// a [PaymentGateway] and records what the provider says. Every call carries
/// the app's request reference, which the provider treats as an idempotency
/// key — asking twice with the same reference returns the first outcome
/// instead of charging again. [lookup] lets reconciliation ask "did you ever
/// receive this?" after the app crashed or lost the response.
///
/// Scope: this prototype ships only [SimulatedPaymentGateway]. No card data
/// leaves the device and no real money moves; the UI says so.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';

/// What the provider did with a request.
enum GatewayStatus { captured, declined, refunded }

class GatewayOutcome {
  const GatewayOutcome({
    required this.status,
    required this.providerReference,
    this.declineCode,
  });

  final GatewayStatus status;
  final String providerReference;

  /// Provider decline code (`card_declined`, `insufficient_funds`…).
  final String? declineCode;

  bool get succeeded => status != GatewayStatus.declined;
}

/// What the app hands the provider. Never a stored PAN: a new card passes its
/// digits straight through for this one request; a saved card is a token.
class GatewayCard {
  const GatewayCard({required this.last4, this.digits, this.token});

  final String last4;

  /// Full number, only for a card typed in for this payment. Not persisted.
  final String? digits;

  /// Saved-card token (the wallet card id).
  final String? token;
}

/// The provider could not be reached, or its answer was lost. The outcome is
/// unknown: the charge may or may not have happened. Callers must reconcile,
/// never assume either way.
class GatewayUnavailable implements Exception {
  const GatewayUnavailable([this.message = 'Payment provider unreachable']);
  final String message;
  @override
  String toString() => 'GatewayUnavailable($message)';
}

abstract interface class PaymentGateway {
  /// Short provider name stored on each transaction.
  String get providerName;

  /// True when no real money moves. Shown to the user.
  bool get isSimulated;

  /// Authorize and capture [amountFils]. Idempotent on [reference].
  /// Throws [GatewayUnavailable] when the outcome is unknown.
  Future<GatewayOutcome> charge({
    required String reference,
    required int amountFils,
    required GatewayCard card,
  });

  /// Return [amountFils] of an earlier capture. Idempotent on [reference].
  Future<GatewayOutcome> refund({
    required String reference,
    required String chargeProviderReference,
    required int amountFils,
  });

  /// What the provider recorded for [reference], or null if it never
  /// received that request.
  Future<GatewayOutcome?> lookup(String reference);
}

/// Faults a test (or a demo of failure handling) can inject.
enum SimulatedFault {
  /// The request never reaches the provider.
  unreachable,

  /// The provider captures the charge but the response is lost.
  responseLost,
}

/// A local stand-in for a card provider. Its ledger lives in
/// `simulated_gateway_charges`, playing the part of the provider's own
/// records, so an interrupted payment can be reconciled after a restart.
///
/// Test card numbers (Stripe-style): `4000 0000 0000 0002` is declined,
/// `4000 0000 0000 9995` has insufficient funds. Every other Luhn-valid
/// number is captured.
class SimulatedPaymentGateway implements PaymentGateway {
  SimulatedPaymentGateway(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Faults to apply to the next calls, consumed in order.
  final List<SimulatedFault> pendingFaults = [];

  static const declinedCard = '4000000000000002';
  static const insufficientFundsCard = '4000000000009995';

  @override
  String get providerName => 'simulated-card';

  @override
  bool get isSimulated => true;

  SimulatedFault? _nextFault() =>
      pendingFaults.isEmpty ? null : pendingFaults.removeAt(0);

  @override
  Future<GatewayOutcome> charge({
    required String reference,
    required int amountFils,
    required GatewayCard card,
  }) async {
    final fault = _nextFault();
    if (fault == SimulatedFault.unreachable) throw const GatewayUnavailable();
    final existing = await lookup(reference);
    if (existing != null) {
      if (fault == SimulatedFault.responseLost) {
        throw const GatewayUnavailable('Response lost');
      }
      return existing;
    }
    final decline = switch (card.digits) {
      declinedCard => 'card_declined',
      insufficientFundsCard => 'insufficient_funds',
      _ => null,
    };
    final outcome = GatewayOutcome(
      status: decline == null ? GatewayStatus.captured : GatewayStatus.declined,
      providerReference: newId('sim_ch'),
      declineCode: decline,
    );
    await _record(reference, 'charge', outcome, amountFils);
    if (fault == SimulatedFault.responseLost) {
      throw const GatewayUnavailable('Response lost');
    }
    return outcome;
  }

  @override
  Future<GatewayOutcome> refund({
    required String reference,
    required String chargeProviderReference,
    required int amountFils,
  }) async {
    final fault = _nextFault();
    if (fault == SimulatedFault.unreachable) throw const GatewayUnavailable();
    final existing = await lookup(reference);
    if (existing != null) return existing;

    final charge =
        await (_db.select(_db.simulatedGatewayCharges)..where(
              (c) =>
                  c.providerReference.equals(chargeProviderReference) &
                  c.operation.equals('charge') &
                  c.status.equals('captured'),
            ))
            .getSingleOrNull();
    final refunded = await _refundedFils(chargeProviderReference);
    final ok = charge != null && refunded + amountFils <= charge.amountFils;
    final outcome = GatewayOutcome(
      status: ok ? GatewayStatus.refunded : GatewayStatus.declined,
      providerReference: newId('sim_re'),
      declineCode: ok ? null : 'refund_exceeds_charge',
    );
    await _record(
      reference,
      'refund',
      outcome,
      amountFils,
      parent: chargeProviderReference,
    );
    if (fault == SimulatedFault.responseLost) {
      throw const GatewayUnavailable('Response lost');
    }
    return outcome;
  }

  @override
  Future<GatewayOutcome?> lookup(String reference) async {
    final row = await (_db.select(
      _db.simulatedGatewayCharges,
    )..where((c) => c.reference.equals(reference))).getSingleOrNull();
    if (row == null) return null;
    return GatewayOutcome(
      status: GatewayStatus.values.byName(row.status),
      providerReference: row.providerReference,
      declineCode: row.declineCode,
    );
  }

  Future<int> _refundedFils(String chargeProviderReference) async {
    final rows =
        await (_db.select(_db.simulatedGatewayCharges)..where(
              (c) =>
                  c.parentProviderReference.equals(chargeProviderReference) &
                  c.status.equals('refunded'),
            ))
            .get();
    return rows.fold<int>(0, (sum, r) => sum + r.amountFils);
  }

  Future<void> _record(
    String reference,
    String operation,
    GatewayOutcome outcome,
    int amountFils, {
    String? parent,
  }) {
    return _db
        .into(_db.simulatedGatewayCharges)
        .insert(
          SimulatedGatewayChargesCompanion.insert(
            reference: reference,
            providerReference: outcome.providerReference,
            operation: operation,
            status: outcome.status.name,
            amountFils: amountFils,
            declineCode: Value(outcome.declineCode),
            parentProviderReference: Value(parent),
            createdAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
