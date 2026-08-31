/// In-memory [AppDatabase] for fast repository unit tests (P1-12+, P6-02).
///
/// `sqlite3` 3.5.x ships as a Dart *native asset*, so `flutter test` builds /
/// downloads the library automatically — no plugin or manual DLL wiring needed.
library;

import 'package:drift/native.dart';
import 'package:myhealthcare/data/db/app_database.dart';

AppDatabase newTestDatabase() => AppDatabase(NativeDatabase.memory());
