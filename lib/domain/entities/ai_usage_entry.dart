/// One row of the AI usage log (ported from the FirstSemMyHealth `ai_logs`
/// table + admin "AI Logs" view). Written every time an AI surface answers,
/// so an admin can see how the assistant is being used and whether the live
/// model or the offline fallback served the request.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'ai_usage_entry.freezed.dart';

@freezed
abstract class AiUsageEntry with _$AiUsageEntry {
  const factory AiUsageEntry({
    required String id,
    required AiFeature feature,
    required DateTime at,

    /// True when a live model produced the answer; false for the deterministic
    /// offline fallback.
    required bool usedLiveModel,

    String? userId,

    /// A one-line note — the prompt gist or the outcome.
    String? summary,
  }) = _AiUsageEntry;
}
