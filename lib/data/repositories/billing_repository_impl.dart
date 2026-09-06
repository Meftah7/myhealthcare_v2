/// Drift-backed [BillingRepository].
library;

import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/billing_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

/// Luhn check — catches typo'd card numbers before we pretend to charge them.
bool passesLuhn(String digits) {
  if (digits.length < 12 || digits.length > 19) return false;
  var sum = 0;
  var double = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    final code = digits.codeUnitAt(i) - 0x30;
    if (code < 0 || code > 9) return false;
    var n = code;
    if (double) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    double = !double;
  }
  return sum % 10 == 0;
}

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<List<Invoice>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.invoices)
                ..where((i) => i.patientId.equals(patientId))
                ..orderBy([(i) => OrderingTerm.desc(i.issuedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Invoice>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Invoice not found.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<Invoice>> pay({
    required String invoiceId,
    required String patientId,
    required CardPayment payment,
  }) {
    return Result.guardAsync(() async {
      _validateCard(payment);

      // Ownership and state are checked together, so another patient's bill
      // is indistinguishable from one that doesn't exist.
      final row =
          await (_db.select(_db.invoices)..where(
                (i) => i.id.equals(invoiceId) & i.patientId.equals(patientId),
              ))
              .getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Invoice not found.');

      final invoice = row.toEntity();
      if (invoice.status == InvoiceStatus.paid) {
        throw const ValidationFailure('This invoice is already paid.');
      }
      if (invoice.status == InvoiceStatus.cancelled) {
        throw const ValidationFailure('This invoice was cancelled.');
      }

      final paidAt = DateTime.now();
      await (_db.update(_db.invoices)..where((i) => i.id.equals(invoiceId)))
          .write(
            InvoicesCompanion(
              status: const Value(InvoiceStatus.paid),
              paidAt: Value(paidAt),
              // Masked descriptor only — never the card number itself.
              paymentMethod: Value(payment.maskedDescriptor),
            ),
          );

      final updated = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(invoiceId))).getSingle();
      return updated.toEntity();
    });
  }

  @override
  Future<Result<Invoice>> issue(NewInvoice invoice) {
    return Result.guardAsync(() async {
      if (invoice.subtotal < 0) {
        throw const ValidationFailure('Amount cannot be negative.');
      }
      final id = newId('inv');
      final taxAmount = invoice.subtotal * (invoice.taxRate / 100);
      await _db
          .into(_db.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: id,
              patientId: invoice.patientId,
              subtotal: Value(invoice.subtotal),
              taxRate: Value(invoice.taxRate),
              taxAmount: Value(taxAmount),
              totalAmount: Value(invoice.subtotal + taxAmount),
              appointmentId: Value(invoice.appointmentId),
              dueDate: Value(invoice.dueDate),
              notes: Value(invoice.notes),
            ),
          );
      final row = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  void _validateCard(CardPayment p) {
    if (p.cardHolder.trim().isEmpty) {
      throw const ValidationFailure('Enter the name on the card.');
    }
    if (!passesLuhn(p.digits)) {
      throw const ValidationFailure('That card number is not valid.');
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(p.cvc)) {
      throw const ValidationFailure('CVC must be 3 or 4 digits.');
    }
    if (p.expiryMonth < 1 || p.expiryMonth > 12) {
      throw const ValidationFailure('Expiry month must be between 1 and 12.');
    }
    // Expiry is end-of-month, so a card expiring this month is still valid.
    final now = DateTime.now();
    final expiresAfter = DateTime(p.expiryYear, p.expiryMonth + 1);
    if (!expiresAfter.isAfter(now)) {
      throw const ValidationFailure('That card has expired.');
    }
  }
}
