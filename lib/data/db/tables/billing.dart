/// Billing tables: patient invoices.
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'appointments.dart';
import 'users.dart';

@DataClassName('InvoiceRow')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get patientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// The visit this bill covers, if it came from one. Kept when the
  /// appointment is deleted so the financial record survives.
  TextColumn get appointmentId =>
      text().nullable().references(Appointments, #id, onDelete: KeyAction.setNull)();

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
