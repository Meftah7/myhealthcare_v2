/// Saved payment methods — the cards a patient can pay invoices or top up
/// their wallet with. Rendered as the bottom section of the Payments screen.
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
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../application/billing_providers.dart';

class PaymentMethodsSection extends ConsumerWidget {
  const PaymentMethodsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final cards = ref.watch(walletCardsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Label(t.savedCardsLabel)),
            TextButton.icon(
              onPressed: () => _addCard(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.addCardButton),
            ),
          ],
        ),
        cards.when(
          loading: () => const LoadingSkeleton(height: 48),
          error: (e, _) => InlineBanner.error(t.couldNotLoadCards),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                t.noCardsSavedYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(children: [for (final c in list) _CardTile(card: c)]);
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
      builder: (_) => const AddCardSheet(),
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
    final t = AppLocalizations.of(context)!;
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
                  '${t.cardExpiresOn(card.expiry)}'
                  '${card.isExpired ? ' · ${t.expiredSuffix}' : ''}',
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
                t.defaultChip,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () =>
                  ref.read(billingControllerProvider).setDefaultCard(card.id),
              child: Text(t.setDefaultButton),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.removeCardTooltip,
            onPressed: () async {
              final ok = await confirm(
                context,
                title: t.removeCardTitle,
                message: t.removeCardMessage(card.brand, card.last4),
                confirmLabel: t.removeButton,
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

/// Add-a-card sheet, shared by the Payment Methods list and the top-up flow.
class AddCardSheet extends ConsumerStatefulWidget {
  const AddCardSheet({super.key});

  @override
  ConsumerState<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<AddCardSheet> {
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
    final t = AppLocalizations.of(context)!;
    final parsed = parseExpiry(v ?? '');
    if (parsed == null) {
      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
      if (d.length >= 2) {
        final mm = int.tryParse(d.substring(0, 2)) ?? 0;
        if (mm < 1 || mm > 12) return t.monthRange;
      }
      return 'MM/YY';
    }
    if (!expiryInFuture(parsed.month, parsed.year)) return t.cardExpired;
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
    final t = AppLocalizations.of(context)!;
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
                Text(t.addACardTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _holder,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.creditCardName],
                  decoration: InputDecoration(labelText: t.nameOnCardLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? t.enterNameOnCard
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
                    labelText: t.cardNumberLabel,
                    hintText: '4242 4242 4242 4242',
                    suffixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: CardBrandBadge(_brand),
                    ),
                  ),
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (d.length < 12) return t.enterFullCardNumber;
                    if (!luhnValid(d)) return t.cardNumberInvalid;
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
                        decoration: InputDecoration(
                          labelText: t.expiryLabel,
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
                            : t.digitsRange,
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
                  t.cardSavedNote,
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
                      : Text(t.saveCardButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
