/// Drift-backed [PatientRepository] + [DepartmentRepository] (P1-12).
library;

import 'package:drift/drift.dart';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../services/auth/access_policy.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  /// Demographics are administrative, but blood type, allergies and chronic
  /// conditions are clinical: a reader without clinical access (an
  /// administrator, or a clinician outside the patient's care) gets the
  /// profile with those fields empty.
  static Patient _withoutClinicalFields(Patient p) => p.copyWith(
    bloodType: null,
    allergies: const [],
    chronicConditions: const [],
  );

  Future<List<Patient>> _redact(List<Patient> patients) async {
    final visible = await _access.clinicallyVisiblePatientIds();
    if (visible == null) return patients;
    return [
      for (final p in patients)
        visible.contains(p.id) ? p : _withoutClinicalFields(p),
    ];
  }

  Future<Patient> _load(String id) async {
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user == null || user.role != UserRole.patient) {
      throw NotFoundFailure('No patient $id.');
    }
    final profile = await (_db.select(
      _db.patientProfiles,
    )..where((p) => p.userId.equals(id))).getSingleOrNull();
    return patientFrom(user, profile);
  }

  @override
  Future<Result<Patient>> byId(String id) => Result.guardAsync(() async {
    await _access.readPatient(
      id,
      scope: PatientDataScope.administrative,
      entityType: 'patient',
      entityId: id,
    );
    final patient = await _load(id);
    return await _access.canRead(id)
        ? patient
        : _withoutClinicalFields(patient);
  });

  @override
  Future<Result<List<Patient>>> search(String query, {int limit = 50}) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'patient');
      final q = '%${query.trim()}%';
      final users =
          await (_db.select(_db.users)
                ..where(
                  (u) =>
                      u.role.equalsValue(UserRole.patient) &
                      (u.fullName.like(q) |
                          u.nationalId.like(q) |
                          u.phone.like(q)),
                )
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)])
                ..limit(limit))
              .get();
      return _redact(await _attachProfiles(users));
    });
  }

  @override
  Future<Result<List<PatientLinkCandidate>>> findLinkCandidate(
    String identifier,
  ) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageProxyGrants,
        entityType: 'family_link',
      );
      final value = identifier.trim();
      if (value.length < 5 || value.length > 254) return const [];
      final normalizedEmail = value.toLowerCase();
      final rows =
          await (_db.select(_db.users)..where(
                (u) =>
                    u.role.equalsValue(UserRole.patient) &
                    u.isActive.equals(true) &
                    u.hasLogin.equals(true) &
                    (u.email.equals(normalizedEmail) |
                        u.nationalId.equals(value)),
              ))
              .get();
      return rows
          .map((u) => PatientLinkCandidate(id: u.id, fullName: u.fullName))
          .toList(growable: false);
    });
  }

  @override
  Future<Result<List<Patient>>> all({int limit = 100, int offset = 0}) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'patient');
      final users =
          await (_db.select(_db.users)
                ..where((u) => u.role.equalsValue(UserRole.patient))
                ..orderBy([(u) => OrderingTerm(expression: u.fullName)])
                ..limit(limit, offset: offset))
              .get();
      return _redact(await _attachProfiles(users));
    });
  }

  @override
  Future<Result<Page<Patient>>> directoryPage({
    String query = '',
    PageRequest page = const PageRequest(),
  }) {
    return Result.guardAsync(() async {
      await _access.requireStaffOrAdmin(entityType: 'patient');
      final q = query.trim();
      final like = '%$q%';
      final users =
          await (_db.select(_db.users)
                ..where(
                  (u) =>
                      u.role.equalsValue(UserRole.patient) &
                      (q.isEmpty
                          ? const Constant(true)
                          : (u.fullName.like(like) |
                                u.nationalId.like(like) |
                                u.phone.like(like))),
                )
                ..orderBy([
                  (u) => OrderingTerm(expression: u.fullName),
                  (u) => OrderingTerm(expression: u.id),
                ])
                ..limit(page.size + 1, offset: page.offset))
              .get();
      final hasMore = users.length > page.size;
      return Page(
        items: await _redact(
          await _attachProfiles(hasMore ? users.sublist(0, page.size) : users),
        ),
        offset: page.offset,
        hasMore: hasMore,
      );
    });
  }

  Future<List<Patient>> _attachProfiles(List<UserRow> users) async {
    if (users.isEmpty) return const [];
    final ids = users.map((u) => u.id).toList();
    final profiles = await (_db.select(
      _db.patientProfiles,
    )..where((p) => p.userId.isIn(ids))).get();
    final byId = {for (final p in profiles) p.userId: p};
    return users.map((u) => patientFrom(u, byId[u.id])).toList();
  }

  @override
  Future<Result<void>> updateProfile(Patient patient) {
    return Result.guardAsync(() async {
      final subject = await _access.actForPatient(
        patient.id,
        Permission.updateProfile,
        entityType: 'patient',
        entityId: patient.id,
      );
      if (!subject.isSelf) {
        await _access.audit(
          'proxy.patient.update_profile',
          entityType: 'patient',
          entityId: patient.id,
          subjectPatientId: patient.id,
        );
      }
      await _db.transaction(() async {
        // Optimistic concurrency: [patient] carries the profile version it
        // was loaded at. If another device saved since, nothing is written
        // and the caller is told to reload — never a silent overwrite of,
        // say, a newly recorded allergy.
        final updated =
            await (_db.update(_db.patientProfiles)..where(
                  (p) =>
                      p.userId.equals(patient.id) &
                      p.version.equals(patient.profileVersion),
                ))
                .write(
                  PatientProfilesCompanion(
                    bloodType: Value(patient.bloodType),
                    allergies: Value(patient.allergies),
                    chronicConditions: Value(patient.chronicConditions),
                    emergencyContact: Value(patient.emergencyContact),
                  ),
                );
        if (updated != 1) {
          final current = await (_db.select(
            _db.patientProfiles,
          )..where((p) => p.userId.equals(patient.id))).getSingleOrNull();
          if (current == null) {
            throw NotFoundFailure('No patient ${patient.id}.');
          }
          throw ConflictFailure(
            'Your health profile was changed on another device. Reload to see '
            'the latest before saving.',
            currentVersion: current.version,
          );
        }
        await (_db.update(
          _db.users,
        )..where((u) => u.id.equals(patient.id))).write(
          UsersCompanion(
            fullName: Value(patient.user.fullName),
            phone: Value(patient.user.phone),
            dob: Value(patient.user.dob),
            gender: Value(patient.user.gender),
          ),
        );
      });
    });
  }

  @override
  Future<Result<List<FamilyMember>>> familyMembers(String patientId) {
    return Result.guardAsync(() async {
      await _access.readPatient(
        patientId,
        scope: PatientDataScope.administrative,
        entityType: 'family_member',
      );
      return _familyMembersOf(patientId);
    });
  }

  /// Only the account holder edits their own household list.
  Future<void> _ownHousehold(String patientId) async {
    final subject = await _access.actForPatient(
      patientId,
      Permission.manageProxyGrants,
      entityType: 'family_member',
    );
    if (!subject.isSelf) {
      throw const AccessDeniedFailure(
        'Only the account holder can change their family list.',
      );
    }
  }

  @override
  Future<Result<void>> addFamilyMember(String patientId, FamilyMember member) {
    return Result.guardAsync(() async {
      await _ownHousehold(patientId);
      final current = await _familyMembersOf(patientId);
      // The dependent record link is assigned here, never by a caller.
      await _writeFamilyMembers(patientId, [
        ...current,
        member.copyWith(patientId: null),
      ]);
    });
  }

  @override
  Future<Result<void>> updateFamilyMember(
    String patientId,
    FamilyMember member,
  ) {
    return Result.guardAsync(() async {
      await _ownHousehold(patientId);
      final current = await _familyMembersOf(patientId);
      final next = [
        for (final m in current)
          if (m.id == member.id) member.copyWith(patientId: m.patientId) else m,
      ];
      await _writeFamilyMembers(patientId, next);
    });
  }

  @override
  Future<Result<void>> removeFamilyMember(String patientId, String memberId) {
    return Result.guardAsync(() async {
      await _ownHousehold(patientId);
      final current = await _familyMembersOf(patientId);
      await _writeFamilyMembers(
        patientId,
        current.where((m) => m.id != memberId).toList(),
      );
    });
  }

  @override
  Future<Result<String>> ensureDependentRecord({
    required String guardianId,
    required String memberId,
  }) {
    return Result.guardAsync(() async {
      await _ownHousehold(guardianId);
      final members = await _familyMembersOf(guardianId);
      final member = members.where((m) => m.id == memberId).firstOrNull;
      if (member == null) {
        throw const NotFoundFailure('That family member was not found.');
      }
      final existing = member.patientId;
      if (existing != null) {
        final row = await (_db.select(
          _db.users,
        )..where((u) => u.id.equals(existing))).getSingleOrNull();
        if (row != null) return existing;
      }

      final id = newId('user');
      final now = DateTime.now();
      // A national ID already on another record is not copied — it would
      // collide with that record's unique index and blur two identities.
      final cpr = member.cpr?.trim();
      final cprTaken = cpr == null || cpr.isEmpty
          ? true
          : await (_db.select(
                  _db.users,
                )..where((u) => u.nationalId.equals(cpr))).getSingleOrNull() !=
                null;
      await _db.transaction(() async {
        await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                id: id,
                role: UserRole.patient,
                fullName: member.fullName.isEmpty
                    ? 'Family member'
                    : member.fullName,
                // Unroutable placeholder: the email column is required and
                // unique, and a dependent can never sign in or recover.
                email: '$id@dependent.invalid',
                // Unusable credentials; sign-in refuses hasLogin == false
                // before any password check.
                passwordHash: '!',
                passwordSalt: '!',
                hasLogin: const Value(false),
                phone: Value(member.phone),
                dob: Value(member.dob),
                gender: Value(member.gender),
                nationalId: Value(cprTaken ? null : cpr),
                createdAt: Value(now),
              ),
            );
        await _db
            .into(_db.patientProfiles)
            .insert(
              PatientProfilesCompanion.insert(
                userId: id,
                bloodType: Value(member.bloodType),
              ),
            );
        await _db
            .into(_db.familyLinks)
            .insert(
              FamilyLinksCompanion.insert(
                id: newId('flink'),
                ownerPatientId: id,
                viewerPatientId: guardianId,
                permission: FamilyLinkPermission.manage,
                status: const Value(FamilyLinkStatus.accepted),
                respondedAt: Value(now),
              ),
            );
        await _writeFamilyMembers(guardianId, [
          for (final m in members)
            if (m.id == memberId) m.copyWith(patientId: id) else m,
        ]);
      });
      await _access.audit(
        'dependent.record_created',
        entityType: 'patient',
        entityId: id,
        subjectPatientId: id,
        detail: member.relationship.name,
      );
      return id;
    });
  }

  Future<List<FamilyMember>> _familyMembersOf(String patientId) async {
    final profile = await (_db.select(
      _db.patientProfiles,
    )..where((p) => p.userId.equals(patientId))).getSingleOrNull();
    return profile?.familyMembers ?? const [];
  }

  Future<void> _writeFamilyMembers(
    String patientId,
    List<FamilyMember> members,
  ) {
    return (_db.update(_db.patientProfiles)
          ..where((p) => p.userId.equals(patientId)))
        .write(PatientProfilesCompanion(familyMembers: Value(members)));
  }
}

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._db, {AccessPolicy? access})
    : _access = access ?? AccessPolicy.unenforced(_db);

  final AppDatabase _db;
  final AccessPolicy _access;

  @override
  Future<Result<List<Department>>> all() {
    return Result.guardAsync(() async {
      final rows = await (_db.select(
        _db.departments,
      )..orderBy([(d) => OrderingTerm(expression: d.name)])).get();
      return rows.map((r) => r.toEntity()).toList();
    });
  }

  @override
  Future<Result<Department>> byId(String id) {
    return Result.guardAsync(() async {
      final row = await (_db.select(
        _db.departments,
      )..where((d) => d.id.equals(id))).getSingleOrNull();
      if (row == null) throw NotFoundFailure('No department $id.');
      return row.toEntity();
    });
  }

  @override
  Future<Result<void>> upsert(Department department) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageDepartments,
        entityType: 'department',
        entityId: department.id,
      );
      await _db
          .into(_db.departments)
          .insertOnConflictUpdate(
            DepartmentsCompanion.insert(
              id: department.id,
              name: department.name,
              description: Value(department.description),
            ),
          );
    });
  }

  @override
  Future<Result<void>> delete(String id) {
    return Result.guardAsync(() async {
      await _access.require(
        Permission.manageDepartments,
        entityType: 'department',
        entityId: id,
      );
      final staff = await (_db.select(
        _db.staffProfiles,
      )..where((p) => p.departmentId.equals(id))).get();
      final appts = await (_db.select(
        _db.appointments,
      )..where((a) => a.departmentId.equals(id))).get();
      if (staff.isNotEmpty || appts.isNotEmpty) {
        throw ValidationFailure(
          'Still in use: ${staff.length} staff and ${appts.length} '
          'appointment(s) are assigned to this department. '
          'Reassign them first.',
        );
      }
      await (_db.delete(_db.departments)..where((d) => d.id.equals(id))).go();
    });
  }
}
