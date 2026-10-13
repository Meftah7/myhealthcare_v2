/// Dental chart (FDI) for one patient: a tooth grid showing what has been
/// observed, planned and completed, and an append-only entry form bound to
/// one of the patient's visits with this dentist.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/identity/permissions.dart';
import '../../../domain/repositories/dental_chart_repository.dart';
import '../../auth/application/session.dart';
import '../../tasks/presentation/task_detail_screen.dart' show workText;
import '../application/chart_providers.dart';

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final dentalEntriesProvider = FutureProvider.autoDispose
    .family<List<DentalEntry>, String>(
      (ref, patientId) async => _unwrap(
        await ref.watch(dentalChartRepositoryProvider).forPatient(patientId),
      ),
    );

/// This patient's non-cancelled visits with the signed-in clinician.
final _myVisitsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, String>((ref, patientId) async {
      final me = ref.watch(currentUserProvider)?.id;
      final all = _unwrap(
        await ref.watch(appointmentRepositoryProvider).forPatient(patientId),
      );
      return [
        for (final a in all)
          if (a.staffId == me && a.status != AppointmentStatus.cancelled) a,
      ]..sort((a, b) => b.slotStart.compareTo(a.slotStart));
    });

String _kindLabel(BuildContext c, DentalEntryKind k) => switch (k) {
  DentalEntryKind.observation => workText(c, 'Observation', 'ملاحظة'),
  DentalEntryKind.planned => workText(c, 'Planned', 'مخطط'),
  DentalEntryKind.completed => workText(c, 'Completed', 'مكتمل'),
};

/// The tooth's state from its entries: completed beats planned beats seen.
DentalEntryKind? _toothState(List<DentalEntry> entries) {
  final planned = {
    for (final e in entries)
      if (e.kind == DentalEntryKind.planned) e.id,
  };
  final fulfilled = {
    for (final e in entries)
      if (e.fulfilsId != null) e.fulfilsId!,
  };
  if (planned.difference(fulfilled).isNotEmpty) return DentalEntryKind.planned;
  if (entries.any((e) => e.kind == DentalEntryKind.completed)) {
    return DentalEntryKind.completed;
  }
  if (entries.isNotEmpty) return DentalEntryKind.observation;
  return null;
}

