/// Ideal weight, body fat, due date and ovulation estimate screens.
///
/// Results come only from `domain/estimates.dart`; an invalid input clears
/// the result instead of leaving a stale one. Nothing entered is saved.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/estimates.dart';
import 'health_tools_directory.dart' show toolsAppBar;

double? _num(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// Shared layout: estimate badge, description, form card, result card,
/// method and limitations.
class _EstimatePage extends StatelessWidget {
  const _EstimatePage({
    required this.title,
    required this.description,
    required this.method,
    required this.limits,
    required this.form,
    required this.onCalculate,
    this.result,
    this.invalid = false,
  });

  final String title;
  final String description;
  final String method;
  final String limits;
  final List<Widget> form;
  final VoidCallback onCalculate;
  final Widget? result;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return PatientPageScaffold(
      appBar: toolsAppBar(context, title),
      children: [
        ReadableLabel(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: Space.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusBadge(t.htEstimate, accent: PatientAccent.blue),
        ),
        const SizedBox(height: Space.sm),
        Text(description),
        const SizedBox(height: Space.md),
        SurfaceCard(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final w in form) ...[w, const SizedBox(height: Space.md)],
              PrimaryActionButton(label: t.paCalculate, onPressed: onCalculate),
            ],
          ),
        ),
        if (invalid) ...[
          const SizedBox(height: Space.md),
          Semantics(
            liveRegion: true,
            child: Text(
              t.htInvalidInput,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ] else if (result != null) ...[
          const SizedBox(height: Space.md),
          Semantics(
            liveRegion: true,
            child: SurfaceCard(
              padding: const EdgeInsets.all(Space.lg),
              child: result!,
            ),
          ),
        ],
        const SizedBox(height: Space.md),
        Text(
          limits,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: Space.xs),
        Text(
          t.htMethod(method),
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SexPicker extends StatelessWidget {
  const _SexPicker({required this.value, required this.onChanged});

  final Sex value;
  final ValueChanged<Sex> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.htSexLabel),
        const SizedBox(height: Space.xs),
        SegmentedButton<Sex>(
          segments: [
            ButtonSegment(value: Sex.female, label: Text(t.htFemale)),
            ButtonSegment(value: Sex.male, label: Text(t.htMale)),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.single),
        ),
      ],
    );
  }
}

TextField _numberField(
  TextEditingController c,
  String label,
  VoidCallback changed,
) => TextField(
  controller: c,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(labelText: label),
  onChanged: (_) => changed(),
);

// ---------------------------------------------------------------------------

class IdealWeightScreen extends StatefulWidget {
  const IdealWeightScreen({super.key});

  @override
  State<IdealWeightScreen> createState() => _IdealWeightState();
}

class _IdealWeightState extends State<IdealWeightScreen> {
  final _height = TextEditingController();
  Sex _sex = Sex.female;
  bool _submitted = false;

  @override
  void dispose() {
    _height.dispose();
    super.dispose();
  }

  // Editing an input hides the previous result until recalculated.
  void _changed() => setState(() => _submitted = false);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final h = _num(_height.text);
    final e = h == null ? null : idealWeight(sex: _sex, heightCm: h);
    return _EstimatePage(
      title: t.htIdealWeight,
      description: t.htIdealWeightDesc,
      method: 'Devine (1974); WHO BMI 18.5–24.9',
      limits: t.htBodyLimits,
      onCalculate: () => setState(() => _submitted = true),
      invalid: _submitted && e == null,
      form: [
        _SexPicker(
          value: _sex,
          onChanged: (s) => setState(() {
            _sex = s;
            _submitted = false;
          }),
        ),
        _numberField(_height, '${t.paHeightCm} (152–220)', _changed),
      ],
      result: _submitted && e != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultLine(
                  t.htIdealDevine,
                  '${localizeDigits(e.devineKg.toStringAsFixed(1))} kg',
                ),
                _ResultLine(
                  t.htHealthyRange,
                  '${localizeDigits(e.healthyMinKg.toStringAsFixed(1))}–'
                  '${localizeDigits(e.healthyMaxKg.toStringAsFixed(1))} kg',
                ),
              ],
            )
          : null,
    );
  }
}

class BodyFatScreen extends StatefulWidget {
  const BodyFatScreen({super.key});

  @override
  State<BodyFatScreen> createState() => _BodyFatState();
}

class _BodyFatState extends State<BodyFatScreen> {
  final _height = TextEditingController();
  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  Sex _sex = Sex.female;
  bool _submitted = false;

