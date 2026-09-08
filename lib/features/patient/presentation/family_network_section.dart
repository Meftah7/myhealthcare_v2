/// Family Network — linked family members (redesign v2 patient dashboard).
///
/// Add: choose a relationship first — last name auto-fills from the
/// patient's own (Child or Sibling only), phone/email auto-fill from the
/// patient's own (any relationship); every pre-filled field stays editable.
/// Required: relationship, first name, last name. Optional: CPR, date of
/// birth, gender, blood type. Edit reopens the same form pre-filled. Remove
/// asks for confirmation before unlinking.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/date_input.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../application/patient_data_providers.dart';

class FamilyNetworkSection extends ConsumerWidget {
  const FamilyNetworkSection({
    required this.patient,
    this.embedded = false,
    super.key,
  });

  final Patient patient;

  /// When true, drop the section header + outer card (the caller supplies the
  /// surface) and move "Add" to a button at the top of the list.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(patientFamilyMembersProvider);

    final list = members.when(
      loading: () => const LoadingSkeleton(height: 72),
      error: (e, _) =>
          const InlineBanner.error('Could not load family members.'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.family_restroom_outlined,
            message: 'No family members linked yet.',
          );
        }
        final tiles = Column(
          children: [
            for (final (i, m) in items.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: Space.md),
              _FamilyMemberTile(
                member: m,
                onEdit: () => _openForm(context, ref, existing: m),
                onRemove: () => _remove(context, ref, m),
              ),
            ],
          ],
        );
        return embedded
            ? tiles
            : AppCard(padding: EdgeInsets.zero, child: tiles);
      },
    );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add family member'),
            ),
          ),
          const SizedBox(height: Space.sm),
          list,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Family network',
          overline: true,
          action: 'Add',
          onAction: () => _openForm(context, ref),
        ),
        list,
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    FamilyMember? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _FamilyMemberForm(patient: patient, existing: existing),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) async {
    final ok = await confirm(
      context,
      title: 'Remove ${member.fullName}?',
      message: 'This unlinks them from your family network.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    final result = await ref
        .read(familyMemberControllerProvider)
        .remove(member.id);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({
    required this.member,
    required this.onEdit,
    required this.onRemove,
  });

  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = <String>[
      _genderLabel(member.gender),
      if (member.dob != null) formatTypedDob(member.dob!),
      if (member.cpr != null) 'CPR ${member.cpr}',
    ].where((s) => s.isNotEmpty).join('  ·  ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Text(
          member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(member.fullName, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: Space.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: Radii.pill,
            ),
            child: Text(
              familyRelationshipLabel(member.relationship),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  static String _genderLabel(Gender? g) => switch (g) {
    null => '',
    Gender.female => 'Female',
    Gender.male => 'Male',
    Gender.other => 'Other',
    Gender.undisclosed => 'Prefer not to say',
  };
}

class _FamilyMemberForm extends ConsumerStatefulWidget {
  const _FamilyMemberForm({required this.patient, this.existing});

  final Patient patient;
  final FamilyMember? existing;

  @override
  ConsumerState<_FamilyMemberForm> createState() => _FamilyMemberFormState();
}

class _FamilyMemberFormState extends ConsumerState<_FamilyMemberForm> {
  late FamilyRelationship _relationship;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _cpr;
  late final TextEditingController _dob;
  late final TextEditingController _bloodType;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  Gender? _gender;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _relationship = existing?.relationship ?? FamilyRelationship.child;
    _firstName = TextEditingController(text: existing?.firstName ?? '');
    _lastName = TextEditingController(
      text: existing?.lastName ?? _autoLastName(_relationship),
    );
    _cpr = TextEditingController(text: existing?.cpr ?? '');
    _dob = TextEditingController(
      text: existing?.dob == null ? '' : formatTypedDob(existing!.dob!),
    );
    _bloodType = TextEditingController(text: existing?.bloodType ?? '');
    // Any relationship auto-fills phone/email from the patient's own.
    _phone = TextEditingController(
      text: existing?.phone ?? widget.patient.user.phone ?? '',
    );
    _email = TextEditingController(
      text: existing?.email ?? widget.patient.user.email,
    );
    _gender = existing?.gender;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _cpr.dispose();
    _dob.dispose();
    _bloodType.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String _autoLastName(FamilyRelationship r) =>
      (r == FamilyRelationship.child || r == FamilyRelationship.sibling)
      ? widget.patient.user.fullName.trim().split(RegExp(r'\s+')).skip(1).join(' ')
      : '';

  void _onRelationshipChanged(FamilyRelationship? r) {
    if (r == null) return;
    setState(() {
      // Only overwrite an auto-filled (still-blank-for-this-purpose) last
      // name — never clobber something the user already typed.
      final wasAutoFillable =
          _relationship == FamilyRelationship.child ||
          _relationship == FamilyRelationship.sibling;
      final isBlankOrAuto =
          _lastName.text.isEmpty || _lastName.text == _autoLastName(_relationship);
      _relationship = r;
      if (!_isEdit && (isBlankOrAuto || !wasAutoFillable)) {
        _lastName.text = _autoLastName(r);
      }
    });
  }

  String? get _cprError {
    final text = _cpr.text;
    if (text.isEmpty) return null;
    return text.length == 9 ? null : '${text.length}/9 digits';
  }

  String? get _dobError => validateTypedDob(_dob.text);

  bool get _isValid =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _cprError == null &&
      _dobError == null;

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _busy = true);
    final member = FamilyMember(
      id: widget.existing?.id ?? newId('fam'),
      relationship: _relationship,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      cpr: _cpr.text.trim().isEmpty ? null : _cpr.text.trim(),
      dob: parseTypedDob(_dob.text),
      gender: _gender,
      bloodType: _bloodType.text.trim().isEmpty ? null : _bloodType.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
    );
    final controller = ref.read(familyMemberControllerProvider);
    final result = _isEdit
        ? await controller.update(member)
        : await controller.add(member);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit family member' : 'Add family member',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<FamilyRelationship>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: [
                for (final r in FamilyRelationship.values)
                  DropdownMenuItem(value: r, child: Text(familyRelationshipLabel(r))),
              ],
              onChanged: _onRelationshipChanged,
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'First name *'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: TextField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Last name *'),
                    onChanged: (_) => setState(() {}),
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
                labelText: 'CPR (optional)',
                errorText: _cprError,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _dob,
              keyboardType: TextInputType.number,
              inputFormatters: [DateSlashFormatter()],
              decoration: InputDecoration(
                labelText: 'Date of birth (DD/MM/YYYY, optional)',
                errorText: _dobError,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<Gender?>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender (optional)'),
              items: const [
                DropdownMenuItem(child: Text('—')),
                DropdownMenuItem(value: Gender.male, child: Text('Male')),
                DropdownMenuItem(value: Gender.female, child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _bloodType,
              decoration: const InputDecoration(labelText: 'Blood type (optional)'),
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
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _isValid && !_busy ? _save : null,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Add family member'),
            ),
          ],
        ),
      ),
    );
  }
}
