/// Payments — one screen for the patient's wallet balance, invoices and
/// saved cards. Balance (+ top-up) at the top, invoices below, payment
/// methods at the bottom: one place, not three.
///
/// Adaptive per DESIGN.md §6: a single column on compact, a two-column grid of
/// receipt cards from medium up, capped at the shared max content width.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/billing_providers.dart';
import 'pay_invoice_sheet.dart';
import 'payment_methods_section.dart';
import 'wallet_topup_sheet.dart';

String money(double amount) => 'BD ${amount.toStringAsFixed(2)}';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({this.embedded = false, super.key});

  /// When true, render the list without a Scaffold/AppBar — the Health
  /// Records screen supplies those.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);

    final body = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientInvoicesProvider);
        ref.invalidate(walletBalanceProvider);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: _body(context, ref, size),
        ),
      ),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.paymentsTitle),
        actions: const [PatientTopActions()],
      ),
      body: body,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, WindowSize size) {
    final t = AppLocalizations.of(context)!;
    final invoices = ref.watch(patientInvoicesProvider);
    final gutter = size.gutter;
    return invoices.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: t.couldNotLoadInvoices,
        onRetry: () => ref.invalidate(patientInvoicesProvider),
      ),
      data: (list) {
        final open = list.where((i) => i.isOutstanding).toList();
        final settled = list.where((i) => !i.isOutstanding).toList();

        return ListView(
          padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.xxl),
          children: [
            const _BalanceCard(),
            const SizedBox(height: Space.lg),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                message: t.noInvoicesYet,
              )
            else ...[
              if (open.isNotEmpty) ...[
                SectionHeader(t.openSectionLabel, overline: true),
                _InvoiceGrid(invoices: open, compact: size.isCompact),
                const SizedBox(height: Space.lg),
              ],
              if (settled.isNotEmpty) ...[
                SectionHeader(t.historyLabel, overline: true),
                _InvoiceGrid(invoices: settled, compact: size.isCompact),
                const SizedBox(height: Space.lg),
              ],
            ],
            const Divider(height: 1),
            const SizedBox(height: Space.lg),
            const PaymentMethodsSection(),
          ],
        );
      },
    );
  }
}

/// Wallet balance (with a Top Up button) and, when relevant, what's still
/// owed — one card, so there's a single "balance" the patient sees at a
/// glance.
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(walletBalanceProvider);
    final summary = ref.watch(billingSummaryProvider).valueOrNull;

    if (!balanceAsync.hasValue) return const LoadingSkeleton(height: 120);
    final balance = balanceAsync.value!;

    return AppCard(
      color: scheme.primaryContainer,
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
                      t.walletBalanceLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      money(balance),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showWalletTopUpSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.topUpButton),
              ),
            ],
          ),
          if (summary != null && summary.outstanding > 0) ...[
            const SizedBox(height: Space.sm),
            const Divider(height: 1),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    t.openInvoicesCount(summary.openCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  money(summary.outstanding),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            if (summary.overdue > 0) ...[
              const SizedBox(height: Space.xs),
              Text(
                t.overdueAmount(money(summary.overdue)),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.clinicalStatus.riskHigh.onContainer,
                ),
              ),
            ],
          ],
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
    final t = AppLocalizations.of(context)!;

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
                        t.issuedOn(fmtDate(invoice.issuedAt)),
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
            _AmountRow(label: t.subtotalLabel, value: money(invoice.subtotal)),
            _AmountRow(
              label: t.taxLabel(invoice.taxRate.toStringAsFixed(0)),
              value: money(invoice.taxAmount),
            ),
            _AmountRow(
              label: t.totalLabel,
              value: money(invoice.totalAmount),
              emphasised: true,
            ),
            if (invoice.dueDate != null && invoice.isPayable) ...[
              const SizedBox(height: Space.xs),
              Text(
                invoice.isOverdue
                    ? t.wasDueOn(fmtDate(invoice.dueDate!))
                    : t.dueOn(fmtDate(invoice.dueDate!)),
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
                '${t.paidOn(fmtDate(invoice.paidAt!))}'
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
                  label: Text(t.payAmountButton(money(invoice.totalAmount))),
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

    final (bg, fg) = switch (invoice) {
      Invoice(status: InvoiceStatus.paid) => (
        theme.clinicalStatus.riskLow.container,
        theme.clinicalStatus.riskLow.onContainer,
      ),
      Invoice(status: InvoiceStatus.cancelled) => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      _ when invoice.isOverdue => (
        theme.clinicalStatus.riskHigh.container,
        theme.clinicalStatus.riskHigh.onContainer,
      ),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    final label = invoiceStatusLabel(
      context,
      invoice.status,
      overdue: invoice.isOverdue,
    );

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
