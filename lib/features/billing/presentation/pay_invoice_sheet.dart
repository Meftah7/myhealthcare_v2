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
///
/// Phase 5: one idempotency key per attempt, reused if the patient retries
/// after a lost answer, replaced only after a definite outcome. A payment
/// whose outcome is unknown is shown as "Confirming", never as paid; the
/// patient can check its status, which asks the provider and never charges.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/data/contracts.dart';
import '../../../core/failures.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/presentation/responsive.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/utils/card_input.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../booking/application/appointment_confirmation.dart';
import '../application/billing_providers.dart';
import 'payments_screen.dart';

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
  bool _useWalletBalance = false;

  bool _submitting = false;
  String? _error;

  /// The current attempt. Kept across a retry after an unknown outcome so
  /// the retry can never become a second charge.
  IdempotencyKey _key = IdempotencyKey.generate();

  /// Sent, but the provider's answer has not been confirmed.
  bool _pending = false;
  String? _pendingMessage;

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
    final t = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final cardsAsync = ref.watch(walletCardsProvider);
    final cards = cardsAsync.valueOrNull ?? const <PaymentMethod>[];
    final walletBalance = ref.watch(walletBalanceProvider).valueOrNull ?? 0;
    final walletCovers = walletBalance >= widget.invoice.totalAmount;

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
                Text(t.payInvoiceTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xxs),
                Text(
                  t.amountDue(money(widget.invoice.totalAmount)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),

                if (walletBalance > 0) ...[
                  Text(
                    t.payWithLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  _WalletBalanceRow(
                    balance: walletBalance,
                    selected: _useWalletBalance,
                    onTap: walletCovers
                        ? () => setState(() {
                            _useWalletBalance = true;
                            _error = null;
                          })
                        : null,
                  ),
                  const SizedBox(height: Space.xs),
                ],

                if (cardsAsync.isLoading)
                  const LoadingSkeleton(height: 56)
                else if (cards.isNotEmpty) ...[
                  if (walletBalance <= 0)
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
                      selected:
                          !_useWalletBalance &&
                          _usingSavedCard &&
                          _selectedCardId == c.id,
                      onTap: c.isExpired
                          ? null
                          : () => setState(() {
                              _selectedCardId = c.id;
                              _choseNewCard = false;
                              _useWalletBalance = false;
                              _error = null;
                            }),
                    ),
                  _NewCardRow(
                    selected: !_useWalletBalance && _choseNewCard,
                    onTap: () => setState(() {
                      _choseNewCard = true;
                      _useWalletBalance = false;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: Space.md),
                ],

                if (_useWalletBalance)
                  const SizedBox.shrink()
                else if (_usingSavedCard)
                  _CvcOnlyField(
                    controller: _cvc,
                    brand: _brandForSelected(cards),
                  )
                else
                  _fullCardForm(theme),

                if (_pending) ...[
                  const SizedBox(height: Space.sm),
                  _PendingBox(
                    message: _pendingMessage ?? t.paymentStillConfirming,
                    busy: _submitting,
                    onCheck: _checkStatus,
                  ),
                ],
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
                        t.demoPaymentNote,
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
                        : Text(
                            t.payAmountButton(
                              money(widget.invoice.totalAmount),
                            ),
                          ),
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
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? t.enterNameOnCard : null,
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
        AdaptiveFormRow(
          children: [
            TextFormField(
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
            TextFormField(
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
              validator: (v) =>
                  RegExp(r'^\d{3,4}$').hasMatch(v ?? '') ? null : t.digitsRange,
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

    Result<Invoice> result;
    if (_useWalletBalance) {
      setState(() => _submitting = true);
      result = await ref
          .read(billingControllerProvider)
          .payWithWallet(widget.invoice.id, key: _key);
    } else if (_usingSavedCard) {
      if (!RegExp(r'^\d{3,4}$').hasMatch(_cvc.text)) {
        setState(() => _error = t.enterSecurityCode);
        return;
      }
      setState(() => _submitting = true);
      result = await ref
          .read(billingControllerProvider)
          .payWithSavedCard(
            invoiceId: widget.invoice.id,
            cardId: _selectedCardId!,
            cvc: _cvc.text,
            key: _key,
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
            key: _key,
          );
    }

    if (!mounted) return;

    switch (result) {
      case Ok():
        _paid();
      case Err(failure: final PaymentPendingFailure f):
        // Unknown outcome: keep the key, so trying again can only complete
        // this same payment.
        setState(() {
          _submitting = false;
          _pending = true;
          _pendingMessage = f.message;
          _error = null;
        });
      case Err(:final failure):
        // A definite answer (declined, invalid): the next try is a new
        // attempt.
        setState(() {
          _submitting = false;
          _pending = false;
          _key = IdempotencyKey.generate();
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
    }
  }

  void _paid() {
    final t = AppLocalizations.of(context)!;
    ref.read(appointmentConfirmationProvider.notifier).show(t.paymentReceived);
    Navigator.of(context).pop();
  }

  /// Asks the provider what became of the attempt. Never charges.
  Future<void> _checkStatus() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final result = await ref
        .read(billingControllerProvider)
        .latestAttempt(widget.invoice.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value) when value?.status == PaymentStatus.settled:
        _paid();
      case Ok(:final value) when value != null && value.isInFlight:
        setState(() {
          _submitting = false;
          _pendingMessage = t.paymentStillConfirming;
        });
      case Ok():
        setState(() {
          _submitting = false;
          _pending = false;
          _key = IdempotencyKey.generate();
          _error = t.paymentReleasedMessage;
        });
      case Err(:final failure):
        setState(() {
          _submitting = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
    }
  }
}

/// "Confirming your payment" — shown instead of success or failure while
/// the provider's answer is unknown.
class _PendingBox extends StatelessWidget {
  const _PendingBox({
    required this.message,
    required this.busy,
    required this.onCheck,
  });

  final String message;
  final bool busy;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: Radii.cardSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.paymentPendingTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: busy ? null : onCheck,
                child: Text(t.checkPaymentStatusAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceRow extends StatelessWidget {
  const _WalletBalanceRow({
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  final double balance;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final disabled = onTap == null;
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
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: disabled ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.payWithWalletLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      disabled
                          ? t.insufficientWalletBalanceHint
                          : t.walletBalanceAvailable(money(balance)),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: disabled
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
    );
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
                  color: disabled ? scheme.onSurfaceVariant : scheme.onSurface,
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
                            ? AppLocalizations.of(
                                context,
                              )!.cardExpiredOn(card.expiry)
                            : AppLocalizations.of(
                                context,
                              )!.cardExpiresOn(card.expiry),
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
