/// Home health care — the patient requests a clinician visit at home and
/// tracks its status (P10-08).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/application/patient_data_providers.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/care_providers.dart';
import 'home_visit_status.dart';

class HomeVisitScreen extends ConsumerWidget {
  const HomeVisitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(patientHomeVisitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home health care'),
        actions: const [PatientTopActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Request a visit'),
      ),
      body: requests.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load your requests.',
          onRetry: () => ref.invalidate(patientHomeVisitsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.home_outlined,
              message: 'No home-visit requests.\nAsk for a clinician to visit '
                  'you at home when getting to the clinic is hard.',
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
                itemBuilder: (context, i) =>
                    _RequestCard(request: list[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _RequestForm(),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final HomeVisitRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Preferred ${fmtDate(request.preferredDate)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              HomeVisitStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            request.reasonText,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.xxs),
              Expanded(
                child: Text(
                  request.addressText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (request.decisionNote != null &&
              request.decisionNote!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: Radii.cardSmall,
              ),
              child: Text(
                'Clinic: ${request.decisionNote}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (request.isOpen &&
              request.status == HomeVisitStatus.requested) ...[
            const SizedBox(height: Space.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _cancel(context, ref),
                child: const Text('Cancel request'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(homeVisitActionsProvider)
        .cancel(request.id);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm();

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final _address = TextEditingController();
  final _reason = TextEditingController();
  late DateTime _date = DateTime.now().add(const Duration(days: 2));
  String? _departmentId;
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref
        .read(homeVisitActionsProvider)
        .request(
          address: _address.text.trim(),
          preferredDate: _date,
          reason: _reason.text.trim(),
          departmentId: _departmentId,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to the clinic.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        ref.watch(departmentDirectoryProvider).valueOrNull ?? const {};
    final df = MaterialLocalizations.of(context);
    final canSubmit =
        _address.text.trim().isNotEmpty && _reason.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request a home visit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _address,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Home address',
                hintText: 'Building, road, block, area',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Why is a home visit needed?',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.sm),
            if (departments.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: _departmentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                ),
                items: [
                  const DropdownMenuItem(child: Text('Not sure')),
                  for (final entry in departments.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text('Preferred date: ${df.formatMediumDate(_date)}'),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: (_busy || !canSubmit) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send request'),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'The clinic will confirm a time or follow up with you.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
