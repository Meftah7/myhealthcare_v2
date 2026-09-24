/// One entry in a patient's wallet ledger — a top-up or a redemption against
/// an invoice. The wallet balance is the sum of these, never stored directly.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'wallet_transaction.freezed.dart';

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String patientId,
    required WalletTransactionType type,

    /// Always positive — [type] gives the sign.
    required double amount,
    required DateTime createdAt,

    /// Masked card descriptor for a top-up (e.g. "Card ····4242"), null for a
    /// redemption.
    String? method,

    /// The invoice a redemption paid toward, null for a top-up.
    String? invoiceId,
  }) = _WalletTransaction;

  const WalletTransaction._();

  /// Signed amount: positive for a top-up, negative for a redemption — sum
  /// these across a patient's history to get their balance.
  double get signedAmount =>
      type == WalletTransactionType.topUp ? amount : -amount;
}
