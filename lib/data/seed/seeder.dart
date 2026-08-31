/// Synthetic dataset generator (P1-20, P1-21).
///
/// Seeded RNG → byte-identical data on every run. The data is **correlated,
/// not random**: chronic patients attend more often, some patients genuinely
/// no-show a lot, and lab values drift toward each condition's abnormal side
/// over time. That correlation is what the no-show model (P4) learns and what
/// the rule engine (P5) reacts to.
library;

import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../../services/auth/password_hasher.dart';
import '../db/app_database.dart';
import 'vocab/clinical.dart';
import 'vocab/names.dart';

class SeedResult {
  const SeedResult({
    required this.departments,
    required this.staff,
    required this.patients,
    required this.appointments,
    required this.records,
  });
  final int departments;
  final int staff;
  final int patients;
  final int appointments;
  final int records;
}

class Seeder {
  Seeder(this._db, {int seed = 20260101})
    : _rng = Random(seed),
      // Cheap work factor for the ~72 demo accounts — the hash string records
      // the count, so login (which reads it back) still verifies fine.
      _hasher = const PasswordHasher(iterations: 1000);

  final AppDatabase _db;
  final Random _rng;
  final PasswordHasher _hasher;

  /// Bump when the generation logic changes so existing DBs re-seed.
  static const seedVersion = 3;

  /// Password for every seeded account (documented in the README).
  static const demoPassword = 'password';

  static final _epoch = DateTime(2026, 8, 31);
  static final _historyStart = DateTime(2024, 8, 31);

  /// Runs the seeder unless the DB is already at [seedVersion] (or [force]).
  Future<SeedResult?> run({bool force = false}) async {
    final current = await _currentSeedVersion();
    if (!force && current == seedVersion) return null;

    await _wipe();
    final result = await _db.transaction(_generate);
    await _setSeedVersion(seedVersion);
    return result;
  }

  /// P1-21: wipe all demo data and regenerate from scratch.
  Future<SeedResult> reset() async {
    await _wipe();
    final result = await _db.transaction(_generate);
    await _setSeedVersion(seedVersion);
    return result;
  }

  // --- generation --------------------------------------------------------

  Future<SeedResult> _generate() async {
    await _seedAdmin();
    final deptIds = await _seedDepartments();
    final staff = await _seedStaff(deptIds);
    final patients = await _seedPatients();

    var appts = 0;
    var records = 0;
    for (final p in patients) {
      final counts = await _seedPatientHistory(p, staff);
      appts += counts.$1;
      records += counts.$2;
    }

    return SeedResult(
      departments: deptIds.length,
      staff: staff.length,
      patients: patients.length,
      appointments: appts,
      records: records,
    );
  }

  Future<void> _seedAdmin() => _insertUser(
    id: 'admin_01',
    role: UserRole.admin,
    fullName: 'System Administrator',
    email: 'admin@myhealth.demo',
    male: true,
    dob: _epoch.subtract(const Duration(days: 365 * 40)),
  );

  Future<List<String>> _seedDepartments() async {
    final ids = <String>[];
    for (var i = 0; i < departments.length; i++) {
      final d = departments[i];
      final id = 'dept_${i + 1}';
      await _db
          .into(_db.departments)
          .insert(
            DepartmentsCompanion.insert(
              id: id,
              name: d.name,
              description: Value(d.description),
            ),
          );
      ids.add(id);
    }
    return ids;
  }

