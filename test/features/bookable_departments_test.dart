// Booking offers only departments and staff that see patients: Reception and
// Pharmacy (receptionists, pharmacists) are never offered, and the booking
// service refuses them even if asked directly.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
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
  });

  test(
    'Reception and Pharmacy are not offered; clinical departments are',
    () async {
      final names = [
        for (final d in await container.read(departmentsProvider.future))
          d.name,
      ];
      expect(names, isNot(contains('Reception')));
      expect(names, isNot(contains('Pharmacy')));
      expect(names, containsAll(['Family Medicine', 'Dental']));
    },
  );

  test('every offered department lists only doctors or dentists', () async {
    for (final d in await container.read(departmentsProvider.future)) {
      final staff = await container.read(departmentStaffProvider(d.id).future);
      expect(staff, isNotEmpty, reason: d.name);
      expect(
        staff.every((s) => s.takesAppointments),
        isTrue,
        reason: '${d.name} offers a non-clinician',
      );
    }
  });

  test('the booking service refuses a receptionist or pharmacist', () async {
    final staff =
        (await container.read(userRepositoryProvider).allStaff()).valueOrNull!;
    final start = DateTime.now().add(const Duration(days: 2));
    final slot = DateTime(start.year, start.month, start.day, 10);
    final patientId = container.read(currentUserProvider)!.id;
    for (final role in [StaffRole.receptionist, StaffRole.pharmacist]) {
      final member = staff.firstWhere((s) => s.role == role);
      final result = await container
          .read(appointmentRepositoryProvider)
          .book(
            BookingRequest(
              patientId: patientId,
              staffId: member.id,
              start: slot,
              end: slot.add(const Duration(minutes: 20)),
              visitType: VisitType.followUp,
            ),
          );
      expect(result.isErr, isTrue, reason: role.name);
      expect(
        result.failureOrNull!.message,
        contains('doctor or dentist'),
        reason: role.name,
      );
    }
  });
}
