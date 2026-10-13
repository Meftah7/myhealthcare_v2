/// Searchable pickers for admin forms, so operators choose a named patient
/// or department instead of typing raw record IDs.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/entities.dart';
import '../../booking/application/booking_providers.dart';
import 'admin_workspace_shared.dart' show adminText;

/// Type a name, CPR/ID or phone; pick a patient. [onSelected] receives the
/// patient id (or `null` when the text no longer matches a selection).
class PatientPickerField extends ConsumerStatefulWidget {
  const PatientPickerField({
    required this.onSelected,
    this.label,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String?> onSelected;
  final String? label;
  final bool enabled;

  @override
  ConsumerState<PatientPickerField> createState() => _PatientPickerState();
}

class _PatientPickerState extends ConsumerState<PatientPickerField> {
  String _last = '';
  List<Patient> _options = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<Iterable<Patient>> _search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    if (q == _last) return _options;
    _last = q;
    final r = await ref.read(patientRepositoryProvider).search(q, limit: 20);
    return _options = r.valueOrNull ?? const [];
  }

  static String _label(Patient p) => [
    p.user.fullName,
    if (p.user.nationalId != null) p.user.nationalId!,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Patient>(
      displayStringForOption: _label,
      optionsBuilder: (value) => _search(value.text),
      onSelected: (p) => widget.onSelected(p.id),
      fieldViewBuilder: (context, controller, focus, submit) => TextField(
        controller: controller,
        focusNode: focus,
        enabled: widget.enabled,
        onChanged: (_) => widget.onSelected(null),
        decoration: InputDecoration(
          labelText:
              widget.label ??
              adminText(
                context,
                'Patient (name, CPR/ID or phone)',
                'المريض (الاسم أو الرقم الشخصي أو الهاتف)',
              ),
          prefixIcon: const Icon(Icons.person_search_outlined),
        ),
      ),
    );
  }
}

/// A department dropdown by name.
class DepartmentPickerField extends ConsumerWidget {
  const DepartmentPickerField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(departmentsProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            adminText(
              context,
              'Could not load departments.',
              'تعذّر تحميل الأقسام.',
            ),
          ),
          data: (list) => DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: adminText(context, 'Department', 'القسم'),
            ),
            items: [
              for (final d in list)
                DropdownMenuItem(value: d.id, child: Text(d.name)),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        );
  }
}
