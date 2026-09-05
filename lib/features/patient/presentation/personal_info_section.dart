/// Editable Personal Info + preferences (redesign v2 patient dashboard).
///
/// First/last name, CPR (national id, live-validated as exactly 9 digits),
/// date of birth (typed DD/MM/YYYY, validated as a real non-future date),
/// gender, phone, email; notification toggles and the existing theme
/// picker. Save/Cancel stay disabled until something actually changed.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/ui_prefs.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';
import '../../../core/utils/date_input.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../settings/presentation/preferences_section.dart';
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
    if (text.length != 9) return '${text.length}/9 digits';
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
          const SnackBar(content: Text('Profile updated.')),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _isDirty && _isValid && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Personal info', overline: true),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'First name'),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: TextField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Last name'),
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
                  labelText: 'CPR',
                  helperText: '${_cpr.text.length}/9 digits',
                  errorText: _cprError,
                ),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _dob,
                keyboardType: TextInputType.number,
                inputFormatters: [DateSlashFormatter()],
                decoration: InputDecoration(
                  labelText: 'Date of birth (DD/MM/YYYY)',
                  errorText: _dobError,
                ),
              ),
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<Gender>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: [
                  for (final g in Gender.values)
                    DropdownMenuItem(value: g, child: Text(_genderLabel(g))),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDirty && !_busy ? _cancel : null,
                      child: const Text('Cancel'),
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
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        const PreferencesSection(),
        const SizedBox(height: Space.md),
        const _NotificationPrefsCard(),
      ],
    );
  }

  static String _genderLabel(Gender g) => switch (g) {
    Gender.female => 'Female',
    Gender.male => 'Male',
    Gender.other => 'Other',
    Gender.undisclosed => 'Prefer not to say',
  };
}

class _NotificationPrefsCard extends ConsumerWidget {
  const _NotificationPrefsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Notifications', overline: true),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('SMS'),
                value: prefs.sms,
                onChanged: notifier.setSms,
              ),
              const Divider(height: 1, indent: Space.md),
              SwitchListTile(
                title: const Text('Email'),
                value: prefs.email,
                onChanged: notifier.setEmail,
              ),
              const Divider(height: 1, indent: Space.md),
              SwitchListTile(
                title: const Text('Push'),
                value: prefs.push,
                onChanged: notifier.setPush,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
