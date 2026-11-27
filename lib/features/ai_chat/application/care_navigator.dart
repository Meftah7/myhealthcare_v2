/// The Care Navigator — the MyHealth assistant. It:
///  1. helps the patient use the app — ordinary conversation through the
///     MyHealth AI service when it is available, else a labelled on-device
///     guide — and offers real buttons to screens ([AssistantAction]);
///  2. summarizes a document the patient attaches (see
///     [documentAttachmentProvider]) and looks up what it states.
/// It answers no medical questions.
///
/// Every message is handled in this order: an explicit emergency gets the
/// fixed emergency message; a medical question (including asking what a
/// document's value means) gets the fixed refusal with "Message my doctor"
/// and "Book an appointment"; "where do I…?" gets the screen's button; with
/// a document attached the question is a factual lookup; anything else is
/// ordinary conversation. The gateway enforces the medical rule again on
/// its side.
///
/// No AI provider is called from the device and no provider key lives here.
/// Requests carry a generation number and a cancel token, so a reset,
/// sign-out or account switch discards late replies. Documents, questions
/// and replies are never logged.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../services/ai/report_ai_client.dart';
import '../../../services/pdf/pdf_text.dart';
import '../../auth/application/session.dart';
import '../../care/application/care_providers.dart';
import 'assistant_actions.dart';
import 'assistant_connection.dart';
import 'assistant_policy.dart';
import 'document_attachment.dart';
import 'report_reader.dart';

enum ChatRole { user, model }

/// What produced a model message — shown as a label in the chat.
enum ChatKind {
  /// A fixed reply or the on-device guide.
  guide,

  /// Made on this device from the document's text (not AI).
  summary,

  /// A reply from the MyHealth AI service.
  live,

  /// The capability is not connected in this build.
  unavailable,

  /// A live request failed; [ChatMessage.retryQuestion] can be retried.
  error,
}

class ChatMessage {
  const ChatMessage(
    this.role,
    this.text, {
    this.isEmergency = false,
    this.kind = ChatKind.guide,
    this.quotes = const [],
    this.supported,
    this.note,
    this.retryQuestion,
    this.isGreeting = false,
    this.actions = const [],
    this.arabic = false,
    this.isMedicalRefusal = false,
    this.isDocument = false,
  });

  final ChatRole role;
  final String text;
  final bool isEmergency;
  final ChatKind kind;

  /// Excerpts verified on the server to appear verbatim in the document.
  final List<String> quotes;

  /// For document lookups: false when the document does not say.
  final bool? supported;

  /// Coverage / mode disclosure shown under the message.
  final String? note;

  /// For [ChatKind.error]: the message to send again (also offered back to
  /// the input so the draft is never lost).
  final String? retryQuestion;

  /// The opening welcome, shown from the app's translations.
  final bool isGreeting;

  /// Buttons under the message. Shown only when the signed-in patient may
  /// open the destination; nothing happens until they tap.
  final List<AssistantAction> actions;

  /// The message is in Arabic: its button labels are too.
  final bool arabic;

  /// The fixed reply to a medical question.
  final bool isMedicalRefusal;

  /// The patient's "summarize this document" turn (not a chat question).
  final bool isDocument;
}

const _greeting = ChatMessage(
  ChatRole.model,
  'Hi! Ask me how to find something in the app, or attach a document '
  '(PDF, Word or text) to get a short summary.',
  isGreeting: true,
);

ChatMessage _emergencyReply(bool arabic) => ChatMessage(
  ChatRole.model,
  AssistantText.emergency(arabic),
  isEmergency: true,
  arabic: arabic,
);

/// The document a conversation is about. [text] stays in memory only for
/// the life of the conversation (never persisted or logged).
class ReportContext {
  const ReportContext({
    required this.id,
    required this.title,
    required this.text,
    required this.extractionPartial,
  });

  final String id;
  final String title;
  final String text;

  /// The on-device extraction hit its cap, so the text itself is incomplete.
  final bool extractionPartial;
}

