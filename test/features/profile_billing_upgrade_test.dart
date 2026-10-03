import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/presentation/app_card.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/features/billing/application/billing_providers.dart';
import 'package:myhealthcare/features/billing/presentation/payments_screen.dart';
import 'package:myhealthcare/features/notifications/application/notification_providers.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('invalid profile photo preserves identity and photo editing', (
    tester,
  ) async {
    var edits = 0;
    await tester.pumpWidget(
      _app(
        ProfileHeader(
          name: 'Alex Patient',
          email: 'alex@example.test',
          avatarPath: 'data:image/png;base64,!!!',
          onEditAvatar: () => edits++,
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Alex Patient'), findsOneWidget);
    final edit = find.byTooltip('Profile photo');
    final size = tester.getSize(edit);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(edit);
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice failure keeps wallet and saved cards accessible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWithValue(null),
          patientInvoicesProvider.overrideWith(
            (ref) async => throw StateError('Invoices unavailable'),
          ),
          walletBalanceProvider.overrideWith((ref) async => 23.5),
          walletCardsProvider.overrideWith((ref) async => <PaymentMethod>[]),
          patientPaymentsProvider.overrideWith(
            (ref) async => <PaymentTransaction>[],
          ),
        ],
        child: _app(const PaymentsScreen(embedded: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your invoices.'), findsOneWidget);
    expect(find.text('Wallet balance'), findsOneWidget);
    expect(find.text('BD 23.50'), findsOneWidget);
    await tester.ensureVisible(find.text('SAVED CARDS'));
    expect(find.text('SAVED CARDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading invoices does not block independent wallet data', (
    tester,
  ) async {
    final invoices = Completer<List<Invoice>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWithValue(null),
          patientInvoicesProvider.overrideWith((ref) => invoices.future),
          walletBalanceProvider.overrideWith((ref) async => 10),
          walletCardsProvider.overrideWith((ref) async => <PaymentMethod>[]),
          patientPaymentsProvider.overrideWith(
            (ref) async => <PaymentTransaction>[],
          ),
        ],
        child: _app(const PaymentsScreen(embedded: true)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('Wallet balance'));
    expect(find.text('BD 10.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    invoices.complete([]);
    await tester.pumpAndSettle();
  });
}
