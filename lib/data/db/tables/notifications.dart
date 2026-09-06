/// Notification table: one row per recipient.
///
/// A broadcast ("all patients") is fanned out into one row per patient so each
/// carries its own read state — no join table, matching how `reminders` and
/// `staff_tasks` model per-target rows.
library;

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';
import 'users.dart';

@DataClassName('NotificationRow')
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get recipientId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  TextColumn get category => textEnum<NotificationCategory>()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();

  /// Optional in-app route to open when the notification is tapped
  /// (e.g. `/patient/appointments`). Null = detail view only.
  TextColumn get deepLink => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Null until the recipient opens it.
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
