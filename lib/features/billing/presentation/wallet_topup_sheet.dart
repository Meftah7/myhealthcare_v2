/// The top-up sheet for adding credit to the patient's wallet balance.
///
/// Same demo payment path as [showPayInvoiceSheet]: card details are
/// validated locally, turned into a masked descriptor, and never stored or
/// transmitted.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/card_input.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../application/billing_providers.dart';
import 'payments_screen.dart' show money;

Future<void> showWalletTopUpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _WalletTopUpSheet(),
  );
}

class _WalletTopUpSheet extends ConsumerStatefulWidget {
  const _WalletTopUpSheet();

  @override
  ConsumerState<_WalletTopUpSheet> createState() => _WalletTopUpSheetState();
}

class _WalletTopUpSheetState extends ConsumerState<_WalletTopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();

  String? _selectedCardId;
  bool _choseNewCard = false;
  bool _initialisedSelection = false;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  CardBrand get _brand => cardBrandOf(_number.text);

  bool get _usingSavedCard => !_choseNewCard && _selectedCardId != null;

  double? get _parsedAmount => double.tryParse(_amount.text.trim());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final cardsAsync = ref.watch(walletCardsProvider);
    final cards = cardsAsync.valueOrNull ?? const <PaymentMethod>[];

    if (!_initialisedSelection && cardsAsync.hasValue) {
      _initialisedSelection = true;
      final usable = cards.where((c) => !c.isExpired).toList();
      if (usable.isNotEmpty) {
        _selectedCardId = usable
            .firstWhere((c) => c.isDefault, orElse: () => usable.first)
            .id;
      } else {
        _choseNewCard = true;
      }
    }

    final amount = _parsedAmount;
    final buttonLabel = (amount != null && amount > 0)
        ? t.topUpAmountButton(money(amount))
        : t.topUpButton;

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg + insets),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.topUpWalletTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: t.topUpAmountLabel,
                    prefixText: 'BD ',
                  ),
                  validator: (v) {
                    final a = double.tryParse((v ?? '').trim());
                    if (a == null || a <= 0) return t.topUpAmountTooSmall;
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.lg),

                if (cardsAsync.isLoading)
                  const LoadingSkeleton(height: 56)
                else if (cards.isNotEmpty) ...[
                  Text(
                    t.payWithLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  for (final c in cards)
                    _SavedCardRow(
                      card: c,
                      selected: _usingSavedCard && _selectedCardId == c.id,
                      onTap: c.isExpired
                          ? null
                          : () => setState(() {
                              _selectedCardId = c.id;
                              _choseNewCard = false;
                              _error = null;
                            }),
                    ),
                  _NewCardRow(
                    selected: _choseNewCard,
                    onTap: () => setState(() {
                      _choseNewCard = true;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: Space.md),
                ],

                if (_usingSavedCard)
                  _CvcOnlyField(controller: _cvc, brand: _brandForSelected(cards))
                else
                  _fullCardForm(theme),

                if (_error != null) ...[
                  const SizedBox(height: Space.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: Radii.cardSmall,
                    ),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        t.walletTopUpNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Space.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CardBrand _brandForSelected(List<PaymentMethod> cards) {
    final c = cards.where((c) => c.id == _selectedCardId).firstOrNull;
    return switch (c?.brand.toLowerCase()) {
      'visa' => CardBrand.visa,
      'mastercard' => CardBrand.mastercard,
      'amex' => CardBrand.amex,
      'discover' => CardBrand.discover,
      _ => CardBrand.unknown,
    };
  }

  Widget _fullCardForm(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                autofillHints: const [AutofillHints.creditCardExpirationDate],
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
                autofillHints: const [AutofillHints.creditCardSecurityCode],
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
      ],
    );
  }

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

  Future<void> _submit() async {
    setState(() => _error = null);
    final t = AppLocalizations.of(context)!;
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      setState(() => _error = t.topUpAmountTooSmall);
      return;
    }

    Result<double> result;
    if (_usingSavedCard) {
      if (!RegExp(r'^\d{3,4}$').hasMatch(_cvc.text)) {
        setState(() => _error = t.enterSecurityCode);
        return;
      }
      setState(() => _submitting = true);
      result = await ref
          .read(billingControllerProvider)
          .topUpWalletWithSavedCard(
            amount: amount,
            cardId: _selectedCardId!,
            cvc: _cvc.text,
          );
    } else {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      final expiry = parseExpiry(_expiry.text);
      if (expiry == null) return;
      setState(() => _submitting = true);
      result = await ref
          .read(billingControllerProvider)
          .topUpWallet(
            amount,
            CardPayment(
              cardNumber: _number.text,
              cardHolder: _holder.text.trim(),
              expiryMonth: expiry.month,
              expiryYear: expiry.year,
              cvc: _cvc.text,
            ),
          );
    }

    if (!mounted) return;

    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.walletToppedUpMessage)),
        );
      case Err(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }
}

class _SavedCardRow extends StatelessWidget {
  const _SavedCardRow({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod card;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardSmall,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 20,
                  color: disabled
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
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
                        card.isExpired
                            ? AppLocalizations.of(context)!.cardExpiredOn(card.expiry)
                            : AppLocalizations.of(context)!.cardExpiresOn(card.expiry),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: card.isExpired
                              ? theme.clinicalStatus.riskHigh.onContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewCardRow extends StatelessWidget {
  const _NewCardRow({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardSmall,
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.add_card_outlined, size: 20, color: scheme.onSurface),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.payWithDifferentCard,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CvcOnlyField extends StatelessWidget {
  const _CvcOnlyField({required this.controller, required this.brand});

  final TextEditingController controller;
  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: brand == CardBrand.amex ? 'CID' : 'CVC',
        helperText: AppLocalizations.of(context)!.securityCodeHelper,
      ),
    );
  }
}
