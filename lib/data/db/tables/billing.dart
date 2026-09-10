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

  @override
  Set<Column<Object>> get primaryKey => {id};
}
