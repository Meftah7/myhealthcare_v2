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

enum RecordsView { all, results, documents, uploads }

class RecordsFilter {
  const RecordsFilter({
    this.query = '',
    this.types = const {},
    this.view = RecordsView.all,
    this.from,
    this.to,
    this.facility,
    this.authorId,
    this.review,
    this.unreadOnly = false,
  });
  final String query;
  final Set<RecordType> types;
  final RecordsView view;
  final DateTime? from, to;
  final String? facility, authorId;
  final ImportReviewStatus? review;
  final bool unreadOnly;
  bool get hasAdvanced =>
      from != null ||
      to != null ||
      facility != null ||
      authorId != null ||
      review != null ||
      unreadOnly;
  bool get includesVitals =>
      query.trim().isEmpty &&
      types.isEmpty &&
      !hasAdvanced &&
      view == RecordsView.all;

  RecordsFilter copyWith({
    String? query,
    Set<RecordType>? types,
    RecordsView? view,
    DateTime? from,
    DateTime? to,
    String? facility,
    String? authorId,
    ImportReviewStatus? review,
    bool? unreadOnly,
    bool clearDates = false,
    bool clearFacility = false,
    bool clearAuthor = false,
    bool clearReview = false,
  }) => RecordsFilter(
    query: query ?? this.query,
    types: types ?? this.types,
    view: view ?? this.view,
    from: clearDates ? null : from ?? this.from,
    to: clearDates ? null : to ?? this.to,
    facility: clearFacility ? null : facility ?? this.facility,
    authorId: clearAuthor ? null : authorId ?? this.authorId,
    review: clearReview ? null : review ?? this.review,
    unreadOnly: unreadOnly ?? this.unreadOnly,
  );

  bool matches(MedicalRecord r, Set<String> readIds, {String? authorName}) {
    if (types.isNotEmpty && !types.contains(r.recordType)) return false;
    if (from != null && r.occurredAt.isBefore(from!)) return false;
    if (to != null &&
        !r.occurredAt.isBefore(DateTime(to!.year, to!.month, to!.day + 1))) {
      return false;
    }
    if (facility != null && r.sourceFacility != facility) return false;
    if (authorId != null && r.authorStaffId != authorId) return false;
    if (review != null && r.reviewStatus != review) return false;
    if (unreadOnly && readIds.contains(r.id)) return false;
    if (!switch (view) {
      RecordsView.all => true,
      RecordsView.results =>
        r.recordType == RecordType.labResult ||
            r.recordType == RecordType.imaging,
      RecordsView.documents =>
        r.hasAttachment ||
            r.recordType == RecordType.discharge ||
            r.recordType == RecordType.referral,
      RecordsView.uploads => r.uploadedByPatient,
    }) {
      return false;
    }
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
}

final recordFiltersProvider = StateProvider.family<RecordsFilter, String>((
  ref,
  id,
) {
  ref.watch(currentUserProvider);
  return const RecordsFilter();
});
