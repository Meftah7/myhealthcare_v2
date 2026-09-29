/// Typed feedback for reads and mutations (Phase 6).
///
/// One place turns a [Failure] into what the person should read and the one
/// recovery action that can help:
///
/// | Failure                  | Says                              | Action        |
/// |--------------------------|-----------------------------------|---------------|
/// | access denied            | the boundary                      | none          |
/// | session expired          | sign in again                     | Sign in       |
/// | re-authentication needed | confirm your password             | none (prompt) |
/// | conflict                 | someone changed it first          | Reload        |
/// | payment pending          | not confirmed, not charged twice  | Check status  |
/// | offline / network        | could not reach                   | Try again     |
/// | validation, not found,   | the repository's specific message | none          |
/// | declined, file           |                                   |               |
/// | anything else            | generic, localized                | Try again     |
///
/// Screens call [showMutationFeedback] after a write and [AsyncDataView] (in
/// `data_state_view.dart`) for a read, instead of printing
/// `failure.message` with a hand-picked action.
library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../di.dart';
import '../failures.dart';
import '../observability/operational_metrics.dart';
import '../result.dart';

/// The app's metrics sink, or null outside a provider scope (isolated
/// widget tests).
OperationalMetrics? operationalMetricsOf(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(operationalMetricsProvider);
  } on Object {
    return null;
  }
}

/// A pending payment is an uncertain outcome, not a failed save. The reason
/// is the recovery action only — never the failure message.
void _recordMutationFailure(BuildContext context, RecoveryAction action) {
  final metrics = operationalMetricsOf(context);
  if (metrics == null) return;
  recordSafely(
    metrics,
    action == RecoveryAction.checkStatus
        ? OperationalSignal.reconciliationPending
        : OperationalSignal.saveFailed,
    workflow: 'mutation',
    reasonCode: action.name.toLowerCase(),
  );
}

enum RecoveryAction { none, retry, reload, signIn, checkStatus }

/// What to tell the person about [error], and what they can do next.
@immutable
class FailureFeedback {
  const FailureFeedback(this.message, this.action);
  final String message;
  final RecoveryAction action;
}

FailureFeedback describeFailure(AppLocalizations t, Object error) {
  return switch (error) {
    AccessDeniedFailure() => FailureFeedback(
      t.accessDeniedBody,
      RecoveryAction.none,
    ),
    SessionExpiredFailure() => FailureFeedback(
      t.feedbackSessionExpired,
      RecoveryAction.signIn,
    ),
    ReauthRequiredFailure() => FailureFeedback(
      t.feedbackReauthRequired,
      RecoveryAction.none,
    ),
    ConflictFailure() => FailureFeedback(
      t.feedbackConflict,
      RecoveryAction.reload,
    ),
    PaymentPendingFailure() => FailureFeedback(
      t.paymentStillConfirming,
      RecoveryAction.checkStatus,
    ),
    NetworkFailure() => FailureFeedback(
      t.feedbackOffline,
      RecoveryAction.retry,
    ),
    // Specific, actionable messages written by the repository.
    ValidationFailure(:final message) ||
    NotFoundFailure(:final message) ||
    PaymentDeclinedFailure(:final message) ||
    FileFailure(
      :final message,
    ) => FailureFeedback(message, RecoveryAction.none),
    // Every typed failure message is sanitised at the repository boundary.
    // Keep that useful detail while still assigning recovery consistently.
    Failure(:final message) => FailureFeedback(message, RecoveryAction.retry),
    _ => FailureFeedback(t.feedbackUnexpected, RecoveryAction.retry),
  };
}

String recoveryLabel(AppLocalizations t, RecoveryAction action) =>
    switch (action) {
      RecoveryAction.retry => t.tryAgain,
      RecoveryAction.reload => t.reloadAction,
      RecoveryAction.signIn => t.signInAgainAction,
      RecoveryAction.checkStatus => t.checkPaymentStatusAction,
      RecoveryAction.none => '',
    };

/// Shows the outcome of a write: [success] on Ok (nothing if null), or the
/// failure's message with its recovery action wired to the matching
/// callback. An action with no callback is left out rather than offered and
/// ignored.
void showMutationFeedback(
  BuildContext context,
  Result<Object?> result, {
  String? success,
  VoidCallback? onRetry,
  VoidCallback? onReload,
  VoidCallback? onSignIn,
  VoidCallback? onCheckStatus,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final t = AppLocalizations.of(context)!;
  switch (result) {
    case Ok():
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    case Err(:final failure):
      final feedback = describeFailure(t, failure);
      _recordMutationFailure(context, feedback.action);
      final callback = switch (feedback.action) {
        RecoveryAction.retry => onRetry,
        RecoveryAction.reload => onReload,
        RecoveryAction.signIn => onSignIn,
        RecoveryAction.checkStatus => onCheckStatus,
        RecoveryAction.none => null,
      };
      messenger.showSnackBar(
        SnackBar(
          content: Text(feedback.message),
          action: callback == null
              ? null
              : SnackBarAction(
                  label: recoveryLabel(t, feedback.action),
                  onPressed: callback,
                ),
        ),
      );
  }
}
