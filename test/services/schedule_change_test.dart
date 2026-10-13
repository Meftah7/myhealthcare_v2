// A schedule change is previewed and blocked until every future booking it
// would leave uncovered is moved to an authorized replacement.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/admin_workspace.dart';
import 'package:myhealthcare/domain/entities/schedule_template.dart';
import 'package:myhealthcare/domain/enums.dart';

import '../support/sessions.dart';

void main() {
  test(
    'preview lists uncovered bookings; save is blocked until moved',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final booked =
          await (db.select(db.appointments)..where(
                (a) =>
                    a.staffId.equals('staff_01') &
                    a.slotStart.isBiggerThanValue(DateTime.now()) &
                    a.status.isInValues([
                      AppointmentStatus.booked,
                      AppointmentStatus.confirmed,
                    ]),
              ))
              .get();
      expect(booked, isNotEmpty, reason: 'seed has future bookings');
      final repo = c.read(appointmentRepositoryProvider);
      // Fridays only: the regular Sunday–Thursday bookings are uncovered.
      const fridays = [
        NewScheduleTemplate(weekday: 5, startMinutes: 480, endMinutes: 960),
      ];
      final preview = (await repo.previewScheduleChange(
        staffId: 'staff_01',
        templates: fridays,
      )).valueOrNull!;
      // Only this clinician's real future bookings, and at least one.
      expect(preview, isNotEmpty);
      expect(
        {for (final b in booked) b.id}.containsAll(preview.map((a) => a.id)),
        isTrue,
      );
      expect(
        (await repo.setTemplates(
          staffId: 'staff_01',
          templates: fridays,
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      // Nothing changed while blocked.
      expect(
        await (db.select(
          db.scheduleTemplates,
        )..where((t) => t.staffId.equals('staff_01'))).get(),
        hasLength(5),
      );

      final rows = await (db.select(
        db.appointments,
      )..where((a) => a.id.isIn([for (final p in preview) p.id]))).get();
      // A free replacement in the same department with the same weekly
      // schedule and no bookings of its own.
      final original = await (db.select(
        db.staffProfiles,
      )..where((p) => p.userId.equals('staff_01'))).getSingle();
      final replacement =
          (await c
                  .read(userRepositoryProvider)
                  .createStaff(
                    fullName: 'Cover Doctor',
                    email: 'cover@myhealth.demo',
                    temporaryPassword: 'temp-12345678',
                    departmentId: original.departmentId,
                    jobTitle: 'Doctor',
                  ))
              .valueOrNull!;
      final templates = await (db.select(
        db.scheduleTemplates,
      )..where((t) => t.staffId.equals('staff_01'))).get();
      for (final t in templates) {
        await db
            .into(db.scheduleTemplates)
            .insert(
              ScheduleTemplatesCompanion.insert(
                id: 'cover_${t.id}',
                staffId: replacement.id,
                weekday: t.weekday,
                startMinutes: t.startMinutes,
                endMinutes: t.endMinutes,
                slotMinutes: Value(t.slotMinutes),
              ),
            );
      }
      await c
          .read(adminWorkspaceProvider)
          .moveBookings('staff_01', replacement.id, rows, 'Hours reduced');
      expect(
        (await repo.previewScheduleChange(
          staffId: 'staff_01',
          templates: fridays,
        )).valueOrNull,
        isEmpty,
      );
      expect(
        (await repo.setTemplates(staffId: 'staff_01', templates: fridays)).isOk,
        isTrue,
      );
    },
  );
}
