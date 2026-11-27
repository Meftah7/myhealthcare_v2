/// Frequently Asked Questions — opened from the assistant's FAQ button.
/// Expandable answers that describe only what the app does, with buttons
/// to the related screens (existing, access-checked routes; nothing happens
/// until the patient taps, and nothing is sent or booked automatically).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/presentation/patient_top_actions.dart';
import '../application/assistant_actions.dart';
import '../application/care_navigator.dart';

/// A button under an answer.
enum _FaqLink { messageDoctor, book, records, assistant }

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final items = <(String, String, List<_FaqLink>)>[
      (t.faqQ1, t.faqA1, [_FaqLink.book]),
      (t.faqQ2, t.faqA2, [_FaqLink.messageDoctor]),
      (t.faqQ3, t.faqA3, [_FaqLink.records]),
      (t.faqQ4, t.faqA4, [_FaqLink.assistant]),
      (t.faqQ5, t.faqA5, const []),
      (t.faqQ6, t.faqA6, const []),
      (t.faqQ7, t.faqA7, const []),
      (t.faqQ8, t.faqA8, const []),
      (t.faqQ9, t.faqA9, [_FaqLink.messageDoctor, _FaqLink.book]),
      (t.faqQ10, t.faqA10, [_FaqLink.messageDoctor, _FaqLink.book]),
    ];
    return AppScaffold(
      title: t.faqTitle,
      actions: const [PatientTopActions()],
      centerBody: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.md,
              Space.md,
              Space.xxl * 2,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
            itemBuilder: (context, i) {
              final (question, answer, links) = items[i];
              return _FaqTile(
                key: ValueKey('faq-item-$i'),
                question: question,
                answer: answer,
                links: links,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends ConsumerWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.links,
    super.key,
  });

  final String question;
  final String answer;
  final List<_FaqLink> links;

  void _open(WidgetRef ref, _FaqLink link) {
    final user = ref.read(currentUserProvider);
    switch (link) {
      case _FaqLink.messageDoctor:
        if (canOfferAssistantAction(user, AssistantAction.openMessages)) {
          ref.read(routerProvider).go(AppRoutes.patientMessages);
        }
      case _FaqLink.book:
        if (canOfferAssistantAction(user, AssistantAction.bookAppointment)) {
          ref.read(routerProvider).go(AppRoutes.patientBookLanding);
        }
      case _FaqLink.records:
        if (canOfferAssistantAction(user, AssistantAction.openRecords)) {
          ref.read(routerProvider).go(AppRoutes.patientTimeline);
        }
      case _FaqLink.assistant:
        ref.read(careNavigatorViewProvider.notifier).state = CareNavView.panel;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsetsDirectional.fromSTEB(
          Space.md,
          Space.xxs,
          Space.sm,
          Space.xxs,
        ),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(
          Space.md,
          0,
          Space.md,
          Space.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(color: palette.text),
        ),
        children: [
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          if (links.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final link in links)
                  FilledButton.tonalIcon(
                    key: ValueKey('faq-link-${link.name}'),
                    onPressed: () => _open(ref, link),
                    icon: Icon(switch (link) {
                      _FaqLink.messageDoctor => Icons.forum_outlined,
                      _FaqLink.book => Icons.event_available_outlined,
                      _FaqLink.records => Icons.folder_outlined,
                      _FaqLink.assistant => Icons.chat_bubble_outline,
                    }, size: 18),
                    label: Text(switch (link) {
                      _FaqLink.messageDoctor => t.faqButtonMessageDoctor,
                      _FaqLink.book => t.faqButtonBook,
                      _FaqLink.records => t.faqButtonRecords,
                      _FaqLink.assistant => t.faqButtonAssistant,
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
