/// Bottom sheets for the staff chart write actions: clinical note (P5-08),
/// prescription and lab-result entry (P5-09).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../application/chart_providers.dart';

Future<void> showChartNoteSheet(BuildContext context, String patientId) {
  return _open(context, _NoteSheet(patientId: patientId));
}

Future<void> showPrescribeSheet(BuildContext context, String patientId) {
  return _open(context, _PrescribeSheet(patientId: patientId));
}

Future<void> showLabResultSheet(BuildContext context, String patientId) {
  return _open(context, _LabSheet(patientId: patientId));
}

Future<void> showSickLeaveSheet(BuildContext context, String patientId) {
  return _open(context, _SickLeaveSheet(patientId: patientId));
}

Future<void> _open(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    ),
  );
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.children,
    required this.onSubmit,
    required this.submitting,
    required this.canSubmit,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool submitting;
  final bool canSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.md),
              ...children,
              if (error != null) ...[
                const SizedBox(height: Space.sm),
                InlineBanner.error(error!),
              ],
              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (submitting || !canSubmit) ? null : onSubmit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reports failures inline on the sheet (via [error]) and successes with a
/// snackbar after the sheet has closed — a failure keeps the sheet open with
/// the entered data intact, so it needs the message to stay in view.
String? _errorOf(Result<Object?> result) => switch (result) {
  Ok() => null,
  Err(:final failure) => failure.message,
};

void _reportOk(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

// --- clinical note ---------------------------------------------------------

class _NoteSheet extends ConsumerStatefulWidget {
  const _NoteSheet({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<_NoteSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;
  bool _titleSeeded = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .addNote(
          title: _title.text.trim(),
          body: _body.text.trim(),
          occurredAt: DateTime.now(),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _errorOf(result);
    });
    if (result.isOk) {
      Navigator.of(context).pop();
      _reportOk(context, t.noteAdded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (!_titleSeeded) {
      _title.text = t.clinicalNoteFallbackTitle;
      _titleSeeded = true;
    }
    return _SheetScaffold(
      title: t.addClinicalNoteAction,
      submitting: _busy,
      canSubmit: _body.text.trim().isNotEmpty,
      onSubmit: _submit,
      error: _error,
      children: [
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: t.titleLabel),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _body,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: t.noteFieldLabel,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// --- prescription --------------------------------------------------------

class _PrescribeSheet extends ConsumerStatefulWidget {
  const _PrescribeSheet({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_PrescribeSheet> createState() => _PrescribeSheetState();
}

class _PrescribeSheetState extends ConsumerState<_PrescribeSheet> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _freq = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _freq.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .prescribe(
          name: _name.text.trim(),
          dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
          frequency: _freq.text.trim().isEmpty ? null : _freq.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _errorOf(result);
    });
    if (result.isOk) {
      Navigator.of(context).pop();
      _reportOk(context, t.medicationPrescribed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _SheetScaffold(
      title: t.prescribeMedicationAction,
      submitting: _busy,
      canSubmit: _name.text.trim().isNotEmpty,
      onSubmit: _submit,
      error: _error,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: t.medicationNameLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _dose,
          decoration: InputDecoration(labelText: t.doseOptionalLabel),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _freq,
          decoration: InputDecoration(labelText: t.frequencyOptionalLabel),
        ),
      ],
    );
  }
}

// --- lab result ---------------------------------------------------------

class _LabSheet extends ConsumerStatefulWidget {
  const _LabSheet({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_LabSheet> createState() => _LabSheetState();
}

class _LabSheetState extends ConsumerState<_LabSheet> {
  final _panel = TextEditingController();
  final _analyte = TextEditingController();
  final _value = TextEditingController();
  final _unit = TextEditingController();
  final _low = TextEditingController();
  final _high = TextEditingController();
  bool _busy = false;
  bool _panelSeeded = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_panel, _analyte, _value, _unit, _low, _high]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _analyte.text.trim().isNotEmpty &&
      double.tryParse(_value.text.trim()) != null;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .addLabResult(
          panelTitle: _panel.text.trim(),
          analyte: _analyte.text.trim(),
          value: double.parse(_value.text.trim()),
          occurredAt: DateTime.now(),
          unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
          refLow: double.tryParse(_low.text.trim()),
          refHigh: double.tryParse(_high.text.trim()),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _errorOf(result);
    });
    if (result.isOk) {
      Navigator.of(context).pop();
      _reportOk(context, t.labResultRecorded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (!_panelSeeded) {
      _panel.text = t.labResultFallbackTitle;
      _panelSeeded = true;
    }
    return _SheetScaffold(
      title: t.enterLabResultAction,
      submitting: _busy,
      canSubmit: _valid,
      onSubmit: _submit,
      error: _error,
      children: [
        TextField(
          controller: _panel,
          decoration: InputDecoration(labelText: t.panelTitleLabel),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _analyte,
          decoration: InputDecoration(labelText: t.analyteLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t.valueLabel),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: _unit,
                decoration: InputDecoration(labelText: t.unitLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _low,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t.refLowLabel),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: _high,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t.refHighLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- sick leave ----------------------------------------------------------

class _SickLeaveSheet extends ConsumerStatefulWidget {
  const _SickLeaveSheet({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_SickLeaveSheet> createState() => _SickLeaveSheetState();
}

class _SickLeaveSheetState extends ConsumerState<_SickLeaveSheet> {
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _from = DateTime.now();
  late DateTime _to = DateTime.now().add(const Duration(days: 2));
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _diagnosis.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _days => _to.difference(_from).inDays + 1;

  Future<void> _pick({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .issueSickLeave(
          diagnosis: _diagnosis.text.trim(),
          fromDate: _from,
          toDate: _to,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _errorOf(result);
    });
    if (result.isOk) {
      Navigator.of(context).pop();
      _reportOk(context, t.certificateIssued);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final df = MaterialLocalizations.of(context);
    return _SheetScaffold(
      title: t.issueSickLeaveAction,
      submitting: _busy,
      canSubmit: _diagnosis.text.trim().isNotEmpty && _days >= 1,
      onSubmit: _submit,
      error: _error,
      children: [
        TextField(
          controller: _diagnosis,
          decoration: InputDecoration(
            labelText: t.reasonDiagnosisLabel,
            hintText: t.acuteViralIllnessHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(isFrom: true),
                child: Text(t.fromDateLabel(df.formatMediumDate(_from))),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(isFrom: false),
                child: Text(t.toDateLabel(df.formatMediumDate(_to))),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Text(
          t.daysCountPlain(_days),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t.notesOptionalLabel,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
