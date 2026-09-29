/// What a screen knows about a piece of data — the shared read contract for
/// repositories and controllers (Phase 2).
///
/// The point is that "nothing to show" is only ever [DataReady] with an empty
/// value. A failed, denied, offline or still-loading read is its own state,
/// so it can never render as a reassuring "No appointments" / "All clear" /
/// "0 due".
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../failures.dart';
import 'contracts.dart';

@immutable
sealed class DataState<T> {
  const DataState();

  /// Map a Riverpod [AsyncValue]. [freshness] (when known) marks old data as
  /// [DataStale]; a previous value survives a refresh or a failed reload.
  factory DataState.fromAsync(
    AsyncValue<T> value, {
    Freshness? freshness,
    Duration staleAfter = const Duration(minutes: 2),
  }) {
    final previous = value.hasValue ? value.value : null;
    if (value.hasError) {
      final error = value.error;
      return switch (error) {
        AccessDeniedFailure() ||
        SessionExpiredFailure() => DataAccessDenied<T>(error as AuthFailure),
        ConflictFailure() => DataConflict<T>(error, previous),
        OfflineFailure() => DataOffline<T>(previous, freshness),
        Failure() => DataFailed<T>(error, previous),
        _ => DataFailed<T>(UnexpectedFailure.from(error!), previous),
      };
    }
    if (value.isLoading) {
      return value.hasValue
          ? DataRefreshing<T>(previous as T, freshness)
          : DataInitial<T>();
    }
    final data = value.value as T;
    if (freshness != null && freshness.isStale(after: staleAfter)) {
      return DataStale<T>(data, freshness);
    }
    return DataReady<T>(data, freshness);
  }

  /// The data this state can show, if any. Null for initial / denied /
  /// failed-without-previous.
  T? get data => null;

  /// True only for a successful, current read.
  bool get isAuthoritative => false;
}

/// Nothing loaded yet.
class DataInitial<T> extends DataState<T> {
  const DataInitial();
}

/// A successful, current read. The only state in which "empty" means empty.
class DataReady<T> extends DataState<T> {
  const DataReady(this.value, [this.freshness]);
  final T value;
  final Freshness? freshness;
  @override
  T get data => value;
  @override
  bool get isAuthoritative => true;
}

/// Showing the previous data while a reload runs.
class DataRefreshing<T> extends DataState<T> {
  const DataRefreshing(this.value, [this.freshness]);
  final T value;
  final Freshness? freshness;
  @override
  T get data => value;
}

/// Data older than the freshness threshold (or served from a cache).
class DataStale<T> extends DataState<T> {
  const DataStale(this.value, this.freshness);
  final T value;
  final Freshness freshness;
  @override
  T get data => value;
}

/// The store is unreachable; [value] is the last copy seen, if any.
class DataOffline<T> extends DataState<T> {
  const DataOffline(this.value, [this.freshness]);
  final T? value;
  final Freshness? freshness;
  @override
  T? get data => value;
}

/// Some parts loaded and some failed — never presented as the whole.
class DataPartial<T> extends DataState<T> {
  const DataPartial(this.value, this.failures);
  final T value;
  final List<Failure> failures;
  @override
  T get data => value;
}

/// The object changed underneath an edit.
class DataConflict<T> extends DataState<T> {
  const DataConflict(this.failure, [this.value]);
  final ConflictFailure failure;
  final T? value;
  @override
  T? get data => value;
}

/// The signed-in principal may not see this (or the session ended).
class DataAccessDenied<T> extends DataState<T> {
  const DataAccessDenied(this.failure);
  final AuthFailure failure;
}

/// The read failed; [value] is the previous data, if there was any.
class DataFailed<T> extends DataState<T> {
  const DataFailed(this.failure, [this.value]);
  final Failure failure;
  final T? value;
  @override
  T? get data => value;
}

extension AsyncCountX<T> on AsyncValue<List<T>> {
  /// A count for a badge or tile, or null when the list isn't known — so a
  /// failed load shows "—", never a reassuring 0.
  int? get countOrNull => hasError || !hasValue ? null : value!.length;
}
