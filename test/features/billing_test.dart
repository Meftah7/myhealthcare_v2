// Billing: a patient sees their invoices, settles an open one, and cannot
// touch anyone else's.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/billing_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/billing_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/billing/application/billing_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

/// A Luhn-valid test card that expires comfortably in the future.
CardPayment validCard() => CardPayment(
  cardNumber: '4242424242424242',
  cardHolder: 'Ali Mohamed',
  expiryMonth: 12,
  expiryYear: DateTime.now().year + 3,
  cvc: '123',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Luhn check', () {
    test('accepts a valid number and rejects a typo', () {
      expect(passesLuhn('4242424242424242'), isTrue);
      expect(passesLuhn('4242424242424243'), isFalse);
      expect(passesLuhn('123'), isFalse); // too short
    });
  });

  test('patient sees seeded invoices and can pay an open one', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final login = await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    expect(login.isOk, isTrue);

    final invoices = await container.read(patientInvoicesProvider.future);
    expect(invoices, isNotEmpty, reason: 'completed visits should be billed');

    // Newest first.
    for (var i = 1; i < invoices.length; i++) {
      expect(
        invoices[i - 1].issuedAt.isBefore(invoices[i].issuedAt),
        isFalse,
        reason: 'invoices should be ordered newest first',
      );
    }

    // Totals add up.
    final any = invoices.first;
    expect(
      any.totalAmount,
      closeTo(any.subtotal + any.taxAmount, 0.001),
    );

    final open = invoices.where((i) => i.isPayable).toList();
    expect(open, isNotEmpty, reason: 'seed leaves recent visits unpaid');

    final summaryBefore = container.read(billingSummaryProvider).value!;
    expect(summaryBefore.outstanding, greaterThan(0));

    final target = open.first;
    final paid = await container
        .read(billingControllerProvider)
        .pay(target.id, validCard());
    expect(paid.isOk, isTrue);
    expect(paid.valueOrNull!.status, InvoiceStatus.paid);
    expect(paid.valueOrNull!.paidAt, isNotNull);

    // Only the masked descriptor is kept — never the card number.
    expect(paid.valueOrNull!.paymentMethod, 'Card ····4242');
    expect(paid.valueOrNull!.paymentMethod, isNot(contains('4242424242')));

    // Outstanding balance drops by exactly that invoice. Paying invalidates
    // the list, so wait for it to re-resolve before reading the summary.
    await container.read(patientInvoicesProvider.future);
    final summaryAfter = container.read(billingSummaryProvider).value!;
    expect(
      summaryAfter.outstanding,
      closeTo(summaryBefore.outstanding - target.totalAmount, 0.001),
    );

    // Paying it again is rejected.
    final again = await container
        .read(billingControllerProvider)
        .pay(target.id, validCard());
    expect(again.isErr, isTrue);
    expect(again.failureOrNull!.message, contains('already paid'));
  });

  test('cannot pay another patient\'s invoice', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final repo = BillingRepositoryImpl(db);

    // Find an invoice belonging to someone, then try to pay it as somebody
    // else. It must fail the same way a missing invoice does.
    final users = await db.select(db.users).get();
    final patients = users.where((u) => u.role == UserRole.patient).toList();
    expect(patients.length, greaterThan(1));

    final ownerInvoices = <String, String>{}; // invoiceId -> ownerId
    for (final p in patients) {
      final list = (await repo.forPatient(p.id)).valueOrNull ?? const [];
      if (list.isNotEmpty) {
        ownerInvoices[list.first.id] = p.id;
        if (ownerInvoices.length == 2) break;
      }
    }
    expect(ownerInvoices.length, 2);

    final entries = ownerInvoices.entries.toList();
    final victimInvoiceId = entries.first.key;
    final attackerId = entries.last.value;

    final result = await repo.pay(
      invoiceId: victimInvoiceId,
      patientId: attackerId,
      payment: validCard(),
    );
    expect(result.isErr, isTrue);
    expect(result.failureOrNull!.message, contains('not found'));

    // And the invoice is untouched.
    final still = (await repo.byId(victimInvoiceId)).valueOrNull!;
    expect(still.status, isNot(InvoiceStatus.paid));
  });

  group('card validation', () {
    late AppDatabaseHarness harness;

    setUp(() async {
      harness = await AppDatabaseHarness.create();
    });
    tearDown(() => harness.db.close());

    Future<void> expectRejected(CardPayment card, String contains) async {
      final result = await harness.repo.pay(
        invoiceId: harness.invoiceId,
        patientId: harness.patientId,
        payment: card,
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.message.toLowerCase(), stringContainsInOrder([contains]));
    }

    test('rejects a bad card number', () async {
      await expectRejected(
        CardPayment(
          cardNumber: '4242424242424243',
          cardHolder: 'Ali',
          expiryMonth: 12,
          expiryYear: DateTime.now().year + 3,
          cvc: '123',
        ),
        'not valid',
      );
    });

    test('rejects an expired card', () async {
      await expectRejected(
        CardPayment(
          cardNumber: '4242424242424242',
          cardHolder: 'Ali',
          expiryMonth: 1,
          expiryYear: DateTime.now().year - 1,
          cvc: '123',
        ),
        'expired',
      );
    });

    test('rejects a missing cardholder name', () async {
      await expectRejected(
        CardPayment(
          cardNumber: '4242424242424242',
          cardHolder: '   ',
          expiryMonth: 12,
          expiryYear: DateTime.now().year + 3,
          cvc: '123',
        ),
        'name on the card',
      );
    });

    test('rejects a malformed CVC', () async {
      await expectRejected(
        CardPayment(
          cardNumber: '4242424242424242',
          cardHolder: 'Ali',
          expiryMonth: 12,
          expiryYear: DateTime.now().year + 3,
          cvc: '1',
        ),
        'cvc',
      );
    });
  });
}

/// A seeded DB plus one known-open invoice, for the validation cases.
class AppDatabaseHarness {
  AppDatabaseHarness({
    required this.db,
    required this.repo,
    required this.patientId,
    required this.invoiceId,
  });

  final AppDatabase db;
  final BillingRepositoryImpl repo;
  final String patientId;
  final String invoiceId;

  static Future<AppDatabaseHarness> create() async {
    final db = newTestDatabase();
    await Seeder(db).run();
    final repo = BillingRepositoryImpl(db);

    final users = await db.select(db.users).get();
    for (final u in users.where((u) => u.role == UserRole.patient)) {
      final list = (await repo.forPatient(u.id)).valueOrNull ?? const [];
      final open = list.where((i) => i.isPayable).toList();
      if (open.isNotEmpty) {
        return AppDatabaseHarness(
          db: db,
          repo: repo,
          patientId: u.id,
          invoiceId: open.first.id,
        );
      }
    }
    throw StateError('seed produced no open invoice');
  }
}
