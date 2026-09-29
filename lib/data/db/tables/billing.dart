/// Billing tables: patient invoices.
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'appointments.dart';
import 'users.dart';

/// A card the patient has saved to their wallet. Only a masked descriptor is
/// ever stored — never the full PAN or CVC.
@DataClassName('PaymentMethodRow')
class PaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get brand => text()();
  TextColumn get last4 => text().withLength(min: 4, max: 4)();
  IntColumn get expiryMonth => integer()();
  IntColumn get expiryYear => integer()();
  TextColumn get holderName => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InvoiceRow')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// The visit this bill covers, if it came from one. Kept when the
  /// appointment is deleted so the financial record survives.
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
  )();

  RealColumn get subtotal => real().withDefault(const Constant(0))();

  /// Percent, e.g. `10` for 10%.
  RealColumn get taxRate => real().withDefault(const Constant(10))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();

  TextColumn get status =>
      textEnum<InvoiceStatus>().withDefault(const Constant('pending'))();

  DateTimeColumn get issuedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();

  /// Masked descriptor only — the full card number is never stored.
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// The signed-in account that paid (the patient or a proxy).
  TextColumn get paidByAccountId => text().nullable()();

  /// Optimistic-concurrency version (trigger-bumped, schema v19).
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One entry in a patient's wallet ledger. The balance is never stored on its
/// own — it's the sum of these rows, so it can never drift from its history.
@DataClassName('WalletTransactionRow')
class WalletTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => textEnum<WalletTransactionType>()();

  /// Always positive — `type` gives the sign.
  RealColumn get amount => real()();

  /// Masked card descriptor for a top-up, null for a redemption.
  TextColumn get method => text().nullable()();

  /// The invoice a redemption paid toward, null for a top-up.
  TextColumn get invoiceId => text().nullable().references(
    Invoices,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The signed-in account that moved the money (the patient or a proxy).
  TextColumn get actorAccountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One attempt to move money (Phase 5): an invoice charge, a wallet top-up,
/// or a refund. Written *before* the payment provider is asked, so a crash or
/// lost response mid-payment leaves a record that reconciliation can resolve
/// against the provider instead of guessing — and an invoice is only marked
/// paid by a transaction that reached `settled`.
///
/// Rows are never deleted (a trigger blocks it); status moves forward only.
@DataClassName('PaymentTransactionRow')
class PaymentTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// The bill this pays or refunds; null for a wallet top-up.
  TextColumn get invoiceId => text().nullable().references(
    Invoices,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get kind => textEnum<PaymentKind>()();
  TextColumn get method => textEnum<PaymentMethodKind>()();
  TextColumn get status =>
      textEnum<PaymentStatus>().withDefault(const Constant('initiated'))();

  /// Always positive, in BHD (three decimals).
  RealColumn get amount => real()();

  /// Who processed it: `simulated-card`, `wallet`, `offline`.
  TextColumn get provider => text()();

  /// Our reference for this attempt, sent to the provider as its idempotency
  /// key. Re-sending it can never charge twice.
  TextColumn get requestReference => text().unique()();

  /// The provider's own reference once it has one (charge/refund id, or the
  /// desk receipt number for an offline payment).
  TextColumn get providerReference => text().nullable()();

  /// Masked descriptor only ("Visa ····4242", "Wallet balance").
  TextColumn get methodDescriptor => text().nullable()();

  /// For a refund: the settled charge it returns money from.
  TextColumn get refundOfId => text().nullable()();

  /// Why a refund or offline payment was recorded (staff-entered).
  TextColumn get reason => text().nullable()();

  /// Decline or failure code — never card data.
  TextColumn get failureReason => text().nullable()();
  TextColumn get actorAccountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get settledAt => dateTime().nullable()();

  /// Last time reconciliation compared this row with the provider.
  DateTimeColumn get reconciledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The simulated card provider's own ledger (Phase 5, demo only).
///
/// Stands in for the records a real payment provider keeps on *its* side, so
/// the app can be tested against a provider that remembers a charge even when
/// the app crashed before hearing the answer. A real integration deletes this
/// table and asks the provider instead.
@DataClassName('SimulatedGatewayChargeRow')
class SimulatedGatewayCharges extends Table {
  /// The app's request reference — the provider's idempotency key.
  TextColumn get reference => text()();
  TextColumn get providerReference => text()();

  /// `charge` or `refund`.
  TextColumn get operation => text()();

  /// `captured`, `declined` or `refunded`.
  TextColumn get status => text()();
  IntColumn get amountFils => integer()();
  TextColumn get declineCode => text().nullable()();

  /// For a refund: the provider reference of the charge it returns.
  TextColumn get parentProviderReference => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {reference};
}
