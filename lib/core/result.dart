/// `Result<T>` — an explicit success-or-[Failure] return type (task P0-08).
///
/// Every repository and service method returns this instead of throwing, so
/// callers must deal with the failure path. Pattern-match it:
///
/// ```dart
/// switch (await repo.load()) {
///   case Ok(:final value): show(value);
///   case Err(:final failure): showError(failure.message);
/// }
/// ```
library;

import 'package:flutter/foundation.dart';

import 'failures.dart';

@immutable
sealed class Result<T> {
  const Result();

  /// Run [body], converting any thrown object into an [UnexpectedFailure].
  static Result<T> guard<T>(T Function() body) {
    try {
      return Ok(body());
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      return Err(UnexpectedFailure.from(e, s));
    }
  }

  /// Async form of [guard].
  static Future<Result<T>> guardAsync<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      return Err(UnexpectedFailure.from(e, s));
    }
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Collapse both branches to one value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  /// Transform the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Chain another fallible step.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok(:final value) => transform(value),
    Err(:final failure) => Err(failure),
  };

  T getOrElse(T Function(Failure failure) orElse) => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => orElse(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err($failure)';
}
