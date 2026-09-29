/// Billing contract: a patient's invoices and settling them.
library;

import '../../core/data/contracts.dart';
import '../../core/result.dart';
import '../entities/entities.dart';
import '../enums.dart';

/// The card details a patient enters to settle an invoice.
///
/// This is a demo payment path: nothing here is persisted beyond a masked
/// descriptor ("Card ····4242"). No PAN, expiry or CVC is ever written to the
/// database, and no card data leaves the device.
class CardPayment {
  const CardPayment({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvc,
  });

  final String cardNumber;
  final String cardHolder;
  final int expiryMonth;
  final int expiryYear;
  final String cvc;

  /// Digits only, for validation and masking.
  String get digits => cardNumber.replaceAll(RegExp(r'\D'), '');

  String get last4 {
    final d = digits;
    return d.length >= 4 ? d.substring(d.length - 4) : d;
  }

  String get maskedDescriptor => 'Card ····$last4';

  /// Best-effort network from the leading digits.
  String get brand {
    final d = digits;
    if (d.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(d)) return 'Amex';
    if (d.startsWith('6')) return 'Discover';
    return 'Card';
  }
}

class NewInvoice {
  const NewInvoice({
    required this.patientId,
    required this.subtotal,
    this.taxRate = 10,
    this.appointmentId,
    this.dueDate,
    this.notes,
  });

  final String patientId;
  final double subtotal;
  final double taxRate;
  final String? appointmentId;
  final DateTime? dueDate;
  final String? notes;
}

abstract interface class BillingRepository {
  /// A patient's invoices, newest issue date first.
  Future<Result<List<Invoice>>> forPatient(String patientId);

  /// Every invoice across all patients — the admin billing overview. Optionally
  /// filtered to one [status].
  Future<Result<List<Invoice>>> all({InvoiceStatus? status});

  Future<Result<Invoice>> byId(String id);

  /// Admin cancels an open invoice. An invoice is never marked paid by a
  /// status change — only by a settled payment ([recordOfflinePayment] for
  /// money taken at the desk). Cancelling is refused while a card payment
  /// for it is still being confirmed.
  Future<Result<Invoice>> setStatus({
    required String id,
    required InvoiceStatus status,
    int? expectedVersion,
  });

  // --- payment ledger (Phase 5) -------------------------------------------

  /// True while payments go to the simulated provider — the UI says no real
  /// money moves.
  bool get paymentsAreSimulated;

  /// Payment history, newest first: every charge, top-up and refund for one
  /// invoice, or for one patient. Admins may read any; a patient (or proxy)
  /// only their own.
  Future<Result<List<PaymentTransaction>>> transactions({
    String? invoiceId,
    String? patientId,
  });

  /// Resolves payments whose outcome is not yet known by asking the provider
  /// what it recorded — after a crash, closed tab or lost response. A charge
  /// the provider captured settles its invoice; one it never received is
  /// released so the patient can try again. Never charges. Scoped to
  /// [patientId] for a patient; everything for an admin. Returns how many
  /// were resolved.
  Future<Result<int>> reconcile({String? patientId});

  /// Records money taken outside the app (cash or card at the desk) against
  /// an open invoice. The receipt reference is required.
  Future<Result<Invoice>> recordOfflinePayment({
    required String invoiceId,
    required String receiptReference,
    String? note,
    IdempotencyKey? idempotencyKey,
  });

  /// Returns [amount] of a settled invoice charge to where it came from
  /// (card, wallet, or at the desk). Needs the refund permission and a
  /// reason; never more than is left unrefunded. A full refund marks the
  /// invoice refunded.
  Future<Result<PaymentTransaction>> refund({
    required String transactionId,
    required double amount,
    required String reason,
    IdempotencyKey? idempotencyKey,
  });

  // Every money movement below takes an [IdempotencyKey]. Reuse it for
  // every retry of the same payment: a retry after a lost response returns
  // the committed result instead of charging again. A card payment whose
  // outcome is unknown fails with `PaymentPendingFailure` — never "paid".

  /// Settles [invoiceId] with [payment].
  ///
  /// [patientId] is the *session's* patient. The invoice is only paid if it
  /// belongs to them and is still open — a mismatch fails rather than paying
  /// someone else's bill.
  Future<Result<Invoice>> pay({
    required String invoiceId,
    required String patientId,
    required CardPayment payment,
    IdempotencyKey? idempotencyKey,
  });

  /// Settles [invoiceId] with a card already saved to the patient's wallet.
  ///
  /// The PAN was Luhn-checked when the card was added, so this only re-checks
  /// the card belongs to [patientId], is not expired, and the CVC is the right
  /// shape. Like [pay], the invoice must be the patient's own and still open.
  Future<Result<Invoice>> payWithSavedCard({
    required String invoiceId,
    required String patientId,
    required String cardId,
    required String cvc,
    IdempotencyKey? idempotencyKey,
  });

  /// Raises a new bill (admin/staff side).
  Future<Result<Invoice>> issue(
    NewInvoice invoice, {
    IdempotencyKey? idempotencyKey,
  });

  // --- wallet: saved cards ------------------------------------------------

  Future<Result<List<PaymentMethod>>> cardsFor(String patientId);

  /// Saves [card] to [patientId]'s wallet (masked descriptor only). The first
  /// card added becomes the default.
  Future<Result<PaymentMethod>> addCard({
    required String patientId,
    required CardPayment card,
  });

  Future<Result<void>> removeCard({
    required String id,
    required String patientId,
  });

  Future<Result<void>> setDefaultCard({
    required String id,
    required String patientId,
  });

  // --- wallet: credit balance ----------------------------------------------

  /// The patient's current wallet balance — the sum of their wallet ledger.
  Future<Result<double>> walletBalance(String patientId);

  /// Adds [amount] to [patientId]'s wallet balance, charged to a new card.
  Future<Result<double>> topUpWallet({
    required String patientId,
    required double amount,
    required CardPayment card,
    IdempotencyKey? idempotencyKey,
  });

  /// Adds [amount] to [patientId]'s wallet balance, charged to a saved card.
  Future<Result<double>> topUpWalletWithSavedCard({
    required String patientId,
    required double amount,
    required String cardId,
    required String cvc,
    IdempotencyKey? idempotencyKey,
  });

  /// Settles [invoiceId] entirely from [patientId]'s wallet balance. Fails if
  /// the balance can't cover the full amount.
  Future<Result<Invoice>> payWithWallet({
    required String invoiceId,
    required String patientId,
    IdempotencyKey? idempotencyKey,
  });
}
