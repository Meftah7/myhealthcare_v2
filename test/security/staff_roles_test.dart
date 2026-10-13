// Explicit staff roles: validated job titles, one permission set per role,
// and no clinical grants for a missing or unknown title.
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';

import '../support/sessions.dart';

void main() {
  group('StaffRole.parse', () {
    test('maps the five stored titles and the seeded Consultant alias', () {
      expect(StaffRole.parse('Doctor'), StaffRole.doctor);
      expect(StaffRole.parse('Consultant'), StaffRole.doctor);
      expect(StaffRole.parse(' nurse '), StaffRole.nurse);
      expect(StaffRole.parse('Receptionist'), StaffRole.receptionist);
      expect(StaffRole.parse('Pharmacist'), StaffRole.pharmacist);
      expect(StaffRole.parse('Dentist'), StaffRole.dentist);
    });

    test('a missing or unknown title is not guessed', () {
      for (final title in [null, '', 'Pharmaceutical rep', 'Surgeon?']) {
        expect(StaffRole.parse(title), isNull, reason: '$title');
      }
    });
  });

  group('RolePermissions.forStaff', () {
    const clinical = {
      Permission.readPatientChart,
      Permission.writeClinicalRecord,
      Permission.prescribe,
      Permission.signEncounter,
      Permission.issueSickLeave,
      Permission.reviewResults,
    };

    test('unknown staff receive no permissions', () {
      expect(RolePermissions.forStaff(null), isEmpty);
      expect(RolePermissions.forRole(UserRole.staff), isEmpty);
    });

    test('reception and pharmacy never get clinical permissions', () {
      for (final role in [StaffRole.receptionist, StaffRole.pharmacist]) {
        expect(
          RolePermissions.forStaff(role).intersection(clinical),
          isEmpty,
          reason: role.name,
        );
      }
      expect(
        RolePermissions.forStaff(StaffRole.receptionist),
        containsAll({
          Permission.bookForPatients,
          Permission.checkInPatients,
          Permission.confirmDocumentCopy,
        }),
      );
      expect(
        RolePermissions.forStaff(StaffRole.pharmacist),
        contains(Permission.dispenseMedication),
      );
    });

    test('nurses draft but do not prescribe or sign', () {
      final nurse = RolePermissions.forStaff(StaffRole.nurse);
      expect(nurse, contains(Permission.readPatientChart));
      expect(nurse, isNot(contains(Permission.prescribe)));
      expect(nurse, isNot(contains(Permission.signEncounter)));
    });

    test('dentists have a dental scope, not the full doctor set', () {
      final dentist = RolePermissions.forStaff(StaffRole.dentist);
      expect(
        dentist,
        containsAll({Permission.prescribe, Permission.signEncounter}),
      );
      expect(dentist, isNot(contains(Permission.reviewResults)));
      expect(dentist, isNot(equals(RolePermissions.doctor)));
    });

    test('no staff role holds dispensing and prescribing together', () {
      for (final role in StaffRole.values) {
        final grants = RolePermissions.forStaff(role);
        expect(
          grants.contains(Permission.prescribe) &&
              grants.contains(Permission.dispenseMedication),
          isFalse,
          reason: role.name,
        );
      }
    });
  });

  group('repository enforcement', () {
    for (final email in ['reception@myhealth.demo', 'pharmacy@myhealth.demo']) {
      test('$email cannot read a patient chart', () async {
        final (c, _) = await seededContainer();
        await signInAs(c, email);
        final r = await c
            .read(recordRepositoryProvider)
            .timeline('patient_001');
        expect(r.failureOrNull, isA<AccessDeniedFailure>());
      });
    }
  });
}
