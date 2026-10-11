/// The Care Navigator chat panel — header, message bubbles, a typing
/// indicator, and an input row. Same shape as the FirstSemMyHealth widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../timeline/presentation/import_record_sheet.dart';
import '../application/care_navigator.dart';

class CareNavigatorPanel extends ConsumerStatefulWidget {
  const CareNavigatorPanel({super.key});

  @override
  ConsumerState<CareNavigatorPanel> createState() => _CareNavigatorPanelState();
}

class _CareNavigatorPanelState extends ConsumerState<CareNavigatorPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    unawaited(ref.read(careNavigatorProvider.notifier).send(text));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: Motion.fast,
          curve: Motion.standard,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final chat = ref.watch(careNavigatorProvider);
    final live = ref.watch(careNavigatorLiveProvider).valueOrNull ?? false;
    final palette = PatientPalette.of(context);
    _scrollToEnd();

    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Space.md),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.aiFeatureCareNavigator,
                        style: theme.textTheme.titleSmall,
                      ),
                      Row(
                        children: [
                          // Honest mode: live model or the offline guide.
                          Icon(
                            live
                                ? Icons.auto_awesome
                                : Icons.cloud_off_outlined,
                            size: 12,
                            color: live
                                ? theme.clinicalStatus.riskLow.onContainer
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.xxs),
                          Flexible(
                            child: Text(
                              live
                                  ? t.paChatReportLiveStatus
                                  : t.paChatOfflineStatus,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(
                    context,
                  )!.restartConversationTooltip,
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () =>
                      ref.read(careNavigatorProvider.notifier).reset(),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.closeTooltip,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () =>
                      ref.read(careNavigatorViewProvider.notifier).state =
                          CareNavView.fab,
                ),
              ],
            ),
          ),

          // The report being explained, with its original one tap away.
          if (chat.report case final report?)
            Container(
              width: double.infinity,
              color: palette.softAccent,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: palette.onSoftAccent,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      t.paChatReportLabel(report.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(careNavigatorViewProvider.notifier).state =
                          CareNavView.fab;
                      context.go(AppRoutes.patientRecord(report.id));
                    },
                    child: Text(t.paViewOriginal),
                  ),
                  IconButton(
                    key: const ValueKey('leave-report'),
                    tooltip: t.paLeaveReport,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ref.read(careNavigatorProvider.notifier).leaveReport(),
                  ),
                ],
              ),
            ),

          // Messages
          Flexible(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(Space.md),
              itemCount: chat.messages.length + (chat.sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == chat.messages.length) return const _TypingDots();
                return _Bubble(
                  message: chat.messages[i],
                  onRetry: chat.sending
                      ? null
                      : (q) => unawaited(
                          ref.read(careNavigatorProvider.notifier).retry(q),
                        ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Input
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: t.uploadPdfForAiTooltip,
                  onPressed: chat.sending
                      ? null
                      : () async {
                          final record = await showImportRecordSheet(context);
                          if (record == null) return;
                          unawaited(
                            ref
                                .read(careNavigatorProvider.notifier)
                                .explainDocument(record),
                          );
                        },
                  icon: const Icon(Icons.upload_file_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: chat.report == null
                          ? t.askAboutAppHint
                          : t.paAskAboutReportHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                IconButton.filled(
                  onPressed: chat.sending ? null : _send,
                  icon: const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});
  final ChatMessage message;
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = PatientPalette.of(context);
    final t = AppLocalizations.of(context)!;
    final isUser = message.role == ChatRole.user;

    final (bg, fg) = isUser
        ? (palette.action, palette.onAction)
        : message.isEmergency
        ? (
            theme.clinicalStatus.riskHigh.container,
            theme.clinicalStatus.riskHigh.onContainer,
          )
        : message.kind == ChatKind.error
        ? (palette.dangerContainer, palette.text)
        : (scheme.surfaceContainerHighest, scheme.onSurface);

    // What produced this message, always visible (not colour alone).
    final source = isUser || message.isEmergency
        ? null
        : switch (message.kind) {
            ChatKind.guide => null,
            ChatKind.summary => (Icons.memory_outlined, t.paSourceOnDevice),
            ChatKind.live =>
              message.supported == false
                  ? (Icons.help_outline, t.paSourceNotInReport)
                  : (Icons.auto_awesome_outlined, t.paSourceLiveDraft),
            ChatKind.unavailable => (
              Icons.cloud_off_outlined,
              t.paSourceUnavailable,
            ),
            ChatKind.error => (Icons.error_outline, t.paSourceError),
          };
    final small = theme.textTheme.labelSmall?.copyWith(
      color: fg.withValues(alpha: .8),
      fontWeight: FontWeight.w600,
    );

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.xxs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          // Directional, not physical, corners — the sharp "tail" corner
          // needs to stay on the side the bubble is pointing from (bottom-end
          // for the user, bottom-start for the assistant) in both directions,
          // not fixed to left/right.
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(isUser ? 16 : 4),
            bottomEnd: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (source != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(source.$1, size: 14, color: fg.withValues(alpha: .8)),
                  const SizedBox(width: 4),
                  Flexible(child: Text(source.$2, style: small)),
                ],
              ),
              const SizedBox(height: Space.xxs),
            ],
            SelectableText(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
            if (message.quotes.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(t.paFromYourReport, style: small),
              for (final q in message.quotes)
                Container(
                  margin: const EdgeInsets.only(top: Space.xxs),
                  padding: const EdgeInsetsDirectional.only(start: Space.xs),
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(color: palette.link, width: 3),
                    ),
                  ),
                  child: SelectableText(
                    q,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            if (message.note != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                message.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: .85),
                ),
              ),
            ],
            if (message.kind == ChatKind.live) ...[
              const SizedBox(height: Space.xs),
              Text(t.paLiveDraftDisclaimer, style: small),
            ],
            if (message.retryQuestion != null && onRetry != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onRetry!(message.retryQuestion!),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(t.tryAgain),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.xxs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity:
                        0.3 +
                        0.7 *
                            (0.5 +
                                0.5 *
                                    ((_c.value * 3 - i).clamp(0, 1) -
                                        (_c.value * 3 - i - 1).clamp(0, 1))),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
