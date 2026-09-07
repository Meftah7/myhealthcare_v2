/// The card sheet for settling an invoice.
///
/// This is a demo payment path. Card details are validated locally, used to
/// build a masked descriptor ("Card ····4242"), and then discarded — nothing
/// is stored or transmitted. The sheet says so, so nobody mistakes it for a
/// real gateway.
///
/// Payment-security parity with the FirstSemMyHealth `pay_invoice` handler:
///  - the CVC never leaves this sheet — it is validated here and never passed
///    to any store (the PHP original simply never POSTs it);
///  - only the last four digits + a masked descriptor are persisted, never the
///    PAN (`billing_repository_impl.pay` writes `payment.maskedDescriptor`);
///  - the invoice is only settled if it belongs to the signed-in patient and
///    is still open (ownership + state checked inside the same query);
///  - the fields opt out of keyboard learning / autocorrect so the PAN and CVC
///    are not cached by the OS, and use the platform credit-card autofill;
///  - an expired card is refused before the network call, and the month field
///    can only hold 01–12.
///
/// If the patient has saved cards they pick one and enter only its CVC;
/// otherwise (or by choosing "a different card") they type a full card.
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
import '../../booking/application/appointment_confirmation.dart';
import '../application/billing_providers.dart';
import 'billing_screen.dart';

Future<void> showPayInvoiceSheet(BuildContext context, Invoice invoice) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PayInvoiceSheet(invoice: invoice),
  );
}

/// `null` id = "use a different card".
class _PayInvoiceSheet extends ConsumerStatefulWidget {
  const _PayInvoiceSheet({required this.invoice});

  final Invoice invoice;

  @override
  ConsumerState<_PayInvoiceSheet> createState() => _PayInvoiceSheetState();
}

class _PayInvoiceSheetState extends ConsumerState<_PayInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();

  /// Which saved card is selected, or null for "a different card". Left unset
  /// until the wallet loads.
  String? _selectedCardId;
  bool _choseNewCard = false;
  bool _initialisedSelection = false;

  bool _submitting = false;
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

  bool get _usingSavedCard => !_choseNewCard && _selectedCardId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final cardsAsync = ref.watch(walletCardsProvider);
    final cards = cardsAsync.valueOrNull ?? const <PaymentMethod>[];

    // First build after the wallet resolves: default to the patient's default
    // card if it is usable, else the first card that isn't expired, else the
    // new-card form.
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
                Text('Pay invoice', style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xxs),
                Text(
                  '${money(widget.invoice.totalAmount)} due',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),

                if (cardsAsync.isLoading)
                  const LoadingSkeleton(height: 56)
                else if (cards.isNotEmpty) ...[
                  Text(
                    'Pay with',
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
                        'Demo payment — card details are checked on this device '
                        'and never stored or sent anywhere.',
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
                        : Text('Pay ${money(widget.invoice.totalAmount)}'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                autofillHints: const [AutofillHints.creditCardExpirationDate],
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
                    : '3–4 digits',
              ),
            ),
          ],
        ),
      ],
    );
  }

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

  Future<void> _submit() async {
    setState(() => _error = null);

    Result<Invoice> result;
    if (_usingSavedCard) {
      if (!RegExp(r'^\d{3,4}$').hasMatch(_cvc.text)) {
        setState(() => _error = 'Enter the 3–4 digit security code.');
        return;
      }
      setState(() => _submitting = true);
      result = await ref
          .read(billingControllerProvider)
          .payWithSavedCard(
            invoiceId: widget.invoice.id,
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
          .pay(
            widget.invoice.id,
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
        ref
            .read(appointmentConfirmationProvider.notifier)
            .show('Payment received');
        Navigator.of(context).pop();
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
                            ? 'Expired ${card.expiry}'
                            : 'Expires ${card.expiry}',
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
                  'Pay with a different card',
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
        helperText: 'The 3–4 digits on the back of the card',
      ),
    );
  }
}
