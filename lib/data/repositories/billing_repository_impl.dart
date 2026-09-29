/// Drift-backed [BillingRepository].
///
/// Money only moves through the payment ledger (Phase 5). A card payment is
/// recorded as `initiated` *before* the provider is asked, the provider's
/// answer is applied in a second transaction, and an invoice is marked paid
/// only by a transaction that reached `settled`. If the answer is lost (the
/// provider is unreachable, the app is closed mid-payment), the attempt stays
/// `initiated` and [BillingRepositoryImpl.reconcile] asks the provider what
/// happened — it never guesses, and never charges again: every provider call
/// carries the attempt's own request reference, which the provider treats as
/// an idempotency key.
library;

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../services/auth/access_policy.dart';
import '../../services/payments/payment_gateway.dart';
import '../db/app_database.dart';
import '../sync/idempotency.dart';
import 'mappers.dart';

/// Luhn check — catches typo'd card numbers before we pretend to charge them.
bool passesLuhn(String digits) {
  if (digits.length < 12 || digits.length > 19) return false;
  var sum = 0;
  var double = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    final code = digits.codeUnitAt(i) - 0x30;
    if (code < 0 || code > 9) return false;
    var n = code;
    if (double) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    double = !double;
  }
  return sum % 10 == 0;
}

/// What an idempotency key committed before: a ledger transaction, or (keys
/// used before the ledger existed) the invoice / wallet entry it produced.
typedef _Prior = ({PaymentTransactionRow? txn, String? legacyRef});

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(
    this._db, {
    AccessPolicy? access,
    PaymentGateway? gateway,
    DateTime Function()? now,
  }) : _access = access ?? AccessPolicy.unenforced(_db),
       _gateway = gateway ?? SimulatedPaymentGateway(_db),
       _now = now ?? DateTime.now,
       _idempotency = IdempotencyGuard(_db);

  final AppDatabase _db;
  final AccessPolicy _access;
  final PaymentGateway _gateway;
  final DateTime Function() _now;
  final IdempotencyGuard _idempotency;

  static const _payScope = 'billing.pay';
  static const _topUpScope = 'billing.top_up';
  static const _refundScope = 'billing.refund';
  static const _offlineScope = 'billing.offline';

  /// A request the provider still has no record of this long after it was
  /// sent never reached it: the attempt is released (nothing was charged).
  static const notReceivedAfter = Duration(minutes: 2);

  static const _inFlight = [PaymentStatus.initiated, PaymentStatus.authorized];

  @override
  bool get paymentsAreSimulated => _gateway.isSimulated;

  // --- access --------------------------------------------------------------

  Future<void> _readFinancial(String patientId, {String? entityId}) =>
      _access.readPatient(
        patientId,
        scope: PatientDataScope.financial,
        entityType: 'billing',
        entityId: entityId,
      );

  /// Billing staff read any patient's payments; everyone else only those they
  /// may see for that patient.
  Future<void> _readPayments(String patientId, {String? entityId}) async {
    final p = await _access.principal();
    if (p != null && p.isAdmin && p.can(Permission.manageBilling)) return;
    await _readFinancial(patientId, entityId: entityId);
  }

  /// The patient, or a proxy with a manage grant, moving money for
  /// [patientId]. Returns the paying account (null when unenforced).
  Future<String?> _payer(String patientId, {String? entityId}) async {
    final subject = await _access.actForPatient(
      patientId,
      Permission.payBills,
      entityType: 'billing',
      entityId: entityId,
    );
    if (!_access.isEnforced) return null;
    if (!subject.isSelf) {
      await _access.audit(
        'proxy.billing.payment',
        entityType: 'billing',
        entityId: entityId,
        subjectPatientId: patientId,
      );
    }
    return subject.actingAccountId;
  }

  // --- reads ---------------------------------------------------------------

  @override
  Future<Result<List<Invoice>>> forPatient(String patientId) {
    return Result.guardAsync(() async {
      await _readFinancial(patientId);
      final rows =
          await (_db.select(_db.invoices)
                ..where((i) => i.patientId.equals(patientId))
                ..orderBy([(i) => OrderingTerm.desc(i.issuedAt)]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<List<Invoice>>> all({InvoiceStatus? status}) {
    return Result.guardAsync(() async {
      await _access.require(Permission.manageBilling, entityType: 'billing');
      final q = _db.select(_db.invoices)
        ..orderBy([(i) => OrderingTerm.desc(i.issuedAt)]);
      if (status != null) q.where((i) => i.status.equalsValue(status));
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Invoice>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.invoices,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (row == null) throw const NotFoundFailure('Invoice not found.');
      await _readFinancial(row.patientId, entityId: id);
      return row.toEntity();
    });
  }

  @override
  Future<Result<List<PaymentTransaction>>> transactions({
    String? invoiceId,
    String? patientId,
  }) {
    return Result.guardAsync(() async {
      final q = _db.select(_db.paymentTransactions)
        ..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ]);
      if (invoiceId != null) {
        final invoice = await _invoiceRow(invoiceId);
        await _readPayments(invoice.patientId, entityId: invoiceId);
        q.where((t) => t.invoiceId.equals(invoiceId));
      } else if (patientId != null) {
        await _readPayments(patientId);
        q.where((t) => t.patientId.equals(patientId));
      } else {
        await _access.require(Permission.manageBilling, entityType: 'billing');
      }
      final rows = await q.get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  // --- admin status --------------------------------------------------------

  @override
  Future<Result<Invoice>> setStatus({
    required String id,
    required InvoiceStatus status,
    int? expectedVersion,
  }) async {
    try {
      await _access.require(
        Permission.manageBilling,
        entityType: 'billing',
        entityId: id,
      );
    } on Failure catch (f) {
      return Err(f);
    }
    return Result.guardAsync(
      () => _db.transaction(() async {
        if (status == InvoiceStatus.paid) {
          throw const ValidationFailure(
            'An invoice is only marked paid by a settled payment. Record the '
            'payment taken at the desk instead.',
          );
        }
        if (status != InvoiceStatus.cancelled) {
          throw const ValidationFailure(
            'An invoice can only be cancelled here.',
          );
        }
        final row = await (_db.select(
          _db.invoices,
        )..where((i) => i.id.equals(id))).getSingleOrNull();
        if (row == null) throw const NotFoundFailure('Invoice not found.');
        if (expectedVersion != null && row.version != expectedVersion) {
          throw ConflictFailure(
            'This invoice was changed by someone else. Reload to see it.',
            currentVersion: row.version,
          );
        }
        if (row.status != InvoiceStatus.pending) {
          throw const ValidationFailure(
            'Only a pending invoice can be cancelled.',
          );
        }
        if (await _liveCharge(id) != null) {
          throw const ValidationFailure(
            'A card payment for this invoice is still being confirmed. '
            'Reconcile payments before cancelling it.',
          );
        }
        final changed =
            await (_db.update(_db.invoices)..where(
                  (i) =>
                      i.id.equals(id) &
                      i.status.equalsValue(InvoiceStatus.pending),
                ))
                .write(
                  const InvoicesCompanion(
                    status: Value(InvoiceStatus.cancelled),
                  ),
                );
        if (changed != 1) {
          throw const ConflictFailure('The invoice status changed. Reload.');
        }
        return (await _invoiceRow(id)).toEntity();
      }),
    );
  }

  // --- paying an invoice ---------------------------------------------------

  @override
  Future<Result<Invoice>> pay({
    required String invoiceId,
    required String patientId,
    required CardPayment payment,
    IdempotencyKey? idempotencyKey,
  }) async {
    final String? payer;
    try {
      payer = await _payer(patientId, entityId: invoiceId);
    } on Failure catch (f) {
      return Err(f);
    }
    return Result.guardAsync(() async {
      _validateCard(payment);
      return _payInvoiceByCard(
        invoiceId: invoiceId,
        patientId: patientId,
        payer: payer,
        card: GatewayCard(last4: payment.last4, digits: payment.digits),
        descriptor: payment.maskedDescriptor,
        method: PaymentMethodKind.card,
        key: idempotencyKey,
      );
    });
  }

  @override
  Future<Result<Invoice>> payWithSavedCard({
    required String invoiceId,
    required String patientId,
    required String cardId,
    required String cvc,
    IdempotencyKey? idempotencyKey,
  }) async {
    final String? payer;
    try {
      payer = await _payer(patientId, entityId: invoiceId);
    } on Failure catch (f) {
      return Err(f);
    }
    return Result.guardAsync(() async {
      final card = await _savedCard(patientId, cardId, cvc);
      return _payInvoiceByCard(
        invoiceId: invoiceId,
        patientId: patientId,
        payer: payer,
        card: GatewayCard(last4: card.last4, token: card.id),
        descriptor: '${card.brand} ····${card.last4}',
        method: PaymentMethodKind.savedCard,
        key: idempotencyKey,
      );
    });
  }

  Future<Invoice> _payInvoiceByCard({
    required String invoiceId,
    required String patientId,
    required String? payer,
    required GatewayCard card,
    required String descriptor,
    required PaymentMethodKind method,
    required IdempotencyKey? key,
  }) async {
    // An earlier attempt for this bill whose answer was lost may be
    // resolvable now; settle that first rather than refuse.
    await _reconcileRows(await _liveCharges(invoiceId: invoiceId));

    final attempt = await _db.transaction(() async {
      final prior = await _prior(key, _payScope, payer);
      if (prior != null) return prior;
      // Ownership and state are checked together, so another patient's bill
      // is indistinguishable from one that doesn't exist.
      final invoice = await _openInvoice(invoiceId, patientId: patientId);
      final live = await _liveCharge(invoiceId);
      if (live != null) {
        throw PaymentPendingFailure.forTransaction(
          live.id,
          'A payment for this invoice is already being confirmed. You have '
          'not been charged twice.',
        );
      }
      final txn = await _insertTxn(
        patientId: patientId,
        invoiceId: invoiceId,
        kind: PaymentKind.invoiceCharge,
        method: method,
        amount: invoice.totalAmount,
        provider: _gateway.providerName,
        descriptor: descriptor,
        actor: payer,
      );
      await _idempotency.remember(
        key,
        scope: _payScope,
        actorAccountId: payer,
        resultRef: txn.id,
      );
      return (txn: txn, legacyRef: null);
    });
    if (attempt.legacyRef != null) {
      return (await _invoiceRow(attempt.legacyRef!)).toEntity();
    }
    final done = await _chargeWithProvider(attempt.txn!, card);
    return (await _invoiceRow(done.invoiceId!)).toEntity();
  }

  @override
  Future<Result<Invoice>> payWithWallet({
    required String invoiceId,
    required String patientId,
    IdempotencyKey? idempotencyKey,
  }) async {
    final String? payer;
    try {
      payer = await _payer(patientId, entityId: invoiceId);
    } on Failure catch (f) {
      return Err(f);
    }
    // One transaction: the balance check, the debit, the ledger entry and
    // the invoice update either all happen or none do.
    return Result.guardAsync(
      () => _db.transaction(() async {
        final prior = await _prior(idempotencyKey, _payScope, payer);
        if (prior != null) {
          final ref = prior.txn?.invoiceId ?? prior.legacyRef!;
          return (await _invoiceRow(ref)).toEntity();
        }
        final invoice = await _openInvoice(invoiceId, patientId: patientId);
        if (await _liveCharge(invoiceId) != null) {
          throw const PaymentPendingFailure(
            'A card payment for this invoice is being confirmed. Wait for it '
            'before paying another way.',
          );
        }
        final balance = await _balanceOf(patientId);
        if (_fils(balance) < _fils(invoice.totalAmount)) {
          throw const ValidationFailure(
            'Not enough wallet balance to cover this invoice.',
          );
        }
        final now = _now();
        final txn = await _insertTxn(
          patientId: patientId,
          invoiceId: invoiceId,
          kind: PaymentKind.invoiceCharge,
          method: PaymentMethodKind.wallet,
          amount: invoice.totalAmount,
          provider: 'wallet',
          descriptor: 'Wallet balance',
          actor: payer,
          status: PaymentStatus.settled,
        );
        await _markInvoicePaid(
          invoiceId,
          descriptor: 'Wallet balance',
          payer: payer,
          at: now,
        );
        await _db
            .into(_db.walletTransactions)
            .insert(
              WalletTransactionsCompanion.insert(
                id: 'wtx_${txn.id}',
                patientId: patientId,
                type: WalletTransactionType.redemption,
                amount: _fils(invoice.totalAmount) / 1000,
                invoiceId: Value(invoiceId),
                actorAccountId: Value(payer),
                createdAt: Value(now),
              ),
            );
        await _idempotency.remember(
          idempotencyKey,
          scope: _payScope,
          actorAccountId: payer,
          resultRef: txn.id,
        );
        await _access.audit(
          'billing.payment.settled',
          entityType: 'billing',
          entityId: invoiceId,
          subjectPatientId: patientId,
          detail: 'wallet',
        );
        return (await _invoiceRow(invoiceId)).toEntity();
      }),
    );
  }

  @override
  Future<Result<Invoice>> recordOfflinePayment({
    required String invoiceId,
    required String receiptReference,
    String? note,
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final admin = await _access.require(
        Permission.manageBilling,
        entityType: 'billing',
        entityId: invoiceId,
      );
      final receipt = receiptReference.trim();
      if (receipt.isEmpty) {
        throw const ValidationFailure(
          'Enter the receipt number for the payment taken.',
          fieldErrors: {'receipt': 'Required'},
        );
      }
      final actor = admin?.accountId;
      return _db.transaction(() async {
        final prior = await _prior(idempotencyKey, _offlineScope, actor);
        if (prior != null) {
          return (await _invoiceRow(
            prior.txn?.invoiceId ?? prior.legacyRef!,
          )).toEntity();
        }
        final invoice = await _openInvoice(invoiceId);
        if (await _liveCharge(invoiceId) != null) {
          throw const ValidationFailure(
            'A card payment for this invoice is still being confirmed. '
            'Reconcile payments first.',
          );
        }
        final now = _now();
        final txn = await _insertTxn(
          patientId: invoice.patientId,
          invoiceId: invoiceId,
          kind: PaymentKind.invoiceCharge,
          method: PaymentMethodKind.offline,
          amount: invoice.totalAmount,
          provider: 'offline',
          descriptor: 'Paid at desk',
          actor: actor,
          status: PaymentStatus.settled,
          providerReference: receipt,
          reason: note?.trim(),
        );
        await _markInvoicePaid(
          invoiceId,
          descriptor: 'Paid at desk',
          payer: actor,
          at: now,
        );
        await _idempotency.remember(
          idempotencyKey,
          scope: _offlineScope,
          actorAccountId: actor,
          resultRef: txn.id,
        );
        await _access.audit(
          'billing.payment.offline',
          entityType: 'billing',
          entityId: invoiceId,
          subjectPatientId: invoice.patientId,
          detail: 'receipt $receipt',
        );
        return (await _invoiceRow(invoiceId)).toEntity();
      });
    });
  }

  // --- issuing -------------------------------------------------------------

  @override
  Future<Result<Invoice>> issue(
    NewInvoice invoice, {
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final issuer = await _access.require(
        Permission.manageBilling,
        entityType: 'billing',
      );
      final prior = await _idempotency.prior(
        idempotencyKey,
        scope: 'billing.issue',
        actorAccountId: issuer?.accountId,
      );
      if (prior != null) return (await _invoiceRow(prior)).toEntity();
      if (!invoice.subtotal.isFinite ||
          !invoice.taxRate.isFinite ||
          invoice.subtotal < 0 ||
          invoice.taxRate < 0) {
        throw const ValidationFailure('Amount cannot be negative.');
      }
      final id = newId('inv');
      final subtotalFils = _fils(invoice.subtotal);
      final taxFils = (subtotalFils * invoice.taxRate / 100).round();
      await _db.transaction(() async {
        await _db
            .into(_db.invoices)
            .insert(
              InvoicesCompanion.insert(
                id: id,
                patientId: invoice.patientId,
                subtotal: Value(subtotalFils / 1000),
                taxRate: Value(invoice.taxRate),
                taxAmount: Value(taxFils / 1000),
                totalAmount: Value((subtotalFils + taxFils) / 1000),
                appointmentId: Value(invoice.appointmentId),
                dueDate: Value(invoice.dueDate),
                notes: Value(invoice.notes),
              ),
            );
        await _idempotency.remember(
          idempotencyKey,
          scope: 'billing.issue',
          actorAccountId: issuer?.accountId,
          resultRef: id,
        );
      });
      return (await _invoiceRow(id)).toEntity();
    });
  }

  // --- refunds -------------------------------------------------------------

  @override
  Future<Result<PaymentTransaction>> refund({
    required String transactionId,
    required double amount,
    required String reason,
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final admin = await _access.require(
        Permission.refundPayments,
        entityType: 'billing',
        entityId: transactionId,
      );
      final actor = admin?.accountId;
      if (reason.trim().isEmpty) {
        throw const ValidationFailure(
          'Give a reason for the refund.',
          fieldErrors: {'reason': 'Required'},
        );
      }
      if (!amount.isFinite || _fils(amount) <= 0) {
        throw const ValidationFailure('Enter an amount greater than zero.');
      }
      final attempt = await _db.transaction(() async {
        final prior = await _prior(idempotencyKey, _refundScope, actor);
        if (prior != null) return prior;
        final original = await _txnRow(transactionId);
        if (original.kind != PaymentKind.invoiceCharge ||
            original.status != PaymentStatus.settled) {
          throw const ValidationFailure(
            'Only a settled invoice payment can be refunded.',
          );
        }
        final remaining =
            _fils(original.amount) - await _refundedFils(original);
        if (_fils(amount) > remaining) {
          throw ValidationFailure(
            'That is more than is left to refund '
            '(BD ${(remaining / 1000).toStringAsFixed(3)}).',
          );
        }
        // Card refunds go back through the provider; wallet refunds return
        // to the wallet; desk and pre-ledger payments are returned at the
        // desk and recorded here.
        final viaProvider =
            original.provider == _gateway.providerName &&
            original.providerReference != null;
        final txn = await _insertTxn(
          patientId: original.patientId,
          invoiceId: original.invoiceId,
          kind: PaymentKind.refund,
          method: original.method == PaymentMethodKind.wallet
              ? PaymentMethodKind.wallet
              : viaProvider
              ? original.method
              : PaymentMethodKind.offline,
          amount: _fils(amount) / 1000,
          provider: viaProvider
              ? _gateway.providerName
              : original.method == PaymentMethodKind.wallet
              ? 'wallet'
              : 'offline',
          descriptor: original.methodDescriptor,
          actor: actor,
          refundOfId: original.id,
          reason: reason.trim(),
        );
        await _idempotency.remember(
          idempotencyKey,
          scope: _refundScope,
          actorAccountId: actor,
          resultRef: txn.id,
        );
        await _access.audit(
          'billing.refund.requested',
          entityType: 'billing',
          entityId: original.invoiceId,
          subjectPatientId: original.patientId,
          detail: 'BD ${(_fils(amount) / 1000).toStringAsFixed(3)}',
        );
        if (!viaProvider) {
          final settled = await _applyOutcome(
            txn.id,
            GatewayOutcome(
              status: GatewayStatus.refunded,
              providerReference: txn.provider == 'wallet'
                  ? 'wallet_${txn.id}'
                  : 'desk_${txn.id}',
            ),
          );
          return (txn: settled, legacyRef: null);
        }
        return (txn: txn, legacyRef: null);
      });
      final txn = attempt.txn;
      if (txn == null) {
        throw const ValidationFailure(
          'This request was already used for something else. Start again.',
        );
      }
      if (_isFinal(txn.status)) return _finalOrThrow(txn).toEntity();
      final original = await _txnRow(txn.refundOfId!);
      final GatewayOutcome outcome;
      try {
        outcome = await _gateway.refund(
          reference: txn.requestReference,
          chargeProviderReference: original.providerReference!,
          amountFils: _fils(txn.amount),
        );
      } on GatewayUnavailable {
        throw PaymentPendingFailure.forTransaction(
          txn.id,
          'The refund was sent but not yet confirmed. It will not be sent '
          'twice; reconcile to see the outcome.',
        );
      }
      return _finalOrThrow(await _applyOutcome(txn.id, outcome)).toEntity();
    });
  }

  Future<int> _refundedFils(PaymentTransactionRow original) async {
    final refunds =
        await (_db.select(_db.paymentTransactions)..where(
              (t) =>
                  t.refundOfId.equals(original.id) &
                  t.kind.equalsValue(PaymentKind.refund) &
                  t.status.isInValues(const [
                    PaymentStatus.initiated,
                    PaymentStatus.authorized,
                    PaymentStatus.settled,
                  ]),
            ))
            .get();
    return refunds.fold<int>(0, (sum, r) => sum + _fils(r.amount));
  }

  // --- reconciliation ------------------------------------------------------

  @override
  Future<Result<int>> reconcile({String? patientId}) {
    return Result.guardAsync(() async {
      if (patientId != null) {
        await _readPayments(patientId);
      } else {
        await _access.require(Permission.manageBilling, entityType: 'billing');
      }
      return reconcilePending(patientId: patientId);
    });
  }

  /// The reconciliation job itself, without an authorization check — for
  /// app start-up (a system task, not a user action). User-facing callers go
  /// through [reconcile].
  Future<int> reconcilePending({String? patientId}) async {
    return _reconcileRows(await _liveCharges(patientId: patientId));
  }

  Future<int> _reconcileRows(List<PaymentTransactionRow> rows) async {
    var resolved = 0;
    for (final row in rows) {
      if (row.provider != _gateway.providerName) continue;
      final GatewayOutcome? found;
      try {
        found = await _gateway.lookup(row.requestReference);
      } on GatewayUnavailable {
        continue; // try again next time
      }
      if (found != null) {
        await _applyOutcome(row.id, found);
        resolved++;
        continue;
      }
      final now = _now();
      if (now.difference(row.createdAt) >= notReceivedAfter) {
        // The provider never received it: nothing was charged.
        final changed =
            await (_db.update(_db.paymentTransactions)..where(
                  (t) => t.id.equals(row.id) & t.status.isInValues(_inFlight),
                ))
                .write(
                  PaymentTransactionsCompanion(
                    status: const Value(PaymentStatus.failed),
                    failureReason: const Value('not_received'),
                    updatedAt: Value(now),
                    reconciledAt: Value(now),
                  ),
                );
        if (changed == 1) {
          resolved++;
          await _access.audit(
            'billing.payment.released',
            entityType: 'billing',
            entityId: row.invoiceId,
            subjectPatientId: row.patientId,
            detail: 'not received by provider',
          );
        }
      } else {
        await (_db.update(_db.paymentTransactions)
              ..where((t) => t.id.equals(row.id)))
            .write(PaymentTransactionsCompanion(reconciledAt: Value(now)));
      }
    }
    return resolved;
  }

  /// Charges and refunds whose outcome is not known yet.
  Future<List<PaymentTransactionRow>> _liveCharges({
    String? invoiceId,
    String? patientId,
  }) {
    final q = _db.select(_db.paymentTransactions)
      ..where((t) => t.status.isInValues(_inFlight))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    if (invoiceId != null) q.where((t) => t.invoiceId.equals(invoiceId));
    if (patientId != null) q.where((t) => t.patientId.equals(patientId));
    return q.get();
  }

  /// The invoice charge being confirmed for [invoiceId], if any.
  Future<PaymentTransactionRow?> _liveCharge(String invoiceId) {
    return (_db.select(_db.paymentTransactions)
          ..where(
            (t) =>
                t.invoiceId.equals(invoiceId) &
                t.kind.equalsValue(PaymentKind.invoiceCharge) &
                t.status.isInValues(_inFlight),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // --- the two-phase provider call ----------------------------------------

  /// Asks the provider to charge for [txn] (again, if it was never answered —
  /// safe, as the provider dedupes on the request reference) and applies the
  /// answer. Returns the settled row; throws for a decline or an unknown
  /// outcome.
  Future<PaymentTransactionRow> _chargeWithProvider(
    PaymentTransactionRow txn,
    GatewayCard card,
  ) async {
    if (_isFinal(txn.status)) return _finalOrThrow(txn);
    final GatewayOutcome outcome;
    try {
      outcome = await _gateway.charge(
        reference: txn.requestReference,
        amountFils: _fils(txn.amount),
        card: card,
      );
    } on GatewayUnavailable {
      await (_db.update(_db.paymentTransactions)
            ..where((t) => t.id.equals(txn.id)))
          .write(PaymentTransactionsCompanion(updatedAt: Value(_now())));
      throw PaymentPendingFailure.forTransaction(txn.id);
    }
    return _finalOrThrow(await _applyOutcome(txn.id, outcome));
  }

  /// Applies the provider's answer to a transaction, once: a row already in
  /// a final state is returned unchanged, so a late or repeated answer (a
  /// retry racing reconciliation) can never settle twice.
  Future<PaymentTransactionRow> _applyOutcome(
    String txnId,
    GatewayOutcome outcome,
  ) {
    return _db.transaction(() async {
      final txn = await _txnRow(txnId);
      if (_isFinal(txn.status)) return txn;
      final now = _now();
      if (!outcome.succeeded) {
        await (_db.update(
          _db.paymentTransactions,
        )..where((t) => t.id.equals(txnId))).write(
          PaymentTransactionsCompanion(
            status: const Value(PaymentStatus.failed),
            failureReason: Value(outcome.declineCode ?? 'declined'),
            providerReference: Value(outcome.providerReference),
            updatedAt: Value(now),
          ),
        );
        await _access.audit(
          txn.kind == PaymentKind.refund
              ? 'billing.refund.declined'
              : 'billing.payment.declined',
          entityType: 'billing',
          entityId: txn.invoiceId,
          subjectPatientId: txn.patientId,
          detail: outcome.declineCode,
        );
        return _txnRow(txnId);
      }
      await (_db.update(
        _db.paymentTransactions,
      )..where((t) => t.id.equals(txnId))).write(
        PaymentTransactionsCompanion(
          status: const Value(PaymentStatus.settled),
          providerReference: Value(outcome.providerReference),
          settledAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      switch (txn.kind) {
        case PaymentKind.invoiceCharge:
          final paid = await _markInvoicePaid(
            txn.invoiceId!,
            descriptor: txn.methodDescriptor ?? 'Card',
            payer: txn.actorAccountId,
            at: now,
            strict: false,
          );
          if (!paid) {
            // The money moved but the bill was no longer open: flag it for a
            // refund rather than lose it.
            await (_db.update(
              _db.paymentTransactions,
            )..where((t) => t.id.equals(txnId))).write(
              const PaymentTransactionsCompanion(
                failureReason: Value('invoice_not_open'),
              ),
            );
          }
          await _access.audit(
            paid ? 'billing.payment.settled' : 'billing.payment.needs_refund',
            entityType: 'billing',
            entityId: txn.invoiceId,
            subjectPatientId: txn.patientId,
          );
        case PaymentKind.walletTopUp:
          await _db
              .into(_db.walletTransactions)
              .insert(
                WalletTransactionsCompanion.insert(
                  id: 'wtx_${txn.id}',
                  patientId: txn.patientId,
                  type: WalletTransactionType.topUp,
                  amount: txn.amount,
                  method: Value(txn.methodDescriptor),
                  actorAccountId: Value(txn.actorAccountId),
                  createdAt: Value(now),
                ),
                mode: InsertMode.insertOrIgnore,
              );
          await _access.audit(
            'billing.top_up.settled',
            entityType: 'billing',
            subjectPatientId: txn.patientId,
          );
        case PaymentKind.refund:
          await _afterRefundSettled(txn, now);
      }
      return _txnRow(txnId);
    });
  }

  /// A settled refund: money back to the wallet when it came from there, and
  /// the invoice marked refunded once the whole charge has been returned.
  Future<void> _afterRefundSettled(
    PaymentTransactionRow refund,
    DateTime now,
  ) async {
    final original = await _txnRow(refund.refundOfId!);
    if (refund.method == PaymentMethodKind.wallet) {
      await _db
          .into(_db.walletTransactions)
          .insert(
            WalletTransactionsCompanion.insert(
              id: 'wtx_${refund.id}',
              patientId: refund.patientId,
              type: WalletTransactionType.refund,
              amount: refund.amount,
              invoiceId: Value(refund.invoiceId),
              actorAccountId: Value(refund.actorAccountId),
              createdAt: Value(now),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final settled =
        await (_db.select(_db.paymentTransactions)..where(
              (t) =>
                  t.refundOfId.equals(original.id) &
                  t.status.equalsValue(PaymentStatus.settled),
            ))
            .get();
    final refundedFils = settled.fold<int>(0, (s, r) => s + _fils(r.amount));
    if (refund.invoiceId != null && refundedFils >= _fils(original.amount)) {
      await (_db.update(_db.invoices)..where(
            (i) =>
                i.id.equals(refund.invoiceId!) &
                i.status.equalsValue(InvoiceStatus.paid),
          ))
          .write(
            const InvoicesCompanion(status: Value(InvoiceStatus.refunded)),
          );
    }
    await _access.audit(
      'billing.refund.settled',
      entityType: 'billing',
      entityId: refund.invoiceId,
      subjectPatientId: refund.patientId,
    );
  }

  // --- wallet: saved cards -------------------------------------------------

  @override
  Future<Result<List<PaymentMethod>>> cardsFor(String patientId) {
    return Result.guardAsync(() async {
      await _readFinancial(patientId);
      final rows =
          await (_db.select(_db.paymentMethods)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([
                  (c) => OrderingTerm.desc(c.isDefault),
                  (c) => OrderingTerm.desc(c.addedAt),
                ]))
              .get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<PaymentMethod>> addCard({
    required String patientId,
    required CardPayment card,
  }) {
    return Result.guardAsync(() async {
      await _payer(patientId);
      _validateCard(card);
      final existing = await (_db.select(
        _db.paymentMethods,
      )..where((c) => c.patientId.equals(patientId))).get();

      // Don't save the same card twice.
      if (existing.any(
        (c) =>
            c.last4 == card.last4 &&
            c.expiryMonth == card.expiryMonth &&
            c.expiryYear == card.expiryYear,
      )) {
        throw const ValidationFailure('That card is already saved.');
      }

      final id = newId('card');
      await _db
          .into(_db.paymentMethods)
          .insert(
            PaymentMethodsCompanion.insert(
              id: id,
              patientId: patientId,
              brand: card.brand,
              last4: card.last4,
              expiryMonth: card.expiryMonth,
              expiryYear: card.expiryYear,
              holderName: card.cardHolder.trim(),
              isDefault: Value(existing.isEmpty),
            ),
          );
      final row = await (_db.select(
        _db.paymentMethods,
      )..where((c) => c.id.equals(id))).getSingle();
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> removeCard({
    required String id,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      await _payer(patientId, entityId: id);
      await (_db.delete(
        _db.paymentMethods,
      )..where((c) => c.id.equals(id) & c.patientId.equals(patientId))).go();
      // If we removed the default, promote the newest remaining card.
      final left =
          await (_db.select(_db.paymentMethods)
                ..where((c) => c.patientId.equals(patientId))
                ..orderBy([(c) => OrderingTerm.desc(c.addedAt)]))
              .get();
      if (left.isNotEmpty && !left.any((c) => c.isDefault)) {
        await (_db.update(_db.paymentMethods)
              ..where((c) => c.id.equals(left.first.id)))
            .write(const PaymentMethodsCompanion(isDefault: Value(true)));
      }
    });
  }

  @override
  Future<Result<void>> setDefaultCard({
    required String id,
    required String patientId,
  }) {
    return Result.guardAsync(() async {
      await _payer(patientId, entityId: id);
      await (_db.update(_db.paymentMethods)
            ..where((c) => c.patientId.equals(patientId)))
          .write(const PaymentMethodsCompanion(isDefault: Value(false)));
      await (_db.update(_db.paymentMethods)
            ..where((c) => c.id.equals(id) & c.patientId.equals(patientId)))
          .write(const PaymentMethodsCompanion(isDefault: Value(true)));
    });
  }

  // --- wallet: credit balance ----------------------------------------------

  @override
  Future<Result<double>> walletBalance(String patientId) {
    return Result.guardAsync(() async {
      await _readFinancial(patientId);
      return _balanceOf(patientId);
    });
  }

  @override
  Future<Result<double>> topUpWallet({
    required String patientId,
    required double amount,
    required CardPayment card,
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final payer = await _payer(patientId);
      _validateCard(card);
      return _topUp(
        patientId: patientId,
        payer: payer,
        amount: amount,
        card: GatewayCard(last4: card.last4, digits: card.digits),
        descriptor: card.maskedDescriptor,
        method: PaymentMethodKind.card,
        key: idempotencyKey,
      );
    });
  }

  @override
  Future<Result<double>> topUpWalletWithSavedCard({
    required String patientId,
    required double amount,
    required String cardId,
    required String cvc,
    IdempotencyKey? idempotencyKey,
  }) {
    return Result.guardAsync(() async {
      final payer = await _payer(patientId);
      final card = await _savedCard(patientId, cardId, cvc);
      return _topUp(
        patientId: patientId,
        payer: payer,
        amount: amount,
        card: GatewayCard(last4: card.last4, token: card.id),
        descriptor: '${card.brand} ····${card.last4}',
        method: PaymentMethodKind.savedCard,
        key: idempotencyKey,
      );
    });
  }

  /// A top-up credits the wallet only once the provider confirms the charge.
  Future<double> _topUp({
    required String patientId,
    required String? payer,
    required double amount,
    required GatewayCard card,
    required String descriptor,
    required PaymentMethodKind method,
    required IdempotencyKey? key,
  }) async {
    if (!amount.isFinite || _fils(amount) <= 0) {
      throw const ValidationFailure('Enter an amount greater than zero.');
    }
    final attempt = await _db.transaction(() async {
      final prior = await _prior(key, _topUpScope, payer);
      if (prior != null) return prior;
      final txn = await _insertTxn(
        patientId: patientId,
        kind: PaymentKind.walletTopUp,
        method: method,
        amount: _fils(amount) / 1000,
        provider: _gateway.providerName,
        descriptor: descriptor,
        actor: payer,
      );
      await _idempotency.remember(
        key,
        scope: _topUpScope,
        actorAccountId: payer,
        resultRef: txn.id,
      );
      return (txn: txn, legacyRef: null);
    });
    if (attempt.txn != null) {
      await _chargeWithProvider(attempt.txn!, card);
    }
    return _balanceOf(patientId);
  }

  // --- helpers -------------------------------------------------------------

  /// What [key] committed before, if anything.
  Future<_Prior?> _prior(
    IdempotencyKey? key,
    String scope,
    String? actor,
  ) async {
    final ref = await _idempotency.prior(
      key,
      scope: scope,
      actorAccountId: actor,
    );
    if (ref == null) return null;
    final txn = await (_db.select(
      _db.paymentTransactions,
    )..where((t) => t.id.equals(ref))).getSingleOrNull();
    return (txn: txn, legacyRef: txn == null ? ref : null);
  }

  Future<PaymentTransactionRow> _insertTxn({
    required String patientId,
    required PaymentKind kind,
    required PaymentMethodKind method,
    required double amount,
    required String provider,
    required String? actor,
    String? invoiceId,
    String? descriptor,
    PaymentStatus status = PaymentStatus.initiated,
    String? providerReference,
    String? refundOfId,
    String? reason,
  }) async {
    final id = newId('ptx');
    final now = _now();
    final settled = status == PaymentStatus.settled;
    await _db
        .into(_db.paymentTransactions)
        .insert(
          PaymentTransactionsCompanion.insert(
            id: id,
            patientId: patientId,
            invoiceId: Value(invoiceId),
            kind: kind,
            method: method,
            status: Value(status),
            amount: amount,
            provider: provider,
            requestReference: 'req_$id',
            providerReference: Value(
              providerReference ?? (settled ? '${provider}_$id' : null),
            ),
            methodDescriptor: Value(descriptor),
            refundOfId: Value(refundOfId),
            reason: Value(reason),
            actorAccountId: Value(actor),
            createdAt: now,
            updatedAt: now,
            settledAt: Value(settled ? now : null),
          ),
        );
    return _txnRow(id);
  }

  Future<PaymentTransactionRow> _txnRow(String id) async {
    final row = await (_db.select(
      _db.paymentTransactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Payment not found.');
    return row;
  }

  Future<InvoiceRow> _invoiceRow(String id) async {
    final row = await (_db.select(
      _db.invoices,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Invoice not found.');
    return row;
  }

  /// A payable invoice — belonging to [patientId] when given.
  Future<InvoiceRow> _openInvoice(String id, {String? patientId}) async {
    final q = _db.select(_db.invoices)..where((i) => i.id.equals(id));
    if (patientId != null) q.where((i) => i.patientId.equals(patientId));
    final row = await q.getSingleOrNull();
    if (row == null) throw const NotFoundFailure('Invoice not found.');
    switch (row.status) {
      case InvoiceStatus.pending:
        return row;
      case InvoiceStatus.paid:
        throw const ValidationFailure('This invoice is already paid.');
      case InvoiceStatus.cancelled:
        throw const ValidationFailure('This invoice was cancelled.');
      case InvoiceStatus.refunded:
        throw const ValidationFailure('This invoice was refunded.');
    }
  }

  /// Moves an open invoice to paid. With [strict], anything else is a
  /// conflict; without, returns whether it was still open.
  Future<bool> _markInvoicePaid(
    String invoiceId, {
    required String descriptor,
    required String? payer,
    required DateTime at,
    bool strict = true,
  }) async {
    final changed =
        await (_db.update(_db.invoices)..where(
              (i) =>
                  i.id.equals(invoiceId) &
                  i.status.equalsValue(InvoiceStatus.pending),
            ))
            .write(
              InvoicesCompanion(
                status: const Value(InvoiceStatus.paid),
                paidAt: Value(at),
                // Masked descriptor only — never the card number itself.
                paymentMethod: Value(descriptor),
                paidByAccountId: Value(payer),
              ),
            );
    if (changed != 1 && strict) {
      throw const ConflictFailure('This invoice is no longer unpaid.');
    }
    return changed == 1;
  }

  static bool _isFinal(PaymentStatus s) =>
      s == PaymentStatus.settled ||
      s == PaymentStatus.failed ||
      s == PaymentStatus.voided;

  /// A finished transaction, or the failure it ended in.
  static PaymentTransactionRow _finalOrThrow(PaymentTransactionRow txn) {
    if (txn.status == PaymentStatus.settled) return txn;
    if (!_isFinal(txn.status)) {
      throw PaymentPendingFailure.forTransaction(txn.id);
    }
    throw PaymentDeclinedFailure(switch (txn.failureReason) {
      'card_declined' => 'The card was declined. Nothing was charged.',
      'insufficient_funds' =>
        'The card has insufficient funds. Nothing was charged.',
      'not_received' =>
        'This payment did not reach the provider and nothing was charged. '
            'Please try again.',
      'refund_exceeds_charge' =>
        'The provider refused the refund: it exceeds the original charge.',
      _ => 'The payment did not go through. Nothing was charged.',
    }, code: txn.failureReason);
  }

  Future<PaymentMethodRow> _savedCard(
    String patientId,
    String cardId,
    String cvc,
  ) async {
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvc)) {
      throw const ValidationFailure('CVC must be 3 or 4 digits.');
    }
    final card =
        await (_db.select(_db.paymentMethods)..where(
              (c) => c.id.equals(cardId) & c.patientId.equals(patientId),
            ))
            .getSingleOrNull();
    if (card == null) throw const NotFoundFailure('Card not found.');
    final firstOfNextMonth = card.expiryMonth == 12
        ? DateTime(card.expiryYear + 1)
        : DateTime(card.expiryYear, card.expiryMonth + 1);
    if (!firstOfNextMonth.isAfter(_now())) {
      throw const ValidationFailure(
        'That card has expired. Choose another card.',
      );
    }
    return card;
  }

  /// BHD has three decimal places; money is compared in whole fils so
  /// floating-point drift can't make an exact balance look short.
  static int _fils(double bhd) => (bhd * 1000).round();

  Future<double> _balanceOf(String patientId) async {
    final rows = await (_db.select(
      _db.walletTransactions,
    )..where((w) => w.patientId.equals(patientId))).get();
    final balanceFils = rows.fold<int>(0, (sum, row) {
      final amount = _fils(row.amount);
      return switch (row.type) {
        WalletTransactionType.topUp ||
        WalletTransactionType.refund => sum + amount,
        WalletTransactionType.redemption => sum - amount,
      };
    });
    return balanceFils / 1000;
  }

  void _validateCard(CardPayment p) {
    if (p.cardHolder.trim().isEmpty) {
      throw const ValidationFailure('Enter the name on the card.');
    }
    if (!passesLuhn(p.digits)) {
      throw const ValidationFailure('That card number is not valid.');
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(p.cvc)) {
      throw const ValidationFailure('CVC must be 3 or 4 digits.');
    }
    if (p.expiryMonth < 1 || p.expiryMonth > 12) {
      throw const ValidationFailure('Expiry month must be between 1 and 12.');
    }
    // Expiry is end-of-month, so a card expiring this month is still valid.
    final now = _now();
    final expiresAfter = DateTime(p.expiryYear, p.expiryMonth + 1);
    if (!expiresAfter.isAfter(now)) {
      throw const ValidationFailure('That card has expired.');
    }
  }
}
