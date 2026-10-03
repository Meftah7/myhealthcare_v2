/// Patient home "Needs your attention" (Phase 6): the few things waiting on
/// the patient — an unread reply from their doctor, an overdue bill, a
/// payment still being confirmed, someone asking to link to their record.
///
/// Hidden only when every source was read successfully and nothing is
/// waiting. A source that could not be read shows its own "couldn't check"
/// row, so a failed read never looks like "nothing to do".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/presentation/payments_screen.dart';
import '../../care/application/care_providers.dart';
import '../../patient/application/family_link_providers.dart';

class NeedsAttentionStrip extends ConsumerWidget {
  const NeedsAttentionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <Widget>[];

    Widget row(IconData icon, String text, String route, {bool tab = false}) =>
        ListTile(
          leading: Icon(icon),
          title: ReadableLabel(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => tab ? context.go(route) : context.push(route),
        );
    Widget failed(String what, VoidCallback retry) => ListTile(
      leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text(t.couldNotCheckQueue(what)),
      trailing: TextButton(onPressed: retry, child: Text(t.tryAgain)),
    );

    // Unread replies from the care team.
    final threads = ref.watch(patientThreadsProvider);
    final unread = ref.watch(patientUnreadCountProvider);
    if (threads.hasError) {
      rows.add(
        failed(t.messagesTitle, () => ref.invalidate(patientThreadsProvider)),
      );
    } else if ((unread ?? 0) > 0) {
      rows.add(
        row(
          Icons.mark_email_unread_outlined,
          t.homeUnreadReplies(unread!),
          AppRoutes.patientMessages,
        ),
      );
    }

    // Bills: overdue, and payments the provider hasn't confirmed yet.
    final bills = ref.watch(billingSummaryProvider);
    if (bills.hasError) {
      rows.add(
        failed(t.paymentsTitle, () => ref.invalidate(patientInvoicesProvider)),
      );
    } else if (bills.valueOrNull case final s? when s.overdue > 0) {
      rows.add(
        row(
          Icons.receipt_long_outlined,
          t.homeOverdueBill(money(s.overdue)),
          AppRoutes.patientBilling,
        ),
      );
    }
    final confirming = ref.watch(invoicesAwaitingConfirmationProvider);
    if (confirming.isNotEmpty) {
      rows.add(
        row(
          Icons.sync_problem_outlined,
          t.homePaymentsConfirming(confirming.length),
          AppRoutes.patientBilling,
        ),
      );
    }

    // Someone asked to link to this record.
    final requests = ref.watch(incomingFamilyRequestsProvider);
    if (requests.hasError) {
      rows.add(
        failed(
          t.homeFamilyRequestsLabel,
          () => ref.invalidate(incomingFamilyRequestsProvider),
        ),
      );
    } else if ((requests.valueOrNull?.length ?? 0) > 0) {
      rows.add(
        row(
          Icons.family_restroom_outlined,
          t.homeFamilyRequests(requests.requireValue.length),
          AppRoutes.patientProfileFamily,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            t.needsYourAttentionHeader,
            overline: true,
            first: true,
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}
