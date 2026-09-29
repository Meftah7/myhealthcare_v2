import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';

Future<Map<String, Object>> _snapshot(AppDatabase db) async {
  Future<int> count(String table) async {
    final row = await db
        .customSelect('SELECT count(*) AS n FROM $table')
        .getSingle();
    return row.read<int>('n');
  }

  final appointmentIds = await db
      .customSelect('SELECT id FROM appointments ORDER BY id')
      .get();
  final foreignKeys = await db.customSelect('PRAGMA foreign_key_check').get();
  final schema = await db.customSelect('PRAGMA user_version').getSingle();

  return {
    'users': await count('users'),
    'appointments': await count('appointments'),
    'records': await count('medical_records'),
    'appointmentIds': appointmentIds
        .map((row) => row.read<String>('id'))
        .join(','),
    'foreignKeyErrors': foreignKeys.length,
    'schemaVersion': schema.read<int>('user_version'),
  };
}

void main() {
  test(
    'prototype database backup restores relationships without reseeding',
    () async {
      final temp = await Directory.systemTemp.createTemp('myhealth-backup-');
      addTearDown(() => temp.delete(recursive: true));
      final liveFile = File('${temp.path}${Platform.pathSeparator}live.sqlite');
      final backupFile = File(
        '${temp.path}${Platform.pathSeparator}backup.sqlite',
      );

      var db = AppDatabase(NativeDatabase(liveFile));
      await Seeder(db).run();
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      final before = await _snapshot(db);
      expect(before['foreignKeyErrors'], 0);
      expect(before['schemaVersion'], db.schemaVersion);
      await db.close();

      final started = Stopwatch()..start();
      await liveFile.copy(backupFile.path);

      db = AppDatabase(NativeDatabase(liveFile));
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement('DELETE FROM appointments');
      await db.customStatement('DELETE FROM medical_records');
      await db.close();

      await backupFile.copy(liveFile.path);
      db = AppDatabase(NativeDatabase(liveFile));
      final restored = await _snapshot(db);
      await db.close();
      started.stop();

      expect(restored, before);
      expect(restored['foreignKeyErrors'], 0);
      expect(started.elapsed, lessThan(const Duration(seconds: 10)));
    },
  );
}
