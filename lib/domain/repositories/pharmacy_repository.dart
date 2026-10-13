/// Pharmacy review and dispensing (pharmacist `dispenseMedication`).
///
/// Prescribing and dispensing stay separate: a pharmacist records what was
/// supplied against an existing prescriber-attributed order and never edits
/// the order itself. Stock management is out of scope (Future work).
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
}

abstract interface class PharmacyRepository {
  /// Active prescriber-attributed orders with their latest pharmacy outcome,
  /// newest first.
  Future<Result<List<PharmacyOrder>>> queue({int limit = 100});

  /// Records one pharmacy outcome. A retry with the same idempotency key
  /// returns the original record; a fully dispensed order is never
  /// dispensed again.
  Future<Result<DateTime>> record(DispenseInput input);
}
