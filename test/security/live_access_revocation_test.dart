import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/staff.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient_chart/application/chart_providers.dart';

import '../support/sessions.dart';

Future<String> unrelatedPatient(ProviderContainer c, AppDatabase db) async {
  final visible = (await c
      .read(accessPolicyProvider)
      .clinicallyVisiblePatientIds())!;
  final patients = await (db.select(
    db.users,
  )..where((u) => u.role.equalsValue(UserRole.patient))).get();
  return patients.firstWhere((p) => !visible.contains(p.id)).id;
}

Future<void> assignment(AppDatabase db, String patientId, {DateTime? ends}) =>
    db
        .into(db.careTeamAssignments)
        .insert(
          CareTeamAssignmentsCompanion.insert(
            id: 'temporary-access',
            patientId: patientId,
            staffId: 'staff_01',
            role: CareTeamRole.primaryClinician,
            assignedAt: DateTime.now().subtract(const Duration(days: 1)),
            endedAt: Value(ends),
          ),
        );

Future<void> waitForLock(
  ProviderContainer c,
  Future<void> Function() mutate,
) async {
  final locked = Completer<void>();
  final sub = c.listen(sessionProvider, (_, next) {
    if (!next.isAuthenticated && !locked.isCompleted) locked.complete();
  });
  try {
    await mutate();
    await locked.future.timeout(const Duration(seconds: 8));
    expect(c.read(authContextProvider).principal, isNull);
  } finally {
    sub.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ending care access locks the session without any clinical-row update',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final patientId = await unrelatedPatient(c, db);
      await c.read(sessionProvider.notifier).logout();
      await assignment(db, patientId);
      await signInAs(c, 'staff1@myhealth.demo');
      final old = await c.read(chartPatientProvider(patientId).future);
      expect(old.id, patientId);
      await waitForLock(c, () async {
        await (db.update(
          db.careTeamAssignments,
        )..where((a) => a.id.equals('temporary-access'))).write(
          CareTeamAssignmentsCompanion(
            endedAt: Value(DateTime.now().subtract(const Duration(seconds: 1))),
          ),
        );
      });
      await expectLater(
        c.read(chartPatientProvider(patientId).future),
        throwsA(isA<AuthFailure>()),
      );
    },
  );

  test(
    'assignment expiry locks the session without a database mutation',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final patientId = await unrelatedPatient(c, db);
      await c.read(sessionProvider.notifier).logout();
      await assignment(
        db,
        patientId,
        ends: DateTime.now().add(const Duration(seconds: 3)),
      );
      await signInAs(c, 'staff1@myhealth.demo');
      await c.read(chartPatientProvider(patientId).future);
      await waitForLock(c, () async {});
    },
  );

  test(
    'a grant gained after sign-in is monitored when it is later removed',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final patientId = await unrelatedPatient(c, db);
      final gained = c
          .read(accessPolicyProvider)
          .watchAuthorization()
          .firstWhere((s) => s.patients.contains(patientId));
      await assignment(db, patientId);
      await gained.timeout(const Duration(seconds: 5));
      await c.read(chartPatientProvider(patientId).future);
      await waitForLock(c, () async {
        await (db.delete(
          db.careTeamAssignments,
        )..where((a) => a.id.equals('temporary-access'))).go();
      });
    },
  );

  test(
    'proxy revocation and manage-to-view downgrade lock the viewer session',
    () async {
      final (c, db) = await seededContainer();
      await db
          .into(db.familyLinks)
          .insert(
            FamilyLinksCompanion.insert(
              id: 'live-proxy',
              ownerPatientId: 'patient_011',
              viewerPatientId: 'patient_010',
              permission: FamilyLinkPermission.manage,
              status: const Value(FamilyLinkStatus.accepted),
            ),
          );
      await signInAs(c, 'patient10@myhealth.demo');
      expect(
        (await c.read(recordRepositoryProvider).timeline('patient_011')).isOk,
        true,
      );
      await waitForLock(c, () async {
        await (db.update(
          db.familyLinks,
        )..where((g) => g.id.equals('live-proxy'))).write(
          const FamilyLinksCompanion(
            permission: Value(FamilyLinkPermission.viewOnly),
          ),
        );
      });
      await signInAs(c, 'patient10@myhealth.demo');
      await waitForLock(c, () async {
        await (db.delete(
          db.familyLinks,
        )..where((g) => g.id.equals('live-proxy'))).go();
      });
    },
  );

  test(
    'staff demotion and credential revocation lock an open session',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      await waitForLock(c, () async {
        await (db.update(
          db.staffProfiles,
        )..where((p) => p.userId.equals('staff_01'))).write(
          const StaffProfilesCompanion(jobTitle: Value(kNurseJobTitle)),
        );
      });
      await db
          .into(db.staffCredentials)
          .insert(
            StaffCredentialsCompanion.insert(
              id: 'verified-credential',
              staffId: 'staff_01',
              kind: CredentialKind.nursingLicense,
              identifier: 'N-123',
              recordedAt: DateTime.now(),
              verifiedAt: Value(DateTime.now()),
            ),
          );
      await signInAs(c, 'staff1@myhealth.demo');
      await waitForLock(c, () async {
        await (db.update(db.staffCredentials)
              ..where((r) => r.staffId.equals('staff_01')))
            .write(StaffCredentialsCompanion(revokedAt: Value(DateTime.now())));
      });
    },
  );

  test('unrelated access changes do not sign the clinician out', () async {
    final (c, db) = await seededContainer();
    await signInAs(c, 'staff1@myhealth.demo');
    final patientId = await unrelatedPatient(c, db);
    final snapshots = c.read(accessPolicyProvider).watchAuthorization();
    final first = await snapshots.first;
    await db
        .into(db.careTeamAssignments)
        .insert(
          CareTeamAssignmentsCompanion.insert(
            id: 'someone-elses-care',
            patientId: patientId,
            staffId: 'staff_02',
            role: CareTeamRole.primaryClinician,
            assignedAt: DateTime.now(),
          ),
        );
    final after = await c.read(accessPolicyProvider).watchAuthorization().first;
    expect(after.losesAccessFrom(first), false);
    expect(c.read(sessionProvider).isAuthenticated, true);
  });

  test(
    'verified credential expiry locks the session without a DB write',
    () async {
      final (c, db) = await seededContainer();
      await db
          .into(db.staffCredentials)
          .insert(
            StaffCredentialsCompanion.insert(
              id: 'expiring-credential',
              staffId: 'staff_01',
              kind: CredentialKind.medicalLicense,
              identifier: 'M-123',
              recordedAt: DateTime.now(),
              verifiedAt: Value(DateTime.now()),
              validUntil: Value(DateTime.now().add(const Duration(seconds: 3))),
            ),
          );
      await signInAs(c, 'staff1@myhealth.demo');
      await waitForLock(c, () async {});
    },
  );

  testWidgets(
    'revocation removes the visible chart and an open preview dialog',
    (tester) async {
      final fixture = await tester.runAsync(() async {
        final (c, db) = await seededContainer(
          prefs: {'ui.hasSeenOnboarding': true},
          overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        );
        await signInAs(c, 'staff1@myhealth.demo');
        final patientId = await unrelatedPatient(c, db);
        await c.read(sessionProvider.notifier).logout();
        await assignment(db, patientId);
        await signInAs(c, 'staff1@myhealth.demo');
        final record = await c.read(chartPatientProvider(patientId).future);
        await Future.wait([
          c.read(chartTimelineProvider(patientId).future),
          c.read(chartVitalsProvider(patientId).future),
          c.read(chartMedicationsProvider(patientId).future),
          c.read(chartFlagsProvider(patientId).future),
        ]);
        return (c, db, patientId, record);
      });
      final (c, db, patientId, record) = fixture!;
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      c.read(routerProvider).go(AppRoutes.staffPatientChart(patientId));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(find.textContaining(record.fullName), findsWidgets);
      final chartContext = tester.element(
        find.textContaining(record.fullName).first,
      );
      unawaited(
        showDialog<void>(
          context: chartContext,
          builder: (_) =>
              const AlertDialog(content: Text('Private preview content')),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(find.text('Private preview content'), findsOneWidget);
      final revoked = (db.delete(
        db.careTeamAssignments,
      )..where((a) => a.id.equals('temporary-access'))).go();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await revoked;
      for (var i = 0; i < 100 && c.read(sessionProvider).isAuthenticated; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(c.read(sessionProvider).isAuthenticated, false);
      expect(find.textContaining(record.fullName), findsNothing);
      expect(find.text('Private preview content'), findsNothing);
      expect(
        c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        AppRoutes.login,
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
