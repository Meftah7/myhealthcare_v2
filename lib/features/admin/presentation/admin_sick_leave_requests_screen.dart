/// Admin queue for sick leave doctors requested from a visit. Approving
/// makes it the patient's certificate (and tells them); rejecting needs a
/// reason, which the doctor is told. Until approved, the patient sees nothing.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

class AdminSickLeaveRequestsScreen extends ConsumerWidget {
  const AdminSickLeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final queue = ref.watch(pendingSickLeaveRequestsProvider);
    final patients =
        ref.watch(adminPatientNamesProvider).valueOrNull ?? const {};
    final doctors =
        ref.watch(referralRequesterNamesProvider).valueOrNull ?? const {};

    return AppScaffold(
      title: t.sickLeaveRequestsTitle,
      actions: const [AdminTopActions()],
      onRefresh: () async => ref.invalidate(pendingSickLeaveRequestsProvider),
      body: queue.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadQueue,
          onRetry: () => ref.invalidate(pendingSickLeaveRequestsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.sick_outlined,
              message: t.noSickLeaveRequests,
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
                  patientName: patients[list[i].patientId] ?? t.rolePatient,
                  doctorName:
                      doctors[list[i].issuedByStaffId] ?? t.aClinicianFallback,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({
    required this.request,
    required this.patientName,
    required this.doctorName,
  });

  final SickLeaveCertificate request;
  final String patientName;
  final String doctorName;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _run(
    Future<Result<Object?>> Function() action,
    String ok,
  ) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context)!;
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => ok,
          Err(:final failure) => describeFailure(t, failure).message,
        }),
      ),
    );
    if (result.isOk) ref.invalidate(pendingSickLeaveRequestsProvider);
  }

  Future<void> _reject() async {
    final t = AppLocalizations.of(context)!;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    await _run(
      () => ref
          .read(sickLeaveRepositoryProvider)
          .reject(widget.request.id, reason: reason.trim()),
      t.sickLeaveRejectedSnackbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final df = MaterialLocalizations.of(context);
    final r = widget.request;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.patientName, style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.xxs),
          Text(
            t.sickLeaveDates(
              df.formatMediumDate(r.fromDate),
              df.formatMediumDate(r.toDate),
              r.days,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(r.diagnosis, style: theme.textTheme.bodyLarge),
          if (r.notes != null && r.notes!.isNotEmpty) ...[
            const SizedBox(height: Space.xxs),
            Text(
              r.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Space.xs),
          Text(
            t.sickLeaveRequestedBy(widget.doctorName),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                key: ValueKey('reject-sick-${r.id}'),
                onPressed: _busy ? null : () => unawaited(_reject()),
                icon: const Icon(Icons.block_outlined, size: 18),
                label: Text(t.rejectAction),
              ),
              FilledButton.icon(
                key: ValueKey('approve-sick-${r.id}'),
                onPressed: _busy
                    ? null
                    : () => unawaited(
                        _run(
                          () => ref
                              .read(sickLeaveRepositoryProvider)
                              .approve(r.id),
                          t.sickLeaveApprovedSnackbar,
                        ),
                      ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(t.approveAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks why the sick leave isn't approved; the doctor is told this reason.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.rejectSickLeaveTitle),
      content: TextField(
        controller: _reason,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(hintText: t.rejectReasonHint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_reason.text),
          child: Text(t.rejectAction),
        ),
      ],
    );
  }
}
