/// Shared "typed DD/MM/YYYY" date input helpers (redesign v2 patient
/// dashboard: Personal Info + Family Network) — live slash formatting plus
/// validation that the value is a real, non-future date.
library;

import 'package:flutter/services.dart';

/// Auto-inserts '/' after the day and month groups as digits are typed.
class DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

final _dobPattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

/// Null when [text] is empty or a real, non-future DD/MM/YYYY date;
/// otherwise a short error message.
String? validateTypedDob(String text) {
  if (text.isEmpty) return null;
  final match = _dobPattern.firstMatch(text);
  if (match == null) return 'Use DD/MM/YYYY';
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return 'Enter a real date';
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return 'Enter a real date';
  }
  if (date.isAfter(DateTime.now())) return "Can't be in the future";
  return null;
}

/// Parses a valid DD/MM/YYYY string, or null if it doesn't match.
DateTime? parseTypedDob(String text) {
  final match = _dobPattern.firstMatch(text);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
  );
}

String formatTypedDob(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
