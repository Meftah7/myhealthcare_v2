// A database that already has a later schema change applied (e.g. a browser
// tab was closed mid-upgrade, so the DDL committed but drift's recorded
// schemaVersion never advanced) must self-heal on its next open instead of
// permanently failing with "duplicate column name" / "table already exists".
// This reproduces the exact failure a live user hit: stuck recording an old
// version while `appointments.ticket_tag` already existed.

import 'dart:io';
import 'package:drift/drift.dart' show Value;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';

void main() {
  test(
    'v25 upgrade links known demo encounters and leaves ordinary unlinked records alone',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/mhc_encounter_upgrade_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      var db = AppDatabase(NativeDatabase(file));
      await Seeder(db).run();
      final appointment = (await db.select(db.appointments).get()).firstWhere(
        (a) => a.status == AppointmentStatus.completed,
      );
      final recordId =
          'rec_${appointment.patientId}_${appointment.slotStart.millisecondsSinceEpoch}';
      await db
          .update(db.medicalRecords)
          .write(const MedicalRecordsCompanion(appointmentId: Value(null)));
      await db
          .into(db.medicalRecords)
          .insert(
            MedicalRecordsCompanion.insert(
              id: 'ordinary-unlinked-record',
              patientId: appointment.patientId,
              authorStaffId: Value(appointment.staffId),
              recordType: RecordType.visitNote,
              title: 'Same date, different record',
              occurredAt: appointment.slotStart,
            ),
          );
      await db.customStatement('ALTER TABLE vitals DROP COLUMN appointment_id');
      await db.customStatement('PRAGMA user_version = 25');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final recovered = await (db.select(
        db.medicalRecords,
      )..where((r) => r.id.equals(recordId))).getSingle();
      expect(recovered.appointmentId, appointment.id);
      final vitals = await (db.select(
        db.vitals,
      )..where((v) => v.appointmentId.equals(appointment.id))).get();
      expect(vitals, isNotEmpty);
      final ordinary = await (db.select(
        db.medicalRecords,
      )..where((r) => r.id.equals('ordinary-unlinked-record'))).getSingle();
      expect(ordinary.appointmentId, isNull);
    },
  );
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
      // are already at the current schema version.
      var db = AppDatabase(NativeDatabase(file));
      await Seeder(db).run();

      // Roll back only the *recorded* version, reproducing the exact stuck
      // state: the schema is already current, but the app forgot. This is
      // what a browser reaches if it's interrupted right after a DDL
      // statement commits but before the new version is recorded.
      await db.customStatement('PRAGMA user_version = 2');
      await db.close();

      // Reopening triggers onUpgrade(from: 2, to: the current version). Every step it re-runs
      // (starting with adding the already-present `ticket_tag` column) must
      // detect the prior work and skip it — not throw "duplicate column
      // name: ticket_tag", which is what a real user hit here.
      db = AppDatabase(NativeDatabase(file));
      final users = await db.select(db.users).get();
      expect(users, isNotEmpty);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), db.schemaVersion);

      await db.close();
    },
  );
}