  Future<List<_Staff>> _seedStaff(List<String> deptIds) async {
    final staff = <_Staff>[];
    var n = 0;
    for (var d = 0; d < departments.length; d++) {
      final dept = departments[d];
      // ~2–3 staff per department → 12 total.
      final perDept = d < 2 ? 3 : 2;
      for (var i = 0; i < perDept; i++) {
        n++;
        final id = 'staff_${n.toString().padLeft(2, '0')}';
        final male = _rng.nextBool();
        final name = _fullName(male: male);
        await _insertUser(
          id: id,
          role: UserRole.staff,
          fullName: 'Dr $name',
          email: 'staff$n@myhealth.demo',
          male: male,
          dob: _epoch.subtract(Duration(days: 365 * (32 + _rng.nextInt(25)))),
        );
        await _db
            .into(_db.staffProfiles)
            .insert(
              StaffProfilesCompanion.insert(
                userId: id,
                specialty: Value(dept.specialties[i % dept.specialties.length]),
                departmentId: Value(deptIds[d]),
                licenseNo: Value('BH-${10000 + n}'),
                jobTitle: const Value('Consultant'),
              ),
            );
        // A weekday schedule: Sun–Thu, 08:00–14:00, 20-minute slots.
        for (final weekday in const [7, 1, 2, 3, 4]) {
          await _db
              .into(_db.scheduleTemplates)
              .insert(
                ScheduleTemplatesCompanion.insert(
                  id: '${id}_wd$weekday',
                  staffId: id,
                  weekday: weekday,
                  startMinutes: 8 * 60,
                  endMinutes: 14 * 60,
                ),
              );
        }
        staff.add(_Staff(id, deptIds[d]));
      }
    }
    return staff;
  }

  Future<List<_Patient>> _seedPatients() async {
    final patients = <_Patient>[];
    for (var i = 1; i <= 60; i++) {
      final id = 'patient_${i.toString().padLeft(3, '0')}';
      final male = _rng.nextBool();
      final age = 8 + _rng.nextInt(75);
      final dob = _epoch.subtract(
        Duration(days: 365 * age + _rng.nextInt(365)),
      );

      // Older adults accumulate more chronic conditions.
      final conditionCount = age < 30
          ? _weighted([0.85, 0.13, 0.02])
          : age < 55
          ? _weighted([0.45, 0.35, 0.15, 0.05])
          : _weighted([0.15, 0.30, 0.30, 0.20, 0.05]);
      final conditions = _sample(chronicConditions, conditionCount);

      // Hidden no-show tendency: most low, a stubborn ~quarter high.
      // Mirrors tools/ml/generate_dataset.py so the model trained offline
      // works on this app's data.
      final noShowTendency = _rng.nextDouble() < 0.24
          ? 0.45 + _rng.nextDouble() * 0.40
          : 0.02 + _rng.nextDouble() * 0.09;

      await _insertUser(
        id: id,
        role: UserRole.patient,
        fullName: _fullName(male: male),
        email: 'patient$i@myhealth.demo',
        male: male,
        dob: dob,
        nationalId: '${_rng.nextInt(3) + 8}${_digits(8)}',
      );
      await _db
          .into(_db.patientProfiles)
          .insert(
            PatientProfilesCompanion.insert(
              userId: id,
              bloodType: Value(_pick(_bloodTypes)),
              allergies: Value(
                _rng.nextDouble() < 0.25 ? [_pick(_allergens)] : const [],
              ),
              chronicConditions: Value(conditions.map((c) => c.name).toList()),
              emergencyContact: Value('+973 3${_digits(7)}'),
            ),
          );

      patients.add(
        _Patient(
          id: id,
          age: age,
          conditions: conditions,
          noShowTendency: noShowTendency,
        ),
      );
    }
    return patients;
  }

  /// Returns (appointmentCount, recordCount).
  Future<(int, int)> _seedPatientHistory(_Patient p, List<_Staff> staff) async {
    final chronic = p.conditions.isNotEmpty;
    // Chronic patients come in every 3–8 weeks; others a few times a year.
    final intervalDays = chronic
        ? 24 + _rng.nextInt(34)
        : 75 + _rng.nextInt(120);

    var appts = 0;
    var records = 0;
    var when = _historyStart.add(Duration(days: _rng.nextInt(intervalDays)));

    // Start each chronic condition on a medication near the first visit.
    for (final c in p.conditions) {
      final meds = medicationsByCondition[c.name];
      if (meds == null) continue;
      await _db
          .into(_db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: 'med_${p.id}_${c.name.hashCode.toUnsigned(16)}',
              patientId: p.id,
              name: _pick(meds),
              startDate: when,
              prescriberId: Value(_pick(staff).id),
              dose: const Value('as directed'),
              frequency: const Value('once daily'),
              isActive: Value(_rng.nextDouble() < 0.9),
            ),
          );
    }

