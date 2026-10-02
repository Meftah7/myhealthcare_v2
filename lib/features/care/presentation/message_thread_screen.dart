/// One patient <-> doctor conversation (P10-07). Shared by the patient's
/// "Ask your doctor" and the staff inbox — [viewerIsStaff] flips the sides.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/presentation/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../application/care_providers.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({
    required this.patientId,
    required this.staffId,
    required this.title,
    required this.viewerIsStaff,
    super.key,
  });

  final String patientId;
  final String staffId;
  final String title;
  final bool viewerIsStaff;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_markRead()));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final result = await ref
        .read(messageActionsProvider)
        .markRead(
          patientId: widget.patientId,
          staffId: widget.staffId,
          readerIsStaff: widget.viewerIsStaff,
        );
    if (result case Err(:final failure) when mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFailure(AppLocalizations.of(context)!, failure).message,
          ),
        ),
      );
    }
  }

  /// A clinician opening a colleague's thread they cover.
  bool get _covering =>
      widget.viewerIsStaff &&
      widget.staffId != ref.read(currentUserProvider)?.id;

  FutureProvider<List<CareMessage>> get _threadProvider => _covering
      ? coveredThreadProvider((
          patientId: widget.patientId,
          ownerId: widget.staffId,
        ))
      : widget.viewerIsStaff
      ? staffThreadProvider(widget.patientId)
      : patientThreadProvider(widget.staffId);

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final actions = ref.read(messageActionsProvider);
    final result = _covering
        ? await actions.sendAsCover(
            patientId: widget.patientId,
            ownerId: widget.staffId,
            body: text,
          )
        : await actions.sendAsCurrentUser(
            counterpartId: widget.viewerIsStaff
                ? widget.patientId
                : widget.staffId,
            body: text,
          );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.isOk) {
      _input.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          unawaited(
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: Motion.fast,
              curve: Motion.standard,
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final messages = ref.watch(_threadProvider);

    return AppScaffold(
      title: widget.title,
      actions: [
        if (widget.viewerIsStaff)
          IconButton(
            tooltip: t.openPatientChartTooltip,
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: () =>
                context.go(AppRoutes.staffPatientChart(widget.patientId)),
          ),
      ],
      centerBody: false,
      body: Column(
        children: [
          // The honest promise: when a reply comes, and that this is not an
          // emergency channel.
          if (!widget.viewerIsStaff)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                0,
              ),
              child: InlineBanner.info(t.messageResponseExpectation),
            ),
          Expanded(
            child: messages.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                message: t.couldNotLoadConversation,
                onRetry: () => ref.invalidate(_threadProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: widget.viewerIsStaff
                        ? t.noMessagesYet
                        : t.sendNonUrgentQuestionMessage,
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Space.maxContentWidth,
                    ),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        Space.md,
                        Space.md,
                        Space.md,
                        Space.md,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _Bubble(
                        message: list[i],
                        mine: list[i].fromStaff == widget.viewerIsStaff,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.md,
                Space.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: t.writeMessageHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final CareMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mine ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fmtTimeAgo(message.sentAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: (mine ? scheme.onPrimary : scheme.onSurfaceVariant)
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
