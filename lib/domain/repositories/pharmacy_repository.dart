/// Pharmacy review and dispensing (pharmacist `dispenseMedication`).
///
/// Prescribing and dispensing stay separate: a pharmacist records what was
/// supplied against an existing prescriber-attributed order and never edits
/// the order itself. Stock is tracked per received batch; dispensing from
/// a batch decrements it exactly once, in the same transaction.
library;

import '../../core/result.dart';
import '../enums.dart';

/// One prescription awaiting or having had pharmacy review.
class PharmacyOrder {
  const PharmacyOrder({
    required this.medicationId,
    required this.patientId,
    required this.patientName,
    required this.prescriberName,
    required this.name,
    required this.startDate,
    this.dose,
    this.frequency,
    this.lastOutcome,
    this.lastOutcomeAt,
  });

  final String medicationId;
  final String patientId;
  final String patientName;
  final String prescriberName;
  final String name;
  final String? dose;
  final String? frequency;
  final DateTime startDate;

  /// The most recent recorded pharmacy outcome, if any.
  final DispenseOutcome? lastOutcome;
  final DateTime? lastOutcomeAt;

  /// Fully supplied: no further dispensing is recorded for this order.
  bool get isDispensed => lastOutcome == DispenseOutcome.dispensed;
}

class DispenseInput {
  const DispenseInput({
    required this.medicationId,
    required this.outcome,
    required this.patientVerified,
    required this.idempotencyKey,
    this.quantity,
    this.batch,
    this.expiry,
    this.note,
    this.stockBatchId,
    this.units,
  });

  final String medicationId;
  final DispenseOutcome outcome;

  /// The pharmacist checked the patient's identity against the order.
  final bool patientVerified;
  final String idempotencyKey;

  /// Supplied quantity as written on the label (required when supplying).
  final String? quantity;
  final String? batch;
  final DateTime? expiry;

  /// Reason for a partial supply, hold or clarification request.
  final String? note;

  /// Supply from this recorded stock batch (its batch/expiry are used).
  final String? stockBatchId;

  /// Whole units taken from [stockBatchId].
  final int? units;
}

class StockBatch {
  const StockBatch({
    required this.id,
    required this.itemName,
    required this.batch,
    required this.expiry,
    required this.quantity,
    required this.unit,
    required this.receivedAt,
    this.version = 1,
  });

  final String id;
  final String itemName;
  final String batch;
  final DateTime expiry;
  final int quantity;
  final String unit;
  final DateTime receivedAt;
  final int version;

  bool isExpired(DateTime now) =>
      !expiry.isAfter(DateTime(now.year, now.month, now.day));

  /// Expires within [days] (default 30) but has not expired yet.
  bool expiresSoon(DateTime now, {int days = 30}) =>
      !isExpired(now) && expiry.isBefore(now.add(Duration(days: days)));

  /// Whether this batch can supply an order named [orderName].
  bool matches(String orderName) {
    final a = itemName.toLowerCase().trim();
    final b = orderName.toLowerCase().trim();
    return a.isNotEmpty && (b.contains(a) || a.contains(b));
  }
}

class ReceiveStockInput {
  const ReceiveStockInput({
    required this.itemName,
    required this.batch,
    required this.expiry,
    required this.quantity,
    required this.idempotencyKey,
    this.unit = 'units',
  });

  final String itemName;
  final String batch;
  final DateTime expiry;
  final int quantity;
  final String unit;
  final String idempotencyKey;
}

abstract interface class PharmacyRepository {
  /// Active prescriber-attributed orders with their latest pharmacy outcome,
  /// newest first.
  Future<Result<List<PharmacyOrder>>> queue({int limit = 100});

  /// Records one pharmacy outcome. A retry with the same idempotency key
  /// returns the original record; a fully dispensed order is never
  /// dispensed again.
  Future<Result<DateTime>> record(DispenseInput input);

  /// Every recorded batch, soonest expiry first.
  Future<Result<List<StockBatch>>> stock();

  /// Records a received batch. A retry with the same key adds nothing.
  Future<Result<StockBatch>> receive(ReceiveStockInput input);
}