    while (when.isBefore(_epoch.add(const Duration(days: 90)))) {
      final doc = _pick(staff);
      final isFuture = when.isAfter(_epoch);
      final leadDays = isFuture ? when.difference(_epoch).inDays : 0;

      final status = _appointmentStatus(
        p,
        isFuture: isFuture,
        leadDays: leadDays,
      );
      final risk = _noShowProbability(p, leadDays: isFuture ? leadDays : 7);

      final slotStart = DateTime(
        when.year,
        when.month,
        when.day,
        8 + _rng.nextInt(6),
        _pick(const [0, 20, 40]),
      );
      final apptId = 'appt_${p.id}_${appts.toString().padLeft(2, '0')}';
      await _db
          .into(_db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: apptId,
              patientId: p.id,
              staffId: doc.id,
              slotStart: slotStart,
              slotEnd: slotStart.add(const Duration(minutes: 20)),
              visitType: chronic
                  ? VisitType.chronicCareReview
                  : _pick(VisitType.values),
              status: Value(status),
              departmentId: Value(doc.departmentId),
              reasonText: Value(_pick(visitReasons)),
              bookedAt: Value(
                when.subtract(Duration(days: 3 + _rng.nextInt(20))),
              ),
              noShowRisk: Value(risk),
              riskBand: Value(_band(risk)),
              remindersSent: Value(isFuture ? 0 : 1 + _rng.nextInt(2)),
            ),
          );
      appts++;

      // A completed visit leaves a note; chronic reviews add labs + vitals.
      if (status == AppointmentStatus.completed) {
        records += await _seedVisitRecords(p, doc, slotStart);
      }

