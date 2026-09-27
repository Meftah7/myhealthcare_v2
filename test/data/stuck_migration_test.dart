// A database that already has a later schema change applied (e.g. a browser
// tab was closed mid-upgrade, so the DDL committed but drift's recorded
// schemaVersion never advanced) must self-heal on its next open instead of
// permanently failing with "duplicate column name" / "table already exists".
// This reproduces the exact failure a live user hit: stuck recording an old
// version while `appointments.ticket_tag` already existed.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';

void main() {
  test(
    'reopening a database stuck at an old recorded version self-heals',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/'
        'mhc_stuck_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // A fully-seeded, current-schema database — its actual columns/tables
      // are already at schemaVersion 15.
      var db = AppDatabase(NativeDatabase(file));
      await Seeder(db).run();

      // Roll back only the *recorded* version, reproducing the exact stuck
      // state: the schema is already current, but the app forgot. This is
      // what a browser reaches if it's interrupted right after a DDL
      // statement commits but before the new version is recorded.
      await db.customStatement('PRAGMA user_version = 2');
      await db.close();

      // Reopening triggers onUpgrade(from: 2, to: 15). Every step it re-runs
      // (starting with adding the already-present `ticket_tag` column) must
      // detect the prior work and skip it — not throw "duplicate column
      // name: ticket_tag", which is what a real user hit here.
      db = AppDatabase(NativeDatabase(file));
      final users = await db.select(db.users).get();
      expect(users, isNotEmpty);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 15);

      await db.close();
    },
  );
}
