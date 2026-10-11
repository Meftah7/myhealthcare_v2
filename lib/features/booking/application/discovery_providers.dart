/// Public care discovery: the published clinician directory and the clinic's
/// departments. Neither needs a patient session, so guests can browse them;
/// every discovery path converges on the one existing booking wizard.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/appointment_repository.dart';

/// Every bookable clinician (nurses excluded — they work the nursing list).
final publicDoctorsProvider = FutureProvider<List<Staff>>((ref) async {
  final result = await ref.watch(userRepositoryProvider).allStaff();
  return switch (result) {
    Ok(:final value) => value.where((s) => s.isDoctor).toList(),
    Err(:final failure) => throw failure,
  };
});

/// Opens the existing booking wizard pre-filled with the chosen department
/// and/or clinician; the wizard loads fresh availability for the patient.
void continueToBooking(
  BuildContext context,
  WidgetRef ref, {
  String? departmentId,
  String? staffId,
}) {
  final query = {'dept': ?departmentId, 'staff': ?staffId};
  final route = Uri(
    path: AppRoutes.patientBook,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
  unawaited(context.push(route));
}

/// One bounded availability look-ahead for every listed clinician (a fixed
/// number of queries, see `availabilitySummaries`). Disposed when search
/// closes, so reopening shows fresh numbers. A summary only: the booking
/// wizard reloads and validates the actual slot.
final doctorAvailabilityProvider =
    FutureProvider.autoDispose<Map<String, StaffAvailabilitySummary>>((
      ref,
    ) async {
      final doctors = await ref.watch(publicDoctorsProvider.future);
      final result = await ref
          .watch(appointmentRepositoryProvider)
          .availabilitySummaries([for (final d in doctors) d.id]);
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => throw failure,
      };
    });