class DentalChartScreen extends ConsumerWidget {
  const DentalChartScreen({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(chartPatientProvider(patientId)).valueOrNull;
    final entries = ref.watch(dentalEntriesProvider(patientId));
    final canWrite = ref.watch(canProvider(Permission.recordDentalChart));
    return AppScaffold(
      title: workText(context, 'Dental chart', 'مخطط الأسنان'),
      heroOverline: patient?.fullName,
      onRefresh: () async => ref.invalidate(dentalEntriesProvider(patientId)),
      children: [
        Text(
          workText(
            context,
            'FDI numbering, viewed facing the patient. Entries are permanent; record a new entry to correct one.',
            'ترقيم FDI بالنظر إلى المريض. الإدخالات دائمة؛ سجّل إدخالًا جديدًا للتصحيح.',
          ),
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.xs,
          children: [
            for (final k in DentalEntryKind.values)
              StatusBadge(
                _kindLabel(context, k),
                accent: _accent(k),
                icon: _icon(k),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        entries.when(
          loading: () => const PatientStateView(kind: PatientStateKind.loading),
          error: (e, _) => PatientStateView(
            kind: PatientStateKind.error,
            message: e is Exception || e is Error
                ? '$e'
                : (e as dynamic).message as String? ?? '$e',
            actionLabel: workText(context, 'Retry', 'إعادة المحاولة'),
            onAction: () => ref.invalidate(dentalEntriesProvider(patientId)),
          ),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, row) in [
                (workText(context, 'Upper', 'العلوي'), fdiUpper),
                (workText(context, 'Lower', 'السفلي'), fdiLower),
              ]) ...[
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final tooth in row)
                      _ToothButton(
                        tooth: tooth,
                        state: _toothState([
                          for (final e in list)
                            if (e.tooth == tooth) e,
                        ]),
                        onTap: () => unawaited(
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => _ToothSheet(
                              patientId: patientId,
                              tooth: tooth,
                              entries: [
                                for (final e in list)
                                  if (e.tooth == tooth) e,
                              ],
                              canWrite: canWrite,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

PatientAccent _accent(DentalEntryKind? k) => switch (k) {
  null => PatientAccent.neutral,
  DentalEntryKind.observation => PatientAccent.blue,
  DentalEntryKind.planned => PatientAccent.amber,
  DentalEntryKind.completed => PatientAccent.green,
};

IconData _icon(DentalEntryKind k) => switch (k) {
  DentalEntryKind.observation => Icons.visibility_outlined,
  DentalEntryKind.planned => Icons.event_note_outlined,
  DentalEntryKind.completed => Icons.check,
};

class _ToothButton extends StatelessWidget {
  const _ToothButton({
    required this.tooth,
    required this.state,
    required this.onTap,
  });

  final int tooth;
  final DentalEntryKind? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _accent(state).colors(PatientPalette.of(context));
    final s = state;
    return Semantics(
      button: true,
      label:
          workText(context, 'Tooth $tooth', 'السن $tooth') +
          (s == null ? '' : ', ${_kindLabel(context, s)}'),
      excludeSemantics: true,
      child: Material(
        color: s == null ? Theme.of(context).colorScheme.surface : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: PatientPalette.of(context).divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          // Minimum (not fixed) size: grows with the text scale.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$tooth',
                    style: TextStyle(color: s == null ? null : fg),
                  ),
                  // State is shown by icon too, not by colour alone.
                  if (s != null) Icon(_icon(s), size: 14, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToothSheet extends ConsumerStatefulWidget {
  const _ToothSheet({
    required this.patientId,
    required this.tooth,
    required this.entries,
    required this.canWrite,
  });

  final String patientId;
  final int tooth;
  final List<DentalEntry> entries;
  final bool canWrite;

  @override
  ConsumerState<_ToothSheet> createState() => _ToothSheetState();
}

class _ToothSheetState extends ConsumerState<_ToothSheet> {
  final _key = IdempotencyKey.generate();
  final _note = TextEditingController();
  final _surface = TextEditingController();
  DentalEntryKind _kind = DentalEntryKind.observation;
  String? _visitId;
  String? _fulfils;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _surface.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final visit = _visitId;
    if (_busy || visit == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(dentalChartRepositoryProvider)
        .add(
          NewDentalEntry(
            patientId: widget.patientId,
            appointmentId: visit,
            tooth: widget.tooth,
            kind: _kind,
            note: _note.text,
            surface: _surface.text,
            fulfilsId: _kind == DentalEntryKind.completed ? _fulfils : null,
            idempotencyKey: _key.value,
          ),
        );
    if (!mounted) return;
    switch (r) {
      case Ok():
        ref.invalidate(dentalEntriesProvider(widget.patientId));
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fulfilled = {
      for (final e in widget.entries)
        if (e.fulfilsId != null) e.fulfilsId!,
    };
    final openPlans = [
      for (final e in widget.entries)
        if (e.kind == DentalEntryKind.planned && !fulfilled.contains(e.id)) e,
    ];
    final visits = widget.canWrite
        ? ref.watch(_myVisitsProvider(widget.patientId))
        : null;
    return Padding(
      padding: EdgeInsets.only(
        left: Space.md,
        right: Space.md,
        top: Space.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              workText(
                context,
                'Tooth ${widget.tooth}',
                'السن ${widget.tooth}',
              ),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Space.sm),
            if (widget.entries.isEmpty)
              Text(
                workText(
                  context,
                  'Nothing recorded yet.',
                  'لا يوجد شيء مسجل بعد.',
                ),
              )
            else
              for (final e in widget.entries.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_icon(e.kind)),
                  title: Text(
                    '${_kindLabel(context, e.kind)}'
                    '${e.surface == null ? '' : ' · ${e.surface}'}'
                    '${fulfilled.contains(e.id) ? ' · ${workText(context, 'done', 'تم')}' : ''}',
                  ),
                  subtitle: Text(
                    '${e.note}\n${fmtDate(e.createdAt)} ${fmtTime(e.createdAt)}',
                  ),
                ),
            if (widget.canWrite) ...[
              const Divider(),
              Text(
                workText(context, 'Add entry', 'إضافة إدخال'),
                style: theme.textTheme.titleMedium,
              ),
              SegmentedButton<DentalEntryKind>(
                segments: [
                  for (final k in DentalEntryKind.values)
                    ButtonSegment(
                      value: k,
                      label: Text(_kindLabel(context, k)),
                    ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.single),
              ),
              if (_kind == DentalEntryKind.completed && openPlans.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: _fulfils,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: workText(
                      context,
                      'Completes plan',
                      'يُكمل الخطة',
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      child: Text(workText(context, 'None', 'لا شيء')),
                    ),
                    for (final p in openPlans)
                      DropdownMenuItem(value: p.id, child: Text(p.note)),
                  ],
                  onChanged: (v) => setState(() => _fulfils = v),
                ),
              visits!.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (list) => list.isEmpty
                    ? Text(
                        workText(
                          context,
                          'You have no visit with this patient to record against.',
                          'لا توجد لديك زيارة مع هذا المريض للتسجيل عليها.',
                        ),
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _visitId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: workText(context, 'Visit', 'الزيارة'),
                        ),
                        items: [
                          for (final a in list)
                            DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${fmtDate(a.slotStart)} ${fmtTime(a.slotStart)} · ${visitTypeLabel(a.visitType)}',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _visitId = v),
                      ),
              ),
              TextField(
                controller: _surface,
                decoration: InputDecoration(
                  labelText: workText(
                    context,
                    'Surface (optional, e.g. O, M, D)',
                    'السطح (اختياري، مثل O أو M أو D)',
                  ),
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 1000,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: workText(context, 'Note', 'ملاحظة'),
                ),
              ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              PrimaryActionButton(
                label: workText(context, 'Save entry', 'حفظ الإدخال'),
                busy: _busy,
                onPressed: _visitId != null && !_busy
                    ? () => unawaited(_save())
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
