/// The staff dashboard "Quick actions" grid (staff-dashboard rebuild).
///
/// Every clinical shortcut lives here — chart writes (note / prescribe / lab),
/// transferring a visit, the panel scan, and jumps to the directory, activity
/// log and analytics. New staff features are added as tiles here.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../care/application/care_providers.dart';
import '../../patient_chart/presentation/chart_write_sheets.dart';
import '../application/staff_providers.dart';

class StaffQuickActions extends ConsumerWidget {
  const StaffQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.note_add_outlined,
        label: 'New note',
        onTap: () => _pickPatientThen(
          context,
          ref,
          title: 'Add a clinical note for…',
          then: showChartNoteSheet,
        ),
      ),
      _QuickAction(
        icon: Icons.medication_outlined,
        label: 'Prescribe',
        onTap: () => _pickPatientThen(
          context,
          ref,
          title: 'Prescribe for…',
          then: showPrescribeSheet,
        ),
      ),
      _QuickAction(
        icon: Icons.science_outlined,
        label: 'Lab result',
        onTap: () => _pickPatientThen(
          context,
          ref,
          title: 'Enter a lab result for…',
          then: showLabResultSheet,
        ),
      ),
      _QuickAction(
        icon: Icons.swap_horiz,
        label: 'Transfer visit',
        onTap: () => unawaited(showTransferSheet(context, ref)),
      ),
      _QuickAction(
        icon: Icons.auto_awesome,
        label: 'AI Scribe',
        onTap: () => _pickPatientThenGo(
          context,
          ref,
          title: 'Scribe a visit note for…',
          route: (id) => '${AppRoutes.staffScribe}?patient=$id',
        ),
      ),
      _QuickAction(
        icon: Icons.summarize_outlined,
        label: 'Patient summary',
        onTap: () => _pickPatientThenGo(
          context,
          ref,
          title: 'Summarise…',
          route: AppRoutes.staffPatientSummary,
        ),
      ),
      _QuickAction(
        icon: Icons.person_search_outlined,
        label: 'Patient lookup',
        onTap: () => context.go(AppRoutes.staffPatients),
      ),
      _QuickAction(
        icon: Icons.forum_outlined,
        label: switch (ref.watch(staffUnreadCountProvider)) {
          0 => 'Messages',
          final n => 'Messages ($n)',
        },
        onTap: () => unawaited(context.push(AppRoutes.staffInbox)),
      ),
      _QuickAction(
        icon: Icons.radar,
        label: 'Panel scan',
        onTap: () => unawaited(_runPanelScan(context, ref)),
      ),
    ];

    // Two tiles per row on a phone, three once there's room — the same shape
    // the patient dashboard uses for its Quick actions.
    return GridView.count(
      crossAxisCount: WindowSize.of(context).isCompact ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
      childAspectRatio: 2.6,
      children: [for (final a in actions) _QuickActionTile(action: a)],
    );
  }

  Future<void> _runPanelScan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Scanning the panel for risks…')),
      );
    final count = await ref.read(staffOpsProvider).refreshPanel();
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Panel scan complete — $count open flag(s).')),
      );
  }

  Future<void> _pickPatientThen(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<void> Function(BuildContext, String) then,
  }) async {
    final patientId = await showPatientPicker(context, ref, title: title);
    if (patientId != null && context.mounted) {
      await then(context, patientId);
    }
  }

  Future<void> _pickPatientThenGo(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String Function(String id) route,
  }) async {
    final patientId = await showPatientPicker(context, ref, title: title);
    if (patientId != null && context.mounted) {
      unawaited(context.push(route(patientId)));
    }
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.sm,
      ),
      onTap: action.onTap,
      child: Row(
        children: [
          // A tinted medallion rather than a bare glyph — it anchors the row
          // and reads as an object you can press.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: Radii.chip,
            ),
            child: Icon(action.icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// --- patient picker ------------------------------------------------------

Future<String?> showPatientPicker(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _PatientPickerSheet(title: title),
    ),
  );
}

class _PatientPickerSheet extends ConsumerStatefulWidget {
  const _PatientPickerSheet({required this.title});
  final String title;

  @override
  ConsumerState<_PatientPickerSheet> createState() =>
      _PatientPickerSheetState();
}

class _PatientPickerSheetState extends ConsumerState<_PatientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(patientPickerResultsProvider(_query));
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + viewInsets),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.md),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by name or national ID',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: Space.sm),
          Expanded(
            child: results.when(
              loading: () => const LoadingSkeleton(height: 120),
              error: (e, _) =>
                  const InlineBanner.error('Could not load patients.'),
              data: (patients) {
                if (patients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: Text('No patients match that search.'),
                  );
                }
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, i) {
                    final p = patients[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          _initials(p.fullName),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      title: Text(p.fullName),
                      subtitle: p.user.nationalId == null
                          ? null
                          : Text('ID ${p.user.nationalId}'),
                      onTap: () => Navigator.of(context).pop(p.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) => name
    .split(' ')
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => s[0])
    .join();

// --- transfer sheet -----------------------------------------------------

Future<void> showTransferSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _TransferSheet(),
  );
}

class _TransferSheet extends ConsumerStatefulWidget {
  const _TransferSheet();

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  Appointment? _appointment;
  String? _targetStaffId;
  bool _busy = false;

  Future<void> _submit() async {
    final appt = _appointment;
    final target = _targetStaffId;
    if (appt == null || target == null) return;
    setState(() => _busy = true);
    final result = await ref
        .read(staffOpsProvider)
        .transferAppointment(id: appt.id, toStaffId: target);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => 'Visit transferred.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
    if (result.isOk) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = ref.watch(staffQueueProvider);
    final directory = ref.watch(staffDirectoryProvider);
    final me = ref.watch(staffProfileProvider).valueOrNull?.id;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + viewInsets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Transfer a visit', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              'Reassign a visit from today to another clinician. It returns to '
              '"booked" so they can re-accept it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            queue.when(
              loading: () => const LoadingSkeleton(height: 56),
              error: (e, _) =>
                  const InlineBanner.error('Could not load your queue.'),
              data: (appts) {
                if (appts.isEmpty) {
                  return const InlineBanner.info(
                    'Nothing in your queue to transfer.',
                  );
                }
                return DropdownButtonFormField<Appointment>(
                  initialValue: _appointment,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Visit'),
                  items: [
                    for (final a in appts)
                      DropdownMenuItem(
                        value: a,
                        child: Text(
                          '${fmtTime(a.slotStart)} · '
                          '${a.ticketTag ?? visitTypeLabel(a.visitType)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _appointment = v),
                );
              },
            ),
            const SizedBox(height: Space.sm),
            directory.when(
              loading: () => const LoadingSkeleton(height: 56),
              error: (e, _) =>
                  const InlineBanner.error('Could not load the directory.'),
              data: (staff) {
                final others = staff.where((s) => s.id != me).toList();
                return DropdownButtonFormField<String>(
                  initialValue: _targetStaffId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Transfer to'),
                  items: [
                    for (final s in others)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.fullName}'
                          '${s.specialty == null ? '' : ' · ${s.specialty}'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _targetStaffId = v),
                );
              },
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed:
                  (_busy || _appointment == null || _targetStaffId == null)
                  ? null
                  : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Transfer visit'),
            ),
          ],
        ),
      ),
    );
  }
}