      when = when.add(Duration(days: intervalDays + _rng.nextInt(21) - 10));
    }

    // A couple of recent risk flags for patients trending abnormal.
    if (chronic && _rng.nextDouble() < 0.4) {
      final c = _pick(p.conditions);
      await _db
          .into(_db.riskFlags)
          .insert(
            RiskFlagsCompanion.insert(
              id: 'flag_${p.id}_1',
              patientId: p.id,
              kind: RiskFlagKind.abnormalLab,
              severity: _rng.nextBool() ? Severity.warning : Severity.urgent,
              rationale: '${c.name}: recent results above target range.',
              dedupeKey: 'lab:${p.id}:${c.name}',
              detectedAt: Value(
                _epoch.subtract(Duration(days: _rng.nextInt(20))),
              ),
            ),
          );
    }

    return (appts, records);
  }

  Future<int> _seedVisitRecords(_Patient p, _Staff doc, DateTime at) async {
    var records = 0;

    await _db
        .into(_db.medicalRecords)
        .insert(
          MedicalRecordsCompanion.insert(
            id: 'rec_${p.id}_${at.millisecondsSinceEpoch}',
            patientId: p.id,
            recordType: RecordType.visitNote,
            title: 'Clinic visit',
            occurredAt: at,
            authorStaffId: Value(doc.id),
            body: Value(
              'Reviewed ${p.conditions.isEmpty ? "general health" : p.conditions.map((c) => c.name).join(", ")}. '
              'Plan discussed, medications continued.',
            ),
            sourceFacility: Value(_pick(facilities)),
          ),
        );
    records++;

    // Vitals at every visit.
    final progress = _monthsSinceStart(at) / 24.0;
    await _db
        .into(_db.vitals)
        .insert(
          VitalsCompanion.insert(
            id: 'vit_${p.id}_${at.millisecondsSinceEpoch}',
            patientId: p.id,
            recordedAt: at,
            systolic: Value(
              _vital(120, p, 'Systolic BP', progress, spread: 10, drift: 18),
            ),
            diastolic: Value(
              _vital(78, p, 'Diastolic BP', progress, spread: 6, drift: 10),
            ),
            heartRate: Value(68 + _rng.nextInt(20)),
            weightKg: Value(
              (62 +
                      _rng.nextInt(38) +
                      progress * (p.hasCondition('Obesity') ? 6 : 1))
                  .toDouble(),
            ),
            heightCm: Value((155 + _rng.nextInt(35)).toDouble()),
            spo2: Value(
              p.hasCondition('Asthma')
                  ? 94 + _rng.nextInt(4)
                  : 97 + _rng.nextInt(3),
            ),
            glucose: Value(
              _vitalD(
                5.0,
                p,
                'Fasting Glucose',
                progress,
                spread: 0.6,
                drift: 2.2,
              ),
            ),
            recordedByStaffId: Value(doc.id),
          ),
        );

    // Chronic reviews order a lab panel.
    if (p.conditions.isNotEmpty && _rng.nextDouble() < 0.7) {
      final recId = 'rec_${p.id}_${at.millisecondsSinceEpoch}_lab';
      await _db
          .into(_db.medicalRecords)
          .insert(
            MedicalRecordsCompanion.insert(
              id: recId,
              patientId: p.id,
              recordType: RecordType.labResult,
              title: 'Laboratory panel',
              occurredAt: at,
              authorStaffId: Value(doc.id),
              sourceFacility: Value(_pick(facilities)),
            ),
          );
      records++;

      final ordered = _sample(analytes, 4 + _rng.nextInt(5));
      for (final a in ordered) {
        final drifts = p.conditions.any((c) => c.raises.contains(a.name));
        final lowers = p.conditions.any((c) => c.lowers.contains(a.name));
        var value =
            a.healthyMean + (_rng.nextDouble() - 0.5) * (a.high - a.low) * 0.5;
        if (drifts) value += (a.high - a.healthyMean) * (0.4 + progress * 1.1);
        if (lowers) value -= (a.healthyMean - a.low) * (0.4 + progress * 1.1);
        value = double.parse(value.toStringAsFixed(2));

        final flag = _classify(value, a.low, a.high);
        await _db
            .into(_db.labValues)
            .insert(
              LabValuesCompanion.insert(
                id: 'lab_${recId}_${a.name.hashCode.toUnsigned(16)}',
                recordId: recId,
                analyte: a.name,
                value: value,
                unit: Value(a.unit),
                refLow: Value(a.low),
                refHigh: Value(a.high),
                abnormalFlag: Value(flag),
              ),
            );
      }
    }

    return records;
  }

  // --- correlation helpers ---------------------------------------------

  double _noShowProbability(_Patient p, {required int leadDays}) {
    // Base tendency + longer lead time + a small age effect. Monotonic and
    // learnable — mirrors tools/ml/generate_dataset.py::hidden_probability.
    var x = p.noShowTendency;
    x += (leadDays.clamp(0, 45) / 45) * 0.35;
    if (p.age < 25) x += 0.06;
    if (p.conditions.isNotEmpty) x -= 0.05;
    return x.clamp(0.02, 0.92);
  }

  AppointmentStatus _appointmentStatus(
    _Patient p, {
    required bool isFuture,
    required int leadDays,
  }) {
    if (isFuture) {
      return leadDays < 7 && _rng.nextDouble() < 0.5
          ? AppointmentStatus.confirmed
          : AppointmentStatus.booked;
    }
    final pNoShow = _noShowProbability(p, leadDays: 10);
    final r = _rng.nextDouble();
    if (r < pNoShow * 0.85) return AppointmentStatus.noShow;
    if (r < pNoShow * 0.85 + 0.05) return AppointmentStatus.cancelled;
    return AppointmentStatus.completed;
  }

  int _vital(
    int base,
    _Patient p,
    String metric,
    double progress, {
    required int spread,
    required int drift,
  }) {
    var v = base + _rng.nextInt(spread * 2) - spread;
    if (p.conditions.any((c) => c.raises.contains(metric))) {
      v += (drift * (0.4 + progress)).round();
    }
    return v;
  }

  double _vitalD(
    double base,
    _Patient p,
    String metric,
    double progress, {
    required double spread,
    required double drift,
  }) {
    var v = base + (_rng.nextDouble() - 0.5) * spread * 2;
    if (p.conditions.any((c) => c.raises.contains(metric))) {
      v += drift * (0.4 + progress);
    }
    return double.parse(v.toStringAsFixed(1));
  }

  AbnormalFlag _classify(double v, double low, double high) {
    if (v < low) {
      return v < low * 0.75 ? AbnormalFlag.critical : AbnormalFlag.low;
    }
    if (v > high) {
      return v > high * 1.5 ? AbnormalFlag.critical : AbnormalFlag.high;
    }
    return AbnormalFlag.normal;
  }

  RiskBand _band(double p) =>
      p > 0.66 ? RiskBand.high : (p >= 0.33 ? RiskBand.medium : RiskBand.low);

  int _monthsSinceStart(DateTime d) =>
      (d.year - _historyStart.year) * 12 + d.month - _historyStart.month;

  // --- primitives ------------------------------------------------------

  Future<void> _insertUser({
    required String id,
    required UserRole role,
    required String fullName,
    required String email,
    required bool male,
    DateTime? dob,
    String? nationalId,
  }) async {
    final salt = List<int>.generate(16, (_) => _rng.nextInt(256));
    final pw = _hasher.hashNew(demoPassword, salt: salt);
    await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            id: id,
            role: role,
            fullName: fullName,
            email: email.toLowerCase(),
            passwordHash: pw.hash,
            passwordSalt: pw.salt,
            phone: Value('+973 3${_digits(7)}'),
            dob: Value(dob),
            gender: Value(male ? Gender.male : Gender.female),
            nationalId: Value(nationalId),
            createdAt: Value(_historyStart),
          ),
        );
  }

  String _fullName({required bool male}) {
    final arabic = _rng.nextDouble() < 0.75;
    final first = arabic
        ? _pick(male ? arabicMaleFirst : arabicFemaleFirst)
        : _pick(male ? englishMaleFirst : englishFemaleFirst);
    return '$first ${_pick(familyNames)}';
  }

  T _pick<T>(List<T> xs) => xs[_rng.nextInt(xs.length)];

  List<T> _sample<T>(List<T> xs, int n) {
    final copy = [...xs]..shuffle(_rng);
    return copy.take(n.clamp(0, xs.length)).toList();
  }

  int _weighted(List<double> weights) {
    final r = _rng.nextDouble();
    var acc = 0.0;
    for (var i = 0; i < weights.length; i++) {
      acc += weights[i];
      if (r < acc) return i;
    }
    return weights.length - 1;
  }

  String _digits(int n) => List.generate(n, (_) => _rng.nextInt(10)).join();

  // --- teardown ------------------------------------------------------

  Future<int> _currentSeedVersion() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    return row?.seedVersion ?? 0;
  }

  Future<void> _setSeedVersion(int v) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1),
            seedVersion: Value(v),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _wipe() async {
    // Children first; app_settings kept (holds seedVersion).
    final tables = <TableInfo<Table, Object?>>[
      _db.labValues,
      _db.reminders,
      _db.riskFlags,
      _db.staffTasks,
      _db.aiSummaries,
      _db.vitals,
      _db.medications,
      _db.medicalRecords,
      _db.appointments,
      _db.scheduleTemplates,
      _db.auditLog,
      _db.patientProfiles,
      _db.staffProfiles,
      _db.users,
      _db.departments,
    ];
    for (final t in tables) {
      await _db.delete(t).go();
    }
  }

  static const _bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  static const _allergens = [
    'Penicillin',
    'Peanuts',
    'Aspirin',
    'Latex',
    'Sulfa drugs',
    'Shellfish',
  ];
}

class _Staff {
  const _Staff(this.id, this.departmentId);
  final String id;
  final String departmentId;
}

class _Patient {
  _Patient({
    required this.id,
    required this.age,
    required this.conditions,
    required this.noShowTendency,
  });
  final String id;
  final int age;
  final List<ConditionSeed> conditions;
  final double noShowTendency;

  bool hasCondition(String name) => conditions.any((c) => c.name == name);
}
