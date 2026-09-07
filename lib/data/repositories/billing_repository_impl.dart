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
  Future<Result<List<Invoice>>> all({InvoiceStatus? status}) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.invoices)
        ..orderBy([(i) => OrderingTerm.desc(i.issuedAt)]);
      if (status != null) q.where((i) => i.status.equalsValue(status));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Invoice>> setStatus({
    required String id,
    required InvoiceStatus status,
  }) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Invoice not found.');
      await (_db.update(_db.invoices)..where((i) => i.id.equals(id))).write(
        InvoicesCompanion(
          status: Value(status),
          paidAt: Value(
            status == InvoiceStatus.paid ? DateTime.now() : null,
          ),
        ),
      );
      final updated = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(id))).getSingle();
      return updated.toEntity();
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

  @override
  Future<Result<List<PaymentMethod>>> cardsFor(String patientId) {
    return Result.guardAsync(() async {
      final rows =
          await (_db.select(_db.paymentMethods)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([
                  (c) => OrderingTerm.desc(c.isDefault),
                  (c) => OrderingTerm.desc(c.addedAt),
                ]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<PaymentMethod>> addCard({
    required String patientId,
    required CardPayment card,
  }) {
    return Result.guardAsync(() async {
      _validateCard(card);
      final existing = await (_db.select(
        _db.paymentMethods,
      )..where((c) => c.patientId.equals(patientId))).get();

      // Don't save the same card twice.
      if (existing.any(
        (c) =>
            c.last4 == card.last4 &&
            c.expiryMonth == card.expiryMonth &&
            c.expiryYear == card.expiryYear,
      )) {
        throw const ValidationFailure('That card is already saved.');
      }

      final id = newId('card');
      await _db
          .into(_db.paymentMethods)
          .insert(
            PaymentMethodsCompanion.insert(
              id: id,
              patientId: patientId,
              brand: card.brand,
              last4: card.last4,
              expiryMonth: card.expiryMonth,
              expiryYear: card.expiryYear,
              holderName: card.cardHolder.trim(),
              isDefault: Value(existing.isEmpty),
            ),
          );
      final row = await (_db.select(
        _db.paymentMethods,
      )..where((c) => c.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> removeCard({
    required String id,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      await (_db.delete(_db.paymentMethods)..where(
            (c) => c.id.equals(id) & c.patientId.equals(patientId),
          ))
          .go();
      // If we removed the default, promote the newest remaining card.
      final left =
          await (_db.select(_db.paymentMethods)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([(c) => OrderingTerm.desc(c.addedAt)]))
              .get();
      if (left.isNotEmpty && !left.any((c) => c.isDefault)) {
        await (_db.update(_db.paymentMethods)
              ..where((c) => c.id.equals(left.first.id)))
            .write(const PaymentMethodsCompanion(isDefault: Value(true)));
      }
    });
  }

  @override
  Future<Result<void>> setDefaultCard({
    required String id,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      await (_db.update(_db.paymentMethods)
            ..where((c) => c.patientId.equals(patientId)))
          .write(const PaymentMethodsCompanion(isDefault: Value(false)));
      await (_db.update(_db.paymentMethods)..where(
            (c) => c.id.equals(id) & c.patientId.equals(patientId),
          ))
          .write(const PaymentMethodsCompanion(isDefault: Value(true)));
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
