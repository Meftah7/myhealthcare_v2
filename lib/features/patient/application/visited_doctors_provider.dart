/// "Visited doctors" (P10-04): the patient's care team, derived from their
/// appointment history — one entry per doctor they have actually seen, with a
/// visit count, the last visit date and any upcoming appointment.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import 'patient_data_providers.dart';

class VisitedDoctor {
  const VisitedDoctor({
    required this.staffId,
    required this.name,
    required this.departmentName,
    required this.visitCount,
    required this.lastVisit,
    required this.nextVisit,
  });

  final String staffId;
  final String name;
  final String? departmentName;
  final int visitCount;
  final DateTime lastVisit;
  final DateTime? nextVisit;

  bool get hasUpcoming => nextVisit != null;
}

/// A visit "counts" once it has happened — completed, or simply a past slot
/// that wasn't cancelled. No-shows still mean the patient has met the doctor.
bool _isVisited(Appointment a) {
  if (a.status == AppointmentStatus.cancelled) return false;
  return a.status == AppointmentStatus.completed ||
      a.status == AppointmentStatus.noShow ||
      a.slotEnd.isBefore(DateTime.now());
}

final visitedDoctorsProvider = FutureProvider<List<VisitedDoctor>>((ref) async {
  final appts = await ref.watch(patientAppointmentsProvider.future);
  final doctors = await ref.watch(doctorDirectoryProvider.future);
  final departments = await ref.watch(departmentDirectoryProvider.future);

  final byDoctor = <String, List<Appointment>>{};
  for (final a in appts) {
    (byDoctor[a.staffId] ??= []).add(a);
  }

  final out = <VisitedDoctor>[];
  for (final entry in byDoctor.entries) {
    final visits = entry.value.where(_isVisited).toList()
      ..sort((a, b) => b.slotStart.compareTo(a.slotStart));
    if (visits.isEmpty) continue;

    final upcoming = entry.value.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

    final dir = doctors[entry.key];
    final deptId = dir?.departmentId ?? visits.first.departmentId;

    out.add(
      VisitedDoctor(
        staffId: entry.key,
        name: dir?.name ?? 'Your doctor',
        departmentName: deptId == null ? null : departments[deptId],
        visitCount: visits.length,
        lastVisit: visits.first.slotStart,
        nextVisit: upcoming.firstOrNull?.slotStart,
      ),
    );
  }

  out.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
  return out;
});
