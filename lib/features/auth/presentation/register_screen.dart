/// Patient self-registration (P2-03).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../application/session.dart';

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
  bool _busy = false;
  String? _error;

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
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            dob: _dob,
            gender: _gender,
            nationalId: _nationalId.text.trim().isEmpty
                ? null
                : _nationalId.text.trim(),
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
      setState(() => _error = failure.message);
    }
    // On success the router redirect lands the new patient on their home.
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          'Account',
                          padding: EdgeInsets.only(bottom: Space.sm),
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'At least 6 characters'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          'Details',
                          padding: EdgeInsets.only(bottom: Space.sm),
                        ),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDob,
                                icon: const Icon(Icons.cake_outlined),
                                label: Text(
                                  _dob == null
                                      ? 'Date of birth'
                                      : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: DropdownButtonFormField<Gender>(
                                initialValue: _gender,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                ),
                                items: [
                                  for (final g in Gender.values)
                                    DropdownMenuItem(
                                      value: g,
                                      child: Text(g.name),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nationalId,
                                decoration: const InputDecoration(
                                  labelText: 'National ID (optional)',
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _bloodType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Blood type',
                                ),
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
                                    DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _bloodType = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          'Medical (optional)',
                          padding: EdgeInsets.only(bottom: Space.sm),
                        ),
                        TextFormField(
                          controller: _conditions,
                          decoration: const InputDecoration(
                            labelText: 'Chronic conditions',
                            helperText: 'Comma-separated',
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _allergies,
                          decoration: const InputDecoration(
                            labelText: 'Allergies',
                            helperText: 'Comma-separated',
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _emergency,
                          decoration: const InputDecoration(
                            labelText: 'Emergency contact',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Space.md),
                    InlineBanner.error(_error!),
                  ],
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
