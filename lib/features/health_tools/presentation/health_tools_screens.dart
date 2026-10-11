/// Public health tools: calculators (BMI, body surface area) and unit
/// converters. Deterministic formulas only; inputs are validated and results
/// are labelled as general information, not a diagnosis.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

/// Parses a positive number within [min]..[max]; null when invalid.
double? parseInRange(String raw, double min, double max) {
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (v == null || v.isNaN || v < min || v > max) return null;
  return v;
}

double bmi(double weightKg, double heightCm) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

/// Mosteller body surface area, m².
double bodySurfaceArea(double weightKg, double heightCm) =>
    math.sqrt(weightKg * heightCm / 3600);

AppBar _toolsAppBar(BuildContext context, String title) => AppBar(
  title: Text(title),
  leading: BackButton(
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(AppRoutes.patientHome),
  ),
);

class HealthCalculatorsScreen extends StatefulWidget {
  const HealthCalculatorsScreen({super.key});

  @override
  State<HealthCalculatorsScreen> createState() =>
      _HealthCalculatorsScreenState();
}

class _HealthCalculatorsScreenState extends State<HealthCalculatorsScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final w = parseInRange(_weight.text, 2, 400);
    final h = parseInRange(_height.text, 40, 250);
    final valid = w != null && h != null;
    String? category(double v) {
      if (v < 18.5) return t.paBmiUnder;
      if (v < 25) return t.paBmiNormal;
      if (v < 30) return t.paBmiOver;
      return t.paBmiObese;
    }

    return PatientPageScaffold(
      appBar: _toolsAppBar(context, t.paHealthCalculators),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.paWeightKg,
                  errorText: _submitted && w == null
                      ? t.paInvalidRange('2', '400')
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.paHeightCm,
                  errorText: _submitted && h == null
                      ? t.paInvalidRange('40', '250')
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.lg),
              PrimaryActionButton(
                label: t.paCalculate,
                onPressed: () => setState(() => _submitted = true),
              ),
            ],
          ),
        ),
        if (_submitted && valid) ...[
          const SizedBox(height: Space.md),
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.paBmiLabel, style: theme.textTheme.titleSmall),
                Text(
                  bmi(w, h).toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                StatusBadge(category(bmi(w, h))!, accent: PatientAccent.blue),
                const SizedBox(height: Space.md),
                Text(t.paBsaLabel, style: theme.textTheme.titleSmall),
                Text(
                  '${bodySurfaceArea(w, h).toStringAsFixed(2)} m²',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.md),
        Text(
          t.paToolsDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

enum _Conversion { weight, height, temperature, glucose }

class HealthConvertersScreen extends StatefulWidget {
  const HealthConvertersScreen({super.key});

  @override
  State<HealthConvertersScreen> createState() => _HealthConvertersScreenState();
}

class _HealthConvertersScreenState extends State<HealthConvertersScreen> {
  _Conversion _kind = _Conversion.weight;
  bool _reverse = false;
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// (from unit, to unit, convert, min, max).
  (String, String, double Function(double), double, double) _spec() => switch ((
    _kind,
    _reverse,
  )) {
    (_Conversion.weight, false) => ('kg', 'lb', (v) => v * 2.20462, 0, 1000),
    (_Conversion.weight, true) => ('lb', 'kg', (v) => v / 2.20462, 0, 2200),
    (_Conversion.height, false) => ('cm', 'in', (v) => v / 2.54, 0, 300),
    (_Conversion.height, true) => ('in', 'cm', (v) => v * 2.54, 0, 120),
    (_Conversion.temperature, false) => (
      '°C',
      '°F',
      (v) => v * 9 / 5 + 32,
      -50,
      60,
    ),
    (_Conversion.temperature, true) => (
      '°F',
      '°C',
      (v) => (v - 32) * 5 / 9,
      -58,
      140,
    ),
    // Glucose: 1 mmol/L = 18.016 mg/dL.
    (_Conversion.glucose, false) => (
      'mg/dL',
      'mmol/L',
      (v) => v / 18.016,
      0,
      2000,
    ),
    (_Conversion.glucose, true) => (
      'mmol/L',
      'mg/dL',
      (v) => v * 18.016,
      0,
      120,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final (from, to, convert, min, max) = _spec();
    final raw = _input.text;
    final value = parseInRange(raw, min, max);
    final labels = {
      _Conversion.weight: t.paConvWeight,
      _Conversion.height: t.paConvHeight,
      _Conversion.temperature: t.paConvTemperature,
      _Conversion.glucose: t.paConvGlucose,
    };
    return PatientPageScaffold(
      appBar: _toolsAppBar(context, t.paHealthConverters),
      children: [
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final k in _Conversion.values)
              ChoiceChip(
                label: Text(labels[k]!),
                selected: _kind == k,
                onSelected: (_) => setState(() {
                  _kind = k;
                  _reverse = false;
                  _input.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        SurfaceCard(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _input,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: from,
                  errorText: raw.isNotEmpty && value == null
                      ? t.paInvalidRange(
                          min.toStringAsFixed(0),
                          max.toStringAsFixed(0),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _reverse = !_reverse;
                    _input.clear();
                  }),
                  icon: const Icon(Icons.swap_vert),
                  label: Text('$from → $to'),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                value == null
                    ? '— $to'
                    : '${convert(value).toStringAsFixed(_kind == _Conversion.glucose ? 1 : 2)} $to',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          t.paToolsDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
