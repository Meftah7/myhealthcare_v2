// Phase 5 gate: an invoice is paid only by a settled payment; interrupted
// payments reconcile without double-charging; refunds and financial
// transitions are authorized and bounded.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/billing_repository_impl.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/billing_repository.dart';
import 'package:myhealthcare/services/payments/payment_gateway.dart';

import '../support/sessions.dart';

const _patient = 'patient3@myhealth.demo';
const _patientId = 'patient_003';

CardPayment _card([String number = '4242424242424242']) => CardPayment(
  cardNumber: number,
  cardHolder: 'Test Patient',
  expiryMonth: 12,
  expiryYear: DateTime.now().year + 3,
  cvc: '123',
);

Matcher _fails<T extends Failure>() =>
    isA<Err<dynamic>>().having((e) => e.failure, 'failure', isA<T>());

Matcher get _denied => _fails<AccessDeniedFailure>();

class _Env {
  _Env(this.c, this.db);
  final ProviderContainer c;
  final AppDatabase db;

  BillingRepository get billing => c.read(billingRepositoryProvider);
  SimulatedPaymentGateway get gateway =>
      c.read(paymentGatewayProvider) as SimulatedPaymentGateway;

  Future<Invoice> openInvoice() async {
    final all = (await billing.forPatient(_patientId)).valueOrNull!;
    return all.firstWhere((i) => i.status == InvoiceStatus.pending);
  }

  Future<InvoiceRow> invoiceRow(String id) =>
      (db.select(db.invoices)..where((i) => i.id.equals(id))).getSingle();

  Future<List<PaymentTransactionRow>> txns(String invoiceId) => (db.select(
    db.paymentTransactions,
  )..where((t) => t.invoiceId.equals(invoiceId))).get();

  /// Captures the provider recorded for this invoice's attempts.
  Future<int> captures(String invoiceId) async {
    final refs = [for (final t in await txns(invoiceId)) t.requestReference];
    final rows =
        await (db.select(db.simulatedGatewayCharges)..where(
              (c) =>
                  c.reference.isIn(refs) &
                  c.operation.equals('charge') &
                  c.status.equals('captured'),
            ))
            .get();
    return rows.length;
  }
}

Future<_Env> _asPatient() async {
  final (c, db) = await seededContainer();
  await signInAs(c, _patient);
  return _Env(c, db);
}

