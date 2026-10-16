import 'dart:convert';

import 'package:drift/drift.dart';
import '../../core/utils/ticketing.dart';

import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../services/auth/password_hasher.dart';
import '../db/app_database.dart';
import 'workforce_manifest.g.dart';

List<Map<String, dynamic>> get demoWorkforceAccounts =>
    (jsonDecode(workforceManifestJson) as List).cast<Map<String, dynamic>>();

/// Additive repair. The caller must explicitly identify the database as demo.
/// Existing credentials, status, identities and nonempty profile fields win.
class DemoWorkforce {
  DemoWorkforce(this.db, {required this.demoEnabled});
  final AppDatabase db;
  final bool demoEnabled;
  final issues = <String>[];

  Future<void> repair() async {
    if (!demoEnabled)
      throw StateError('Synthetic workforce provisioning is disabled.');
    await db.transaction(() async {
      for (final account in demoWorkforceAccounts) {
        final email = account['email'] as String;
        final expectedId = account['id'] as String;
        var user = await (db.select(
          db.users,
        )..where((u) => u.email.equals(email))).getSingleOrNull();
        if (user == null) {
          final occupied = await (db.select(
            db.users,
          )..where((u) => u.id.equals(expectedId))).getSingleOrNull();
          if (occupied != null) {
            issues.add(
              '$email: identifier collision; administrator review required',
            );
            continue;
          }
          final hash = const PasswordHasher(
            iterations: 1000,
          ).hashNew('password');
          await db
              .into(db.users)
              .insert(
                UsersCompanion.insert(
                  id: expectedId,
                  role: account['role'] == 'admin'
                      ? UserRole.admin
                      : UserRole.staff,
                  fullName: account['name'] as String,
                  email: email,
                  passwordHash: hash.hash,
                  passwordSalt: hash.salt,
                ),
              );
          user = await (db.select(
            db.users,
          )..where((u) => u.id.equals(expectedId))).getSingle();
        }
        final expectedType = account['role'] == 'admin'
            ? UserRole.admin
            : UserRole.staff;
        if (user.role != expectedType) {
          issues.add(
            '$email: account type differs; administrator review required',
          );
          continue;
        }
        if (expectedType == UserRole.admin) continue;
        final departmentId = account['departmentId'] as String;
        await db
            .into(db.departments)
            .insert(
              DepartmentsCompanion.insert(
                id: departmentId,
                name: account['departmentName'] as String,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        final role = StaffRole.values.byName(account['role'] as String);
        final profile = await (db.select(
          db.staffProfiles,
        )..where((p) => p.userId.equals(user!.id))).getSingleOrNull();
        if (profile == null) {
          await db
              .into(db.staffProfiles)
              .insert(
                StaffProfilesCompanion.insert(
                  userId: user.id,
                  jobTitle: Value(role.jobTitle),
                  departmentId: Value(departmentId),
                ),
              );
          if (role == StaffRole.doctor || role == StaffRole.dentist) {
            final at = DateTime.now();
            await db
                .into(db.staffCredentials)
                .insert(
                  StaffCredentialsCompanion.insert(
                    id: 'demo_credential_${user.id}',
                    staffId: user.id,
                    kind: role == StaffRole.dentist
                        ? CredentialKind.dentalLicense
                        : CredentialKind.medicalLicense,
                    identifier: 'SYNTHETIC-${user.id}',
                    issuer: const Value('Synthetic demo only'),
                    recordedAt: at,
                    verifiedAt: Value(at),
                    validUntil: Value(at.add(const Duration(days: 365))),
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        } else {
          if (StaffRole.parse(profile.jobTitle) != role) {
            issues.add(
              '$email: professional role differs; administrator review required',
            );
            continue;
          }
          if (profile.departmentId == null) {
            await (db.update(
              db.staffProfiles,
            )..where((p) => p.userId.equals(user!.id))).write(
              StaffProfilesCompanion(departmentId: Value(departmentId)),
            );
          }
        }
        if (!user.isActive ||
            !user.hasLogin ||
            user.lockedUntil?.isAfter(DateTime.now()) == true) {
          issues.add(
            '$email: disabled or locked; use account recovery/administrator controls',
          );
          continue;
        }
        final scheduleMarker = 'demo.roster.schedule:${user.id}';
        final prior = await (db.select(
          db.clinicConfigurations,
        )..where((c) => c.id.equals(scheduleMarker))).getSingleOrNull();
        if (prior == null) {
          if (role.takesAppointments) {
            final existing = await (db.select(
              db.scheduleTemplates,
            )..where((s) => s.staffId.equals(user!.id))).get();
            if (existing.isEmpty)
              for (final weekday in [7, 1, 2, 3, 4]) {
                await db
                    .into(db.scheduleTemplates)
                    .insert(
                      ScheduleTemplatesCompanion.insert(
                        id: 'demo_${user.id}_wd$weekday',
                        staffId: user.id,
                        weekday: weekday,
                        startMinutes: 480,
                        endMinutes: 960,
                      ),
                      mode: InsertMode.insertOrIgnore,
                    );
              }
          } else {
            final existing = await (db.select(
              db.staffShifts,
            )..where((s) => s.staffId.equals(user!.id))).get();
            if (existing.isEmpty)
              for (final weekday in [7, 1, 2, 3, 4]) {
                await db
                    .into(db.staffShifts)
                    .insert(
                      StaffShiftsCompanion.insert(
                        id: 'demo_${user.id}_shift$weekday',
                        staffId: user.id,
                        weekday: weekday,
                        startMinutes: 480,
                        endMinutes: 960,
                        departmentId: Value(departmentId),
                      ),
                      mode: InsertMode.insertOrIgnore,
                    );
              }
          }
          await db
              .into(db.clinicConfigurations)
              .insert(
                ClinicConfigurationsCompanion.insert(
                  id: scheduleMarker,
                  valueJson: '{"synthetic":true}',
                  updatedAt: DateTime.now(),
                ),
              );
        }
      }
      await _workloads();
    });
  }

  Future<void> _workloads() async {
    final patients =
        (await (db.select(
              db.users,
            )..where((u) => u.role.equalsValue(UserRole.patient))).get())
            .where(
              (u) => RegExp(r'^patient\d+@myhealth\.demo$').hasMatch(u.email),
            )
            .toList();
    if (patients.isEmpty) return;
    final profiles = await db.select(db.staffProfiles).get();
    final people = {for (final u in await db.select(db.users).get()) u.id: u};
    final syntheticEmails = demoWorkforceAccounts
        .map((a) => a['email'])
        .toSet();
    final clinicians = profiles
        .where(
          (p) =>
              StaffRole.parse(p.jobTitle)?.takesAppointments == true &&
              people[p.userId]?.isActive == true &&
              syntheticEmails.contains(people[p.userId]?.email),
        )
        .toList();
    if (clinicians.isEmpty) return;
    final wall = DateTime.now().toUtc().add(const Duration(hours: 3));
    final day = DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
    ).subtract(const Duration(hours: 3));
    Future<String> ticket(DateTime start) async {
      final bucket = DateTime.utc(
        start.toUtc().year,
        start.toUtc().month,
        start.toUtc().day,
        start.toUtc().hour,
      );
      final existing =
          await (db.select(db.appointments)..where(
                (a) =>
                    a.slotStart.isBiggerOrEqualValue(bucket) &
                    a.slotStart.isSmallerThanValue(
                      bucket.add(const Duration(hours: 1)),
                    ),
              ))
              .get();
      return '${hourLetterFor(start)}-${existing.length + 1}';
    }

    Future<String> room(StaffProfileRow clinician) async {
      final department =
          await (db.select(db.departments)
                ..where((d) => d.id.equals(clinician.departmentId ?? '')))
              .getSingleOrNull();
      final peers =
          clinicians
              .where((p) => p.departmentId == clinician.departmentId)
              .map((p) => p.userId)
              .toList()
            ..sort();
      return '${departmentLetterFor(department?.name ?? '')}-${peers.indexOf(clinician.userId) + 1}';
    }

    Future<AppointmentRow?> visit(
      String key,
      StaffProfileRow clinician,
      String patient, {
      bool arrived = false,
    }) async {
      final prior = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(key))).getSingleOrNull();
      if (prior != null) return prior;
      for (var offset = 0; offset < 7; offset++) {
        final date = day.add(Duration(days: offset));
        final templates =
            await (db.select(db.scheduleTemplates)..where(
                  (s) =>
                      s.staffId.equals(clinician.userId) &
                      s.weekday.equals(
                        date.add(const Duration(hours: 3)).weekday,
                      ),
                ))
                .get();
        for (final template in templates) {
          for (
            var minute = template.startMinutes;
            minute + template.slotMinutes <= template.endMinutes;
            minute += template.slotMinutes
          ) {
            final start = date.add(Duration(minutes: minute)),
                end = date.add(
                  Duration(minutes: minute + template.slotMinutes),
                );
            if (!start.isAfter(DateTime.now().add(const Duration(minutes: 5))))
              continue;
            final collision =
                await (db.select(db.appointments)..where(
                      (a) =>
                          a.staffId.equals(clinician.userId) &
                          a.status.isNotInValues([
                            AppointmentStatus.cancelled,
                          ]) &
                          a.slotStart.isSmallerThanValue(end) &
                          a.slotEnd.isBiggerThanValue(start),
                    ))
                    .get();
            final exceptions =
                await (db.select(db.availabilityExceptions)..where(
                      (e) =>
                          e.staffId.equals(clinician.userId) &
                          e.startsAt.isSmallerThanValue(end) &
                          e.endsAt.isBiggerThanValue(start),
                    ))
                    .get();
            if (collision.isNotEmpty || exceptions.isNotEmpty) continue;
            await db
                .into(db.appointments)
                .insert(
                  AppointmentsCompanion.insert(
                    id: key,
                    patientId: patient,
                    staffId: clinician.userId,
                    departmentId: Value(clinician.departmentId),
                    slotStart: start,
                    slotEnd: end,
                    status: Value(
                      arrived
                          ? AppointmentStatus.confirmed
                          : AppointmentStatus.booked,
                    ),
                    visitType: VisitType.followUp,
                    reasonText: const Value('Synthetic demonstration visit'),
                    bookedAt: Value(day),
                    ticketTag: Value(await ticket(start)),
                    roomNumber: Value(await room(clinician)),
                  ),
                );
            return (db.select(
              db.appointments,
            )..where((a) => a.id.equals(key))).getSingle();
          }
        }
      }
      return null;
    }

    for (var i = 0; i < clinicians.length; i++) {
      final clinician = clinicians[i];
      if (clinician.departmentId == null) continue;
      await visit(
        'demo_roster_visit_${clinician.userId}',
        clinician,
        patients[i % patients.length].id,
      );
    }
    final nurses = profiles
        .where(
          (p) =>
              StaffRole.parse(p.jobTitle) == StaffRole.nurse &&
              people[p.userId]?.isActive == true &&
              syntheticEmails.contains(people[p.userId]?.email),
        )
        .toList();
    for (var i = 0; i < nurses.length; i++) {
      final nurse = nurses[i],
          patient = patients[(i + 12) % patients.length].id;
      final matching = clinicians
          .where((c) => c.departmentId == nurse.departmentId)
          .toList();
      if (matching.isEmpty) continue;
      final appointment = await visit(
        'demo_roster_intake_${nurse.userId}',
        matching[i % matching.length],
        patient,
        arrived: true,
      );
      if (appointment == null) continue;
      await db
          .into(db.careTeamAssignments)
          .insert(
            CareTeamAssignmentsCompanion.insert(
              id: 'demo_roster_care_${nurse.userId}',
              patientId: appointment.patientId,
              staffId: nurse.userId,
              role: CareTeamRole.nurse,
              assignedAt: day,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await db
          .into(db.nursingIntakes)
          .insert(
            NursingIntakesCompanion.insert(
              id: 'demo_intake_${nurse.userId}',
              appointmentId: appointment.id,
              nurseId: nurse.userId,
              assignedAt: day,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final pharmacists = profiles
        .where(
          (p) =>
              StaffRole.parse(p.jobTitle) == StaffRole.pharmacist &&
              people[p.userId]?.isActive == true &&
              syntheticEmails.contains(people[p.userId]?.email),
        )
        .toList();
    if (pharmacists.isNotEmpty) {
      const orderId = 'demo_workforce_prescription';
      final existing = await (db.select(
        db.medications,
      )..where((m) => m.id.equals(orderId))).getSingleOrNull();
      if (existing == null) {
        final clinician = clinicians.first;
        final patient = patients.first.id;
        final at = day.subtract(const Duration(days: 1));
        const encounter = 'demo_workforce_signed_encounter';
        await db
            .into(db.appointments)
            .insert(
              AppointmentsCompanion.insert(
                id: encounter,
                patientId: patient,
                staffId: clinician.userId,
                visitType: VisitType.routineCheckup,
                departmentId: Value(clinician.departmentId),
                slotStart: at,
                slotEnd: at.add(const Duration(minutes: 20)),
                status: const Value(AppointmentStatus.completed),
                completedAt: Value(at.add(const Duration(minutes: 20))),
                reasonText: const Value(
                  'Synthetic signed prescription workflow',
                ),
                bookedAt: Value(at),
                ticketTag: Value(await ticket(at)),
                roomNumber: Value(await room(clinician)),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await db
            .into(db.signedNotes)
            .insert(
              SignedNotesCompanion.insert(
                id: 'demo_workforce_signed_note',
                appointmentId: encounter,
                patientId: patient,
                authorStaffId: clinician.userId,
                body: 'Synthetic completed encounter for demonstration only.',
                signedAt: Value(at),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await db
            .into(db.medications)
            .insert(
              MedicationsCompanion.insert(
                id: orderId,
                patientId: patient,
                prescriberId: Value(clinician.userId),
                appointmentId: const Value(encounter),
                name: 'Paracetamol',
                dose: const Value('500 mg'),
                frequency: const Value('As recorded in synthetic order'),
                startDate: day,
                issuedAt: Value(at),
              ),
            );
        await db
            .into(db.pharmacyStockBatches)
            .insert(
              PharmacyStockBatchesCompanion.insert(
                id: 'demo_workforce_stock',
                idempotencyKey: 'demo_workforce_stock',
                itemName: 'Paracetamol',
                batch: 'SYNTHETIC-2026',
                expiry: day.add(const Duration(days: 365)),
                quantity: 100,
                unit: const Value('tablets'),
                receivedBy: pharmacists.first.userId,
                receivedAt: day,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  }

  /// Safe export: no hash, salt, password, token, or clinical content.
  Future<List<Map<String, dynamic>>> manifest() async {
    if (!demoEnabled)
      throw StateError('Demo manifest is unavailable in production.');
    return [
      for (final r in await db.customSelect('''
      SELECT u.id,u.full_name AS name,u.email,u.role AS account_type,
      sp.job_title AS professional_role,d.name AS department,
      u.is_active AS active,u.has_login AS login_enabled
      FROM users u LEFT JOIN staff_profiles sp ON sp.user_id=u.id
      LEFT JOIN departments d ON d.id=sp.department_id
      WHERE u.role IN ('staff','admin') ORDER BY u.role,sp.job_title,u.email
    ''').get())
        {
          ...r.data,
          'professional_role': StaffRole.parse(
            r.data['professional_role'] as String?,
          )?.name,
        },
    ];
  }
}
