import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/auth_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/auth/password_hasher.dart';

import '../support/test_database.dart';

void main() {
  test(
    'unknown staff profiles fail normal login without acquiring doctor access',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      await (db.update(db.staffProfiles)
            ..where((s) => s.userId.equals('staff_01')))
          .write(const StaffProfilesCompanion(jobTitle: Value('Porter')));
      final result = await AuthRepositoryImpl(
        db,
      ).login(email: 'staff1@myhealth.demo', password: 'password');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.message, contains('administrator'));
    },
  );
  for (final marker in [15, Seeder.seedVersion]) {
    test(
      'repairs missing staff logins in a nonempty demo at marker $marker',
      () async {
        final db = newTestDatabase();
        addTearDown(db.close);
        final hash = const PasswordHasher(iterations: 1000).hashNew('password');
        await db
            .into(db.users)
            .insert(
              UsersCompanion.insert(
                id: 'staff_01',
                role: UserRole.staff,
                fullName: 'Existing Doctor',
                email: 'staff1@myhealth.demo',
                passwordHash: hash.hash,
                passwordSalt: hash.salt,
              ),
            );
        await db
            .into(db.staffProfiles)
            .insert(
              StaffProfilesCompanion.insert(
                userId: 'staff_01',
                jobTitle: const Value('Doctor'),
              ),
            );
        await db
            .into(db.appSettings)
            .insert(AppSettingsCompanion(seedVersion: Value(marker)));
        final auth = AuthRepositoryImpl(db);
        expect(
          (await auth.login(
            email: 'staff1@myhealth.demo',
            password: 'password',
          )).isOk,
          isTrue,
        );
        for (final login in ['nurse', 'reception', 'pharmacy', 'dentist']) {
          expect(
            (await auth.login(
              email: '$login@myhealth.demo',
              password: 'password',
            )).isErr,
            isTrue,
          );
        }
        await Seeder(db).run();
        for (final login in ['nurse', 'reception', 'pharmacy', 'dentist']) {
          expect(
            (await auth.login(
              email: '$login@myhealth.demo',
              password: 'password',
            )).isOk,
            isTrue,
            reason:
                '$login must be provisioned even when the marker is current',
          );
        }
        final original = await (db.select(
          db.users,
        )..where((u) => u.id.equals('staff_01'))).getSingle();
        expect(original.fullName, 'Existing Doctor');
        expect(original.passwordHash, hash.hash);
      },
    );
  }
}
