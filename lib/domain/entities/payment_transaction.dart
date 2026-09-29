/// One attempt to move money: an invoice charge, a wallet top-up or a refund
/// (Phase 5). The invoice's paid state is derived from these, never set by
/// hand.
library;

import 'package:flutter/foundation.dart';

import '../enums.dart';

@immutable
class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.patientId,
    required this.kind,
    required this.method,
    required this.status,
    required this.amount,
    required this.provider,
    required this.requestReference,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceId,
    this.providerReference,
    this.methodDescriptor,
    this.refundOfId,
    this.reason,
    this.failureReason,
    this.actorAccountId,
    this.settledAt,
    this.reconciledAt,
  });

  final String id;
  final String patientId;
  final String? invoiceId;
  final PaymentKind kind;
  final PaymentMethodKind method;
  final PaymentStatus status;

  /// BHD, always positive.
  final double amount;
  final String provider;
  final String requestReference;
  final String? providerReference;
  final String? methodDescriptor;
  final String? refundOfId;
  final String? reason;
  final String? failureReason;
  final String? actorAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? settledAt;
  final DateTime? reconciledAt;

  /// Sent, but the outcome is not known yet.
  bool get isInFlight =>
      status == PaymentStatus.initiated || status == PaymentStatus.authorized;

  bool get isSettled => status == PaymentStatus.settled;
}
