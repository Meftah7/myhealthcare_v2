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
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/date_input.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../application/patient_data_providers.dart';
import 'linked_family_accounts_section.dart';

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
    final t = AppLocalizations.of(context)!;
    final members = ref.watch(patientFamilyMembersProvider);

    final list = members.when(
      loading: () => const LoadingSkeleton(height: 72),
      error: (e, _) => InlineBanner.error(t.couldNotLoadFamilyMembers),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.family_restroom_outlined,
            message: t.noFamilyMembersLinkedYet,
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
          const LinkedFamilyAccountsSection(),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.addFamilyMemberAction),
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
          t.familyNetworkTitle,
          overline: true,
          action: t.addButton,
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
    final t = AppLocalizations.of(context)!;
    final ok = await confirm(
      context,
      title: t.removeConfirmTitle(member.fullName),
      message: t.unlinksFromFamilyNetworkNote,
      confirmLabel: t.removeButton,
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = <String>[
      if (member.gender != null) member.gender!.label(context),
      if (member.dob != null) formatTypedDob(member.dob!),
      if (member.cpr != null) t.cprValueLabel(member.cpr!),
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
              member.relationship.label(context),
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
            tooltip: t.editAction,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.removeTooltip,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
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
    return text.length == 9
        ? null
        : AppLocalizations.of(context)!.cprDigitsHelper(text.length);
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
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? t.editFamilyMemberTitle : t.addFamilyMemberAction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<FamilyRelationship>(
              initialValue: _relationship,
              decoration: InputDecoration(labelText: t.relationshipLabel),
              items: [
                for (final r in FamilyRelationship.values)
                  DropdownMenuItem(value: r, child: Text(r.label(context))),
              ],
              onChanged: _onRelationshipChanged,
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstName,
                    decoration: InputDecoration(
                      labelText: t.firstNameRequiredLabel,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: TextField(
                    controller: _lastName,
                    decoration: InputDecoration(
                      labelText: t.lastNameRequiredLabel,
                    ),
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
                labelText: t.cprOptionalLabel,
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
                labelText: t.dobDdmmyyyyOptionalLabel,
                errorText: _dobError,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<Gender?>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: t.genderOptionalLabel),
              items: [
                const DropdownMenuItem(child: Text('—')),
                DropdownMenuItem(
                  value: Gender.male,
                  child: Text(Gender.male.label(context)),
                ),
                DropdownMenuItem(
                  value: Gender.female,
                  child: Text(Gender.female.label(context)),
                ),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _bloodType,
              decoration: InputDecoration(labelText: t.bloodTypeOptionalLabel),
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
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _isValid && !_busy ? _save : null,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? t.saveChangesAction : t.addFamilyMemberAction),
            ),
          ],
        ),
      ),
    );
  }
}
