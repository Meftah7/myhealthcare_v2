import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/record_activity_repository.dart';
import '../../auth/application/session.dart';
import '../../patient/application/family_link_providers.dart';
import '../../patient/application/patient_data_providers.dart';

T recordValue<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final selectedRecordsPatientProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});
final recordsPatientIdProvider = Provider<String>(
  (ref) =>
      ref.watch(selectedRecordsPatientProvider) ??
      ref.watch(currentUserProvider)?.id ??
      '',
);

final recordsProfileProvider = FutureProvider<Patient>((ref) {
  final id = ref.watch(recordsPatientIdProvider);
  return id == ref.watch(currentUserProvider)?.id
      ? ref.watch(patientProfileProvider.future)
      : ref.watch(linkedPatientProvider(id).future);
});
final recordsCanManageProvider = FutureProvider<bool>((ref) async {
  final id = ref.watch(recordsPatientIdProvider);
  if (id == ref.watch(currentUserProvider)?.id) return true;
  if (id.isEmpty) return false;
  return await ref.watch(linkedPermissionProvider(id).future) ==
      FamilyLinkPermission.manage;
});

final recordsHistoryProvider = FutureProvider<List<MedicalRecord>>((ref) async {
  final id = ref.watch(recordsPatientIdProvider);
  if (ref.watch(selectedRecordsPatientProvider) == null) {
    return ref.watch(patientRecordHistoryProvider.future);
  }
  final repo = ref.watch(recordRepositoryProvider);
  var page = await ref.watch(linkedTimelinePageProvider(id).future);
  final all = [...page.items];
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  while (page.hasMore) {
    if (cancelled) throw StateError('Record history request cancelled');
    page = recordValue(
      await repo.timelinePage(
        id,
        page: PageRequest(offset: all.length, size: PageLimits.maxSize),
      ),
    );
    all.addAll(page.items);
  }
  return all;
});
final recordsVisitDatesProvider =
    FutureProvider.autoDispose<Map<String, DateTime>>((ref) async {
      final patientId = ref.watch(recordsPatientIdProvider);
      if (patientId.isEmpty) return {};
      final appointments = ref.watch(selectedRecordsPatientProvider) == null
          ? await ref.watch(patientAppointmentsProvider.future)
          : recordValue(
              await ref
                  .watch(appointmentRepositoryProvider)
                  .forPatient(patientId),
            );
      return {
        for (final a in appointments)
          if (a.patientId == patientId) a.id: a.slotStart,
      };
    });

final recordsVitalsProvider = FutureProvider<List<Vitals>>(
  (ref) => ref.watch(selectedRecordsPatientProvider) == null
      ? ref.watch(patientVitalsProvider.future)
      : ref.watch(
          linkedVitalsProvider(ref.watch(recordsPatientIdProvider)).future,
        ),
);
final recordsMedicationsProvider = FutureProvider<List<Medication>>(
  (ref) => ref.watch(selectedRecordsPatientProvider) == null
      ? ref.watch(patientMedicationsProvider.future)
      : ref.watch(
          linkedMedicationsProvider(ref.watch(recordsPatientIdProvider)).future,
        ),
);

final recordReadIdsProvider = FutureProvider<Set<String>>((ref) async {
  final id = ref.watch(recordsPatientIdProvider);
  if (id.isEmpty) return {};
  return ref.watch(recordPatientReadIdsProvider(id).future);
});
final recordPatientReadIdsProvider = FutureProvider.family<Set<String>, String>(
  (ref, id) async => recordValue(
    await ref.watch(recordActivityRepositoryProvider).readIds(id),
  ),
);
final recordCanCorrectProvider = FutureProvider.family<bool, String>((
  ref,
  id,
) async {
  if (id == ref.watch(currentUserProvider)?.id) return true;
  return await ref.watch(linkedPermissionProvider(id).future) ==
      FamilyLinkPermission.manage;
});
final recordCorrectionsProvider =
    FutureProvider.family<List<RecordCorrection>, String>(
      (ref, id) async => recordValue(
        await ref.watch(recordActivityRepositoryProvider).corrections(id),
      ),
    );

class RecordsFilter {
  const RecordsFilter({this.query = '', this.oldestFirst = false});

  final String query;
  final bool oldestFirst;
  bool get includesVitals => query.trim().isEmpty;

  bool matches(MedicalRecord r, {String? authorName}) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        [
          r.title,
          ?r.body,
          ?r.extractedText,
          ?r.sourceFacility,
          ?authorName,
          for (final lab in r.labValues) lab.analyte,
        ].any((v) => v.toLowerCase().contains(q));
  }

  int compareDates(DateTime a, DateTime b) =>
      oldestFirst ? a.compareTo(b) : b.compareTo(a);
}

final recordFiltersProvider = StateProvider.family<RecordsFilter, String>((
  ref,
  id,
) {
  ref.watch(currentUserProvider);
  return const RecordsFilter();
});
