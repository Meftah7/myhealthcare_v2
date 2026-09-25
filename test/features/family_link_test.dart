// Family Network account linking: request an existing account, the owner
// must accept before any access, and either side can undo it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/family_link_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/booking/application/booking_providers.dart';
import 'package:myhealthcare/features/patient/application/family_link_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('request must accept before an active link exists, and rejects duplicates', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final repo = FamilyLinkRepositoryImpl(db);

    final patients = (await db.select(db.users).get())
        .where((u) => u.role == UserRole.patient)
        .toList();
    final a = patients[0].id;
    final b = patients[1].id;

    // Can't link to yourself.
    final self = await repo.request(
      ownerPatientId: a,
      viewerPatientId: a,
      permission: FamilyLinkPermission.viewOnly,
    );
    expect(self.isErr, isTrue);

    final requested = await repo.request(
      ownerPatientId: b,
      viewerPatientId: a,
      permission: FamilyLinkPermission.viewOnly,
    );
    expect(requested.isOk, isTrue);
    expect(requested.valueOrNull!.status, FamilyLinkStatus.pending);

    // No access yet — still pending.
    final beforeAccept = await repo.activeLink(
      viewerPatientId: a,
      ownerPatientId: b,
    );
    expect(beforeAccept.valueOrNull, isNull);

    // A second request between the same two accounts is rejected.
    final dup = await repo.request(
      ownerPatientId: b,
      viewerPatientId: a,
      permission: FamilyLinkPermission.manage,
    );
    expect(dup.isErr, isTrue);
    expect(dup.failureOrNull!.message, contains('already pending'));

    // Only the owner (b) can accept.
    final wrongAcceptor = await repo.accept(
      linkId: requested.valueOrNull!.id,
      actingPatientId: a,
    );
    expect(wrongAcceptor.isErr, isTrue);

    final accepted = await repo.accept(
      linkId: requested.valueOrNull!.id,
      actingPatientId: b,
    );
    expect(accepted.isOk, isTrue);
    expect(accepted.valueOrNull!.status, FamilyLinkStatus.accepted);

    final afterAccept = await repo.activeLink(
      viewerPatientId: a,
      ownerPatientId: b,
    );
    expect(afterAccept.valueOrNull, isNotNull);
    expect(afterAccept.valueOrNull!.permission, FamilyLinkPermission.viewOnly);
  });

  test('either side can decline a pending request or unlink an accepted one', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();
    final repo = FamilyLinkRepositoryImpl(db);

    final patients = (await db.select(db.users).get())
        .where((u) => u.role == UserRole.patient)
        .toList();
    final a = patients[0].id;
    final b = patients[1].id;
    final c = patients[2].id;

    // The viewer can cancel their own pending request.
    final r1 = await repo.request(
      ownerPatientId: b,
      viewerPatientId: a,
      permission: FamilyLinkPermission.viewOnly,
    );
    final cancelled = await repo.decline(
      linkId: r1.valueOrNull!.id,
      actingPatientId: a,
    );
    expect(cancelled.isOk, isTrue);

    // A stranger can't decline someone else's request.
    final r2 = await repo.request(
      ownerPatientId: b,
      viewerPatientId: a,
      permission: FamilyLinkPermission.viewOnly,
    );
    final stranger = await repo.decline(
      linkId: r2.valueOrNull!.id,
      actingPatientId: c,
    );
    expect(stranger.isErr, isTrue);

    // Accept, then either side can unlink.
    await repo.accept(linkId: r2.valueOrNull!.id, actingPatientId: b);
    final unlinked = await repo.unlink(
      linkId: r2.valueOrNull!.id,
      actingPatientId: b,
    );
    expect(unlinked.isOk, isTrue);
    final gone = await repo.activeLink(viewerPatientId: a, ownerPatientId: b);
    expect(gone.valueOrNull, isNull);
  });

  test('manage permission lets a linked patient cancel; view-only cannot', () async {
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

    final familyRepo = FamilyLinkRepositoryImpl(db);
    final apptRepo = AppointmentRepositoryImpl(db);
    final patients = (await db.select(db.users).get())
        .where((u) => u.role == UserRole.patient)
        .toList();
    final manager = patients[0];
    final viewer = patients[1];
    final owner = patients[2];

    final ownerAppts = (await apptRepo.forPatient(owner.id)).valueOrNull!;
    expect(
      ownerAppts.length,
      greaterThanOrEqualTo(2),
      reason: 'need two of this patient\'s appointments for the two checks',
    );

    final manageReq = await familyRepo.request(
      ownerPatientId: owner.id,
      viewerPatientId: manager.id,
      permission: FamilyLinkPermission.manage,
    );
    await familyRepo.accept(
      linkId: manageReq.valueOrNull!.id,
      actingPatientId: owner.id,
    );
    final viewReq = await familyRepo.request(
      ownerPatientId: owner.id,
      viewerPatientId: viewer.id,
      permission: FamilyLinkPermission.viewOnly,
    );
    await familyRepo.accept(
      linkId: viewReq.valueOrNull!.id,
      actingPatientId: owner.id,
    );

    // View-only: the controller refuses before ever touching the appointment.
    await container
        .read(sessionProvider.notifier)
        .login(email: viewer.email, password: Seeder.demoPassword);
    final deniedResult = await container
        .read(familyLinkControllerProvider)
        .cancelForLinkedAccount(
          ownerPatientId: owner.id,
          appointmentId: ownerAppts[0].id,
        );
    expect(deniedResult.isErr, isTrue);
    expect(deniedResult.failureOrNull!.message, contains('view access'));
    final stillOpen = await apptRepo.forPatient(owner.id);
    expect(
      stillOpen.valueOrNull!.firstWhere((a) => a.id == ownerAppts[0].id).status,
      isNot(AppointmentStatus.cancelled),
    );

    // Manage: the controller allows it.
    await container.read(sessionProvider.notifier).logout();
    await container
        .read(sessionProvider.notifier)
        .login(email: manager.email, password: Seeder.demoPassword);
    final allowedResult = await container
        .read(familyLinkControllerProvider)
        .cancelForLinkedAccount(
          ownerPatientId: owner.id,
          appointmentId: ownerAppts[1].id,
        );
    expect(allowedResult.isOk, isTrue);
    final updated = await apptRepo.forPatient(owner.id);
    expect(
      updated.valueOrNull!.firstWhere((a) => a.id == ownerAppts[1].id).status,
      AppointmentStatus.cancelled,
    );
  });

  test('manage permission lets a linked patient book for the owner; view-only cannot',
      () async {
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

    final familyRepo = FamilyLinkRepositoryImpl(db);
    final apptRepo = AppointmentRepositoryImpl(db);
    final patients = (await db.select(db.users).get())
        .where((u) => u.role == UserRole.patient)
        .toList();
    final manager = patients[3];
    final viewer = patients[4];
    final owner = patients[5];

    final manageReq = await familyRepo.request(
      ownerPatientId: owner.id,
      viewerPatientId: manager.id,
      permission: FamilyLinkPermission.manage,
    );
    await familyRepo.accept(
      linkId: manageReq.valueOrNull!.id,
      actingPatientId: owner.id,
    );
    final viewReq = await familyRepo.request(
      ownerPatientId: owner.id,
      viewerPatientId: viewer.id,
      permission: FamilyLinkPermission.viewOnly,
    );
    await familyRepo.accept(
      linkId: viewReq.valueOrNull!.id,
      actingPatientId: owner.id,
    );

    final depts = await container.read(departmentsProvider.future);
    final staff = await container.read(
      departmentStaffProvider(depts.first.id).future,
    );
    var date = DateTime.now().add(const Duration(days: 2));
    while (date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    final draft = BookingRequestDraft(
      departmentId: depts.first.id,
      staffId: staff.first.id,
      date: DateTime(date.year, date.month, date.day),
    );

    final beforeCount = (await apptRepo.forPatient(owner.id)).valueOrNull!.length;

    // View-only: booking for the owner is refused before it ever hits the
    // appointments table.
    await container
        .read(sessionProvider.notifier)
        .login(email: viewer.email, password: Seeder.demoPassword);
    container.read(bookingDraftProvider.notifier).state = draft;
    container.read(bookingTargetPatientIdProvider.notifier).state = owner.id;
    final viewerRanked = await container.read(rankedSlotsProvider.future);
    expect(viewerRanked, isNotEmpty);
    final deniedResult = await container
        .read(bookingControllerProvider)
        .confirm(viewerRanked.first);
    expect(deniedResult.isErr, isTrue);
    expect(deniedResult.failureOrNull!.message, contains('manage access'));
    expect(
      (await apptRepo.forPatient(owner.id)).valueOrNull!.length,
      beforeCount,
    );

    // Manage: booking for the owner succeeds and lands under their account.
    await container.read(sessionProvider.notifier).logout();
    await container
        .read(sessionProvider.notifier)
        .login(email: manager.email, password: Seeder.demoPassword);
    container.read(bookingTargetPatientIdProvider.notifier).state = owner.id;
    final managerRanked = await container.read(rankedSlotsProvider.future);
    expect(managerRanked, isNotEmpty);
    final allowedBooking = await container
        .read(bookingControllerProvider)
        .confirm(managerRanked.first);
    expect(allowedBooking.isOk, isTrue);
    expect(allowedBooking.valueOrNull!.patientId, owner.id);
    expect(
      (await apptRepo.forPatient(owner.id)).valueOrNull!.length,
      beforeCount + 1,
    );
  });
}
