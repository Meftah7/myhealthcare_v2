/// Result review contract (Phase 4): abnormal, critical and unjudgeable
/// results are owned work with a due time, not rows in a chart.
library;

import '../../core/result.dart';
import '../entities/entities.dart';

abstract interface class ResultReviewRepository {
  /// The review for one result record, if it needed one.
  Future<Result<ResultReview?>> forRecord(String recordId);

  /// Open reviews [staffId] owns or covers, most urgent and earliest due
  /// first.
  Future<Result<List<ResultReview>>> queueFor(String staffId);

  /// Every open review (administrator oversight), optionally only those past
  /// due or without an owner.
  Future<Result<List<ResultReview>>> openReviews({bool needsAttentionOnly});

  /// Give the review to [ownerStaffId] — a first assignment or a handover.
  /// The owner can change but never be cleared. Done by an administrator, or
  /// by the current owner handing over (with a [note]).
  Future<Result<ResultReview>> assign({
    required String id,
    required String ownerStaffId,
    String? note,
    int? expectedVersion,
  });

  /// The owner or cover starts reviewing.
  Future<Result<ResultReview>> startReview({
    required String id,
    required String staffId,
    int? expectedVersion,
  });

  /// Pass to a covering clinician who must act now. [note] says why.
  Future<Result<ResultReview>> escalate({
    required String id,
    required String staffId,
    required String coverageStaffId,
    required String note,
    int? expectedVersion,
  });

  /// Close the review with a documented outcome; the result's values are
  /// marked verified by [staffId].
  Future<Result<ResultReview>> resolve({
    required String id,
    required String staffId,
    required String note,
    int? expectedVersion,
  });
}
