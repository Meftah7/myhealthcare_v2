import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/lab_conversion.dart';
import 'health_tools_directory.dart';

class LabConverterScreen extends StatefulWidget {
  const LabConverterScreen({required this.analyte, super.key});
  final LabAnalyte analyte;
  @override
  State<LabConverterScreen> createState() => _LabConverterScreenState();
}

class _LabConverterScreenState extends State<LabConverterScreen> {
  final _input = TextEditingController();
  bool _fromMmol = false;
  double? _mg;
  bool _invalid = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _edit(String raw) {
    final value = parseLocalizedNumber(raw);
    double? mg;
    if (value != null && value >= 0) {
      try {
        mg = _fromMmol ? widget.analyte.convert(value, fromMmol: true) : value;
      } on ArgumentError {
        mg = null;
      }
      if (mg != null && !(mg * widget.analyte.mmolPerMg).isFinite) {
        mg = null;
      }
    }
    setState(() {
      _mg = mg;
      _invalid = raw.trim().isNotEmpty && mg == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = switch (widget.analyte) {
      LabAnalyte.glucose => t.htBloodSugar,
      LabAnalyte.cholesterol => t.htCholesterol,
      LabAnalyte.triglycerides => t.htTriglycerides,
    };
    final factor = switch (widget.analyte) {
      LabAnalyte.glucose => t.htFactorGlucose,
      LabAnalyte.cholesterol => t.htFactorCholesterol,
      LabAnalyte.triglycerides => t.htFactorTriglycerides,
    };
    final from = _fromMmol ? 'mmol/L' : 'mg/dL';
    final to = _fromMmol ? 'mg/dL' : 'mmol/L';
    final value = _mg == null
        ? null
        : (_fromMmol ? _mg! : _mg! * widget.analyte.mmolPerMg);
    final output = value == null
        ? '—'
        : NumberFormat('0.00', t.localeName).format(value);
    return PatientPageScaffold(
      appBar: toolsAppBar(context, title),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Space.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FutureWorkBadge(label: t.paFutureWork),
        ),
        const SizedBox(height: Space.sm),
        Text(t.htScope),
        const SizedBox(height: Space.lg),
        SurfaceCard(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('lab-input'),
                controller: _input,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${t.htInput} ($from)',
                  errorText: _invalid ? t.htInvalidNumber : null,
                ),
                onChanged: _edit,
              ),
              const SizedBox(height: Space.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton.filledTonal(
                  key: const ValueKey('lab-swap'),
                  tooltip: t.htSwap,
                  onPressed: _invalid
                      ? null
                      : () => setState(() {
                          _fromMmol = !_fromMmol;
                          if (_mg != null) {
                            final next = _fromMmol
                                ? _mg! * widget.analyte.mmolPerMg
                                : _mg!;
                            _input.text = NumberFormat(
                              '0.##########',
                              t.localeName,
                            ).format(next);
                          }
                        }),
                  icon: const Icon(Icons.swap_vert),
                ),
              ),
              const Divider(),
              Text('${t.htResult} ($to)'),
              const SizedBox(height: Space.sm),
              Semantics(
                liveRegion: true,
                label: '${t.htResult}: $output $to',
                excludeSemantics: true,
                child: Text(
                  '$output $to',
                  key: const ValueKey('lab-output'),
                  textDirection: TextDirection.ltr,
                  textAlign: Directionality.of(context) == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: Space.sm),
              TextButton.icon(
                key: const ValueKey('lab-copy'),
                style: TextButton.styleFrom(
                  foregroundColor: PatientPalette.of(context).link,
                ),
                onPressed: value == null
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: '$output $to'),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(t.htCopied)));
                      },
                icon: const Icon(Icons.copy_outlined),
                label: Text(t.htCopy),
              ),
              const Divider(),
              Text(factor),
              const SizedBox(height: Space.sm),
              Text(t.htConversionExplanation),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        Text(t.htConverterDescription),
      ],
    );
  }
}
