/// One widget for every state a read can be in (Phase 6).
///
/// Built on the Phase 2 [DataState] contract, so a screen cannot confuse "we
/// don't know" with "there is nothing":
///
/// * **loading** — a placeholder that keeps the layout stable;
/// * **refreshing** — the data, with a thin progress line;
/// * **stale / offline** — the data, with when it was last current;
/// * **failed with previous data** — the data, with a banner saying the
///   refresh failed and a retry;
/// * **failed with nothing** — an error with a retry, never an empty state;
/// * **conflict** — the data, with a reload;
/// * **access lost** — the boundary, with sign-in when the session ended;
/// * **ready** — the content, or the empty state *only* after a successful
///   read that returned nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../data/contracts.dart';
import '../data/data_state.dart';
import '../failures.dart';
import '../observability/operational_metrics.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'feedback.dart';
import 'states.dart';

class AsyncDataView<T> extends StatelessWidget {
  const AsyncDataView({
    required this.value,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.onRetry,
    this.onSignIn,
    this.fetchedAt,
    this.staleAfter = const Duration(minutes: 5),
    this.fill = false,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;

  /// Whether [T] counts as "nothing to show"; [empty] is shown then — but
  /// only for a successful, current read.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;

  /// Re-read (also used for conflict reloads).
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;

  /// When the data was last read successfully, if tracked.
  final DateTime? fetchedAt;
  final Duration staleAfter;

  /// True when [builder] returns a scrollable that should take the remaining
  /// height (a full-screen list); false for an inline section.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final freshness = fetchedAt == null
        ? null
        : Freshness(fetchedAt: fetchedAt!);
    final state = DataState<T>.fromAsync(
      value,
      freshness: freshness,
      staleAfter: staleAfter,
    );

    Widget content(T data) {
      if (state.isAuthoritative && (isEmpty?.call(data) ?? false)) {
        return empty ?? const SizedBox.shrink();
      }
      return builder(context, data);
    }

    Widget withBanner(Widget banner, T data) =>
        _stack(banner: banner, child: content(data));

    if (state is DataStale<T> || state is DataOffline<T>) {
      final metrics = operationalMetricsOf(context);
      if (metrics != null) {
        recordThrottled(
          metrics,
          OperationalSignal.staleDataShown,
          workflow: state is DataOffline<T> ? 'view.offline' : 'view.stale',
        );
      }
    }

    return switch (state) {
      DataInitial() => loading ?? const SkeletonList(lines: 3),
      DataReady(:final value) => content(value),
      DataRefreshing(:final value) => _stack(
        banner: const LinearProgressIndicator(minHeight: 2),
        child: content(value),
        gap: false,
      ),
      DataStale(:final value, :final freshness) => withBanner(
        _Banner(
          icon: Icons.history,
          message: t.staleDataBanner(fmtTime(freshness.fetchedAt)),
          actionLabel: t.tryAgain,
          onAction: onRetry,
        ),
        value,
      ),
      DataOffline(:final value, :final freshness) when value != null =>
        withBanner(
          _Banner(
            icon: Icons.cloud_off_outlined,
            message: freshness == null
                ? t.feedbackOffline
                : t.staleDataBanner(fmtTime(freshness.fetchedAt)),
            actionLabel: t.tryAgain,
            onAction: onRetry,
          ),
          value as T,
        ),
      DataConflict(:final value) when value != null => withBanner(
        _Banner(
          icon: Icons.sync_problem_outlined,
          message: t.feedbackConflict,
          actionLabel: t.reloadAction,
          onAction: onRetry,
          error: true,
        ),
        value as T,
      ),
      DataFailed(:final value) when value != null => withBanner(
        _Banner(
          icon: Icons.error_outline,
          message: t.refreshFailedShowingPrevious,
          actionLabel: t.tryAgain,
          onAction: onRetry,
          error: true,
        ),
        value as T,
      ),
      DataAccessDenied(:final failure) => AccessBoundaryView(
        sessionEnded: failure is SessionExpiredFailure,
        onSignIn: onSignIn,
      ),
      DataFailed(:final failure) => _failure(t, failure),
      DataConflict(:final failure) => _failure(t, failure),
      DataOffline() => _failure(t, const OfflineFailure()),
      DataPartial(:final value) => content(value),
    };
  }

  Widget _failure(AppLocalizations t, Failure failure) {
    final f = describeFailure(t, failure);
    return ErrorStateView(
      message: f.message,
      onRetry: f.action == RecoveryAction.none ? null : onRetry,
    );
  }

  Widget _stack({
    required Widget banner,
    required Widget child,
    bool gap = true,
  }) {
    return Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        if (gap) const SizedBox(height: Space.xs),
        if (fill) Expanded(child: child) else child,
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.error = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = error
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (scheme.surfaceContainerHighest, scheme.onSurface);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Space.sm,
          Space.xxs,
          Space.xxs,
          Space.xxs,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: Radii.cardSmall),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
            if (onAction != null && actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Protected content is gone: say why, and offer sign-in when the session
/// ended (never a retry that cannot succeed).
class AccessBoundaryView extends StatelessWidget {
  const AccessBoundaryView({
    this.sessionEnded = false,
    this.onSignIn,
    super.key,
  });

  final bool sessionEnded;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 28),
          const SizedBox(height: Space.xs),
          Text(
            sessionEnded ? t.feedbackSessionExpired : t.accessDeniedBody,
            textAlign: TextAlign.center,
          ),
          if (sessionEnded && onSignIn != null) ...[
            const SizedBox(height: Space.xs),
            FilledButton(onPressed: onSignIn, child: Text(t.signInAgainAction)),
          ],
        ],
      ),
    );
  }
}
