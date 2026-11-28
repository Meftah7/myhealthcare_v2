/// The Care Navigator chat panel — header (with the real connection status
/// and the FAQ), message bubbles with their buttons, the attachment card
/// (file, size, type, each step, real upload progress, Summarize / Retry /
/// Remove), and the input row.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/ai/report_ai_client.dart';
import '../../../services/documents/document_text.dart';
import '../../auth/application/session.dart';
import '../application/assistant_actions.dart';
import '../application/assistant_connection.dart';
import '../application/care_navigator.dart';
import '../application/document_attachment.dart';
import 'assistant_document_picker.dart';
import 'care_navigator_mascot.dart';

/// Opens the file picker (PDF, Word, text) and attaches the chosen file in
/// the assistant, opening the panel. Never asks for a summary: the patient
/// taps Summarize when the file is ready.
Future<void> pickDocumentForAssistant(WidgetRef ref) async {
  final context = ref.context;
  final userId = ref.read(currentUserProvider)?.id;
  bool samePatient() =>
      context.mounted && ref.read(currentUserProvider)?.id == userId;
  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  if (userId == null) return;
  final ui = _Ui.of(context);
  try {
    final file = await pickAssistantDocument();
    if (file == null || !samePatient()) return;
    if (DocumentFormat.forFileName(file.name) == null) {
      showError(ui.document(DocumentProblem.unsupportedType));
      return;
    }
    if ((file.size ?? 0) > maxDocumentBytes) {
      showError(ui.document(DocumentProblem.tooLarge));
      return;
    }
    final bytes = await file.readBytes();
    if (!samePatient()) return;
    ref.read(careNavigatorViewProvider.notifier).state = CareNavView.panel;
    await ref
        .read(documentAttachmentProvider.notifier)
        .attach(file.name, bytes);
  } on DocumentReadException catch (e) {
    if (samePatient()) showError(ui.document(e.problem));
  } on Object {
    if (samePatient()) showError(ui.fileAccessFailed);
  }
}

/// The assistant's own UI words, in the app language.
class _Ui {
  const _Ui(this.ar);
  final bool ar;

  static _Ui of(BuildContext context) =>
      _Ui(Localizations.localeOf(context).languageCode == 'ar');

  String get faq => ar ? 'الأسئلة الشائعة' : 'FAQ';
  String get attach => ar
      ? 'إرفاق مستند (PDF أو Word أو نص)'
      : 'Attach a document (PDF, Word or text)';
  String get summarize => ar ? 'لخّص' : 'Summarize';
  String get fileAccessFailed => ar
      ? 'تعذّر فتح الملف. احفظ نسخة على جهازك وحاول مرة أخرى.'
      : 'Couldn’t open the file. Save a copy on your device and try again.';
  String get retry => ar ? 'إعادة المحاولة' : 'Retry';
  String get remove => ar ? 'إزالة' : 'Remove';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get editMessage => ar ? 'تعديل الرسالة' : 'Edit message';
  String get checkAgain => ar ? 'تحقق مرة أخرى' : 'Check again';
  String get liveChat => ar ? 'ذكاء MyHealth الاصطناعي' : 'MyHealth AI';
  String get onDeviceGuide =>
      ar ? 'دليل على الجهاز · ليس ذكاءً اصطناعيًا' : 'On-device guide · not AI';

  String readiness(GatewayReadiness r) => switch (r) {
    GatewayReadiness.available =>
      ar ? 'الذكاء الاصطناعي متاح' : 'AI service available',
    GatewayReadiness.checking =>
      ar ? 'جارٍ التحقق من الاتصال…' : 'Checking connection…',
    GatewayReadiness.unconfigured =>
      ar
          ? 'مساعد على الجهاز · بلا ذكاء اصطناعي مباشر'
          : 'On-device assistant · no live AI',
    GatewayReadiness.unreachable =>
      ar ? 'تعذّر الوصول إلى خدمة الذكاء الاصطناعي' : 'AI service unreachable',
    GatewayReadiness.unauthorized =>
      ar
          ? 'الخدمة لا تتعرّف على هذا التطبيق'
          : 'AI service does not recognise this app',
    GatewayReadiness.providerUnavailable =>
      ar
          ? 'خدمة الذكاء الاصطناعي غير متاحة الآن'
          : 'AI service not available right now',
  };

