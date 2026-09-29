// Phase 4: a failed mark-read is visible, for any role's inbox. The
// notification is still shown — the failure never pretends it was read.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/notifications/application/notification_providers.dart';
import 'package:myhealthcare/features/notifications/presentation/notifications_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

class _FailingController extends NotificationController {
  _FailingController(super.ref);

  var attempts = 0;

  @override
  Future<Result<void>> markRead(String id) async {
    attempts++;
    return const Err(DatabaseFailure('Could not mark this as read.'));
  }

  @override
  Future<Result<void>> markAllRead() async {
    attempts++;
    return const Err(DatabaseFailure('Could not mark these as read.'));
  }
}

void main() {
  final unread = AppNotification(
    id: 'ntf_staff',
    recipientId: 'staff_01',
    category: NotificationCategory.message,
    title: 'Referral needs clarification',
    body: 'Which cardiology service?',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  /// The controller the screen used — created lazily on first use.
  final made = <_FailingController>[];

  Future<void> pump(WidgetTester tester) async {
    made.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myNotificationsProvider.overrideWith((ref) => Stream.value([unread])),
          notificationControllerProvider.overrideWith((ref) {
            final controller = _FailingController(ref);
            made.add(controller);
            return controller;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // A staff inbox: no patient top bar.
          home: const NotificationsScreen(topActions: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opening a notification whose mark-read fails says so', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Referral needs clarification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(made.single.attempts, 1);
    expect(find.text('Could not mark this as read.'), findsOneWidget);
  });

  testWidgets('"Mark all read" failing says so and keeps the unread item', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(made.single.attempts, 1);
    expect(find.text('Could not mark these as read.'), findsOneWidget);
    expect(find.text('Referral needs clarification'), findsOneWidget);
  });
}
