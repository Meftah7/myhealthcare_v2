import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/admin_workspace.dart';
import 'package:myhealthcare/data/repositories/booking_safety.dart';
import 'package:myhealthcare/domain/enums.dart';

import '../support/sessions.dart';

void main() {
  test(
    'workspace denies patients and clinicians; metadata excludes clinical message bodies',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(adminWorkspaceProvider);
      await expectLater(service.queue(), throwsA(isA<AccessDeniedFailure>()));
      await expectLater(
        service.search('patient'),
        throwsA(isA<AccessDeniedFailure>()),
      );
      await db
          .into(db.careMessages)
          .insert(
            CareMessagesCompanion.insert(
              id: 'private-source',
              patientId: 'patient_050',
              staffId: 'staff_01',
              fromStaff: false,
              body: 'Private diagnostic details',
              responseDueAt: Value(
                DateTime.now().subtract(const Duration(hours: 1)),
              ),
            ),
          );
      await signInAs(c, 'admin@myhealth.demo');
      final queue = await service.queue();
      final message = queue.singleWhere((w) => w.sourceId == 'private-source');
      expect(message.nextAction, isNot(contains('Private diagnostic')));
      expect(queue.map((w) => w.id).toSet().length, queue.length);
      expect(await service.search('Private diagnostic'), isEmpty);
    },
  );

  test(
    'coordination updates retain source ownership, immutable history and reject stale saves',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      await db
          .into(db.careMessages)
          .insert(
            CareMessagesCompanion.insert(
              id: 'coordination',
              patientId: 'patient_050',
              staffId: 'staff_01',
              fromStaff: false,
              body: 'Please reply',
              responseDueAt: Value(DateTime.now()),
            ),
          );
      final service = c.read(adminWorkspaceProvider);
      final original = (await service.queue()).singleWhere(
        (w) => w.sourceId == 'coordination',
      );
      final owner = (await service.owners()).single.id;
      await service.updateWork(
        original,
        owner: owner,
        due: DateTime.now().add(const Duration(hours: 2)),
        status: 'waiting',
        reason: 'Confirm callback availability',
      );
      final current = (await service.queue()).singleWhere(
        (w) => w.id == original.id,
      );
      expect(current.version, 1);
      expect(current.state, 'waiting');
      expect(
        (await (db.select(
          db.careMessages,
        )..where((m) => m.id.equals('coordination'))).getSingle()).staffId,
        'staff_01',
      );
      expect(
        (await service.history(current)).single.reason,
        'Confirm callback availability',
      );
      final notices = await (db.select(
        db.notifications,
      )..where((n) => n.title.equals('Clinic information request'))).get();
      expect(notices.single.recipientId, 'staff_01');
      expect(notices.single.body, isNot(contains('Confirm callback')));
      await expectLater(
        service.updateWork(
          original,
          owner: owner,
          due: DateTime.now(),
          status: 'resolved',
          reason: 'Stale outcome',
        ),
        throwsA(isA<ConflictFailure>()),
      );
      await expectLater(
        (db.update(db.adminWorkHistory)
              ..where((h) => h.workId.equals(original.id)))
            .write(const AdminWorkHistoryCompanion(reason: Value('Changed'))),
        throwsA(anything),
      );
      expect((await service.history(current)).length, 1);
      await service.updateWork(
        current,
        owner: owner,
        due: DateTime.now(),
        status: 'resolved',
        reason: 'Coordinated response',
      );
      expect((await service.history(current)).length, 2);
      expect(
        (await (db.select(
          db.careMessages,
        )..where((m) => m.id.equals('coordination'))).getSingle()).fromStaff,
        false,
      );
    },
  );

  test(
    'invalid assignment and waiting deadline create no work or history',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      await db
          .into(db.feedbacks)
          .insert(
            FeedbacksCompanion.insert(
              id: 'invalid-work',
              category: FeedbackCategory.generalFeedback,
              message: 'Review service',
            ),
          );
      final service = c.read(adminWorkspaceProvider);
      final item = (await service.queue()).singleWhere(
        (w) => w.sourceId == 'invalid-work',
      );
      await expectLater(
        service.updateWork(
          item,
          owner: 'staff_01',
          due: DateTime.now().add(const Duration(days: 1)),
          status: 'open',
          reason: 'Assign',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        service.updateWork(
          item,
          owner: (await service.owners()).single.id,
          due: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'waiting',
          reason: 'Wait',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await db.select(db.adminWorkItems).get(), isEmpty);
      expect(await db.select(db.adminWorkHistory).get(), isEmpty);
    },
  );

  test(
    'configuration is persisted, validated and personal action lists cannot cross accounts',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final service = c.read(adminWorkspaceProvider);
      await service.saveConfiguration('clinic', {
        'name': 'Clinic A',
        'address': 'Building 1',
        'contact': '123',
      });
      expect((await service.configuration('clinic'))['name'], 'Clinic A');
      await expectLater(
        service.saveConfiguration('integrations', {
          'verificationOrigin': 'https://example.test/path',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        service.saveConfiguration('integrations', {'apiKey': 'secret'}),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        service.saveConfiguration('backup', {
          'recoveryHours': '-1',
          'retentionDays': '0',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        service.configuration('actions:someone-else'),
        throwsA(isA<AccessDeniedFailure>()),
      );
      expect(
        jsonDecode(
          (await db.select(db.clinicConfigurations).get()).single.valueJson,
        )['name'],
        'Clinic A',
      );
    },
  );

  test(
    'last administrator and staff with unfinished responsibility cannot be deactivated',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final admin = (await c.read(adminWorkspaceProvider).owners()).single;
      await expectLater(
        requireSafeDeactivation(db, admin.id),
        throwsA(isA<ValidationFailure>()),
      );
      await db
          .into(db.staffTasks)
          .insert(
            StaffTasksCompanion.insert(
              id: 'deactivate-owned',
              staffId: 'staff_01',
              title: 'Review',
              kind: TaskKind.followUpDue,
            ),
          );
      await expectLater(
        requireSafeDeactivation(db, 'staff_01'),
        throwsA(isA<ValidationFailure>()),
      );
      final result = await c
          .read(userRepositoryProvider)
          .setActive(id: 'staff_01', active: false);
      expect(result.isErr, true);
      expect(
        (await (db.select(
          db.users,
        )..where((u) => u.id.equals('staff_01'))).getSingle()).isActive,
        true,
      );
    },
  );

  test(
    'admin availability and service-hour changes refuse affected bookings atomically',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
      await db
          .into(db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: 'protected-booking',
              patientId: 'patient_050',
              staffId: 'staff_01',
              slotStart: start,
              slotEnd: start.add(const Duration(minutes: 20)),
              visitType: VisitType.routineCheckup,
            ),
          );
      expect(
        (await c
                .read(appointmentRepositoryProvider)
                .addAvailabilityException(
                  staffId: 'staff_01',
                  start: start,
                  end: start.add(const Duration(hours: 1)),
                  reason: 'Time off',
                ))
            .isErr,
        true,
      );
      expect(
        await (db.select(
          db.availabilityExceptions,
        )..where((e) => e.reason.equals('Time off'))).get(),
        isEmpty,
      );
      expect(
        (await c
                .read(settingsRepositoryProvider)
                .setClinicSchedule(
                  openDays: {1, 2, 3, 4, 5, 6, 7},
                  openHour: 12,
                  closeHour: 18,
                ))
            .isErr,
        true,
      );
      expect(
        (await (db.select(
          db.appointments,
        )..where((a) => a.id.equals('protected-booking'))).getSingle()).staffId,
        'staff_01',
      );
    },
  );

  test(
    'booking replacement checks preview version and conflicts before any write',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final service = c.read(adminWorkspaceProvider);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
      final from = await (db.select(
        db.staffProfiles,
      )..where((s) => s.userId.equals('staff_01'))).getSingle();
      await (db.update(
        db.staffProfiles,
      )..where((s) => s.userId.equals('staff_02'))).write(
        StaffProfilesCompanion(departmentId: Value(from.departmentId)),
      );
      await (db.delete(db.appointments)..where(
            (a) =>
                a.staffId.equals('staff_02') &
                a.status.isInValues(activeBookingStates),
          ))
          .go();
      await db
          .into(db.scheduleTemplates)
          .insert(
            ScheduleTemplatesCompanion.insert(
              id: 'replacement-hours',
              staffId: 'staff_02',
              weekday: start.weekday,
              startMinutes: 0,
              endMinutes: 1440,
            ),
          );
      await db
          .into(db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: 'move-booking',
              patientId: 'patient_050',
              staffId: 'staff_01',
              departmentId: Value(from.departmentId),
              slotStart: start,
              slotEnd: start.add(const Duration(minutes: 20)),
              visitType: VisitType.routineCheckup,
            ),
          );
      final preview = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals('move-booking'))).getSingle();
      await service.moveBookings('staff_01', 'staff_02', [
        preview,
      ], 'Replacement confirmed');
      final updated = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(preview.id))).getSingle();
      expect(updated.staffId, 'staff_02');
      expect(updated.slotStart, preview.slotStart);
      expect(updated.version, greaterThan(preview.version));
      await expectLater(
        service.moveBookings('staff_01', 'staff_02', [
          preview,
        ], 'Retry stale preview'),
        throwsA(isA<ConflictFailure>()),
      );
      expect(
        (await (db.select(db.notifications)..where(
                  (n) => n.title.equals('Appointment clinician changed'),
                ))
                .get())
            .length,
        1,
      );
    },
  );

  test(
    'schema 30 upgrades to admin workflow tables without losing existing rows',
    () async {
      final dir = await Directory.systemTemp.createTemp('task6-migration-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/clinic.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db
          .into(db.departments)
          .insert(
            DepartmentsCompanion.insert(
              id: 'retained',
              name: 'Retained department',
            ),
          );
      await db.customStatement('DROP TABLE admin_work_history');
      await db.customStatement('DROP TABLE admin_work_items');
      await db.customStatement('DROP TABLE clinic_configurations');
      await db.customStatement('PRAGMA user_version=30');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());
      expect(
        (await db.select(db.departments).get()).single.name,
        'Retained department',
      );
      expect(await db.select(db.adminWorkItems).get(), isEmpty);
      expect(await db.select(db.adminWorkHistory).get(), isEmpty);
      expect(await db.select(db.clinicConfigurations).get(), isEmpty);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        31,
      );
    },
  );
}