  String status(ChatAttachment a, {required bool live}) => switch (a.status) {
    AttachmentStatus.validating =>
      ar ? 'جارٍ التحقق من الملف…' : 'Checking the file…',
    AttachmentStatus.reading =>
      ar
          ? 'جارٍ قراءة النص على هذا الجهاز…'
          : 'Reading the text on this device…',
    AttachmentStatus.ready =>
      ar
          ? 'جاهز · ${a.charCount} حرف — اضغط «لخّص» عندما تريد'
          : 'Ready · ${a.charCount} characters read — tap Summarize when you '
                'want',
    AttachmentStatus.saving =>
      ar
          ? 'جارٍ الحفظ في سجلاتك على هذا الجهاز…'
          : 'Saving to your Records on this device…',
    AttachmentStatus.uploading =>
      a.progress == null
          ? (ar
                ? 'جارٍ رفع النص إلى خدمة التلخيص…'
                : 'Uploading the text to the summary service…')
          : (ar
                ? 'جارٍ رفع النص إلى خدمة التلخيص · '
                      '${(a.progress! * 100).round()}٪'
                : 'Uploading the text to the summary service · '
                      '${(a.progress! * 100).round()}%'),
    AttachmentStatus.summarizing =>
      live
          ? (ar ? 'جارٍ إعداد الملخص…' : 'Writing the summary…')
          : (ar
                ? 'جارٍ إعداد الملخص على هذا الجهاز…'
                : 'Making the summary on this device…'),
    AttachmentStatus.complete => ar ? 'اكتمل' : 'Done',
    AttachmentStatus.cancelled => ar ? 'أُلغي' : 'Cancelled',
    AttachmentStatus.failed => failure(a),
  };

  String failure(ChatAttachment a) {
    switch (a.problem) {
      case AttachmentProblem.saveFailed:
        return ar
            ? 'تعذّر الحفظ في سجلاتك. اضغط «إعادة المحاولة».'
            : "Couldn't save to your Records. Tap Retry.";
      case AttachmentProblem.ai:
        return '${reportAiFailureMessage(a.aiProblem ?? ReportAiFailureKind.provider)}'
            '${ar ? ' الملف ما زال جاهزًا.' : ' The file is still ready.'}';
      case AttachmentProblem.document || null:
        return document(a.documentProblem ?? DocumentProblem.malformed);
    }
  }

  String document(DocumentProblem p) => switch (p) {
    DocumentProblem.empty => ar ? 'الملف فارغ.' : 'This file is empty.',
    DocumentProblem.tooLarge =>
      ar ? 'الملف أكبر من 20 ميغابايت.' : 'This file is larger than 20 MB.',
    DocumentProblem.unsupportedType =>
      ar
          ? 'هذا النوع غير مدعوم. اختر PDF أو Word (.docx/.doc) أو ملفًا نصيًا '
                '(.txt).'
          : 'This type is not supported. Choose a PDF, Word (.docx/.doc) or '
                'text (.txt) file.',
    DocumentProblem.mismatch =>
      ar
          ? 'محتوى الملف لا يطابق امتداده.'
          : "The file's contents don't match its extension.",
    DocumentProblem.executable =>
      ar
          ? 'هذا ملف برنامج وليس مستندًا.'
          : 'This is a program file, not a document.',
    DocumentProblem.encrypted =>
      ar
          ? 'الملف محمي بكلمة مرور. احفظ نسخة بلا كلمة مرور ثم أرفقها.'
          : 'This file is password-protected. Save a copy without a password '
                'and attach that.',
    DocumentProblem.malformed =>
      ar
          ? 'الملف تالف أو لا يمكن قراءته.'
          : 'This file is damaged or cannot be read.',
    DocumentProblem.noText =>
      ar
          ? 'لا يحتوي الملف على نص قابل للقراءة (ربما صورة ممسوحة). أرفق ملف '
                'PDF قابلًا للبحث.'
          : 'No readable text — it may be a scanned image. Attach a '
                'searchable PDF instead.',
    DocumentProblem.unsupportedEncoding =>
      ar
          ? 'ترميز الملف النصي غير مدعوم. احفظه بترميز UTF-8.'
          : "This text file's encoding isn't supported. Save it as UTF-8.",
    DocumentProblem.tooComplex =>
      ar
          ? 'الملف كبير أو معقّد جدًا للقراءة هنا.'
          : 'This file is too large or complex to read here.',
  };
}

class CareNavigatorPanel extends ConsumerStatefulWidget {
  const CareNavigatorPanel({super.key});

  @override
  ConsumerState<CareNavigatorPanel> createState() => _CareNavigatorPanelState();
}

