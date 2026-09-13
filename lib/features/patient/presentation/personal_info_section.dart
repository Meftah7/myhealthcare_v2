/// Editable personal-info form (redesign v2 patient dashboard).
///
/// First/last name, CPR (national id, live-validated as exactly 9 digits),
/// date of birth (typed DD/MM/YYYY, validated as a real non-future date),
/// gender, phone, email. Save/Cancel stay disabled until something actually
/// changed. Rendered bare — the caller supplies the surrounding page.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/result.dart';
import '../../../core/utils/date_input.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/patient_data_providers.dart';

class PersonalInfoSection extends ConsumerStatefulWidget {
  const PersonalInfoSection({required this.patient, super.key});

  final Patient patient;

  @override
  ConsumerState<PersonalInfoSection> createState() =>
      _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends ConsumerState<PersonalInfoSection> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _cpr;
  late final TextEditingController _dob;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late Gender? _gender;

  late final String _baselineFirst;
  late final String _baselineLast;
  late final String _baselineCpr;
  late final String _baselineDob;
  late final String _baselinePhone;
  late final String _baselineEmail;
  late final Gender? _baselineGender;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = widget.patient.user;
    final nameParts = u.fullName.trim().split(RegExp(r'\s+'));
    final first = nameParts.first;
    final last = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    final dob = u.dob == null ? '' : formatTypedDob(u.dob!);

    _firstName = TextEditingController(text: first)..addListener(_onChanged);
    _lastName = TextEditingController(text: last)..addListener(_onChanged);
    _cpr = TextEditingController(text: u.nationalId ?? '')
      ..addListener(_onChanged);
    _dob = TextEditingController(text: dob)..addListener(_onChanged);
    _phone = TextEditingController(text: u.phone ?? '')
      ..addListener(_onChanged);
    _email = TextEditingController(text: u.email)..addListener(_onChanged);
    _gender = u.gender;

    _baselineFirst = first;
    _baselineLast = last;
    _baselineCpr = u.nationalId ?? '';
    _baselineDob = dob;
    _baselinePhone = u.phone ?? '';
    _baselineEmail = u.email;
    _baselineGender = u.gender;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _cpr.dispose();
    _dob.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isDirty =>
      _firstName.text != _baselineFirst ||
      _lastName.text != _baselineLast ||
      _cpr.text != _baselineCpr ||
      _dob.text != _baselineDob ||
      _phone.text != _baselinePhone ||
      _email.text != _baselineEmail ||
      _gender != _baselineGender;

  String? get _cprError {
    final text = _cpr.text;
    if (text.isEmpty) return null;
    if (text.length != 9) {
      return AppLocalizations.of(context)!.cprDigitsHelper(text.length);
    }
    return null;
  }

  String? get _dobError => validateTypedDob(_dob.text);

  bool get _isValid => _cprError == null && _dobError == null;

  void _cancel() {
    setState(() {
      _firstName.text = _baselineFirst;
      _lastName.text = _baselineLast;
      _cpr.text = _baselineCpr;
      _dob.text = _baselineDob;
      _phone.text = _baselinePhone;
      _email.text = _baselineEmail;
      _gender = _baselineGender;
    });
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _busy = true);
    final dob = parseTypedDob(_dob.text);
    final fullName = [
      _firstName.text.trim(),
      _lastName.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    final updated = widget.patient.copyWith(
      user: widget.patient.user.copyWith(
        fullName: fullName,
        email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        dob: dob,
        gender: _gender,
        nationalId: _cpr.text.trim().isEmpty ? null : _cpr.text.trim(),
      ),
    );

    final result = await ref
        .read(patientRepositoryProvider)
        .updateProfile(updated);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        ref.invalidate(patientProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUpdatedSnackbar),
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
    final canSave = _isDirty && _isValid && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstName,
                decoration: InputDecoration(labelText: t.firstNameLabel),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: _lastName,
                decoration: InputDecoration(labelText: t.lastNameLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _cpr,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          decoration: InputDecoration(
            labelText: t.cprLabel,
            helperText: t.cprDigitsHelper(_cpr.text.length),
            errorText: _cprError,
          ),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _dob,
          keyboardType: TextInputType.number,
          inputFormatters: [DateSlashFormatter()],
          decoration: InputDecoration(
            labelText: t.dateOfBirthDdmmyyyyLabel,
            errorText: _dobError,
          ),
        ),
        const SizedBox(height: Space.sm),
        DropdownButtonFormField<Gender>(
          initialValue: _gender,
          decoration: InputDecoration(labelText: t.genderFieldLabel),
          items: [
            for (final g in Gender.values)
              DropdownMenuItem(value: g, child: Text(g.label(context))),
          ],
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: t.phoneLabel),
        ),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: t.emailLabel),
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
                onPressed: canSave ? _save : null,
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
      ],
    );
  }
}
