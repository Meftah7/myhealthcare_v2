/// Billing contract: a patient's invoices and settling them.
library;

import '../../core/result.dart';
import '../entities/entities.dart';

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

  String get maskedDescriptor {
    final d = digits;
    final last4 = d.length >= 4 ? d.substring(d.length - 4) : d;
    return 'Card ····$last4';
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

  Future<Result<Invoice>> byId(String id);

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
}
