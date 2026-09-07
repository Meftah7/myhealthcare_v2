// Card-entry helpers: digit grouping, expiry auto-slash, brand detection.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/utils/card_input.dart';

TextEditingValue _type(TextInputFormatter f, String previous, String next) {
  return f.formatEditUpdate(
    TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    ),
    TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    ),
  );
}

void main() {
  group('card brand', () {
    test('detects the major networks from the prefix', () {
      expect(cardBrandOf('4'), CardBrand.visa);
      expect(cardBrandOf('4242 4242'), CardBrand.visa);
      expect(cardBrandOf('5105'), CardBrand.mastercard);
      expect(cardBrandOf('2223'), CardBrand.mastercard);
      expect(cardBrandOf('3782'), CardBrand.amex);
      expect(cardBrandOf('6011'), CardBrand.discover);
      expect(cardBrandOf('9999'), CardBrand.unknown);
      expect(cardBrandOf(''), CardBrand.unknown);
    });
  });

  group('CardNumberInputFormatter', () {
    const f = CardNumberInputFormatter();

    test('groups a Visa number 4-4-4-4', () {
      expect(_type(f, '424242424242', '4242424242424242').text,
          '4242 4242 4242 4242');
    });

    test('groups an Amex number 4-6-5', () {
      expect(_type(f, '37828224631', '378282246310005').text,
          '3782 822463 10005');
    });

    test('caps the PAN at 19 digits', () {
      final out = _type(f, '4242424242424242', '42424242424242424242424').text;
      expect(out.replaceAll(' ', '').length, 19);
    });

    test('caps an Amex at 15 digits', () {
      final out = _type(f, '378282246310005', '3782822463100050000').text;
      expect(out.replaceAll(' ', '').length, 15);
    });
  });

  group('ExpiryInputFormatter', () {
    const f = ExpiryInputFormatter();

    test('inserts the slash after two digits', () {
      expect(_type(f, '1', '12').text, '12/');
      expect(_type(f, '12/', '12/2').text, '12/2');
      expect(_type(f, '12/2', '12/25').text, '12/25');
    });

    test('clamps an impossible month', () {
      expect(_type(f, '1', '13').text, '12/');
      expect(_type(f, '', '9').text, '09/');
      expect(_type(f, '0', '00').text, '01/');
    });

    test('a backspace onto the slash deletes the digit before it', () {
      expect(_type(f, '12/', '12').text, '1');
    });
  });

  group('parseExpiry / expiryInFuture', () {
    test('parses MM/YY', () {
      final p = parseExpiry('12/30');
      expect(p, isNotNull);
      expect(p!.month, 12);
      expect(p.year, 2030);
    });

    test('rejects a bad month', () {
      expect(parseExpiry('13/30'), isNull);
      expect(parseExpiry('00/30'), isNull);
    });

    test('a past month is not in the future', () {
      final now = DateTime.now();
      expect(expiryInFuture(now.month, now.year - 1), isFalse);
      expect(expiryInFuture(now.month, now.year + 1), isTrue);
    });
  });

  group('luhnValid', () {
    test('accepts a valid number and rejects a typo', () {
      expect(luhnValid('4242 4242 4242 4242'), isTrue);
      expect(luhnValid('4242424242424243'), isFalse);
      expect(luhnValid('123'), isFalse);
    });
  });
}
