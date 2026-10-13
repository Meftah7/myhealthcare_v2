// One displayed-money format: BHD with three decimals (fils).
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/utils/format.dart';

void main() {
  test('BHD always shows three decimals and grouping', () {
    expect(fmtBhd(0), 'BHD 0.000');
    expect(fmtBhd(12.5), 'BHD 12.500');
    expect(fmtBhd(1234.5678), 'BHD 1,234.568');
    expect(fmtBhd(-3.1), 'BHD -3.100');
  });
}
