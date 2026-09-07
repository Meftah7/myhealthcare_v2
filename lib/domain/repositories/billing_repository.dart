/// Billing contract: a patient's invoices and settling them.
library;

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

  /// Admin sets an invoice's status directly (no card). Moving to
  /// [InvoiceStatus.paid] stamps `paidAt`; moving away from it clears it.
  Future<Result<Invoice>> setStatus({
    required String id,
    required InvoiceStatus status,
  });

  /// Settles [invoiceId] with [payment].
  ///
  /// [patientId] is the *session's* patient. The invoice is only paid if it
  /// belongs to them and is still open — a mismatch fails rather than paying
  /// someone else's bill.
  Future<Result<Invoice>> pay({
    required String invoiceId,
    required String patientId,
    required CardPayment payment,
  });

  /// Raises a new bill (admin/staff side).
  Future<Result<Invoice>> issue(NewInvoice invoice);

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
}