class _CareNavigatorPanelState extends ConsumerState<CareNavigatorPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _shownMessages = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The same path for Send and the Enter key. The draft is cleared only
  /// once the message is accepted (not while one is still on its way).
  void _send() {
    final accepted = ref.read(careNavigatorProvider.notifier).send(_input.text);
    if (accepted) _input.clear();
  }

  /// Puts a failed message back in the input to edit.
  void _edit(String text) {
    _input
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _runAction(AssistantAction action) async {
    // Checked again now: the signed-in patient must still be allowed.
    if (!canOfferAssistantAction(ref.read(currentUserProvider), action)) {
      return;
    }
    switch (action.route) {
      case final route?:
        ref.read(careNavigatorViewProvider.notifier).state = CareNavView.fab;
        ref.read(routerProvider).go(route);
      case null:
        await pickDocumentForAssistant(ref);
    }
  }

  void _openFaq() {
    ref.read(careNavigatorViewProvider.notifier).state = CareNavView.fab;
    ref.read(routerProvider).go(AppRoutes.patientFaq);
  }

  void _scrollToEnd() {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final ui = _Ui.of(context);
    final chat = ref.watch(careNavigatorProvider);
    final attachment = ref.watch(documentAttachmentProvider);
    final readiness = ref.watch(assistantReadinessProvider);
    final palette = PatientPalette.of(context);
    final user = ref.watch(currentUserProvider);
    // New replies (and the typing indicator) scroll into view.
    if (chat.messages.length != _shownMessages || chat.sending) {
      _shownMessages = chat.messages.length;
      _scrollToEnd();
    }
    final retryable =
        readiness == GatewayReadiness.unreachable ||
        readiness == GatewayReadiness.unauthorized ||
        readiness == GatewayReadiness.providerUnavailable;

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
            padding: const EdgeInsetsDirectional.fromSTEB(
              Space.md,
              Space.sm,
              Space.xs,
              Space.sm,
            ),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                const CareNavigatorAvatar(size: 40),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.aiFeatureCareNavigator,
                        style: theme.textTheme.titleSmall,
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          key: const ValueKey('assistant-readiness'),
                          children: [
                            Icon(
                              switch (readiness) {
                                GatewayReadiness.available =>
                                  Icons.auto_awesome,
                                GatewayReadiness.checking => Icons.sync,
                                _ => Icons.cloud_off_outlined,
                              },
                              size: 12,
                              color: readiness == GatewayReadiness.available
                                  ? theme.clinicalStatus.riskLow.onContainer
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: Space.xxs),
                            Flexible(
                              child: Text(
                                ui.readiness(readiness),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // The FAQ and "check again" sit under the status, so
                      // a long label wraps instead of crowding the title row.
                      Wrap(
                        spacing: Space.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (retryable)
                            InkWell(
                              key: const ValueKey('assistant-recheck'),
                              onTap: () => unawaited(
                                ref
                                    .read(assistantConnectionProvider.notifier)
                                    .recheck(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  ui.checkAgain,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: palette.link,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          TextButton.icon(
                            key: const ValueKey('assistant-faq'),
                            onPressed: _openFaq,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.xs,
                              ),
                              minimumSize: const Size(48, 36),
                            ),
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: Text(ui.faq),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.restartConversationTooltip,
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () =>
                      ref.read(careNavigatorProvider.notifier).reset(),
                ),
                IconButton(
                  tooltip: t.closeTooltip,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () =>
                      ref.read(careNavigatorViewProvider.notifier).state =
                          CareNavView.fab,
                ),
              ],
            ),
          ),

          // The document being discussed, with its original one tap away.
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
                  user: user,
                  ui: ui,
                  onAction: (a) => unawaited(_runAction(a)),
                  onRetry: chat.sending
                      ? null
                      : (q) => unawaited(
                          ref.read(careNavigatorProvider.notifier).retry(q),
                        ),
                  onEdit: _edit,
                );
              },
            ),
          ),

          if (attachment != null)
            _AttachmentCard(
              attachment: attachment,
              ui: ui,
              live: readiness == GatewayReadiness.available,
            ),

          const Divider(height: 1),

          // Input
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('assistant-attach'),
                  tooltip: ui.attach,
                  onPressed: () => unawaited(pickDocumentForAssistant(ref)),
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('assistant-input'),
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLength: ReportAiLimits.maxQuestionChars,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
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
                  key: const ValueKey('assistant-send'),
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