class CareNavigatorState {
  const CareNavigatorState({
    required this.messages,
    this.sending = false,
    this.reportContext,
  });
  final List<ChatMessage> messages;

  /// A chat message is on its way (attachments have their own state).
  final bool sending;

  /// The document under discussion, or null.
  final ReportContext? reportContext;

  ({String id, String title})? get report => reportContext == null
      ? null
      : (id: reportContext!.id, title: reportContext!.title);

  CareNavigatorState copyWith({List<ChatMessage>? messages, bool? sending}) =>
      CareNavigatorState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        reportContext: reportContext,
      );
}

/// Whether the live AI service answered its readiness check.
final careNavigatorLiveProvider = FutureProvider<bool>(
  (ref) async =>
      await ref.watch(assistantConnectionProvider.future) ==
      GatewayReadiness.available,
);

class CareNavigator extends Notifier<CareNavigatorState> {
  int _generation = 0;
  CancelToken? _cancel;

  @override
  CareNavigatorState build() {
    // A new account (sign-out, switch, linked-account change) starts a fresh
    // conversation: no document text or replies carry over between patients.
    ref.watch(currentUserProvider.select((u) => u?.id));
    _invalidate();
    ref.onDispose(_invalidate);
    return const CareNavigatorState(messages: [_greeting]);
  }

