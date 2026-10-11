import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/features/health_tools/domain/lab_conversion.dart';
import 'package:myhealthcare/features/health_tools/presentation/health_tools_screens.dart';

void main() {
  for (final (analyte, mg, mmol) in [
    (LabAnalyte.glucose, 180.16, 10.0),
    (LabAnalyte.cholesterol, 200.0, 5.18),
    (LabAnalyte.triglycerides, 150.0, 1.695),
  ]) {
    test('${analyte.name}: known example, reverse and round trips', () {
      expect(analyte.convert(mg, fromMmol: false), closeTo(mmol, 1e-10));
      expect(analyte.convert(mmol, fromMmol: true), closeTo(mg, 1e-10));
      for (final value in [0.0, .0001, 1.0, 5.75, 120.0, 9999.99]) {
        final result = analyte.convert(value, fromMmol: false);
        expect(analyte.convert(result, fromMmol: true), closeTo(value, 1e-9));
      }
    });
    test('${analyte.name}: invalid values do not generate results', () {
      for (final value in [-1.0, double.nan, double.infinity]) {
        expect(
          () => analyte.convert(value, fromMmol: false),
          throwsArgumentError,
        );
        expect(
          () => analyte.convert(value, fromMmol: true),
          throwsArgumentError,
        );
      }
    });
  }
  test('analytes use distinct factors, not the glucose factor for lipids', () {
    final values = LabAnalyte.values
        .map((a) => a.convert(120, fromMmol: false))
        .toSet();
    expect(values.length, 3);
    expect(
      LabAnalyte.cholesterol.convert(120, fromMmol: false),
      closeTo(3.108, 1e-12),
    );
    expect(
      LabAnalyte.triglycerides.convert(120, fromMmol: false),
      closeTo(1.356, 1e-12),
    );
  });
  test(
    'localized digits and decimal separators parse without guessed values',
    () {
      for (final value in [
        '120.5',
        '120,5',
        '١٢٠٫٥',
        '۱۲۰٫۵',
        '١٢٠,٥',
        '\u200f١٢٠٫٥',
      ]) {
        expect(parseLocalizedNumber(value), 120.5);
      }
      expect(parseLocalizedNumber('١٬٠٠٠٫٥'), 1000.5);
      for (final value in ['', 'abc', 'NaN', 'Infinity', '1,2,3', '1e999']) {
        expect(parseLocalizedNumber(value), isNull);
      }
      expect(parseLocalizedNumber('−1'), -1);
      expect(parseInRange('١٧٥٫٥', 40, 250), 175.5);
    },
  );
  test('existing BMI/BSA formulas and validation stay consistent', () {
    expect(bmi(70, 175), closeTo(22.857142857, 1e-8));
    expect(bodySurfaceArea(70, 175), closeTo(1.844661968, 1e-8));
    expect(parseInRange('Infinity', 2, 400), isNull);
    expect(parseInRange('-5', 2, 400), isNull);
  });
}
