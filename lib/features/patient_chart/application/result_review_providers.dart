/// Result reviews for the signed-in clinician (Phase 4): the queue they own
/// or cover, one result's review, and the actions that move it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';
import 'chart_providers.dart';

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

/// Open reviews the signed-in clinician owns or covers, most urgent first.
/// A failed read is an error — never an empty, all-clear queue.
final myResultReviewsProvider = FutureProvider<List<ResultReview>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isStaff) return const [];
  return _unwrap(
    await ref.watch(resultReviewRepositoryProvider).queueFor(user.id),
  );
});

/// The review attached to one result record, if it needed one.
final recordReviewProvider = FutureProvider.family<ResultReview?, String>((
  ref,
  recordId,
) async {
  return _unwrap(
    await ref.watch(resultReviewRepositoryProvider).forRecord(recordId),
  );
});

/// One record, read through the repository's access checks.
final chartRecordProvider = FutureProvider.family<MedicalRecord, String>((
  ref,
  recordId,
) async {
  return _unwrap(await ref.watch(recordRepositoryProvider).byId(recordId));
});

class ResultReviewActions {
  ResultReviewActions(this._ref);
  final Ref _ref;

  String get _me => _ref.read(currentUserProvider)!.id;

  void _refresh(ResultReview review) {
    _ref
      ..invalidate(myResultReviewsProvider)
      ..invalidate(recordReviewProvider(review.recordId))
      ..invalidate(chartRecordProvider(review.recordId))
      ..invalidate(chartTimelinePageProvider(review.patientId));
  }

  Future<Result<ResultReview>> start(ResultReview review) async {
    final r = await _ref
        .read(resultReviewRepositoryProvider)
        .startReview(
          id: review.id,
          staffId: _me,
          expectedVersion: review.version,
        );
    _refresh(review);
    return r;
  }

  Future<Result<ResultReview>> resolve(ResultReview review, String note) async {
    final r = await _ref
        .read(resultReviewRepositoryProvider)
        .resolve(
          id: review.id,
          staffId: _me,
          note: note,
          expectedVersion: review.version,
        );
    _refresh(review);
    return r;
  }

  Future<Result<ResultReview>> escalate(
    ResultReview review, {
    required String toStaffId,
    required String note,
  }) async {
    final r = await _ref
        .read(resultReviewRepositoryProvider)
        .escalate(
          id: review.id,
          staffId: _me,
          coverageStaffId: toStaffId,
          note: note,
          expectedVersion: review.version,
        );
    _refresh(review);
    return r;
  }
}

/// A clinician accepts or rejects a patient-imported record.
Future<Result<MedicalRecord>> reviewImport(
  WidgetRef ref,
  MedicalRecord record, {
  required ImportReviewStatus decision,
  String? note,
}) async {
  final r = await ref
      .read(recordRepositoryProvider)
      .reviewImport(
        recordId: record.id,
        staffId: ref.read(currentUserProvider)!.id,
        decision: decision,
        note: note,
      );
  ref
    ..invalidate(chartRecordProvider(record.id))
    ..invalidate(chartTimelinePageProvider(record.patientId));
  return r;
}

final resultReviewActionsProvider = Provider<ResultReviewActions>(
  ResultReviewActions.new,
);
