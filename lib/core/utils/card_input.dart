/// Shared card-entry helpers: live digit grouping, expiry auto-slash, and
/// best-effort brand detection from the leading digits.
///
/// Used by both the "pay an invoice" sheet and the "add a card" sheet so a
/// card is entered the same way everywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The networks the app recognises well enough to name while the patient types.
enum CardBrand { visa, mastercard, amex, discover, unknown }

extension CardBrandX on CardBrand {
  String get label => switch (this) {
    CardBrand.visa => 'Visa',
    CardBrand.mastercard => 'Mastercard',
    CardBrand.amex => 'Amex',
    CardBrand.discover => 'Discover',
    CardBrand.unknown => 'Card',
  };

  /// Digit groups for display — Amex is 4-6-5, everything else 4-4-4-4(-3).
  List<int> get groups => switch (this) {
    CardBrand.amex => const [4, 6, 5],
    _ => const [4, 4, 4, 4, 3],
  };

  int get maxDigits => this == CardBrand.amex ? 15 : 19;

  /// Amex prints a 4-digit CID; everyone else a 3-digit CVC.
  int get cvcLength => this == CardBrand.amex ? 4 : 3;
}

/// Classify a (partial) PAN. Matches on the shortest unambiguous prefix so the
/// brand appears as soon as the patient has typed enough to tell.
CardBrand cardBrandOf(String input) {
  final d = input.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return CardBrand.unknown;
  if (d.startsWith('4')) return CardBrand.visa;
  if (RegExp(r'^(5[1-5]|22[2-9]|2[3-6]|27[01]|2720)').hasMatch(d)) {
    return CardBrand.mastercard;
  }
  if (RegExp(r'^3[47]').hasMatch(d)) return CardBrand.amex;
  if (RegExp(r'^(6011|65|64[4-9]|622)').hasMatch(d)) return CardBrand.discover;
  return CardBrand.unknown;
}

/// The Luhn check digit test — a mistyped number fails this before it ever
/// reaches the repository.
bool luhnValid(String input) {
  final d = input.replaceAll(RegExp(r'\D'), '');
  if (d.length < 12) return false;
  var sum = 0;
  var alt = false;
  for (var i = d.length - 1; i >= 0; i--) {
    var n = d.codeUnitAt(i) - 48;
    if (n < 0 || n > 9) return false;
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

/// Groups the PAN as the patient types — "4242424242424242" shows as
/// "4242 4242 4242 4242" (or "3782 822463 10005" for Amex).
class CardNumberInputFormatter extends TextInputFormatter {
  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final brand = cardBrandOf(digits);
    final capped = digits.length > brand.maxDigits
        ? digits.substring(0, brand.maxDigits)
        : digits;

    final buffer = StringBuffer();
    var i = 0;
    for (final group in brand.groups) {
      if (i >= capped.length) break;
      if (i > 0) buffer.write(' ');
      final end = (i + group).clamp(0, capped.length);
      buffer.write(capped.substring(i, end));
      i = end;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Turns "1225" into "12/25" and keeps the slash in place as the patient edits.
class ExpiryInputFormatter extends TextInputFormatter {
  const ExpiryInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final deleting = newValue.text.length < oldValue.text.length;

    // Backspacing the auto-inserted slash ("12/" → "12") should take the digit
    // with it, so the month can be re-typed.
    if (deleting && oldValue.text == '${newValue.text}/' &&
        !newValue.text.contains('/')) {
      final d = newValue.text.replaceAll(RegExp(r'\D'), '');
      final trimmed = d.isEmpty ? d : d.substring(0, d.length - 1);
      return TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }

    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    // Clamp an impossible month as it is typed ("9" is fine, "93" is not).
    if (digits.length >= 2) {
      final mm = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (mm == 0) {
        digits = '01${digits.substring(2)}';
      } else if (mm > 12) {
        digits = '12${digits.substring(2)}';
      }
    } else if (digits.length == 1 && int.parse(digits) > 1) {
      digits = '0$digits';
    }

    // Reached the month → drop the slash in so the year comes next. Only bare
    // while deleting *within* the year, so a lone digit stays clearable.
    final keepBare = deleting && digits.length == 2 && oldValue.text.length <= 3;
    final text = switch (digits.length) {
      < 2 => digits,
      2 => keepBare ? digits : '$digits/',
      _ => '${digits.substring(0, 2)}/${digits.substring(2)}',
    };
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// `MM/YY` (or `MMYY`) → (month, full year). Null when it can't be a real,
/// not-yet-expired card date.
({int month, int year})? parseExpiry(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length != 4) return null;
  final month = int.tryParse(d.substring(0, 2));
  final year = int.tryParse(d.substring(2));
  if (month == null || year == null) return null;
  if (month < 1 || month > 12) return null;
  return (month: month, year: 2000 + year);
}

/// True when a card with this expiry is still valid through the end of its
/// month (so a card expiring this month still works today).
bool expiryInFuture(int month, int year) {
  final firstOfNextMonth = month == 12
      ? DateTime(year + 1)
      : DateTime(year, month + 1);
  return firstOfNextMonth.isAfter(DateTime.now());
}

/// A small brand chip for a text field's `suffixIcon`.
class CardBrandBadge extends StatelessWidget {
  const CardBrandBadge(this.brand, {super.key});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    if (brand == CardBrand.unknown) {
      return const Icon(Icons.credit_card, size: 20);
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        widthFactor: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            brand.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
