/// Billing state for the signed-in patient: their invoices and paying one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../auth/application/session.dart';

/// Every invoice raised against the signed-in patient, newest first.
final patientInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) return const [];
  final result = await ref.watch(billingRepositoryProvider).forPatient(user.id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// What the patient still owes, and how much of it is past its due date.
typedef BillingSummary = ({double outstanding, double overdue, int openCount});

final billingSummaryProvider = Provider<AsyncValue<BillingSummary>>((ref) {
  return ref
      .watch(patientInvoicesProvider)
      .whenData(
        (invoices) => (
          outstanding: invoices
              .where((i) => i.isOutstanding)
              .fold(0.0, (sum, i) => sum + i.totalAmount),
          overdue: invoices
              .where((i) => i.isOverdue)
              .fold(0.0, (sum, i) => sum + i.totalAmount),
          openCount: invoices.where((i) => i.isOutstanding).length,
        ),
      );
});

/// The patient's saved cards.
final walletCardsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) return const [];
  final result = await ref.watch(billingRepositoryProvider).cardsFor(user.id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// The patient's current wallet balance.
final walletBalanceProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) return 0;
  final result = await ref
      .watch(billingRepositoryProvider)
      .walletBalance(user.id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

class BillingController {
  BillingController(this._ref);
  final Ref _ref;

  String? get _patientId {
    final user = _ref.read(currentUserProvider);
    return (user != null && user.isPatient) ? user.id : null;
  }

  Future<Result<PaymentMethod>> addCard(CardPayment card) async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in to save a card.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .addCard(patientId: id, card: card);
    if (result case Ok()) _ref.invalidate(walletCardsProvider);
    return result;
  }

  Future<Result<void>> removeCard(String cardId) async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .removeCard(id: cardId, patientId: id);
    if (result case Ok()) _ref.invalidate(walletCardsProvider);
    return result;
  }

  Future<Result<void>> setDefaultCard(String cardId) async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .setDefaultCard(id: cardId, patientId: id);
    if (result case Ok()) _ref.invalidate(walletCardsProvider);
    return result;
  }

  /// Settles [invoiceId] for the signed-in patient. Scoped to their own id, so
  /// a tampered invoice id cannot pay (or reveal) someone else's bill.
  Future<Result<Invoice>> pay(
    String invoiceId,
    CardPayment payment, {
    IdempotencyKey? key,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isPatient) {
      return const Err(AuthFailure('Sign in to pay an invoice.'));
    }
    final result = await _ref
        .read(billingRepositoryProvider)
        .pay(
          invoiceId: invoiceId,
          patientId: user.id,
          payment: payment,
          idempotencyKey: key,
        );
    _afterPayment();
    return result;
  }

  /// Settles [invoiceId] with one of the patient's saved cards.
  Future<Result<Invoice>> payWithSavedCard({
    required String invoiceId,
    required String cardId,
    required String cvc,
    IdempotencyKey? key,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isPatient) {
      return const Err(AuthFailure('Sign in to pay an invoice.'));
    }
    final result = await _ref
        .read(billingRepositoryProvider)
        .payWithSavedCard(
          invoiceId: invoiceId,
          patientId: user.id,
          cardId: cardId,
          cvc: cvc,
          idempotencyKey: key,
        );
    _afterPayment();
    return result;
  }

  /// Tops up the signed-in patient's wallet with a new card.
  Future<Result<double>> topUpWallet(
    double amount,
    CardPayment card, {
    IdempotencyKey? key,
  }) async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in to top up.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .topUpWallet(
          patientId: id,
          amount: amount,
          card: card,
          idempotencyKey: key,
        );
    _afterPayment();
    return result;
  }

  /// Tops up the signed-in patient's wallet with one of their saved cards.
  Future<Result<double>> topUpWalletWithSavedCard({
    required double amount,
    required String cardId,
    required String cvc,
    IdempotencyKey? key,
  }) async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in to top up.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .topUpWalletWithSavedCard(
          patientId: id,
          amount: amount,
          cardId: cardId,
          cvc: cvc,
          idempotencyKey: key,
        );
    _afterPayment();
    return result;
  }

  /// Settles [invoiceId] from the signed-in patient's wallet balance.
  Future<Result<Invoice>> payWithWallet(
    String invoiceId, {
    IdempotencyKey? key,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isPatient) {
      return const Err(AuthFailure('Sign in to pay an invoice.'));
    }
    final result = await _ref
        .read(billingRepositoryProvider)
        .payWithWallet(
          invoiceId: invoiceId,
          patientId: user.id,
          idempotencyKey: key,
        );
    _afterPayment();
    return result;
  }

  /// Whatever happened — paid, declined or still being confirmed — the
  /// screens re-read the authoritative state rather than assume.
  void _afterPayment() {
    _ref
      ..invalidate(patientInvoicesProvider)
      ..invalidate(walletBalanceProvider)
      ..invalidate(patientPaymentsProvider);
  }

  /// Ask the provider about payments whose outcome is unknown. Never charges.
  Future<Result<int>> reconcile() async {
    final id = _patientId;
    if (id == null) return const Err(AuthFailure('Sign in first.'));
    final result = await _ref
        .read(billingRepositoryProvider)
        .reconcile(patientId: id);
    _afterPayment();
    return result;
  }

  /// The newest payment attempt for [invoiceId], after reconciling.
  Future<Result<PaymentTransaction?>> latestAttempt(String invoiceId) async {
    await reconcile();
    final result = await _ref
        .read(billingRepositoryProvider)
        .transactions(invoiceId: invoiceId);
    return switch (result) {
      Ok(:final value) => Ok(
        value.where((t) => t.kind == PaymentKind.invoiceCharge).firstOrNull,
      ),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Every payment, top-up and refund for the signed-in patient, newest first.
/// Reconciles first, so a payment interrupted last session shows its real
/// outcome.
final patientPaymentsProvider = FutureProvider<List<PaymentTransaction>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isPatient) return const [];
  final repo = ref.watch(billingRepositoryProvider);
  await repo.reconcile(patientId: user.id);
  final result = await repo.transactions(patientId: user.id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Invoice ids with a card payment still being confirmed.
final invoicesAwaitingConfirmationProvider = Provider<Set<String>>((ref) {
  final payments = ref.watch(patientPaymentsProvider).valueOrNull ?? const [];
  return {
    for (final p in payments)
      if (p.isInFlight && p.kind == PaymentKind.invoiceCharge) ?p.invoiceId,
  };
});

/// True while payments go to the simulated provider.
final paymentsSimulatedProvider = Provider<bool>(
  (ref) => ref.watch(billingRepositoryProvider).paymentsAreSimulated,
);

final billingControllerProvider = Provider<BillingController>(
  BillingController.new,
);
