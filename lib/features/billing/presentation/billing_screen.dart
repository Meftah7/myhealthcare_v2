/// Billing — the patient's invoices, and settling an open one.
///
/// Adaptive per DESIGN.md §6: a single column on compact, a two-column grid of
/// receipt cards from medium up, capped at the shared max content width.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/billing_providers.dart';
import 'pay_invoice_sheet.dart';

String money(double amount) => 'BD ${amount.toStringAsFixed(2)}';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({this.embedded = false, super.key});

  /// When true, render the list without a Scaffold/AppBar — the Health Records
  /// screen supplies those.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);

    final body = RefreshIndicator(
      onRefresh: () async => ref.invalidate(patientInvoicesProvider),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: _list(context, ref, size),
        ),
      ),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: const [PatientTopActions()],
      ),
      body: body,
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, WindowSize size) {
    final invoices = ref.watch(patientInvoicesProvider);
    final gutter = size.gutter;
    return invoices.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                message: 'Could not load your invoices.',
                onRetry: () => ref.invalidate(patientInvoicesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.all(gutter),
                    children: const [
                      SizedBox(height: Space.xxl),
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message:
                            'No invoices yet.\nBills for your visits will appear here.',
                      ),
                    ],
                  );
                }

                final open = list.where((i) => i.isOutstanding).toList();
                final settled = list.where((i) => !i.isOutstanding).toList();

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    Space.md,
                    gutter,
                    Space.xxl,
                  ),
                  children: [
                    const _BillingSummaryCard(),
                    const SizedBox(height: Space.lg),
                    if (open.isNotEmpty) ...[
                      const SectionHeader('Open', overline: true),
                      _InvoiceGrid(invoices: open, compact: size.isCompact),
                      const SizedBox(height: Space.lg),
                    ],
                    if (settled.isNotEmpty) ...[
                      const SectionHeader('History', overline: true),
                      _InvoiceGrid(invoices: settled, compact: size.isCompact),
                    ],
                  ],
                );
              },
    );
  }
}

/// Outstanding balance at a glance, with an overdue call-out when relevant.
class _BillingSummaryCard extends ConsumerWidget {
  const _BillingSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ref.watch(billingSummaryProvider).valueOrNull;
    if (summary == null) return const LoadingSkeleton(height: 92);

    final owes = summary.outstanding > 0;
    return AppCard(
      color: owes ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owes ? 'Outstanding balance' : 'All settled',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: owes
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  money(summary.outstanding),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: owes
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                if (summary.openCount > 0) ...[
                  const SizedBox(height: Space.xxs),
                  Text(
                    '${summary.openCount} open '
                    '${summary.openCount == 1 ? 'invoice' : 'invoices'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
                if (summary.overdue > 0) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    '${money(summary.overdue)} overdue',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.clinicalStatus.riskHigh.onContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            owes ? Icons.account_balance_wallet_outlined : Icons.verified_outlined,
            size: 36,
            color: owes ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// One column on compact, two from medium up.
class _InvoiceGrid extends StatelessWidget {
  const _InvoiceGrid({required this.invoices, required this.compact});

  final List<Invoice> invoices;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [for (final i in invoices) _InvoiceCard(i)],
      );
    }
    return Column(
      children: [
        for (var row = 0; row < invoices.length; row += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InvoiceCard(invoices[row])),
              const SizedBox(width: Space.sm),
              Expanded(
                child: row + 1 < invoices.length
                    ? _InvoiceCard(invoices[row + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard(this.invoice);

  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        money(invoice.totalAmount),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Issued ${fmtDate(invoice.issuedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _InvoiceStatusChip(invoice),
              ],
            ),
            if (invoice.notes != null) ...[
              const SizedBox(height: Space.xs),
              Text(invoice.notes!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: Space.sm),
            const Divider(height: 1),
            const SizedBox(height: Space.sm),
            _AmountRow(label: 'Subtotal', value: money(invoice.subtotal)),
            _AmountRow(
              label: 'Tax (${invoice.taxRate.toStringAsFixed(0)}%)',
              value: money(invoice.taxAmount),
            ),
            _AmountRow(
              label: 'Total',
              value: money(invoice.totalAmount),
              emphasised: true,
            ),
            if (invoice.dueDate != null && invoice.isPayable) ...[
              const SizedBox(height: Space.xs),
              Text(
                invoice.isOverdue
                    ? 'Was due ${fmtDate(invoice.dueDate!)}'
                    : 'Due ${fmtDate(invoice.dueDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: invoice.isOverdue
                      ? theme.clinicalStatus.riskHigh.onContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (invoice.paidAt != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                'Paid ${fmtDate(invoice.paidAt!)}'
                '${invoice.paymentMethod == null ? '' : ' · ${invoice.paymentMethod}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (invoice.isPayable) ...[
              const SizedBox(height: Space.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showPayInvoiceSheet(context, invoice),
                  icon: const Icon(Icons.credit_card),
                  label: Text('Pay ${money(invoice.totalAmount)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasised
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: Space.sm),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _InvoiceStatusChip extends StatelessWidget {
  const _InvoiceStatusChip(this.invoice);

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (label, bg, fg) = switch (invoice) {
      Invoice(status: InvoiceStatus.paid) => (
        'Paid',
        theme.clinicalStatus.riskLow.container,
        theme.clinicalStatus.riskLow.onContainer,
      ),
      Invoice(status: InvoiceStatus.cancelled) => (
        'Cancelled',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      _ when invoice.isOverdue => (
        'Overdue',
        theme.clinicalStatus.riskHigh.container,
        theme.clinicalStatus.riskHigh.onContainer,
      ),
      _ => ('Pending', scheme.primaryContainer, scheme.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.chip),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
