// Wallet: saved cards (add / remove / default), scoped to the patient, and
// only a masked descriptor is stored.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/repositories/billing_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/billing_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/billing/application/billing_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

CardPayment card(String number) => CardPayment(
  cardNumber: number,
  cardHolder: 'Aisha Smith',
  expiryMonth: 12,
  expiryYear: DateTime.now().year + 3,
  cvc: '123',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed gives each patient one default card', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final repo = BillingRepositoryImpl(db);
    final patient = (await db.select(db.users).get())
        .firstWhere((u) => u.role == UserRole.patient);
    final cards = (await repo.cardsFor(patient.id)).valueOrNull!;
    expect(cards, hasLength(1));
    expect(cards.first.isDefault, isTrue);
    expect(cards.first.last4, '4242');
  });

  test('add / default / remove, all scoped to the patient', () async {
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

    await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    final me = container.read(currentUserProvider)!.id;

    final ctrl = container.read(billingControllerProvider);

    // Add a Mastercard.
    final added = await ctrl.addCard(card('5555555555554444'));
    expect(added.isOk, isTrue);
    expect(added.valueOrNull!.brand, 'Mastercard');
    expect(added.valueOrNull!.last4, '4444');
    // Never the full number.
    expect(added.valueOrNull!.toString(), isNot(contains('5555555555')));

    await container.read(walletCardsProvider.future);
    var cards = container.read(walletCardsProvider).value!;
    expect(cards, hasLength(2)); // seeded Visa + new Mastercard

    // Same card twice is rejected.
    final dup = await ctrl.addCard(card('5555555555554444'));
    expect(dup.isErr, isTrue);
    expect(dup.failureOrNull!.message, contains('already saved'));

    // Make the Mastercard default.
    await ctrl.setDefaultCard(added.valueOrNull!.id);
    await container.read(walletCardsProvider.future);
    cards = container.read(walletCardsProvider).value!;
    expect(cards.where((c) => c.isDefault), hasLength(1));
    expect(cards.firstWhere((c) => c.isDefault).id, added.valueOrNull!.id);

    // Remove it; the other card is promoted to default.
    await ctrl.removeCard(added.valueOrNull!.id);
    await container.read(walletCardsProvider.future);
    cards = container.read(walletCardsProvider).value!;
    expect(cards, hasLength(1));
    expect(cards.first.isDefault, isTrue);

    // Another patient's card can't be removed via this patient.
    final repo = BillingRepositoryImpl(db);
    final other = (await db.select(db.users).get()).firstWhere(
      (u) => u.role == UserRole.patient && u.id != me,
    );
    final otherCards = (await repo.cardsFor(other.id)).valueOrNull!;
    await repo.removeCard(id: otherCards.first.id, patientId: me);
    expect(
      (await repo.cardsFor(other.id)).valueOrNull,
      isNotEmpty,
      reason: 'a mismatched patient id must not delete the card',
    );
  });
}
