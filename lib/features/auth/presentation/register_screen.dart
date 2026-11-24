/// Patient self-registration (P2-03).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/result.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _conditions = TextEditingController();
  final _allergies = TextEditingController();
  final _emergency = TextEditingController();
  Gender? _gender;
  DateTime? _dob;
  String? _bloodType;
  int _step = 0;
  bool _busy = false;
  String? _error;

  /// An email / national ID found to be in use when Continue was pressed;
  /// the field shows it until the value is changed.
  String? _takenEmail;
  String? _takenNationalId;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _password,
      _phone,
      _nationalId,
      _conditions,
      _allergies,
      _emergency,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _split(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(sessionProvider.notifier)
        .register(
          PatientRegistration(
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phone: _phone.text.trim(),
            dob: _dob,
            gender: _gender,
            nationalId: _nationalId.text.trim(),
            bloodType: _bloodType,
            allergies: _split(_allergies.text),
            chronicConditions: _split(_conditions.text),
            emergencyContact: _emergency.text.trim().isEmpty
                ? null
                : _emergency.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      setState(
        () => _error = describeFailure(
          AppLocalizations.of(context)!,
          failure,
        ).message,
      );
    }
    // On success the router redirect lands the new patient on their home.
  }

  /// Continue to the next step — after checking, on the step where it was
  /// typed, that the email (step 1) or national ID (step 2) isn't already
  /// in use, rather than only when the account is finally created.
  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authRepositoryProvider);
    setState(() => _busy = true);
    var taken = false;
    if (_step == 0) {
      final email = _email.text.trim().toLowerCase();
      // If the check itself can't run, carry on: creating the account
      // still refuses a duplicate.
      taken = (await auth.isEmailRegistered(email)).valueOrNull ?? false;
      if (taken) _takenEmail = email;
    } else if (_step == 1) {
      final id = _nationalId.text.trim();
      taken = (await auth.isNationalIdRegistered(id)).valueOrNull ?? false;
      if (taken) _takenNationalId = id;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!taken) _step++;
    });
    if (taken) _formKey.currentState!.validate();
  }

  /// A phone number: digits with optional +, spaces, dashes or brackets,
  /// and at least 8 digits.
  static bool _validPhone(String v) =>
      RegExp(r'^[+\d\s()-]+$').hasMatch(v) &&
      RegExp(r'\d').allMatches(v).length >= 8;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 110),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final labels = [
      t.accountSection,
      t.detailsSection,
      t.medicalSectionOptional,
    ];
    final last = _step == labels.length - 1;
    return AuthScaffold(
      title: t.createAccount,
      subtitle: t.stepProgress(_step + 1, labels.length, labels[_step]),
      onBack: _step > 0
          ? () => setState(() => _step--)
          : () => Navigator.of(context).maybePop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: Space.xs),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Space.lg),
            if (_step == 0) ...[
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t.fullName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.requiredField : null,
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.email),
                validator: (v) => (v == null || !v.contains('@'))
                    ? t.validEmailRequired
                    : v.trim().toLowerCase() == _takenEmail
                    ? t.emailAlreadyRegistered
                    : null,
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                // The rule is shown up front, not only after a failed try.
                decoration: InputDecoration(
                  labelText: t.password,
                  helperText: t.passwordMinLength,
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? t.passwordMinLength : null,
              ),
            ] else if (_step == 1) ...[
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.phoneLabel),
                validator: (v) => (v == null || !_validPhone(v.trim()))
                    ? t.phoneNumberRequired
                    : null,
              ),
              const SizedBox(height: Space.md),
              AdaptiveFormRow(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDob,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                      _dob == null
                          ? t.dateOfBirth
                          : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownButtonFormField<Gender>(
                    initialValue: _gender,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.gender),
                    items: [
                      DropdownMenuItem(
                        value: Gender.male,
                        child: Text(t.genderMale),
                      ),
                      DropdownMenuItem(
                        value: Gender.female,
                        child: Text(t.genderFemale),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AdaptiveFormRow(
                children: [
                  TextFormField(
                    controller: _nationalId,
                    decoration: InputDecoration(labelText: t.nationalIdLabel),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.nationalIdRequired
                        : v.trim() == _takenNationalId
                        ? t.nationalIdAlreadyRegistered
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _bloodType,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.bloodType),
                    items: [
                      for (final b in const [
                        'O+',
                        'O-',
                        'A+',
                        'A-',
                        'B+',
                        'B-',
                        'AB+',
                        'AB-',
                      ])
                        DropdownMenuItem(value: b, child: Text(b)),
                    ],
                    onChanged: (v) => setState(() => _bloodType = v),
                  ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _conditions,
                decoration: InputDecoration(
                  labelText: t.chronicConditions,
                  helperText: t.commaSeparatedHelper,
                ),
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _allergies,
                decoration: InputDecoration(
                  labelText: t.allergies,
                  helperText: t.commaSeparatedHelper,
                ),
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _emergency,
                decoration: InputDecoration(labelText: t.emergencyContact),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              InlineBanner.error(_error!),
            ],
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _busy
                  ? null
                  : last
                  ? _submit
                  : () => unawaited(_next()),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(last ? t.createAccount : t.continueButton),
            ),
          ],
        ),
      ),
    );
  }
}
