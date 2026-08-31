// No-show feature extraction + predictor behaviour (P6-01).

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/services/ml/feature_extractor.dart';

Appointment _appt({
  required String id,
  required DateTime start,
  DateTime? bookedAt,
  AppointmentStatus status = AppointmentStatus.booked,
}) => Appointment(
  id: id,
  patientId: 'p1',
  staffId: 's1',
  slotStart: start,
  slotEnd: start.add(const Duration(minutes: 20)),
  visitType: VisitType.followUp,
  status: status,
  bookedAt: bookedAt ?? start.subtract(const Duration(days: 7)),
  remindersSent: 0,
);

Patient _patient({int? age, List<String> chronic = const []}) => Patient(
  user: User(
    id: 'p1',
    role: UserRole.patient,
    fullName: 'P',
    email: 'p@e.com',
    isActive: true,
    createdAt: DateTime(2020),
    dob: age == null ? null : DateTime(DateTime.now().year - age),
  ),
  chronicConditions: chronic,
);

void main() {
  final target = _appt(
    id: 'target',
    start: DateTime(2026, 6, 15, 10),
    bookedAt: DateTime(2026, 6, 1, 10),
  );
  const names = noShowFeatureNames;

  test('lead time is the booking-to-slot gap in days', () {
    final f = buildNoShowFeatures(
      appointment: target,
      patient: _patient(age: 40),
      patientHistory: const [],
    );
    expect(f.leadTimeDays, closeTo(14, 0.01));
  });

  test('prior no-show rate counts only resolved earlier appointments', () {
    final history = [
      _appt(
        id: 'a',
        start: DateTime(2026),
        status: AppointmentStatus.completed,
      ),
      _appt(
        id: 'b',
        start: DateTime(2026, 2),
        status: AppointmentStatus.noShow,
      ),
      _appt(
        id: 'c',
        start: DateTime(2026, 3),
        status: AppointmentStatus.cancelled,
      ),
      _appt(id: 'd', start: DateTime(2026, 12)), // unresolved — ignored
    ];
    final f = buildNoShowFeatures(
      appointment: target,
      patient: _patient(age: 40),
      patientHistory: history,
    );
    expect(f.priorAppointmentCount, 3);
    expect(f.priorNoShowRate, closeTo(1 / 3, 1e-9));
  });

  test('first visit flag and chronic flag propagate into the vector', () {
    final f = buildNoShowFeatures(
      appointment: target,
      patient: _patient(age: 55, chronic: const ['Hypertension']),
      patientHistory: const [],
    );
    final v = f.toVector();
    expect(v[names.indexOf('is_first_visit')], 1.0);
    expect(v[names.indexOf('has_chronic_condition')], 1.0);
    expect(v[names.indexOf('age_years')], 55.0);
  });

  test('vector values are clamped to the training ranges', () {
    final far = _appt(
      id: 't2',
      start: DateTime(2027),
      bookedAt: DateTime(2024), // ~3 years lead
    );
    final f = buildNoShowFeatures(
      appointment: far,
      patient: _patient(age: 200),
      patientHistory: const [],
    );
    final v = f.toVector();
    expect(v[names.indexOf('lead_time_days')], 60.0);
    expect(v[names.indexOf('age_years')], 100.0);
  });

  test('missing DOB falls back to age 40', () {
    final f = buildNoShowFeatures(
      appointment: target,
      patient: _patient(),
      patientHistory: const [],
    );
    expect(f.ageYears, 40);
  });
}
