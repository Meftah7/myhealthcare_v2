// Admin schedule-template editor: a doctor's weekly working blocks, saved as
// one replace-all operation per staff member.

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setTemplates round-trips and replaces the previous week', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final repo = AppointmentRepositoryImpl(db);

    final staff = (await db.select(db.staffProfiles).get()).first;

    final saved = await repo.setTemplates(
      staffId: staff.userId,
      templates: const [
        NewScheduleTemplate(weekday: 1, startMinutes: 540, endMinutes: 1020),
        NewScheduleTemplate(weekday: 3, startMinutes: 540, endMinutes: 780),
      ],
    );
    expect(saved.isOk, isTrue);
    expect(saved.valueOrNull!.map((t) => t.weekday), [1, 3]);

    final read = (await repo.templatesFor(staff.userId)).valueOrNull!;
    expect(read.length, 2);
    expect(read.first.startMinutes, 540);
    expect(read.first.endMinutes, 1020);
    expect(read.first.slotMinutes, 20, reason: 'default slot length');

    // Saving again replaces the old week entirely, it doesn't add to it.
    final resaved = await repo.setTemplates(
      staffId: staff.userId,
      templates: const [
        NewScheduleTemplate(weekday: 2, startMinutes: 600, endMinutes: 900),
      ],
    );
    expect(resaved.isOk, isTrue);
    final after = (await repo.templatesFor(staff.userId)).valueOrNull!;
    expect(after.length, 1);
    expect(after.first.weekday, 2);
  });

  test('rejects a block where start is not before end', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final repo = AppointmentRepositoryImpl(db);
    final staff = (await db.select(db.staffProfiles).get()).first;
    final before = (await repo.templatesFor(staff.userId)).valueOrNull!;

    final result = await repo.setTemplates(
      staffId: staff.userId,
      templates: const [
        NewScheduleTemplate(weekday: 1, startMinutes: 900, endMinutes: 600),
      ],
    );
    expect(result.isErr, isTrue);
    expect(result.failureOrNull!.message, contains('before'));

    // Validation runs before anything is written — the seeded week (or
    // whatever was there before) is untouched, not partially overwritten.
    final after = (await repo.templatesFor(staff.userId)).valueOrNull!;
    expect(after.map((t) => t.id), before.map((t) => t.id));
  });

  test('rejects a non-positive slot length', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final repo = AppointmentRepositoryImpl(db);
    final staff = (await db.select(db.staffProfiles).get()).first;

    final result = await repo.setTemplates(
      staffId: staff.userId,
      templates: const [
        NewScheduleTemplate(
          weekday: 1,
          startMinutes: 540,
          endMinutes: 1020,
          slotMinutes: 0,
        ),
      ],
    );
    expect(result.isErr, isTrue);
    expect(result.failureOrNull!.message, contains('greater than zero'));
  });
}
