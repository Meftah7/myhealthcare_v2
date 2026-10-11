/// Deterministic unit conversion only; no interpretation or persisted history.
library;

/// Glucose keeps MyHealth's existing molecular-weight factor. Lipid factors
/// follow Labcorp's SI Unit Conversion Table (checked 11 October 2026):
/// https://www.labcorp.com/test-menu/resources/si-unit-conversion-table
/// Reverse conversion uses the exact reciprocal, avoiding rounded-factor drift.
enum LabAnalyte {
  glucose(1 / 18.016),
  cholesterol(0.0259),
  triglycerides(0.0113);

  const LabAnalyte(this.mmolPerMg);
  final double mmolPerMg;

  double convert(double value, {required bool fromMmol}) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Must be finite and nonnegative',
      );
    }
    final result = fromMmol ? value / mmolPerMg : value * mmolPerMg;
    if (!result.isFinite) {
      throw ArgumentError.value(value, 'value', 'Too large');
    }
    return result;
  }
}

/// Accepts Latin, Arabic-Indic and Persian digits and locale decimal marks.
/// A comma is a decimal separator (the existing tool behavior), never grouping.
double? parseLocalizedNumber(String raw) {
  final normalized =
      String.fromCharCodes(
            raw.trim().runes.map((r) {
              if (r >= 0x660 && r <= 0x669) return r - 0x660 + 48;
              if (r >= 0x6f0 && r <= 0x6f9) return r - 0x6f0 + 48;
              return r;
            }),
          )
          .replaceAll(RegExp('[\u200e\u200f\u061c]'), '')
          .replaceAll('\u066c', '')
          .replaceAll('\u066b', '.')
          .replaceAll(',', '.')
          .replaceAll('\u2212', '-');
  final value = double.tryParse(normalized);
  return value != null && value.isFinite ? value : null;
}
