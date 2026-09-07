/// Admin → billing overview (ported from the FirstSemMyHealth admin "Billing"
/// view): every invoice across all patients, filterable by status, with
/// mark-paid / cancel actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../application/admin_providers.dart';
import 'admin_top_actions.dart';

class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  ConsumerState<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen> {
  InvoiceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoices = ref.watch(allInvoicesProvider(_filter));
    final names = ref.watch(adminPatientNamesProvider).valueOrNull ?? const {};
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: const [AdminTopActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
            child: Row(
              children: [
                for (final (label, value) in const [
                  ('All', null),
                  ('Open', InvoiceStatus.pending),
                  ('Paid', InvoiceStatus.paid),
                  ('Cancelled', InvoiceStatus.cancelled),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: FilterChip(
                      label: Text(label),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: invoices.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load invoices.',
          onRetry: () => ref.invalidate(allInvoicesProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No invoices in this view.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.sm,
                  gutter,
                  Space.xxl,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
                itemBuilder: (context, i) {
                  final inv = list[i];
                  return _InvoiceCard(
                    invoice: inv,
                    patientName: names[inv.patientId],
                    theme: theme,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.patientName,
    required this.theme,
  });

  final Invoice invoice;
  final String? patientName;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = theme.colorScheme;
    final open = invoice.status == InvoiceStatus.pending;

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  patientName ?? 'Patient',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              _StatusChip(invoice.status),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'BD ${invoice.totalAmount.toStringAsFixed(2)} · '
            'issued ${fmtDate(invoice.issuedAt)}'
            '${invoice.dueDate == null ? '' : ' · due ${fmtDate(invoice.dueDate!)}'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(invoice.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (open) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => _set(context, ref, InvoiceStatus.paid),
                  child: const Text('Mark paid'),
                ),
                const SizedBox(width: Space.xs),
                TextButton(
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      title: 'Cancel this invoice?',
                      message: 'The patient will no longer owe it.',
                      confirmLabel: 'Cancel invoice',
                      destructive: true,
                    );
                    if (ok && context.mounted) {
                      await _set(context, ref, InvoiceStatus.cancelled);
                    }
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    InvoiceStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref
        .read(adminActionsProvider)
        .setInvoiceStatus(id: invoice.id, status: status);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => 'Invoice marked ${status.name}.',
          Err(:final failure) => failure.message,
        }),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramp = theme.clinicalStatus;
    final (label, style) = switch (status) {
      InvoiceStatus.paid => ('Paid', ramp.riskLow),
      InvoiceStatus.pending => ('Open', ramp.severityWarning),
      InvoiceStatus.cancelled => ('Cancelled', ramp.labNormal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(color: style.container, borderRadius: Radii.chip),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: style.onContainer),
      ),
    );
  }
}
