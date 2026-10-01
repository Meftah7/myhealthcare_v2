// The web build ships web/demo_seed.sqlite so browsers (Safari especially)
// never generate the demo data themselves. It is committed, so it must stay
// in step with the schema and the seeder. If this fails, regenerate it:
//
//   flutter test tool/demo_db/generate_demo_db_test.dart

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';

void main() {
  test('shipped demo snapshot matches the current schema and seed', () async {
    final shipped = File('web/demo_seed.sqlite');
    expect(shipped.existsSync(), isTrue, reason: 'snapshot missing');

    // Inspect a copy so opening it can never modify the committed file.
    final temp = await Directory.systemTemp.createTemp('demo-snapshot-');
    addTearDown(() => temp.delete(recursive: true));
    final copy = await shipped.copy(
      '${temp.path}${Platform.pathSeparator}demo.sqlite',
    );

    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final seed = await db
        .customSelect('SELECT seed_version FROM app_settings WHERE id = 1')
        .getSingle();

    expect(
      version.read<int>('user_version'),
      db.schemaVersion,
      reason: 'schema changed — regenerate the snapshot',
    );
    expect(
      seed.read<int>('seed_version'),
      Seeder.seedVersion,
      reason: 'seed data changed — regenerate the snapshot',
    );
    // A demo account signs in with the documented password.
    final admin = await (db.select(
      db.users,
    )..where((u) => u.email.equals('admin@myhealth.demo'))).getSingleOrNull();
    expect(admin, isNotNull);
  });
}
