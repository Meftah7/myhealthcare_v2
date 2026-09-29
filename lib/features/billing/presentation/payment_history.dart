/// Payment history rows (Phase 5): each charge, top-up and refund with its
/// method, status and provider reference, so "paid" is always traceable to
/// the payment behind it.
library;

import 'package:flutter/material.dart';

import '../../../core/i18n/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../l10n/app_localizations.dart';
import 'payments_screen.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({required this.payment, this.trailing, super.key});

  final PaymentTransaction payment;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final p = payment;
    final failed =
        p.status == PaymentStatus.failed || p.status == PaymentStatus.voided;
    final sign = p.kind == PaymentKind.refund ? '−' : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(switch (p.kind) {
        PaymentKind.invoiceCharge => Icons.receipt_long_outlined,
        PaymentKind.walletTopUp => Icons.account_balance_wallet_outlined,
        PaymentKind.refund => Icons.undo,
      }),
      title: Text('${p.kind.label(context)} · $sign${money(p.amount)}'),
      subtitle: Text(
        [
          p.status.label(context),
          ?p.methodDescriptor,
          '${fmtDate(p.createdAt)} ${fmtTime(p.createdAt)}',
          if (p.providerReference != null)
            t.paymentReferenceLabel(p.providerReference!),
          if (p.reason != null && p.reason!.isNotEmpty) p.reason!,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: failed || p.isInFlight
              ? theme.colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      trailing: trailing,
    );
  }
}
