/// One patient <-> doctor conversation (P10-07). Shared by the patient's
/// "Ask your doctor" and the staff inbox — [viewerIsStaff] flips the sides.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _markRead() {
    unawaited(
      ref
          .read(messageActionsProvider)
          .markRead(
            patientId: widget.patientId,
            staffId: widget.staffId,
            readerIsStaff: widget.viewerIsStaff,
          ),
    );
  }

  FutureProvider<List<CareMessage>> get _threadProvider => widget.viewerIsStaff
      ? staffThreadProvider(widget.patientId)
      : patientThreadProvider(widget.staffId);

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(messageActionsProvider)
        .send(
          patientId: widget.patientId,
          staffId: widget.staffId,
          fromStaff: widget.viewerIsStaff,
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
    final messages = ref.watch(_threadProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                message: 'Could not load this conversation.',
                onRetry: () => ref.invalidate(_threadProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: widget.viewerIsStaff
                        ? 'No messages yet.'
                        : 'Send your doctor a non-urgent question.\nFor '
                              'emergencies, call your clinic.',
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
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
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
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
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
