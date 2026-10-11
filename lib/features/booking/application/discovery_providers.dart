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
