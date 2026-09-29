/// Typed failures (task P0-08).
///
/// No raw exceptions cross a layer boundary — data/service code catches and
/// returns `Result<T>` (result.dart) carrying one of these. `message` is safe
/// to surface to a user; `cause`/`stackTrace` are for logs only.
library;

import 'package:flutter/foundation.dart';

@immutable
sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// User-facing, already sanitised.
  final String message;

  /// Original error, if any — for logging, never for display.
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

/// Local database read/write error (Drift/SQLite).
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause, super.stackTrace});
}

/// Network transport error talking to the AI API (timeout, offline, 5xx).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

/// Authentication / authorisation error (bad credentials, expired or missing
/// session, wrong role).
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause, super.stackTrace});
}

/// The authenticated principal is not allowed to perform this action on this
/// object (wrong patient, wrong clinician, missing permission, revoked proxy).
/// Kept an [AuthFailure] so existing callers that match on it still work.
class AccessDeniedFailure extends AuthFailure {
  const AccessDeniedFailure([
    super.message = 'You do not have access to this.',
  ]);
}

/// There is no signed-in session, or it has expired. The UI should return to
/// sign-in rather than retry.
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure([
    super.message = 'Your session has ended. Please sign in again.',
  ]);
}

/// A sensitive action needs the password re-entered first.
class ReauthRequiredFailure extends AuthFailure {
  const ReauthRequiredFailure([
    super.message = 'Please confirm your password to continue.',
  ]);
}

/// Someone else changed the object first: the caller's copy is stale. Carries
/// the version now stored so the UI can reload, show both, and let the user
/// decide — never silently overwrite.
class ConflictFailure extends Failure {
  const ConflictFailure(
    super.message, {
    this.currentVersion,
    super.cause,
    super.stackTrace,
  });

  final int? currentVersion;
}

/// The authoritative store can't be reached right now (no connection, or the
/// local store is unavailable). Data shown alongside it is stale, not empty.
class OfflineFailure extends NetworkFailure {
  const OfflineFailure([
    super.message = 'You appear to be offline. Showing the last saved data.',
  ]);
}

/// The payment was sent but its outcome is not known yet (the provider was
/// unreachable or its answer was lost). The invoice is *not* paid and must
/// not be shown as paid; reconciliation settles it or releases it. Retrying
/// with the same idempotency key is safe — it can never charge twice.
class PaymentPendingFailure extends Failure {
  const PaymentPendingFailure([
    super.message =
        'We could not confirm this payment yet. You have not been charged '
        'twice — we will check with the payment provider and update the bill.',
  ]) : transactionId = null;

  const PaymentPendingFailure.forTransaction(
    String this.transactionId, [
    super.message =
        'We could not confirm this payment yet. You have not been charged '
        'twice — we will check with the payment provider and update the bill.',
  ]);

  final String? transactionId;
}

/// The payment provider refused the payment. Nothing was charged.
class PaymentDeclinedFailure extends Failure {
  const PaymentDeclinedFailure(super.message, {this.code});

  /// Provider decline code, for support — never shown raw.
  final String? code;
}

/// A requested entity does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause, super.stackTrace});
}

/// Invalid user input (form validation, out-of-range values).
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  });

  /// Optional per-field messages, keyed by field name.
  final Map<String, String> fieldErrors;
}

/// AI layer failure — malformed response, unparseable JSON, model unavailable.
/// Callers degrade to [MockAiService] rather than surfacing this (P3-05).
class AiFailure extends Failure {
  const AiFailure(super.message, {super.cause, super.stackTrace});
}

/// File import / PDF extraction error (P2-11, P2-12).
class FileFailure extends Failure {
  const FileFailure(super.message, {super.cause, super.stackTrace});
}

/// Anything not covered above. Prefer a specific failure where possible.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});

  factory UnexpectedFailure.from(Object error, [StackTrace? stackTrace]) {
    return UnexpectedFailure(
      'Something went wrong. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
