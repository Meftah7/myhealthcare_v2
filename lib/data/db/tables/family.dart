/// Family Network account linking: one patient account granted access to
/// another's data, once the owner accepts.
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

@DataClassName('FamilyLinkRow')
class FamilyLinks extends Table {
  TextColumn get id => text()();

  /// The account whose data is being shared.
  TextColumn get ownerPatientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// The account being granted access.
  TextColumn get viewerPatientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get permission => textEnum<FamilyLinkPermission>()();
  TextColumn get status =>
      textEnum<FamilyLinkStatus>().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get respondedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
