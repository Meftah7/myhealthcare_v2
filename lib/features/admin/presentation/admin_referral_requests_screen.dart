/// Admin queue for doctor→admin referral requests. The doctor supplied a
/// clinical reason mid-consultation; here the admin decides department-vs-
/// hospital and the exact target, then executes it (a department referral
/// opens a walk-in ticket; a hospital referral produces a downloadable letter).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

class AdminReferralRequestsScreen extends ConsumerWidget {
  const AdminReferralRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(pendingReferralRequestsProvider);
    final patients =
        ref.watch(adminPatientNamesProvider).valueOrNull ?? const {};
    final doctors =
        ref.watch(referralRequesterNamesProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: 'Referral requests',
      actions: const [AdminTopActions()],
      onRefresh: () async => ref.invalidate(pendingReferralRequestsProvider),
      body: queue.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load the queue.',
          onRetry: () => ref.invalidate(pendingReferralRequestsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.forward_to_inbox_outlined,
              message: 'No referral requests waiting.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) => _RequestCard(
                  request: list[i],
                  patientName: patients[list[i].patientId] ?? 'Patient',
                  doctorName:
                      doctors[list[i].requestedByStaffId] ?? 'A clinician',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({
    required this.request,
    required this.patientName,
    required this.doctorName,
  });

  final ReferralRequest request;
  final String patientName;
  final String doctorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(patientName, style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.xxs),
          Text(
            'Requested by $doctorName · ${fmtDate(request.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(request.reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _action(context, ref),
                  child: const Text('Action'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<Result<MedicalRecord>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ActionSheet(request: request, patientName: patientName),
      ),
    );
    if (result == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => '$patientName referred.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this request'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Why is no referral needed?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (note == null || !context.mounted) return;
    await ref
        .read(adminActionsProvider)
        .rejectReferralRequest(id: request.id, note: note);
  }
}

class _ActionSheet extends ConsumerStatefulWidget {
  const _ActionSheet({required this.request, required this.patientName});

  final ReferralRequest request;
  final String patientName;

  @override
  ConsumerState<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends ConsumerState<_ActionSheet> {
  bool _external = false;
  String? _departmentId;
  String _hospital = kReferralHospitals.first;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _valid => _external || _departmentId != null;

  Future<void> _submit(List<Department> departments) async {
    setState(() => _busy = true);
    final dept = _external
        ? null
        : departments.firstWhere((d) => d.id == _departmentId);
    final result = await ref
        .read(adminActionsProvider)
        .actionReferralRequest(
          request: widget.request,
          destination: _external ? _hospital : dept!.name,
          external: _external,
          departmentId: _external ? null : _departmentId,
          decisionNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departments = ref.watch(departmentsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Action referral', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xxs),
            Text(
              widget.patientName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            Container(
              padding: const EdgeInsets.all(Space.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: Radii.cardSmall,
              ),
              child: Text(
                widget.request.reason,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: Space.md),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Another department')),
                ButtonSegment(value: true, label: Text('Another hospital')),
              ],
              selected: {_external},
              onSelectionChanged: (s) => setState(() => _external = s.first),
            ),
            const SizedBox(height: Space.md),
            if (_external)
              DropdownButtonFormField<String>(
                initialValue: _hospital,
                decoration: const InputDecoration(labelText: 'Hospital'),
                items: [
                  for (final h in kReferralHospitals)
                    DropdownMenuItem(value: h, child: Text(h)),
                ],
                onChanged: (v) => setState(() => _hospital = v ?? _hospital),
              )
            else
              departments.maybeWhen(
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _departmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: [
                    for (final d in list)
                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => _departmentId = v),
                ),
                orElse: () => const LoadingSkeleton(height: 56),
              ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note for the record (optional)',
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || !_valid)
                  ? null
                  : () => _submit(departments.valueOrNull ?? const []),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Refer patient'),
            ),
          ],
        ),
      ),
    );
  }
}
