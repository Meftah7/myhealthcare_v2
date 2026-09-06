/// A card saved to the patient's wallet.
///
/// Holds only a masked descriptor — the full card number and CVC are never
/// persisted (validated locally, then discarded).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method.freezed.dart';

@freezed
abstract class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    required String id,
    required String patientId,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    required String holderName,
    required DateTime addedAt,
    @Default(false) bool isDefault,
  }) = _PaymentMethod;

  const PaymentMethod._();

  String get masked => 'Card ····$last4';

  String get expiry =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear % 100}';

  bool get isExpired {
    final now = DateTime.now();
    return !DateTime(expiryYear, expiryMonth + 1).isAfter(now);
  }
}
