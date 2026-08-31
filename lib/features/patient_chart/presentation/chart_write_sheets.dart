/// Bottom sheets for the staff chart write actions: clinical note (P5-08),
/// prescription and lab-result entry (P5-09).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/result.dart';
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

Future<void> _open(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool submitting;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.md),
            ...children,
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (submitting || !canSubmit) ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

void _report(BuildContext context, Result<Object?> result, String ok) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        Ok() => ok,
        Err(:final failure) => failure.message,
      }),
    ),
  );
}

// --- clinical note ---------------------------------------------------------

class _NoteSheet extends ConsumerStatefulWidget {
  const _NoteSheet({required this.patientId});
  final String patientId;

  @override
  ConsumerState<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<_NoteSheet> {
  final _title = TextEditingController(text: 'Clinical note');
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .addNote(
          title: _title.text.trim(),
          body: _body.text.trim(),
          occurredAt: DateTime.now(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    _report(context, result, 'Note added.');
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Add clinical note',
      submitting: _busy,
      canSubmit: _body.text.trim().isNotEmpty,
      onSubmit: _submit,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _body,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Note',
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

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _freq.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .prescribe(
          name: _name.text.trim(),
          dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
          frequency: _freq.text.trim().isEmpty ? null : _freq.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    _report(context, result, 'Medication prescribed.');
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Prescribe medication',
      submitting: _busy,
      canSubmit: _name.text.trim().isNotEmpty,
      onSubmit: _submit,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Medication name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _dose,
          decoration: const InputDecoration(labelText: 'Dose (optional)'),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _freq,
          decoration: const InputDecoration(labelText: 'Frequency (optional)'),
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
  final _panel = TextEditingController(text: 'Lab result');
  final _analyte = TextEditingController();
  final _value = TextEditingController();
  final _unit = TextEditingController();
  final _low = TextEditingController();
  final _high = TextEditingController();
  bool _busy = false;

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
    setState(() => _busy = true);
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
    setState(() => _busy = false);
    _report(context, result, 'Lab result recorded.');
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Enter lab result',
      submitting: _busy,
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        TextField(
          controller: _panel,
          decoration: const InputDecoration(labelText: 'Panel / title'),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _analyte,
          decoration: const InputDecoration(labelText: 'Analyte'),
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
                decoration: const InputDecoration(labelText: 'Value'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
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
                decoration: const InputDecoration(labelText: 'Ref low'),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: _high,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Ref high'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
