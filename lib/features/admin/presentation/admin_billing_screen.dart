/// Admin → billing overview (ported from the FirstSemMyHealth admin "Billing"
/// view): every invoice across all patients, filterable by status.
///
/// Phase 5: an invoice is never "marked paid" by hand. Money taken at the
/// desk is recorded as a payment with its receipt number; a paid invoice
/// shows the payment history behind it and can be refunded (with a reason);
/// unconfirmed card payments are reconciled against the provider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admin_workspace_screens.dart';

import '../../../app/theme/theme.dart';
import '../../../core/data/contracts.dart';
import '../../../core/i18n/enum_labels.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/presentation/payment_history.dart';
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final invoices = ref.watch(allInvoicesProvider(_filter));
    final names = ref.watch(adminPatientNamesProvider).valueOrNull ?? const {};
    final gutter = WindowSize.of(context).gutter;

    return AppScaffold(
      hero: true,
      title: t.billingTitle,
      actions: [
        IconButton(
          tooltip: adminText(
            context,
            'Finance exceptions and export',
            'الاستثناءات والتصدير المالي',
          ),
          icon: const Icon(Icons.receipt_outlined),
          onPressed: () => context.push('/admin/billing/exceptions'),
        ),
        IconButton(
          tooltip: t.reconcilePaymentsAction,
          icon: const Icon(Icons.sync),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final r = await ref.read(adminActionsProvider).reconcilePayments();
            messenger.showSnackBar(
              SnackBar(
                content: Text(switch (r) {
                  Ok(:final value) => t.reconciledCount(value),
                  Err(:final failure) => describeFailure(
                    AppLocalizations.of(context)!,
                    failure,
                  ).message,
                }),
              ),
            );
          },
        ),
        const AdminTopActions(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
          child: Row(
            children: [
              for (final (label, value) in [
                (t.allFilterChip, null),
                (InvoiceStatus.pending.label(context), InvoiceStatus.pending),
                (InvoiceStatus.paid.label(context), InvoiceStatus.paid),
                (
                  InvoiceStatus.cancelled.label(context),
                  InvoiceStatus.cancelled,
                ),
                (InvoiceStatus.refunded.label(context), InvoiceStatus.refunded),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
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
      body: invoices.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: t.couldNotLoadInvoicesAdmin,
          onRetry: () => ref.invalidate(allInvoicesProvider(_filter)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              message: t.noInvoicesInView,
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
      centerBody: false,
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
    final t = AppLocalizations.of(context)!;
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
                child: ReadableLabel(
                  patientName ?? t.rolePatient,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              _StatusChip(invoice.status),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            [
              'BD ${invoice.totalAmount.toStringAsFixed(2)}',
              t.issuedOn(fmtDate(invoice.issuedAt)),
              if (invoice.dueDate != null) t.dueOn(fmtDate(invoice.dueDate!)),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(invoice.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (!open) _PaymentsPanel(invoice: invoice),
          if (open) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                FilledButton.tonal(
                  onPressed: () => _recordDeskPayment(context, ref),
                  child: Text(t.recordDeskPaymentAction),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      title: t.cancelThisInvoiceTitle,
                      message: t.patientWillNoLongerOweIt,
                      confirmLabel: t.cancelInvoiceAction,
                      destructive: true,
                    );
                    if (ok && context.mounted) {
                      await _set(context, ref, InvoiceStatus.cancelled);
                    }
                  },
                  child: Text(t.cancel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recordDeskPayment(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final entered = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _TwoFieldDialog(
        title: t.recordDeskPaymentAction,
        firstLabel: t.receiptNumberLabel,
        secondLabel: t.paymentNoteOptionalLabel,
        secondRequired: false,
        confirmLabel: t.recordDeskPaymentAction,
      ),
    );
    if (entered == null) return;
    final r = await ref
        .read(adminActionsProvider)
        .recordDeskPayment(
          invoiceId: invoice.id,
          receipt: entered.$1,
          note: entered.$2.isEmpty ? null : entered.$2,
          key: IdempotencyKey.generate(),
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => t.deskPaymentRecorded,
          Err(:final failure) => describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message,
        }),
      ),
    );
  }

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    InvoiceStatus status,
  ) async {
    final t = AppLocalizations.of(context)!;
    final statusLabel = status.label(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref
        .read(adminActionsProvider)
        .setInvoiceStatus(id: invoice.id, status: status);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => t.invoiceMarkedStatus(statusLabel),
          Err(:final failure) => describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message,
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
    final scheme = theme.colorScheme;
    final (label, bg, fg) = switch (status) {
      InvoiceStatus.paid => (
        status.label(context),
        ramp.riskLow.container,
        ramp.riskLow.onContainer,
      ),
      InvoiceStatus.pending => (
        status.label(context),
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      InvoiceStatus.cancelled || InvoiceStatus.refunded => (
        status.label(context),
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
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

/// The payments behind a settled invoice, each refundable for whatever has
/// not been refunded yet. A failed read says so.
class _PaymentsPanel extends ConsumerWidget {
  const _PaymentsPanel({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final payments = ref.watch(invoicePaymentsProvider(invoice.id));
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(t.paymentHistoryHeader),
      children: [
        payments.when(
          loading: () => const LoadingSkeleton(height: 48),
          error: (e, _) => InlineBanner.error(t.couldNotLoadPayments),
          data: (list) {
            if (list.isEmpty) return Text(t.noPaymentsYet);
            return Column(
              children: [
                for (final p in list)
                  PaymentHistoryTile(
                    payment: p,
                    trailing: _refundable(p, list) > 0
                        ? TextButton(
                            onPressed: () =>
                                _refund(context, ref, p, _refundable(p, list)),
                            child: Text(t.refundAction),
                          )
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// What is left to refund of a settled charge, in BHD.
  static double _refundable(
    PaymentTransaction p,
    List<PaymentTransaction> all,
  ) {
    if (p.kind != PaymentKind.invoiceCharge || !p.isSettled) return 0;
    final refundedFils = all
        .where((r) => r.refundOfId == p.id && (r.isSettled || r.isInFlight))
        .fold<int>(0, (sum, r) => sum + (r.amount * 1000).round());
    return ((p.amount * 1000).round() - refundedFils) / 1000;
  }

  Future<void> _refund(
    BuildContext context,
    WidgetRef ref,
    PaymentTransaction payment,
    double remaining,
  ) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final entered = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _TwoFieldDialog(
        title: t.refundAction,
        firstLabel: t.refundAmountLabel,
        firstInitial: remaining.toStringAsFixed(3),
        numericFirst: true,
        secondLabel: t.refundReasonLabel,
        confirmLabel: t.refundAction,
      ),
    );
    if (entered == null) return;
    final amount = double.tryParse(entered.$1.trim()) ?? 0;
    final r = await ref
        .read(adminActionsProvider)
        .refundPayment(
          payment: payment,
          amount: amount,
          reason: entered.$2,
          key: IdempotencyKey.generate(),
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => t.refundRecorded,
          Err(:final failure) => describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message,
        }),
      ),
    );
  }
}

/// A small form dialog: a required first field and a second one, returned
/// trimmed. Keeps what was typed until confirmed or cancelled.
class _TwoFieldDialog extends StatefulWidget {
  const _TwoFieldDialog({
    required this.title,
    required this.firstLabel,
    required this.secondLabel,
    required this.confirmLabel,
    this.firstInitial = '',
    this.numericFirst = false,
    this.secondRequired = true,
  });

  final String title;
  final String firstLabel;
  final String secondLabel;
  final String confirmLabel;
  final String firstInitial;
  final bool numericFirst;
  final bool secondRequired;

  @override
  State<_TwoFieldDialog> createState() => _TwoFieldDialogState();
}

class _TwoFieldDialogState extends State<_TwoFieldDialog> {
  late final _first = TextEditingController(text: widget.firstInitial);
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  bool get _ready =>
      _first.text.trim().isNotEmpty &&
      (!widget.secondRequired || _second.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _first,
            autofocus: true,
            keyboardType: widget.numericFirst
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(labelText: widget.firstLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _second,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: widget.secondLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _ready
              ? () => Navigator.pop(context, (
                  _first.text.trim(),
                  _second.text.trim(),
                ))
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
