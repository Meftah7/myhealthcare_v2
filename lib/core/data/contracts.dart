/// Shared repository contracts for authoritative data (Phase 2).
///
/// Every repository speaks these types, so a networked backend can replace
/// the local store without changing callers:
///
/// * reads return [Page]s — never an unexplained, silently truncated list;
/// * consequential writes carry an [IdempotencyKey], so a retry after a lost
///   response cannot commit the work twice;
/// * editable objects carry a `version`; a write names the version it was
///   based on and fails with `ConflictFailure` if someone changed it first;
/// * authorization context is implicit — it is the signed-in principal (see
///   `AccessPolicy`), never an argument;
/// * failures are typed (`core/failures.dart`) and every read reports its
///   [Freshness].
library;

import 'package:flutter/foundation.dart';

import '../utils/ids.dart';

/// Default and maximum page sizes. Exposed so screens can say how many they
/// show rather than hiding a cap.
abstract final class PageLimits {
  static const defaultSize = 50;
  static const maxSize = 200;
}

/// Which slice of a list to read. Offset-based: stable because every paged
/// query has a deterministic order with an id tie-breaker.
@immutable
class PageRequest {
  const PageRequest({this.offset = 0, this.size = PageLimits.defaultSize})
    : assert(offset >= 0),
      assert(size > 0 && size <= PageLimits.maxSize);

  final int offset;
  final int size;

  PageRequest get next => PageRequest(offset: offset + size, size: size);
}

/// One page of results.
@immutable
class Page<T> {
  const Page({
    required this.items,
    required this.offset,
    required this.hasMore,
    this.total,
  });

  const Page.empty() : items = const [], offset = 0, hasMore = false, total = 0;

  final List<T> items;
  final int offset;

  /// True when more items exist beyond this page — the UI offers "Load more"
  /// instead of pretending the list is complete.
  final bool hasMore;

  /// Total matching items, when cheap to know.
  final int? total;

  Page<T> append(Page<T> next) => Page(
    items: [...items, ...next.items],
    offset: offset,
    hasMore: next.hasMore,
    total: next.total ?? total,
  );
}

/// Read the first [pages] pages via [fetch] and join them — backs "Load more"
/// lists (raise [pages] by one to show the next page). Stops early at the
/// last page. [fetch] should throw on failure.
Future<Page<T>> loadPages<T>(
  int pages,
  Future<Page<T>> Function(PageRequest request) fetch, {
  int size = PageLimits.defaultSize,
}) async {
  var request = PageRequest(size: size);
  var all = await fetch(request);
  for (var i = 1; i < pages && all.hasMore; i++) {
    request = request.next;
    all = all.append(await fetch(request));
  }
  return all;
}

/// Identifies one logical mutation across retries. Create it when the user
/// *starts* the action (opens the sheet, confirms the slot) and reuse it for
/// every retry of that same action; a new action gets a new key.
@immutable
class IdempotencyKey {
  const IdempotencyKey(this.value);

  factory IdempotencyKey.generate() => IdempotencyKey(newId('idem'));

  final String value;

  @override
  bool operator ==(Object other) =>
      other is IdempotencyKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IdempotencyKey($value)';
}

/// Where a read came from and how old it is.
@immutable
class Freshness {
  const Freshness({required this.fetchedAt, this.fromCache = false});

  factory Freshness.now() => Freshness(fetchedAt: DateTime.now());

  final DateTime fetchedAt;

  /// True when served from a local copy because the authoritative store was
  /// unreachable.
  final bool fromCache;

  Duration age([DateTime? now]) =>
      (now ?? DateTime.now()).difference(fetchedAt);

  bool isStale({Duration after = const Duration(minutes: 2), DateTime? now}) =>
      fromCache || age(now) > after;
}
