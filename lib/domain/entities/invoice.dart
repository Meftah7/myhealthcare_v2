/// A patient bill: what was charged, what tax applied, and whether it's paid.
///
/// Issued by an admin against a patient (optionally against one appointment);
/// the patient sees it in Billing and settles it there.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'invoice.freezed.dart';

@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String patientId,
    required double subtotal,

    /// Percent, e.g. `10` for 10%.
    required double taxRate,
    required double taxAmount,
    required double totalAmount,
    required InvoiceStatus status,
    required DateTime issuedAt,
    String? appointmentId,
    DateTime? dueDate,
    DateTime? paidAt,

    /// Masked descriptor only — never a full card number (e.g. "Card ····4242").
    String? paymentMethod,
    String? notes,
  }) = _Invoice;

  const Invoice._();

  /// Past its due date and still unpaid. Derived, never stored.
  bool get isOverdue {
    if (status != InvoiceStatus.pending) return false;
    final due = dueDate;
    return due != null && due.isBefore(DateTime.now());
  }

  /// Only an open bill can be settled — a paid or cancelled one cannot.
  bool get isPayable => status == InvoiceStatus.pending;

  /// Counts toward the patient's outstanding balance.
  bool get isOutstanding => status == InvoiceStatus.pending;
}
