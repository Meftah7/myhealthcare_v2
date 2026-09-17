// Locale-aware formatting helpers, in particular Arabic-Indic digit output.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:myhealthcare/core/utils/format.dart';

void main() {
  final original = Intl.defaultLocale;

  tearDown(() => Intl.defaultLocale = original);

  group('localizeDigits', () {
    test('leaves Western digits alone outside Arabic locale', () {
      Intl.defaultLocale = 'en';
      expect(localizeDigits('5m'), '5m');
    });

    test('swaps Western digits for Eastern Arabic-Indic under ar', () {
      Intl.defaultLocale = 'ar';
      expect(localizeDigits('5m'), '٥m');
      expect(localizeDigits('2026'), '٢٠٢٦');
      expect(localizeDigits('no digits here'), 'no digits here');
    });
  });

  group('fmtTimeAgo', () {
    test('renders Arabic-Indic digits under the ar locale', () {
      Intl.defaultLocale = 'ar';
      final now = DateTime(2026, 1, 1, 12);
      expect(
        fmtTimeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '٥ د',
      );
      expect(
        fmtTimeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '٣ س',
      );
    });

    test('renders Western digits under the en locale', () {
      Intl.defaultLocale = 'en';
      final now = DateTime(2026, 1, 1, 12);
      expect(
        fmtTimeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m',
      );
    });
  });
}