void main() {
  group('paid means a settled payment', () {
    test('a card payment settles through the ledger', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      final paid = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(paid.valueOrNull?.status, InvoiceStatus.paid);
      final txn = (await env.txns(invoice.id)).single;
      expect(txn.status, PaymentStatus.settled);
      expect(txn.providerReference, startsWith('sim_ch'));
      expect(txn.methodDescriptor, 'Card ····4242');
      expect(await env.captures(invoice.id), 1);
    });

    test('a declined card charges nothing and leaves the bill open', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      final declined = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(SimulatedPaymentGateway.declinedCard),
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(declined, _fails<PaymentDeclinedFailure>());
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.pending);
      expect((await env.txns(invoice.id)).single.status, PaymentStatus.failed);

      final retry = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(retry.valueOrNull?.status, InvoiceStatus.paid);
      expect(await env.captures(invoice.id), 1);
    });

    test(
      'an admin cannot mark an invoice paid by changing its status',
      () async {
        final env = await _asPatient();
        final invoice = await env.openInvoice();
        await signInAs(env.c, 'admin@myhealth.demo');
        expect(
          await env.billing.setStatus(
            id: invoice.id,
            status: InvoiceStatus.paid,
          ),
          _fails<ValidationFailure>(),
        );
        // …and the database refuses backwards moves whatever code tries.
        final paidRow =
            await (env.db.select(env.db.invoices)
                  ..where((i) => i.status.equalsValue(InvoiceStatus.paid))
                  ..limit(1))
                .getSingle();
        await expectLater(
          env.db.customStatement(
            "UPDATE invoices SET status = 'pending' WHERE id = '${paidRow.id}'",
          ),
          throwsA(anything),
        );
        await expectLater(
          env.db.customStatement('DELETE FROM payment_transactions'),
          throwsA(anything),
        );
      },
    );

    test('desk payments need a receipt and an admin', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      expect(
        await env.billing.recordOfflinePayment(
          invoiceId: invoice.id,
          receiptReference: 'R-1',
        ),
        _denied,
      );
      await signInAs(env.c, 'admin@myhealth.demo');
      expect(
        await env.billing.recordOfflinePayment(
          invoiceId: invoice.id,
          receiptReference: '  ',
        ),
        _fails<ValidationFailure>(),
      );
      final paid = await env.billing.recordOfflinePayment(
        invoiceId: invoice.id,
        receiptReference: 'DESK-0042',
        note: 'Cash',
      );
      expect(paid.valueOrNull?.status, InvoiceStatus.paid);
      final txn = (await env.txns(invoice.id)).single;
      expect(txn.method, PaymentMethodKind.offline);
      expect(txn.providerReference, 'DESK-0042');
    });
  });

  group('interrupted payments reconcile and never double-charge', () {
    test('a lost answer is pending, then the same-key retry completes it '
        'without a second charge', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      final key = IdempotencyKey.generate();
      env.gateway.pendingFaults.add(SimulatedFault.responseLost);

      final first = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: key,
      );
      expect(first, _fails<PaymentPendingFailure>());
      // The provider took the money, but the app must not claim "paid" on a
      // lost answer.
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.pending);

      final retry = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: key,
      );
      expect(retry.valueOrNull?.status, InvoiceStatus.paid);
      expect(await env.captures(invoice.id), 1);
      expect(
        (await env.txns(
          invoice.id,
        )).where((t) => t.status == PaymentStatus.settled),
        hasLength(1),
      );
    });

    test('after a restart, reconciliation settles a charge the provider '
        'took — without charging again', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      env.gateway.pendingFaults.add(SimulatedFault.responseLost);
      await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );

      // The app restarts: a new repository and gateway over the same data.
      final restarted = BillingRepositoryImpl(env.db);
      expect(await restarted.reconcilePending(), 1);
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.paid);
      expect(await env.captures(invoice.id), 1);
    });

    test('a charge that never reached the provider is released after the '
        'grace period, and paying again charges once', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      env.gateway.pendingFaults.add(SimulatedFault.unreachable);
      final lost = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(lost, _fails<PaymentPendingFailure>());

      // While it is unconfirmed, no other payment can be started for the
      // bill — by card or wallet.
      expect(
        await env.billing.payWithWallet(
          invoiceId: invoice.id,
          patientId: _patientId,
        ),
        _fails<PaymentPendingFailure>(),
      );
      // Too early to call it lost: still pending.
      expect(
        (await env.billing.reconcile(patientId: _patientId)).valueOrNull,
        0,
      );

      final later = BillingRepositoryImpl(
        env.db,
        access: env.c.read(accessPolicyProvider),
        now: () => DateTime.now().add(const Duration(minutes: 3)),
      );
      expect((await later.reconcile(patientId: _patientId)).valueOrNull, 1);
      final released = (await env.txns(invoice.id)).single;
      expect(released.status, PaymentStatus.failed);
      expect(released.failureReason, 'not_received');
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.pending);

      final paid = await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      expect(paid.valueOrNull?.status, InvoiceStatus.paid);
      expect(await env.captures(invoice.id), 1);
    });

    test(
      'a wallet top-up is credited only once the provider confirms it',
      () async {
        final env = await _asPatient();
        final before = (await env.billing.walletBalance(
          _patientId,
        )).valueOrNull!;
        final key = IdempotencyKey.generate();
        env.gateway.pendingFaults.add(SimulatedFault.responseLost);
        expect(
          await env.billing.topUpWallet(
            patientId: _patientId,
            amount: 20,
            card: _card(),
            idempotencyKey: key,
          ),
          _fails<PaymentPendingFailure>(),
        );
        expect(
          (await env.billing.walletBalance(_patientId)).valueOrNull,
          before,
        );
        final retried = await env.billing.topUpWallet(
          patientId: _patientId,
          amount: 20,
          card: _card(),
          idempotencyKey: key,
        );
        expect(retried.valueOrNull, before + 20);
        final again = await env.billing.topUpWallet(
          patientId: _patientId,
          amount: 20,
          card: _card(),
          idempotencyKey: key,
        );
        expect(again.valueOrNull, before + 20);
      },
    );
  });

  group('refunds', () {
    Future<(Invoice, PaymentTransaction)> paidByCard(_Env env) async {
      final invoice = await env.openInvoice();
      await env.billing.pay(
        invoiceId: invoice.id,
        patientId: _patientId,
        payment: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      final txn = (await env.billing.transactions(
        invoiceId: invoice.id,
      )).valueOrNull!.single;
      return (invoice, txn);
    }

    test('only an admin with the refund permission may refund', () async {
      final env = await _asPatient();
      final (_, txn) = await paidByCard(env);
      expect(
        await env.billing.refund(transactionId: txn.id, amount: 1, reason: 'x'),
        _denied,
      );
      await signInAs(env.c, 'staff1@myhealth.demo');
      expect(
        await env.billing.refund(transactionId: txn.id, amount: 1, reason: 'x'),
        _denied,
      );
    });

    test('partial then full refund through the provider; never more than '
        'was paid', () async {
      final env = await _asPatient();
      final (invoice, txn) = await paidByCard(env);
      await signInAs(env.c, 'admin@myhealth.demo');
      expect(
        await env.billing.refund(transactionId: txn.id, amount: 5, reason: ''),
        _fails<ValidationFailure>(),
      );
      final part = await env.billing.refund(
        transactionId: txn.id,
        amount: 5,
        reason: 'Lab test not performed',
      );
      expect(part.valueOrNull?.status, PaymentStatus.settled);
      expect(part.valueOrNull?.providerReference, startsWith('sim_re'));
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.paid);

      expect(
        await env.billing.refund(
          transactionId: txn.id,
          amount: txn.amount,
          reason: 'too much',
        ),
        _fails<ValidationFailure>(),
      );
      final rest = await env.billing.refund(
        transactionId: txn.id,
        amount: ((txn.amount * 1000).round() - 5000) / 1000,
        reason: 'Visit cancelled by clinic',
      );
      expect(rest.isOk, isTrue);
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.refunded);
      // A refund is not itself refundable.
      expect(
        await env.billing.refund(
          transactionId: rest.valueOrNull!.id,
          amount: 1,
          reason: 'x',
        ),
        _fails<ValidationFailure>(),
      );
    });

    test('a wallet payment is refunded to the wallet', () async {
      final env = await _asPatient();
      final invoice = await env.openInvoice();
      await env.billing.topUpWallet(
        patientId: _patientId,
        amount: invoice.totalAmount + 10,
        card: _card(),
        idempotencyKey: IdempotencyKey.generate(),
      );
      await env.billing.payWithWallet(
        invoiceId: invoice.id,
        patientId: _patientId,
      );
      final before = (await env.billing.walletBalance(_patientId)).valueOrNull!;
      final txn = (await env.billing.transactions(
        invoiceId: invoice.id,
      )).valueOrNull!.single;
      await signInAs(env.c, 'admin@myhealth.demo');
      final refund = await env.billing.refund(
        transactionId: txn.id,
        amount: invoice.totalAmount,
        reason: 'Duplicate bill',
      );
      expect(refund.valueOrNull?.method, PaymentMethodKind.wallet);
      await signInAs(env.c, _patient);
      final after = (await env.billing.walletBalance(_patientId)).valueOrNull!;
      expect(
        (after * 1000).round(),
        ((before + invoice.totalAmount) * 1000).round(),
      );
      expect((await env.invoiceRow(invoice.id)).status, InvoiceStatus.refunded);
    });

    test('a seeded (pre-existing) card payment can be refunded', () async {
      final env = await _asPatient();
      await signInAs(env.c, 'admin@myhealth.demo');
      final seeded =
          await (env.db.select(env.db.paymentTransactions)
                ..where((t) => t.id.like('ptx_seed_%'))
                ..limit(1))
              .getSingle();
      final r = await env.billing.refund(
        transactionId: seeded.id,
        amount: seeded.amount,
        reason: 'Goodwill',
      );
      expect(r.valueOrNull?.status, PaymentStatus.settled);
    });
  });

  test("a patient cannot read another patient's payments", () async {
    final env = await _asPatient();
    expect(await env.billing.transactions(patientId: 'patient_001'), _denied);
  });
}
