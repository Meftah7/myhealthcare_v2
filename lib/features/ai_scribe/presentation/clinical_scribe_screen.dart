/// AI Clinical Scribe screen (Tier B): dictate free text → a structured,
/// editable visit note → save it to the patient's record.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/status_badges.dart';
import '../../../core/result.dart';
import '../../patient_chart/application/chart_providers.dart';
import '../../staff_dashboard/presentation/staff_top_actions.dart';
import '../application/clinical_scribe.dart';

class ClinicalScribeScreen extends ConsumerStatefulWidget {
  const ClinicalScribeScreen({required this.patientId, super.key});

  final String patientId;

  @override
  ConsumerState<ClinicalScribeScreen> createState() =>
      _ClinicalScribeScreenState();
}

class _ClinicalScribeScreenState extends ConsumerState<ClinicalScribeScreen> {
  final _dictation = TextEditingController();
  final _chief = TextEditingController();
  final _hpi = TextEditingController();
  final _assessment = TextEditingController();
  final _plan = TextEditingController();
  var _icdCodes = <String>[];

  bool _structuring = false;
  bool _saving = false;
  bool _usedAi = false;
  bool _hasDraft = false;

  @override
  void dispose() {
    for (final c in [_dictation, _chief, _hpi, _assessment, _plan]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _structure() async {
    setState(() => _structuring = true);
    final result = await ref
        .read(clinicalScribeProvider)
        .structure(_dictation.text);
    if (!mounted) return;
    setState(() => _structuring = false);
    switch (result) {
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      case Ok(:final value):
        setState(() {
          _chief.text = value.chiefComplaint;
          _hpi.text = value.hpi;
          _assessment.text = value.assessment;
          _plan.text = value.plan;
          _icdCodes = [...value.icdCodes];
          _usedAi = value.usedAi;
          _hasDraft = true;
        });
    }
  }

  Future<void> _save() async {
    final draft = ScribeDraft(
      chiefComplaint: _chief.text,
      hpi: _hpi.text,
      assessment: _assessment.text,
      plan: _plan.text,
      icdCodes: _icdCodes,
    );
    final title = _chief.text.trim().isEmpty
        ? 'Clinical note'
        : _chief.text.trim();

    setState(() => _saving = true);
    final result = await ref
        .read(chartActionsProvider(widget.patientId))
        .addNote(
          title: title.length > 120 ? title.substring(0, 120) : title,
          body: draft.toNoteBody(),
          occurredAt: DateTime.now(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => 'Saved to the patient record.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = ref.watch(chartPatientProvider(widget.patientId));
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Clinical Scribe'),
        actions: const [StaffTopActions()],
      ),
      body: Column(
        children: [
          if (_usedAi) const AiDisclaimerBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    Space.md,
                    gutter,
                    Space.xxl,
                  ),
                  children: [
                    Text(
                      patient.valueOrNull == null
                          ? 'Visit note'
                          : 'Visit note · ${patient.valueOrNull!.fullName}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.md),

                    // --- dictation ---
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _dictation,
                            minLines: 4,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              labelText: 'Dictation',
                              alignLabelWithHint: true,
                              hintText:
                                  'Type or paste your visit notes in plain '
                                  'language — the scribe will structure them.',
                            ),
                          ),
                          const SizedBox(height: Space.md),
                          FilledButton.icon(
                            onPressed: _structuring ? null : _structure,
                            icon: _structuring
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              _structuring
                                  ? 'Structuring…'
                                  : 'Structure with AI',
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_hasDraft) ...[
                      const SizedBox(height: Space.md),
                      const SectionHeader('Structured note', overline: true),
                      _field('Chief complaint', _chief, lines: 1),
                      _field('History of present illness', _hpi, lines: 4),
                      _field('Assessment', _assessment, lines: 3),
                      _field('Plan', _plan, lines: 3),
                      if (_icdCodes.isNotEmpty) ...[
                        const SizedBox(height: Space.sm),
                        Text(
                          'Suggested ICD-10 — confirm before coding',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Wrap(
                          spacing: Space.xs,
                          runSpacing: Space.xs,
                          children: [
                            for (final code in _icdCodes)
                              InputChip(
                                label: Text(code),
                                onDeleted: () =>
                                    setState(() => _icdCodes.remove(code)),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: Space.lg),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save as visit note'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {required int lines}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TextField(
        controller: c,
        minLines: lines,
        maxLines: lines + 4,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
