/// The card sheet for settling an invoice.
///
/// This is a demo payment path. Card details are validated locally, used to
/// build a masked descriptor ("Card ····4242"), and then discarded — nothing
/// is stored or transmitted. The sheet says so, so nobody mistakes it for a
/// real gateway.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/result.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        Space.lg + insets,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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

              TextFormField(
                controller: _holder,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name on card'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the name on the card'
                    : null,
              ),
              const SizedBox(height: Space.sm),

              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: '4242 4242 4242 4242',
                ),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (d.length < 12) return 'Enter a full card number';
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                      ),
                      validator: (v) =>
                          _parseExpiry(v ?? '') == null ? 'MM/YY' : null,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _cvc,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(labelText: 'CVC'),
                      validator: (v) => RegExp(r'^\d{3,4}$').hasMatch(v ?? '')
                          ? null
                          : '3–4 digits',
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: Space.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: Radii.card,
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
    );
  }

  /// `MM/YY` or `MMYY` → (month, full year). Null when unparseable.
  static (int, int)? _parseExpiry(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 4) return null;
    final month = int.tryParse(d.substring(0, 2));
    final year = int.tryParse(d.substring(2));
    if (month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    return (month, 2000 + year);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final expiry = _parseExpiry(_expiry.text);
    if (expiry == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await ref
        .read(billingControllerProvider)
        .pay(
          widget.invoice.id,
          CardPayment(
            cardNumber: _number.text,
            cardHolder: _holder.text.trim(),
            expiryMonth: expiry.$1,
            expiryYear: expiry.$2,
            cvc: _cvc.text,
          ),
        );

    if (!mounted) return;

    switch (result) {
      case Ok():
        // Reuse the app-level checkmark so payment confirms the same way a
        // booking does.
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
