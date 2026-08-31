// A patient books an AI-ranked slot and it lands in their appointments (P4-13,
// P4-14, P4-16, P4-17).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ranked slots carry a probability + band and confirm() books', () async {
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
    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday > 5) {
      date = date.add(const Duration(days: 1));
    }

    container.read(bookingDraftProvider.notifier).state = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final ranked = await container.read(rankedSlotsProvider.future);
    expect(ranked, isNotEmpty);
    expect(ranked.first.probability, inInclusiveRange(0.0, 1.0));
    expect(RiskBand.values, contains(ranked.first.band));
    expect(
      ranked.first.probability,
      lessThanOrEqualTo(ranked.last.probability + 1e-9),
    );

    final before = (await container.read(
      patientAppointmentsProvider.future,
    )).length;
    final result = await container
        .read(bookingControllerProvider)
        .confirm(ranked.first);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.noShowRisk, isNotNull);
    expect(result.valueOrNull!.riskBand, isNotNull);

    final after = await container.read(patientAppointmentsProvider.future);
    expect(after.length, before + 1);
  });
}
