/// Wallet — the patient's saved cards, what they owe now, and past payments.
/// Rendered bare inside its own profile page.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/card_input.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../application/billing_providers.dart';
import 'billing_screen.dart' show money;

class WalletSection extends ConsumerWidget {
  const WalletSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoices = ref.watch(patientInvoicesProvider);
    final cards = ref.watch(walletCardsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Saved cards ---
        Row(
          children: [
            const Expanded(child: _Label('Saved cards')),
            TextButton.icon(
              onPressed: () => _addCard(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add card'),
            ),
          ],
        ),
        cards.when(
          loading: () => const LoadingSkeleton(height: 48),
          error: (e, _) => const InlineBanner.error('Could not load cards.'),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'No cards saved yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(children: [for (final c in list) _CardTile(card: c)]);
          },
        ),

        const SizedBox(height: Space.md),
        const Divider(height: 1),
        const SizedBox(height: Space.md),

        // --- History ---
        const _Label('Transaction history'),
        invoices.when(
          loading: () => const LoadingSkeleton(height: 48),
          error: (e, _) => const SizedBox.shrink(),
          data: (list) {
            final paid =
                list.where((i) => i.status == InvoiceStatus.paid).toList()
                  ..sort((a, b) {
                    final ap = a.paidAt ?? a.issuedAt;
                    final bp = b.paidAt ?? b.issuedAt;
                    return bp.compareTo(ap);
                  });
            if (paid.isEmpty) {
              return Text(
                'No payments yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [
                for (final inv in paid.take(12))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xxs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: theme.clinicalStatus.riskLow.onContainer,
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            fmtDate(inv.paidAt ?? inv.issuedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (inv.paymentMethod != null)
                          Text(
                            inv.paymentMethod!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(width: Space.sm),
                        Text(
                          money(inv.totalAmount),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddCardSheet(),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card});
  final PaymentMethod card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Icon(Icons.credit_card, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand} ····${card.last4}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Expires ${card.expiry}'
                  '${card.isExpired ? ' · expired' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: card.isExpired
                        ? theme.clinicalStatus.riskHigh.onContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (card.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: Radii.chip,
              ),
              child: Text(
                'Default',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () =>
                  ref.read(billingControllerProvider).setDefaultCard(card.id),
              child: const Text('Set default'),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove card',
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Remove card?',
                message: '${card.brand} ····${card.last4} will be removed.',
                confirmLabel: 'Remove',
                destructive: true,
              );
              if (ok) {
                await ref.read(billingControllerProvider).removeCard(card.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AddCardSheet extends ConsumerStatefulWidget {
  const _AddCardSheet();

  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  CardBrand get _brand => cardBrandOf(_number.text);

  String? _validateExpiry(String? v) {
    final parsed = parseExpiry(v ?? '');
    if (parsed == null) {
      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
      if (d.length >= 2) {
        final mm = int.tryParse(d.substring(0, 2)) ?? 0;
        if (mm < 1 || mm > 12) return 'Month must be 01–12';
      }
      return 'MM/YY';
    }
    if (!expiryInFuture(parsed.month, parsed.year)) return 'Card has expired';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final exp = parseExpiry(_expiry.text);
    if (exp == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(billingControllerProvider)
        .addCard(
          CardPayment(
            cardNumber: _number.text,
            cardHolder: _holder.text.trim(),
            expiryMonth: exp.month,
            expiryYear: exp.year,
            cvc: _cvc.text,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
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
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add a card', style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _holder,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.creditCardName],
                  decoration: const InputDecoration(labelText: 'Name on card'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the name on the card'
                      : null,
                ),
                const SizedBox(height: Space.sm),
                TextFormField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  inputFormatters: const [CardNumberInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Card number',
                    hintText: '4242 4242 4242 4242',
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CardBrandBadge(_brand),
                    ),
                  ),
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (d.length < 12) return 'Enter a full card number';
                    if (!luhnValid(d)) return 'That card number is not valid';
                    return null;
                  },
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiry,
                        keyboardType: TextInputType.number,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [
                          AutofillHints.creditCardExpirationDate,
                        ],
                        inputFormatters: const [ExpiryInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Expiry',
                          hintText: 'MM/YY',
                        ),
                        validator: _validateExpiry,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _cvc,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [
                          AutofillHints.creditCardSecurityCode,
                        ],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: _brand == CardBrand.amex ? 'CID' : 'CVC',
                        ),
                        validator: (v) => RegExp(r'^\d{3,4}$').hasMatch(v ?? '')
                            ? null
                            : '3–4 digits',
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: Space.sm),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Space.sm),
                Text(
                  'Only the last 4 digits and expiry are saved — never the full '
                  'number or CVC.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.md),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
