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
