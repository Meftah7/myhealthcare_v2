/// Editable health-details form (redesign v3): blood type, allergies, chronic
/// conditions and emergency contact. Rendered bare inside a profile
/// its own profile page; Save/Cancel stay disabled until something changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../application/patient_data_providers.dart';

const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class HealthDetailsSection extends ConsumerStatefulWidget {
  const HealthDetailsSection({required this.patient, super.key});

  final Patient patient;

  @override
  ConsumerState<HealthDetailsSection> createState() =>
      _HealthDetailsSectionState();
}

class _HealthDetailsSectionState extends ConsumerState<HealthDetailsSection> {
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _emergency;
  String? _bloodType;

  late final String _baseAllergies;
  late final String _baseConditions;
  late final String _baseEmergency;
  late final String? _baseBloodType;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _baseAllergies = p.allergies.join(', ');
    _baseConditions = p.chronicConditions.join(', ');
    _baseEmergency = p.emergencyContact ?? '';
    _baseBloodType = p.bloodType;

    _allergies = TextEditingController(text: _baseAllergies)
      ..addListener(_onChanged);
    _conditions = TextEditingController(text: _baseConditions)
      ..addListener(_onChanged);
    _emergency = TextEditingController(text: _baseEmergency)
      ..addListener(_onChanged);
    _bloodType = _baseBloodType;
  }

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    _emergency.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isDirty =>
      _allergies.text != _baseAllergies ||
      _conditions.text != _baseConditions ||
      _emergency.text != _baseEmergency ||
      _bloodType != _baseBloodType;

  static List<String> _split(String raw) => raw
      .split(RegExp('[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _cancel() {
    setState(() {
      _allergies.text = _baseAllergies;
      _conditions.text = _baseConditions;
      _emergency.text = _baseEmergency;
      _bloodType = _baseBloodType;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final updated = widget.patient.copyWith(
      bloodType: _bloodType,
      allergies: _split(_allergies.text),
      chronicConditions: _split(_conditions.text),
      emergencyContact:
          _emergency.text.trim().isEmpty ? null : _emergency.text.trim(),
    );
    final result =
        await ref.read(patientRepositoryProvider).updateProfile(updated);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ref.invalidate(patientProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.healthDetailsUpdatedSnackbar,
            ),
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _bloodType,
          decoration: InputDecoration(labelText: t.bloodTypeLabel),
          items: [
            DropdownMenuItem(child: Text(t.unknownOption)),
            for (final b in _bloodTypes)
              DropdownMenuItem(value: b, child: Text(b)),
          ],
          onChanged: (v) => setState(() => _bloodType = v),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _allergies,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t.allergiesLabel,
            helperText: t.separateWithCommasHelper,
          ),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _conditions,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t.chronicConditionsLabel,
            helperText: t.separateWithCommasHelper,
          ),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _emergency,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: t.emergencyContactLabel,
            hintText: t.emergencyContactHint,
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isDirty && !_busy ? _cancel : null,
                child: Text(t.cancel),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: FilledButton(
                onPressed: _isDirty && !_busy ? _save : null,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.saveButton),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(
            t.sharedWithCliniciansNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
