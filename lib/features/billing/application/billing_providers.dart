/// Billing state for the signed-in patient: their invoices and paying one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
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
  Future<Result<Invoice>> pay(String invoiceId, CardPayment payment) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isPatient) {
      return const Err(AuthFailure('Sign in to pay an invoice.'));
    }
    final result = await _ref
        .read(billingRepositoryProvider)
        .pay(invoiceId: invoiceId, patientId: user.id, payment: payment);
    if (result case Ok()) _ref.invalidate(patientInvoicesProvider);
    return result;
  }
}

final billingControllerProvider = Provider<BillingController>(
  BillingController.new,
);
