// A patient books an AI-ranked slot and it lands in their appointments (P4-13,
// P4-14, P4-16, P4-17).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unvalidated risk stays disabled and confirm() still books', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final login = await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    expect(login.isOk, isTrue);

    final depts = await container.read(departmentsProvider.future);
    final staff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    // Land on a clinic day (Sun–Thu; templates skip Fri/Sat).
    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }

    container.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final ranked = await container.read(rankedSlotsProvider.future);
    expect(ranked, isNotEmpty);
    expect(ranked.every((slot) => !slot.hasRiskEstimate), isTrue);
    expect(!ranked.first.slot.start.isAfter(ranked.last.slot.start), isTrue);

    final before = (await container.read(
      patientAppointmentsProvider.future,
    )).length;
    final result = await container
        .read(bookingControllerProvider)
        .confirm(ranked.first);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.noShowRisk, isNull);
    expect(result.valueOrNull!.riskBand, isNull);

    final after = await container.read(patientAppointmentsProvider.future);
    expect(after.length, before + 1);
    // Booked for the account holder — no family-member stamp.
    expect(result.valueOrNull!.bookedForName, isNull);
  });

  test('a visit booked for a household member lands on their own record, '
      'labelled with their name', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);

    final depts = await container.read(departmentsProvider.future);
    final staff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }

    await container
        .read(familyMemberControllerProvider)
        .add(
          const FamilyMember(
            id: 'fm_sara',
            relationship: FamilyRelationship.child,
            firstName: 'Sara',
            lastName: 'Ali',
          ),
        );
    final sara = (await container.read(
      patientFamilyMembersProvider.future,
    )).firstWhere((m) => m.id == 'fm_sara');
    final saraRecord =
        (await container
                .read(bookingSubjectSelectorProvider)
                .selectMember(sara))
            .valueOrNull!;
    final draft = container.read(bookingDraftProvider);
    container.read(bookingDraftProvider.notifier).state = draft.copyWith(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final ranked = await container.read(rankedSlotsProvider.future);
    final result = await container
        .read(bookingControllerProvider)
        .confirm(ranked.first);
    expect(result.isOk, isTrue, reason: '$result');
    expect(result.valueOrNull!.bookedForName, 'Sara Ali');
    // Sara's own record — not the account holder's.
    expect(result.valueOrNull!.patientId, saraRecord);

    // Persisted and read back on the entity.
    final appts = await container.read(patientAppointmentsProvider.future);
    expect(appts.where((a) => a.bookedForName == 'Sara Ali'), isNotEmpty);
  });
}
