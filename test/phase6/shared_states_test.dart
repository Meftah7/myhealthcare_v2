// Phase 6: the shared read/write feedback never turns a failure into an
// all-clear, and offers only the recovery that can help.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/presentation/data_state_view.dart';
import 'package:myhealthcare/core/presentation/feedback.dart';
import 'package:myhealthcare/core/presentation/states.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:myhealthcare/l10n/app_localizations_en.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Widget _list(AsyncValue<List<String>> value, {DateTime? fetchedAt}) => _host(
  AsyncDataView<List<String>>(
    value: value,
    fetchedAt: fetchedAt,
    onRetry: () {},
    isEmpty: (l) => l.isEmpty,
    empty: const Text('Nothing here'),
    builder: (_, l) => Text('Items: ${l.join(',')}'),
  ),
);

void main() {
  final t = AppLocalizationsEn();

  group('describeFailure', () {
    test('maps each failure to its message and recovery', () {
      expect(
        describeFailure(t, const AccessDeniedFailure()).action,
        RecoveryAction.none,
      );
      expect(
        describeFailure(t, const SessionExpiredFailure()).action,
        RecoveryAction.signIn,
      );
      expect(
        describeFailure(t, const ConflictFailure('x')).action,
        RecoveryAction.reload,
      );
      expect(
        describeFailure(t, const PaymentPendingFailure()).action,
        RecoveryAction.checkStatus,
      );
      expect(
        describeFailure(t, const OfflineFailure()).action,
        RecoveryAction.retry,
      );
      final validation = describeFailure(
        t,
        const ValidationFailure('Enter a receipt number.'),
      );
      expect(validation.message, 'Enter a receipt number.');
      expect(validation.action, RecoveryAction.none);
      // An unknown error never leaks its text.
      final unknown = describeFailure(t, StateError('db locked at 0x1f'));
      expect(unknown.message, t.feedbackUnexpected);
      expect(unknown.action, RecoveryAction.retry);
    });
  });

  group('showMutationFeedback', () {
    Future<void> pumpAndShow(
      WidgetTester tester,
      Result<Object?> result, {
      VoidCallback? onReload,
    }) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMutationFeedback(
                context,
                result,
                success: 'Saved.',
                onReload: onReload,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      // Let the snackbar finish sliding in before anything taps it.
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('success shows the success line', (tester) async {
      await pumpAndShow(tester, const Ok(null));
      expect(find.text('Saved.'), findsOneWidget);
    });

    testWidgets('a conflict with no way to reload offers no action', (
      tester,
    ) async {
      await pumpAndShow(tester, const Err(ConflictFailure('x')));
      expect(find.text(t.feedbackConflict), findsOneWidget);
      expect(find.text(t.reloadAction), findsNothing);
    });

    testWidgets('a conflict offers Reload when the screen can reload', (
      tester,
    ) async {
      var reloaded = false;
      await pumpAndShow(
        tester,
        const Err(ConflictFailure('x')),
        onReload: () => reloaded = true,
      );
      await tester.tap(find.text(t.reloadAction));
      expect(reloaded, isTrue);
    });
  });

  group('AsyncDataView', () {
    testWidgets('loading keeps a placeholder, never the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(_list(const AsyncLoading()));
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.text('Nothing here'), findsNothing);
    });

    testWidgets('empty only after a successful read', (tester) async {
      await tester.pumpWidget(_list(const AsyncData([])));
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('a failed read with nothing loaded is an error, not empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _list(const AsyncError(DatabaseFailure('x'), StackTrace.empty)),
      );
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Nothing here'), findsNothing);
    });

    testWidgets('a failed refresh keeps the old data and says so', (
      tester,
    ) async {
      const previous = AsyncData(['a', 'b']);
      final failed = const AsyncError<List<String>>(
        DatabaseFailure('x'),
        StackTrace.empty,
      ).copyWithPrevious(previous);
      await tester.pumpWidget(_list(failed));
      expect(find.text('Items: a,b'), findsOneWidget);
      expect(find.text(t.refreshFailedShowingPrevious), findsOneWidget);
    });

    testWidgets('a failed refresh of an empty list is not "Nothing here"', (
      tester,
    ) async {
      final failed = const AsyncError<List<String>>(
        DatabaseFailure('x'),
        StackTrace.empty,
      ).copyWithPrevious(const AsyncData([]));
      await tester.pumpWidget(_list(failed));
      expect(find.text('Nothing here'), findsNothing);
      expect(find.text(t.refreshFailedShowingPrevious), findsOneWidget);
    });

    testWidgets('lost access shows the boundary with sign-in', (tester) async {
      await tester.pumpWidget(
        _host(
          AsyncDataView<List<String>>(
            value: const AsyncError(SessionExpiredFailure(), StackTrace.empty),
            onSignIn: () {},
            builder: (_, l) => const Text('secret'),
          ),
        ),
      );
      expect(find.text('secret'), findsNothing);
      expect(find.byType(AccessBoundaryView), findsOneWidget);
      expect(find.text(t.signInAgainAction), findsOneWidget);
    });

    testWidgets('old data says when it was last current', (tester) async {
      final fetched = DateTime.now().subtract(const Duration(hours: 2));
      await tester.pumpWidget(
        _list(const AsyncData(['a']), fetchedAt: fetched),
      );
      expect(find.text('Items: a'), findsOneWidget);
      expect(find.textContaining('Last updated'), findsOneWidget);
    });
  });
}