/// The attached document: name, size, type, the current step, real upload
/// progress, and Summarize / Retry / Remove.
class _AttachmentCard extends ConsumerWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.ui,
    required this.live,
  });

  final ChatAttachment attachment;
  final _Ui ui;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final a = attachment;
    final controller = ref.read(documentAttachmentProvider.notifier);
    final failed = a.status == AttachmentStatus.failed;
    final type = a.format?.label ?? '—';
    return Container(
      key: const ValueKey('assistant-attachment'),
      margin: const EdgeInsets.fromLTRB(Space.sm, 0, Space.sm, Space.xs),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: failed ? palette.dangerContainer : palette.softAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(switch (a.format) {
                DocumentFormat.pdf => Icons.picture_as_pdf_outlined,
                DocumentFormat.docx ||
                DocumentFormat.doc => Icons.description_outlined,
                DocumentFormat.txt => Icons.notes_outlined,
                null => Icons.insert_drive_file_outlined,
              }, color: palette.onSoftAccent),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.text,
                      ),
                    ),
                    Text(
                      '${formatFileSize(a.sizeBytes)} · $type',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('attachment-remove'),
                tooltip: a.busy ? ui.cancel : ui.remove,
                icon: const Icon(Icons.close, size: 18),
                onPressed: controller.remove,
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Semantics(
            liveRegion: true,
            child: Text(
              ui.status(a, live: live),
              key: const ValueKey('attachment-status'),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.text),
            ),
          ),
          if (a.busy) ...[
            const SizedBox(height: Space.xs),
            // A percentage only for the real upload; otherwise indeterminate.
            LinearProgressIndicator(
              key: const ValueKey('attachment-progress'),
              value: a.progress,
            ),
          ],
          if (a.canSummarize) ...[
            const SizedBox(height: Space.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                key: const ValueKey('attachment-summarize'),
                onPressed: () => unawaited(controller.send()),
                icon: Icon(failed ? Icons.refresh : Icons.summarize_outlined),
                label: Text(failed ? ui.retry : ui.summarize),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.user,
    required this.ui,
    this.onAction,
    this.onRetry,
    this.onEdit,
  });
  final ChatMessage message;
  final User? user;
  final _Ui ui;
  final ValueChanged<AssistantAction>? onAction;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onEdit;

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

    final aboutDocument =
        message.quotes.isNotEmpty || message.supported != null;
    final source = isUser || message.isEmergency || message.isGreeting
        ? null
        : switch (message.kind) {
            ChatKind.guide =>
              message.isMedicalRefusal
                  ? null
                  : (Icons.memory_outlined, ui.onDeviceGuide),
            ChatKind.summary => (Icons.memory_outlined, t.paSourceOnDevice),
            ChatKind.live =>
              message.supported == false
                  ? (Icons.help_outline, t.paSourceNotInReport)
                  : aboutDocument || message.text.contains('\n•')
                  ? (Icons.auto_awesome_outlined, t.paSourceLiveDraft)
                  : (Icons.auto_awesome_outlined, ui.liveChat),
            ChatKind.unavailable => (
              Icons.cloud_off_outlined,
              t.paSourceUnavailable,
            ),
            ChatKind.error => (Icons.error_outline, t.paSourceError),
          };
    final actions = [
      for (final a in message.actions)
        if (canOfferAssistantAction(user, a)) a,
    ];
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
              message.isGreeting ? t.careNavigatorGreeting : message.text,
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
            if (message.kind == ChatKind.live && aboutDocument) ...[
              const SizedBox(height: Space.xs),
              Text(t.paLiveDraftDisclaimer, style: small),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final a in actions)
                    FilledButton.tonalIcon(
                      key: ValueKey('assistant-action-${a.id}'),
                      onPressed: onAction == null ? null : () => onAction!(a),
                      icon: Icon(switch (a) {
                        AssistantAction.openAppointments =>
                          Icons.calendar_month_outlined,
                        AssistantAction.bookAppointment =>
                          Icons.event_available_outlined,
                        AssistantAction.openRecords => Icons.folder_outlined,
                        AssistantAction.uploadReport => Icons.attach_file,
                        AssistantAction.openMessages => Icons.forum_outlined,
                        AssistantAction.openMedications =>
                          Icons.medication_outlined,
                        AssistantAction.openSickLeave =>
                          Icons.assignment_outlined,
                        AssistantAction.openProfile =>
                          Icons.account_circle_outlined,
                      }, size: 18),
                      label: Text(a.label(arabic: message.arabic)),
                    ),
                ],
              ),
            ],
            if (message.retryQuestion != null)
              Wrap(
                spacing: Space.xs,
                children: [
                  if (onRetry != null)
                    TextButton.icon(
                      key: const ValueKey('chat-retry'),
                      onPressed: () => onRetry!(message.retryQuestion!),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(t.tryAgain),
                    ),
                  if (onEdit != null)
                    TextButton.icon(
                      key: const ValueKey('chat-edit'),
                      onPressed: () => onEdit!(message.retryQuestion!),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(ui.editMessage),
                    ),
                ],
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
        key: const ValueKey('assistant-typing'),
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
