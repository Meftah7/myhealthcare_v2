/// A piece of user feedback / an issue report (ported from the
/// FirstSemMyHealth `feedback_reports` table + admin "Reports" view).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'feedback.freezed.dart';

@freezed
abstract class UserFeedback with _$UserFeedback {
  const factory UserFeedback({
    required String id,
    required FeedbackCategory category,
    required String message,
    required FeedbackStatus status,
    required DateTime createdAt,

    /// Null for an anonymous / signed-out report.
    String? reporterId,
    String? reporterName,
    String? reporterEmail,

    /// The admin who marked it resolved.
    String? handledByAdminId,
    DateTime? handledAt,
  }) = _UserFeedback;

  const UserFeedback._();

  bool get isOpen => status == FeedbackStatus.open;
}