  @override
  void dispose() {
    for (final c in [_height, _neck, _waist, _hip]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _submitted = false);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final h = _num(_height.text), n = _num(_neck.text), w = _num(_waist.text);
    final value = h == null || n == null || w == null
        ? null
        : navyBodyFat(
            sex: _sex,
            heightCm: h,
            neckCm: n,
            waistCm: w,
            hipCm: _sex == Sex.female ? _num(_hip.text) : null,
          );
    return _EstimatePage(
      title: t.htBodyFat,
      description: t.htBodyFatDesc,
      method: 'U.S. Navy circumference method (Hodgdon & Beckett, 1984)',
      limits: t.htBodyLimits,
      onCalculate: () => setState(() => _submitted = true),
      invalid: _submitted && value == null,
      form: [
        _SexPicker(
          value: _sex,
          onChanged: (s) => setState(() {
            _sex = s;
            _submitted = false;
          }),
        ),
        _numberField(_height, t.paHeightCm, _changed),
        _numberField(_neck, t.htNeckCm, _changed),
        _numberField(_waist, t.htWaistCm, _changed),
        if (_sex == Sex.female) _numberField(_hip, t.htHipCm, _changed),
      ],
      result: _submitted && value != null
          ? _ResultLine(
              t.htBodyFatResult,
              '${localizeDigits(value.toStringAsFixed(1))}%',
            )
          : null,
    );
  }
}

/// Shared date + cycle form for the two pregnancy-related estimates.
mixin _CycleForm<T extends StatefulWidget> on State<T> {
  final cycle = TextEditingController(text: '28');
  DateTime? lmp;
  bool submitted = false;

  @override
  void dispose() {
    cycle.dispose();
    super.dispose();
  }

  int? get cycleDays => int.tryParse(cycle.text.trim());

  List<Widget> cycleForm(AppLocalizations t) => [
    OutlinedButton.icon(
      icon: const Icon(Icons.event_outlined),
      label: Text(
        lmp == null
            ? '${t.htLmpLabel}: ${t.htPickDate}'
            : '${t.htLmpLabel}: ${fmtDate(lmp!)}',
      ),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: lmp ?? now,
          firstDate: now.subtract(const Duration(days: 300)),
          lastDate: now,
        );
        if (picked != null && mounted) {
          setState(() {
            lmp = picked;
            submitted = false;
          });
        }
      },
    ),
    TextField(
      controller: cycle,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: t.htCycleLabel),
      onChanged: (_) => setState(() => submitted = false),
    ),
  ];
}

class DueDateScreen extends StatefulWidget {
  const DueDateScreen({super.key});

  @override
  State<DueDateScreen> createState() => _DueDateState();
}

class _DueDateState extends State<DueDateScreen> with _CycleForm {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = cycleDays;
    final e = lmp == null || c == null
        ? null
        : dueDate(lmp: lmp!, today: DateTime.now(), cycleDays: c);
    return _EstimatePage(
      title: t.htDueDate,
      description: t.htDueDateDesc,
      method: "Naegele's rule, cycle-adjusted (ACOG Committee Opinion 700)",
      limits: t.htPregnancyLimits,
      onCalculate: () => setState(() => submitted = true),
      invalid: submitted && e == null,
      form: cycleForm(t),
      result: submitted && e != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultLine(t.htDueResult, fmtDate(e.dueDate)),
                Text(
                  t.htGestation(
                    localizeDigits('${e.gestationWeeks}'),
                    localizeDigits('${e.gestationDays}'),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class OvulationScreen extends StatefulWidget {
  const OvulationScreen({super.key});

  @override
  State<OvulationScreen> createState() => _OvulationState();
}

class _OvulationState extends State<OvulationScreen> with _CycleForm {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = cycleDays;
    final e = lmp == null || c == null
        ? null
        : fertileWindow(lmp: lmp!, today: DateTime.now(), cycleDays: c);
    return _EstimatePage(
      title: t.htOvulation,
      description: t.htOvulationDesc,
      method: 'Calendar method: ovulation ≈ 14 days before the next period',
      limits: t.htPregnancyLimits,
      onCalculate: () => setState(() => submitted = true),
      invalid: submitted && e == null,
      form: cycleForm(t),
      result: submitted && e != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultLine(t.htOvulationResult, fmtDate(e.ovulation)),
                _ResultLine(
                  t.htFertileWindow,
                  '${fmtDate(e.fertileStart)} – ${fmtDate(e.fertileEnd)}',
                ),
                _ResultLine(t.htNextPeriod, fmtDate(e.nextPeriod)),
              ],
            )
          : null,
    );
  }
}
