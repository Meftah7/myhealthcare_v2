/// Appointment + patient history → the 11-feature no-show vector (P4-08).
///
/// The encoding here MUST match tools/ml/features.py exactly — the parity test
/// (P4-11) asserts Python and Dart agree within 1e-6.
library;

import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';

/// Feature order — the column order of the exported model JSON.
const noShowFeatureNames = [
  'lead_time_days',
  'prior_no_show_rate',
  'prior_appointment_count',
  'age_years',
  'visit_type_urgent',
  'visit_type_routine',
  'day_of_week',
  'hour_of_day',
  'is_first_visit',
  'has_chronic_condition',
  'reminders_acknowledged',
];

const _clamp = <String, (double, double)>{
  'lead_time_days': (0, 60),
  'prior_no_show_rate': (0, 1),
  'prior_appointment_count': (0, 40),
  'age_years': (0, 100),
  'day_of_week': (1, 7),
  'hour_of_day': (0, 23),
  'reminders_acknowledged': (0, 3),
};

class NoShowFeatureInput {
  const NoShowFeatureInput({
    required this.leadTimeDays,
    required this.priorNoShowRate,
    required this.priorAppointmentCount,
    required this.ageYears,
    required this.visitType,
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.hasChronicCondition,
    required this.remindersAcknowledged,
  });

  final double leadTimeDays;
  final double priorNoShowRate;
  final int priorAppointmentCount;
  final int ageYears;
  final VisitType visitType;
  final int dayOfWeek; // 1 = Monday … 7 = Sunday
  final int hourOfDay;
  final bool hasChronicCondition;
  final int remindersAcknowledged;

  List<double> toVector() {
    final firstVisit = priorAppointmentCount == 0 ? 1.0 : 0.0;
    final raw = <String, double>{
      'lead_time_days': leadTimeDays,
      'prior_no_show_rate': priorNoShowRate,
      'prior_appointment_count': priorAppointmentCount.toDouble(),
      'age_years': ageYears.toDouble(),
      'visit_type_urgent': visitType == VisitType.urgentCare ? 1.0 : 0.0,
      'visit_type_routine':
          (visitType == VisitType.routineCheckup ||
              visitType == VisitType.chronicCareReview)
          ? 1.0
          : 0.0,
      'day_of_week': dayOfWeek.toDouble(),
      'hour_of_day': hourOfDay.toDouble(),
      'is_first_visit': firstVisit,
      'has_chronic_condition': hasChronicCondition ? 1.0 : 0.0,
      'reminders_acknowledged': remindersAcknowledged.toDouble(),
    };
    return [
      for (final name in noShowFeatureNames) _applyClamp(name, raw[name]!),
    ];
  }

  static double _applyClamp(String name, double v) {
    final range = _clamp[name];
    if (range == null) return v;
    return v.clamp(range.$1, range.$2);
  }
}

/// Builds the feature input for [appointment] from the patient's prior history.
NoShowFeatureInput buildNoShowFeatures({
  required Appointment appointment,
  required Patient patient,
  required List<Appointment> patientHistory,
}) {
  final priorResolved = patientHistory.where(
    (a) =>
        a.id != appointment.id &&
        a.slotStart.isBefore(appointment.slotStart) &&
        (a.status == AppointmentStatus.completed ||
            a.status == AppointmentStatus.noShow ||
            a.status == AppointmentStatus.cancelled),
  );
  final priorCount = priorResolved.length;
  final priorNoShow = priorResolved
      .where((a) => a.status == AppointmentStatus.noShow)
      .length;

  return NoShowFeatureInput(
    leadTimeDays:
        appointment.slotStart
            .difference(appointment.bookedAt)
            .inHours
            .toDouble() /
        24.0,
    priorNoShowRate: priorCount == 0 ? 0.0 : priorNoShow / priorCount,
    priorAppointmentCount: priorCount,
    ageYears: patient.user.ageYears ?? 40,
    visitType: appointment.visitType,
    dayOfWeek: appointment.slotStart.weekday,
    hourOfDay: appointment.slotStart.hour,
    hasChronicCondition: patient.hasChronicCondition,
    remindersAcknowledged: appointment.remindersSent.clamp(0, 3),
  );
}