  void _invalidate() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
  }

  void _log({required bool live}) => unawaited(
    ref
        .read(aiUsageRepositoryProvider)
        .log(
          feature: AiFeature.careNavigator,
          usedLiveModel: live,
          userId: ref.read(currentUserProvider)?.id,
        ),
  );

  void _append(ChatMessage message) =>
      state = state.copyWith(messages: [...state.messages, message]);

  /// The patient's earlier turns, for follow-up detection.
  List<PolicyTurn> _policyHistory() => [
    for (final m in state.messages)
      if (!m.isGreeting && !m.isDocument)
        (fromPatient: m.role == ChatRole.user, text: m.text),
  ];

  /// Sends [raw]. Returns false (and changes nothing) when it is empty or a
  /// message is already on its way — so the input keeps the draft.
  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return false;
    final history = _policyHistory();
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(ChatRole.user, text)],
    );
    unawaited(_handle(text, history));
    return true;
  }

  Future<void> _handle(String text, List<PolicyTurn> history) async {
    final arabic = isArabicText(text);
    final aboutReport = state.reportContext != null;

    if (isEmergencyStatement(text)) {
      _append(_emergencyReply(arabic));
      return;
    }

    // Medical questions — including asking what a document's value means —
    // get the fixed refusal and the ways to a clinician. Navigation in the
    // same message ("…and book an appointment") is covered by those buttons.
    if (isMedicalQuestion(text, history: history, hasDocument: aboutReport)) {
      await _refuseMedical(arabic);
      return;
    }

    // A summary asked for with no document attached: attach one first.
    if (!aboutReport && isSummaryRequest(text)) {
      _append(
        ChatMessage(
          ChatRole.model,
          AssistantText.noReport(arabic),
          arabic: arabic,
          actions: const [AssistantAction.uploadReport],
        ),
      );
      _log(live: false);
      return;
    }

    // "Where do I…?" — the screen's button; no document needed.
    final places = navigationRequests(text, aboutReport: aboutReport);
    if (places.isNotEmpty) {
      _append(
        ChatMessage(
          ChatRole.model,
          places.map((a) => AssistantText.navigation(a, arabic)).join('\n'),
          arabic: arabic,
          actions: places,
        ),
      );
      _log(live: false);
      return;
    }

    if (aboutReport) {
      if (isSmallTalk(text)) {
        _append(
          ChatMessage(
            ChatRole.model,
            AssistantText.reportHint(arabic),
            arabic: arabic,
          ),
        );
        return;
      }
      await _askAboutReport(text);
      return;
    }

    await _converse(text);
  }

  /// The fixed reply to a medical question, with "Message my doctor" when
  /// the patient can message a doctor (else the eligibility rule) and "Book
  /// an appointment".
  Future<void> _refuseMedical(bool arabic) async {
    final generation = _generation;
    var canMessage = false;
    try {
      canMessage = (await ref.read(
        messageableDoctorsProvider.future,
      )).isNotEmpty;
    } on Object {
      canMessage = false;
    }
    if (generation != _generation) return;
    _append(
      ChatMessage(
        ChatRole.model,
        AssistantText.medical(arabic),
        arabic: arabic,
        isMedicalRefusal: true,
        note: canMessage ? null : AssistantText.messagingEligibility(arabic),
        actions: [
          if (canMessage) AssistantAction.openMessages,
          AssistantAction.bookAppointment,
        ],
      ),
    );
    _log(live: false);
  }

  /// Ordinary conversation: the live service when it answered its
  /// readiness check, else the labelled on-device guide.
  Future<void> _converse(String text) async {
    final generation = _generation;
    final readiness = await ref
        .read(assistantConnectionProvider.notifier)
        .current();
    if (generation != _generation) return;
    if (readiness != GatewayReadiness.available) {
      _append(_offlineReply(text, isArabicText(text)));
      _log(live: false);
      return;
    }
    // Earlier ordinary-conversation turns; the current message is sent once,
    // as the message itself.
    final turns = <ReportTurn>[
      for (final m in state.messages)
        if (m.role == ChatRole.user && !m.isDocument)
          ReportTurn(fromPatient: true, text: m.text)
        else if (m.role == ChatRole.model &&
            m.kind == ChatKind.live &&
            m.quotes.isEmpty)
          ReportTurn(fromPatient: false, text: m.text),
    ];
    if (turns.isNotEmpty && turns.last.fromPatient && turns.last.text == text) {
      turns.removeLast();
    }
    final cancel = CancelToken();
    _cancel = cancel;
    state = state.copyWith(sending: true);
    try {
      final reply = await ref
          .read(reportAiClientProvider)
          .chat(message: text, history: turns, cancelToken: cancel);
      if (generation != _generation) return;
      final arabic = isArabicText(text);
      if (reply.emergency) {
        _append(_emergencyReply(arabic));
      } else if (reply.medical) {
        state = state.copyWith(sending: false);
        await _refuseMedical(arabic);
        return;
      } else {
        _append(
          ChatMessage(
            ChatRole.model,
            reply.reply,
            kind: ChatKind.live,
            arabic: arabic,
            actions: [
              for (final id in reply.actions) ?AssistantAction.fromId(id),
            ],
          ),
        );
      }
      _log(live: true);
    } on ReportAiException catch (e) {
      if (generation != _generation ||
          e.kind == ReportAiFailureKind.cancelled) {
        return;
      }
      ref.read(assistantConnectionProvider.notifier).reportFailure(e.kind);
      _append(
        ChatMessage(
          ChatRole.model,
          reportAiFailureMessage(e.kind),
          kind: ChatKind.error,
          retryQuestion: text,
        ),
      );
    } finally {
      if (generation == _generation) state = state.copyWith(sending: false);
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  /// Sends a failed message again, without adding it to the conversation a
  /// second time.
  Future<void> retry(String question) async {
    if (state.sending) return;
    final messages = [...state.messages];
    if (messages.isNotEmpty &&
        messages.last.kind == ChatKind.error &&
        messages.last.retryQuestion == question) {
      messages.removeLast();
      state = state.copyWith(messages: messages);
    }
    await _handle(question, _policyHistory());
  }

  /// Leaves the document conversation.
  void leaveReport() => reset();

  /// Starts over: cancels anything in flight, the attachment included.
  void reset() {
    _invalidate();
    ref.read(documentAttachmentProvider.notifier).remove();
    state = const CareNavigatorState(messages: [_greeting]);
  }

  /// A factual question about the attached document.
  Future<void> _askAboutReport(String question) async {
    final context = state.reportContext!;
    final generation = _generation;
    final readiness = await ref
        .read(assistantConnectionProvider.notifier)
        .current();
    if (generation != _generation || !_sameReport(context)) return;
    if (readiness != GatewayReadiness.available) {
      _append(_answerOnDevice(context, question));
      _log(live: false);
      return;
    }
    if (question.length > ReportAiLimits.maxQuestionChars) {
      _append(
        const ChatMessage(
          ChatRole.model,
          'Please ask a shorter question (up to 1,000 characters).',
          kind: ChatKind.error,
        ),
      );
      return;
    }
    // Authorization before anything leaves the device: the record must still
    // be readable by whoever is signed in now.
    if (!await _stillAuthorized(context.id)) {
      if (generation == _generation) reset();
      return;
    }
    final history = <ReportTurn>[
      for (final m in state.messages)
        if (m.role == ChatRole.user && !m.isDocument)
          ReportTurn(fromPatient: true, text: m.text)
        else if (m.role == ChatRole.model && m.kind == ChatKind.live)
          ReportTurn(fromPatient: false, text: m.text),
    ];
    if (history.isNotEmpty && history.last.fromPatient) history.removeLast();

    final cancel = CancelToken();
    _cancel = cancel;
    state = state.copyWith(sending: true);
    try {
      final answer = await ref
          .read(reportAiClientProvider)
          .ask(
            reportText: context.text,
            question: question,
            history: history,
            cancelToken: cancel,
          );
      if (generation != _generation || !_sameReport(context)) return;
      final arabic = isArabicText(question);
      if (answer.refusal) {
        state = state.copyWith(sending: false);
        await _refuseMedical(arabic);
        return;
      }
      final actions = [
        for (final id in {...answer.actions, ?answer.action})
          ?AssistantAction.fromId(id),
      ];
      _append(
        ChatMessage(
          ChatRole.model,
          // An unsupported answer is never shown in the model's words.
          answer.supported || actions.isNotEmpty
              ? answer.answer
              : AssistantText.notFound(arabic),
          kind: ChatKind.live,
          quotes: answer.supported ? answer.quotes : const [],
          supported: answer.supported,
          note: _coverageNote(
            answer.coverage,
            context.extractionPartial,
            arabic: arabic,
          ),
          arabic: arabic,
          actions: actions,
        ),
      );
      _log(live: true);
    } on ReportAiException catch (e) {
      if (generation != _generation ||
          !_sameReport(context) ||
          e.kind == ReportAiFailureKind.cancelled) {
        return;
      }
      ref.read(assistantConnectionProvider.notifier).reportFailure(e.kind);
      _append(
        ChatMessage(
          ChatRole.model,
          reportAiFailureMessage(e.kind),
          kind: ChatKind.error,
          retryQuestion:
              e.kind == ReportAiFailureKind.unavailable ||
                  e.kind == ReportAiFailureKind.rejected
              ? null
              : question,
        ),
      );
    } finally {
      if (generation == _generation) state = state.copyWith(sending: false);
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  /// A factual question answered on this device from the document's own
  /// lines, labelled as not AI.
  ChatMessage _answerOnDevice(ReportContext context, String question) {
    final arabic = isArabicText(question);
    final asksSummary = RegExp(
      r'\b(summari[sz]e|summary|overview)\b|لخص|لخّص|ملخص',
      caseSensitive: false,
    ).hasMatch(question);
    if (asksSummary) {
      return ChatMessage(
        ChatRole.model,
        summarizeReportOnDevice(context.text, title: context.title),
        kind: ChatKind.summary,
        arabic: arabic,
      );
    }
    final found = answerFromReportOnDevice(
      context.text,
      question,
      arabic: arabic,
    );
    return ChatMessage(
      ChatRole.model,
      found?.answer ?? AssistantText.notFound(arabic),
      kind: ChatKind.summary,
      quotes: found?.quotes ?? const [],
      supported: found != null,
      note: context.extractionPartial ? AssistantText.partial(arabic) : null,
      arabic: arabic,
    );
  }

  bool _sameReport(ReportContext context) =>
      identical(state.reportContext, context);

  Future<bool> _stillAuthorized(String recordId) async =>
      (await ref.read(recordRepositoryProvider).byId(recordId)).isOk;

  /// Shows an attachment's summary (from the attachment flow) and makes the
  /// document the subject of follow-up questions. [reason] is why it was
  /// made on the device, when it was.
  void showDocumentSummary({
    required MedicalRecord record,
    required String fileName,
    required String overview,
    required List<String> points,
    required bool live,
    required bool partial,
    List<String> quotes = const [],
    GatewayReadiness? reason,
  }) {
    _invalidate();
    final arabic = _appInArabic();
    final text = (record.extractedText ?? '').trim();
    final context = ReportContext(
      id: record.id,
      title: record.title,
      text: text,
      extractionPartial: text.length >= maxExtractedChars,
    );
    // Another document starts a clean conversation, so answers about one
    // document are never mixed with another's.
    final previous =
        state.reportContext != null && state.reportContext!.id != record.id
        ? const [_greeting]
        : state.messages;
    final body = [overview, for (final p in points) '• $p'].join('\n');
    state = CareNavigatorState(
      reportContext: context,
      messages: [
        ...previous,
        ChatMessage(ChatRole.user, '📎 $fileName', isDocument: true),
        ChatMessage(
          ChatRole.model,
          live ? body : '$basicSummaryLabel\n\n$body',
          kind: live ? ChatKind.live : ChatKind.summary,
          quotes: quotes,
          arabic: arabic,
          note: [
            if (partial) AssistantText.partial(arabic),
            if (!live && reason != null) offlineReason(reason, arabic),
          ].whereType<String>().join('\n').let((n) => n.isEmpty ? null : n),
        ),
      ],
    );
    _log(live: live);
  }

  /// Summarizes a record already in Records (the earlier "explain" flow):
  /// the live service when available, else this device.
  Future<void> explainDocument(MedicalRecord record) async {
    if (state.sending) return;
    if (!await _stillAuthorized(record.id)) return;
    final text = (record.extractedText ?? '').trim();
    final arabic = _appInArabic();
    if (text.isEmpty) {
      _append(_unreadableReply(arabic));
      return;
    }
    final generation = _generation;
    final readiness = await ref
        .read(assistantConnectionProvider.notifier)
        .current();
    if (generation != _generation) return;
    if (readiness != GatewayReadiness.available) {
      final s = summarizeDocumentOnDevice(text, title: record.title);
      showDocumentSummary(
        record: record,
        fileName: record.title,
        overview: s.overview,
        points: s.points,
        live: false,
        partial: text.length >= maxExtractedChars,
        reason: readiness,
      );
      return;
    }
    state = state.copyWith(sending: true);
    try {
      final explanation = await ref
          .read(reportAiClientProvider)
          .explain(text, arabic: arabic);
      if (generation != _generation) return;
      state = state.copyWith(sending: false);
      if (!explanation.readable) {
        _append(_unreadableReply(arabic));
        return;
      }
      final lines = explanation.answer.split('\n');
      showDocumentSummary(
        record: record,
        fileName: record.title,
        overview: lines.first,
        points: [
          for (final l in lines.skip(1))
            if (l.trim().isNotEmpty) l.replaceFirst(RegExp(r'^•\s*'), ''),
        ],
        quotes: explanation.quotes,
        live: true,
        partial:
            !explanation.coverage.complete || text.length >= maxExtractedChars,
      );
    } on ReportAiException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(sending: false);
      ref.read(assistantConnectionProvider.notifier).reportFailure(e.kind);
      final s = summarizeDocumentOnDevice(text, title: record.title);
      showDocumentSummary(
        record: record,
        fileName: record.title,
        overview: '${reportAiFailureMessage(e.kind)}\n\n${s.overview}',
        points: s.points,
        live: false,
        partial: text.length >= maxExtractedChars,
      );
    }
  }

  static String? _coverageNote(
    ReportCoverage coverage,
    bool extractionPartial, {
    required bool arabic,
  }) {
    if (!coverage.complete) return clippedReportNote(coverage.totalChars);
    if (extractionPartial) return AssistantText.partial(arabic);
    return null;
  }

  static ChatMessage _unreadableReply(bool arabic) => ChatMessage(
    ChatRole.model,
    AssistantText.unreadable(arabic),
    arabic: arabic,
    actions: const [AssistantAction.uploadReport],
  );

  /// The app's language (a summary has no patient wording to follow).
  bool _appInArabic() => Intl.getCurrentLocale().startsWith('ar');

  /// The on-device guide, clearly labelled — used when the live service is
  /// not available. Never presented as an AI reply.
  ChatMessage _offlineReply(String text, bool arabic) {
    final readiness = ref.read(assistantReadinessProvider);
    final note = offlineReason(readiness, arabic);
    if (arabic) {
      return ChatMessage(
        ChatRole.model,
        AssistantText.fallbackArabic,
        arabic: true,
        note: note,
        actions: const [
          AssistantAction.openAppointments,
          AssistantAction.openRecords,
          AssistantAction.openMessages,
          AssistantAction.uploadReport,
        ],
      );
    }
    final t = text.toLowerCase();
    bool has(List<String> ws) => ws.any(t.contains);
    ChatMessage say(String reply) =>
        ChatMessage(ChatRole.model, reply, note: note);

    if (has(['bill', 'invoice', 'pay', 'payment', 'wallet', 'owe'])) {
      return say(
        'Billing & Payments is marked as future work in this version of '
        'myhealth, so bills and payments are not available here yet.',
      );
    }
    if (has(['nutrition', 'calorie', 'macro', 'meal'])) {
      return say(
        'Nutrition is marked as future work in this version of myhealth. '
        'You can find it under Services.',
      );
    }
    if (has(['notification', 'alert', 'reminder', 'unread'])) {
      return say(
        'Tap the bell at the top of Home to open your Notifications — '
        'appointment reminders and results land there.',
      );
    }
    return ChatMessage(
      ChatRole.model,
      'I can take you to Appointments, Records, Messages or your Medications, '
      'or summarize a document you attach. Which would you like?',
      note: note,
      actions: const [
        AssistantAction.openAppointments,
        AssistantAction.openRecords,
        AssistantAction.openMessages,
        AssistantAction.uploadReport,
      ],
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// Why a reply was made on this device instead of by the AI service.
String? offlineReason(
  GatewayReadiness readiness,
  bool arabic,
) => switch (readiness) {
  GatewayReadiness.available || GatewayReadiness.checking => null,
  GatewayReadiness.unconfigured =>
    arabic
        ? 'تم الرد على هذا الجهاز: خدمة الذكاء الاصطناعي غير مُعدّة في هذا الإصدار.'
        : 'Answered on this device: the AI service is not set up in this '
              'version.',
  GatewayReadiness.unreachable =>
    arabic
        ? 'تم الرد على هذا الجهاز: تعذّر الوصول إلى خدمة الذكاء الاصطناعي.'
        : 'Answered on this device: the AI service could not be reached.',
  GatewayReadiness.unauthorized =>
    arabic
        ? 'تم الرد على هذا الجهاز: خدمة الذكاء الاصطناعي لا تتعرّف على هذا التطبيق.'
        : 'Answered on this device: the AI service does not recognise '
              'this app.',
  GatewayReadiness.providerUnavailable =>
    arabic
        ? 'تم الرد على هذا الجهاز: خدمة الذكاء الاصطناعي غير متاحة الآن.'
        : 'Answered on this device: the AI service is not available right '
              'now.',
};

/// Live explanations read at most this many characters of a report.
const kReportExplainLimit = 12000;

const basicSummaryLabel =
    'Summary made on this device from the document text (not AI):';

/// A plain account of why a live request did not produce an answer.
String reportAiFailureMessage(ReportAiFailureKind kind) => switch (kind) {
  ReportAiFailureKind.unavailable =>
    "The AI service isn't set up in this version of the app.",
  ReportAiFailureKind.providerUnavailable =>
    "The AI service isn't available right now. You can try again later.",
  ReportAiFailureKind.unauthorized =>
    "The AI service doesn't recognise this app, so it can't answer.",
  ReportAiFailureKind.timeout =>
    'The AI service took too long to answer. You can try again.',
  ReportAiFailureKind.provider =>
    "The AI service couldn't produce an answer. You can try again.",
  ReportAiFailureKind.invalidResponse =>
    "The AI service sent an answer the app couldn't read. You can try again.",
  ReportAiFailureKind.rateLimited =>
    'Too many requests in a short time. Please wait a minute and try again.',
  ReportAiFailureKind.rejected =>
    "That request couldn't be sent (it may be too long).",
  ReportAiFailureKind.network =>
    "Couldn't reach the AI service. Check your connection and try again.",
  ReportAiFailureKind.cancelled => 'Cancelled.',
};

/// Disclosed whenever a lookup read only part of a long document.
String clippedReportNote(int length) =>
    'Note: this document is long, so only its first $kReportExplainLimit of '
    '$length characters were searched. Open the original in your Records '
    'for the full document.';

/// A plain summary of a document's text without an AI service (see
/// [summarizeReportOnDevice]).
String explainDocumentOffline(String text, {required String title}) =>
    summarizeReportOnDevice(text, title: title);

final careNavigatorProvider =
    NotifierProvider<CareNavigator, CareNavigatorState>(CareNavigator.new);

/// How the floating widget is showing:
///  - [edge]  the mascot's head peeking in from the nearest side (docked)
///  - [fab]   the round mascot button, ready to open
///  - [panel] the chat panel is open
/// Kept out of [CareNavigator] so toggling it doesn't rebuild the conversation.
enum CareNavView { edge, fab, panel }

final careNavigatorViewProvider = StateProvider<CareNavView>(
  (_) => CareNavView.fab,
);

/// Where the patient has parked the floating button. [dx] / [dy] are fractions
/// (0–1) of the free area (the safe area above the bottom navigation) — `dx`
/// is which side it gravitates to, `dy` its height. The default is the
/// lower-right corner, just above the bottom navigation. Persisted per device
/// so it stays where they put it.
class CareNavPlacement {
  const CareNavPlacement({this.dx = 1, this.dy = 1});

  final double dx;
  final double dy;

  /// The button (and, once docked, the head) sits on the right half.
  bool get onRight => dx >= 0.5;

  CareNavPlacement copyWith({double? dx, double? dy}) => CareNavPlacement(
    dx: (dx ?? this.dx).clamp(0.0, 1.0),
    dy: (dy ?? this.dy).clamp(0.0, 1.0),
  );

  /// Snap [dx] to whichever side is nearer — used when the button is released
  /// or the widget is dismissed to the edge.
  CareNavPlacement snappedToSide() => copyWith(dx: onRight ? 1 : 0);
}

const _placementKey = 'ui.careNav.placement';

class CareNavPlacementController extends Notifier<CareNavPlacement> {
  @override
  CareNavPlacement build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_placementKey);
    if (raw == null) return const CareNavPlacement();
    final parts = raw.split(',');
    if (parts.length != 2) return const CareNavPlacement();
    return CareNavPlacement(
      dx: double.tryParse(parts[0]) ?? 1,
      dy: double.tryParse(parts[1]) ?? 1,
    );
  }

  void drag({double? dx, double? dy}) => state = state.copyWith(dx: dx, dy: dy);

  /// Persist the final resting place (called on drag end).
  Future<void> settle({bool snapToSide = false}) async {
    if (snapToSide) state = state.snappedToSide();
    await ref
        .read(sharedPreferencesProvider)
        .setString(_placementKey, '${state.dx},${state.dy}');
  }
}

final careNavPlacementProvider =
    NotifierProvider<CareNavPlacementController, CareNavPlacement>(
      CareNavPlacementController.new,
    );
