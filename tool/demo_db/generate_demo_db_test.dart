// Writes web/demo_seed.sqlite: the demo database the web build ships so a
// browser never has to generate it (see lib/data/db/demo_snapshot.dart).
//
//   flutter test tool/demo_db/generate_demo_db_test.dart
//
// The output is committed; re-run whenever the schema or seed data changes
// (test/data/demo_snapshot_test.dart fails until you do). It lives in tool/
// so a plain `flutter test` never rewrites it.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';

void main() {
  test('write the pre-seeded demo database for the web build', () async {
    final out = File('web/demo_seed.sqlite');
    if (out.existsSync()) out.deleteSync();

    final db = AppDatabase(NativeDatabase(out));
    await Seeder(db).run();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final users = await db
        .customSelect('SELECT count(*) AS n FROM users')
        .getSingle();
    await db.close();

    // The browser opens this file as-is: it must already be at the app's
    // schema version (so no migration runs) and hold the seeded accounts.
    expect(version.read<int>('user_version'), db.schemaVersion);
    expect(users.read<int>('n'), greaterThan(0));
    expect(File('${out.path}-wal').existsSync(), isFalse);
    stdout.writeln(
      'demo_seed.sqlite: ${out.lengthSync() ~/ 1024} KiB, '
      '${users.read<int>('n')} users, schema ${db.schemaVersion}',
    );
  });
}
