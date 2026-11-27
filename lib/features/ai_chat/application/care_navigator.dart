/// The Care Navigator — the MyHealth Report Assistant. Two jobs:
///  1. summarize the patient's selected PDF and answer questions about what
///     that PDF says (grounded, quoted, never advice);
///  2. guide the patient to an existing screen with a real button
///     ([AssistantAction]) — the app picks the label, checks access and
///     navigates only when they tap.
///
/// Every message is handled in this order: an explicit emergency gets the
/// fixed emergency message; a request for a diagnosis, advice or a medicine
/// change gets the fixed decline (with Open Appointments); "where do I…?"
/// gets the screen's button — no PDF needed; then, with a report selected,
/// the question goes to the report AI ([assistant_policy.dart]).
///
/// No AI provider is called from the device and no provider key lives here.
/// Summaries and answers go through the MyHealth report AI gateway
/// ([reportAiClientProvider]); without it, summaries are a clearly labelled
/// on-device summary and report questions say the service is not connected —
/// never canned answers. Report text and questions are never logged.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../services/ai/report_ai_client.dart';
import '../../../services/pdf/pdf_text.dart';
import '../../auth/application/session.dart';
import 'assistant_actions.dart';
import 'assistant_policy.dart';

enum ChatRole { user, model }

/// What produced a model message — shown as a label in the chat.
enum ChatKind {
  /// The deterministic navigation guide.
  guide,

  /// The on-device keyword summary of a report (not AI).
  summary,

  /// A live AI draft from the report AI service.
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
  });

  final ChatRole role;
  final String text;
  final bool isEmergency;
  final ChatKind kind;

  /// Excerpts verified on the server to appear verbatim in the report.
  final List<String> quotes;

  /// For live answers: false when the report does not answer the question.
  final bool? supported;

  /// Coverage / extraction disclosure shown under the message.
  final String? note;

  /// For [ChatKind.error] on a follow-up: the question to retry.
  final String? retryQuestion;

  /// The opening welcome. The chat shows it from the app's translations
  /// (`careNavigatorGreeting`) so it follows the chosen language; [text] is
  /// the English copy for anything outside the UI.
  final bool isGreeting;

  /// Buttons under the message. Shown only when the signed-in patient may
  /// open the destination; nothing happens until they tap.
  final List<AssistantAction> actions;

  /// The message is in Arabic: its button labels are too.
  final bool arabic;
}

const _greeting = ChatMessage(
  ChatRole.model,
  "Hi! I'm here to help you use the app. Ask me about your appointments, "
  'records, medicines or bills.',
  isGreeting: true,
);

/// The fixed emergency message: local emergency services, no assessment and
/// no button to a routine booking.
ChatMessage _emergencyReply(bool arabic) => ChatMessage(
  ChatRole.model,
  AssistantText.emergency(arabic),
  isEmergency: true,
  arabic: arabic,
);

/// The report a conversation is about. [text] stays in memory only for the
/// life of the conversation (never persisted or logged).
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

  /// The on-device extraction hit its cap, so the report text itself is
  /// incomplete.
  final bool extractionPartial;
}

class CareNavigatorState {
  const CareNavigatorState({
    required this.messages,
    this.sending = false,
    this.reportContext,
  });
  final List<ChatMessage> messages;
  final bool sending;

  /// The report under discussion, or null for navigation help.
  final ReportContext? reportContext;

  /// The report shown in the chat header (with a link to its original).
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

/// Whether live report AI is connected in this build (header status).
final careNavigatorLiveProvider = FutureProvider<bool>(
  (ref) async => ref.watch(reportAiClientProvider).isConfigured,
);

class CareNavigator extends Notifier<CareNavigatorState> {
  @override
  CareNavigatorState build() {
    // A new account (sign-out, switch, linked-account change) starts a fresh
    // conversation: no report text or replies carry over between patients.
    ref.watch(currentUserProvider.select((u) => u?.id));
    return const CareNavigatorState(messages: [_greeting]);
  }

  void _log({required bool live}) => unawaited(
    ref
        .read(aiUsageRepositoryProvider)
        .log(
          feature: AiFeature.careNavigator,
          usedLiveModel: live,
          userId: ref.read(currentUserProvider)?.id,
          // Never the report text or the patient's question.
          summary: null,
        ),
  );

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(ChatRole.user, text)],
    );
    final arabic = isArabicText(text);
    final aboutReport = state.reportContext != null;

    if (isEmergencyStatement(text)) {
      _append(_emergencyReply(arabic));
      return;
    }

    // Diagnosis, advice, urgency or a medicine change: declined, with the
    // way to a clinician. A second part asking for a screen still gets its
    // button ("Do I need medication, and where can I book?").
    if (isAdviceRequest(text)) {
      _append(
        ChatMessage(
          ChatRole.model,
          AssistantText.advice(arabic),
          arabic: arabic,
          actions: {
            AssistantAction.openAppointments,
            ...navigationRequests(text, aboutReport: false),
          }.toList(),
        ),
      );
      _log(live: false);
      return;
    }

    // A summary asked for with no report selected: choose one first.
    if (!aboutReport && isSummaryRequest(text)) {
      _append(
        ChatMessage(
          ChatRole.model,
          AssistantText.noReport(arabic),
          arabic: arabic,
          actions: {
            AssistantAction.uploadReport,
            ...navigationRequests(
              text,
              aboutReport: false,
            ).where((a) => a != AssistantAction.openRecords),
          }.toList(),
        ),
      );
      _log(live: false);
      return;
    }

    // "Where do I…?" — the screen's button; no PDF needed.
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
      await _askAboutReport(text);
      return;
    }

    // Anything else: the deterministic guide to the app's other areas.
    _append(
      arabic
          ? const ChatMessage(
              ChatRole.model,
              AssistantText.fallbackArabic,
              arabic: true,
              actions: [
                AssistantAction.openAppointments,
                AssistantAction.openRecords,
                AssistantAction.uploadReport,
              ],
            )
          : _offlineReply(text),
    );
    _log(live: false);
  }

  /// Retries a failed follow-up question.
  Future<void> retry(String question) async {
    if (state.sending || state.reportContext == null) return;
    await _askAboutReport(question);
  }

  /// Leaves the report conversation and returns to navigation help.
  void leaveReport() => reset();

  void reset() => state = const CareNavigatorState(messages: [_greeting]);

  Future<void> _askAboutReport(String question) async {
    final context = state.reportContext!;
    final client = ref.read(reportAiClientProvider);
    if (!client.isConfigured) {
      _append(
        const ChatMessage(
          ChatRole.model,
          'Questions about this report need the myhealth report AI service, '
          "which isn't connected in this version of the app. The summary above "
          'was made on this device, and your doctor can answer questions about '
          'the report.',
          kind: ChatKind.unavailable,
        ),
      );
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
      reset();
      return;
    }
    // Earlier turns of this report conversation (live answers and the
    // patient's questions), bounded by the client.
    final history = <ReportTurn>[
      for (final m in state.messages)
        if (m.role == ChatRole.user && !m.text.startsWith('📄 '))
          ReportTurn(fromPatient: true, text: m.text)
        else if (m.role == ChatRole.model && m.kind == ChatKind.live)
          ReportTurn(fromPatient: false, text: m.text),
    ];
    // The current question is the last user message; don't send it twice.
    if (history.isNotEmpty && history.last.fromPatient) history.removeLast();

    state = state.copyWith(sending: true);
    try {
      final answer = await client.ask(
        reportText: context.text,
        question: question,
        history: history,
      );
      if (!_sameReport(context)) return;
      final arabic = isArabicText(question);
      final action = AssistantAction.fromId(answer.action);
      final actions = [?action];
      if (answer.refusal) {
        // The fixed decline from the gateway, with the way to a clinician.
        _append(
          ChatMessage(
            ChatRole.model,
            answer.answer,
            arabic: arabic,
            actions: {AssistantAction.openAppointments, ...actions}.toList(),
          ),
        );
      } else {
        _append(
          ChatMessage(
            ChatRole.model,
            // An unsupported answer is never shown in the model's words: the
            // gateway sends the fixed message (or a screen's text, with its
            // button); this keeps it so even for an older gateway.
            answer.supported || action != null
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
      }
      _log(live: true);
    } on ReportAiException catch (e) {
      if (!_sameReport(context)) return;
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
      if (_sameReport(context)) state = state.copyWith(sending: false);
    }
  }

  bool _sameReport(ReportContext context) =>
      identical(state.reportContext, context);

  void _append(ChatMessage message) =>
      state = state.copyWith(messages: [...state.messages, message]);

  Future<bool> _stillAuthorized(String recordId) async =>
      (await ref.read(recordRepositoryProvider).byId(recordId)).isOk;

  /// The patient uploaded [record] (a PDF): explain it in plain words —
  /// live when the report AI service is connected, otherwise the labelled
  /// on-device summary. Never a diagnosis.
  Future<void> explainDocument(MedicalRecord record) async {
    if (state.sending) return;
    if (!await _stillAuthorized(record.id)) return;
    final text = (record.extractedText ?? '').trim();
    final context = ReportContext(
      id: record.id,
      title: record.title,
      text: text,
      extractionPartial: text.length >= maxExtractedChars,
    );
    // A different report starts a clean conversation, so answers about one
    // report are never mixed with another's.
    final previous =
        state.reportContext != null && state.reportContext!.id != record.id
        ? const [_greeting]
        : state.messages;
    state = CareNavigatorState(
      sending: true,
      reportContext: context,
      messages: [...previous, ChatMessage(ChatRole.user, '📄 ${record.title}')],
    );

    final arabic = _appInArabic();
    if (text.isEmpty) {
      _append(_unreadableReply(arabic));
      state = state.copyWith(sending: false);
      return;
    }

    final client = ref.read(reportAiClientProvider);
    ChatMessage reply;
    var live = false;
    if (client.isConfigured) {
      try {
        final explanation = await client.explain(text, arabic: arabic);
        if (!explanation.readable) {
          reply = _unreadableReply(arabic);
        } else {
          final partial =
              !explanation.coverage.complete || context.extractionPartial;
          reply = ChatMessage(
            ChatRole.model,
            partial
                ? '${AssistantText.partial(arabic)}\n\n${explanation.answer}'
                : explanation.answer,
            kind: ChatKind.live,
            quotes: explanation.quotes,
            arabic: arabic,
          );
          live = true;
        }
      } on ReportAiException catch (e) {
        reply = ChatMessage(
          ChatRole.model,
          '${reportAiFailureMessage(e.kind)}\n\n$basicSummaryLabel\n\n'
          '${explainDocumentOffline(text, title: record.title)}',
          kind: ChatKind.summary,
        );
      }
    } else {
      reply = ChatMessage(
        ChatRole.model,
        '$basicSummaryLabel\n\n'
        '${explainDocumentOffline(text, title: record.title)}',
        kind: ChatKind.summary,
        note: context.extractionPartial ? AssistantText.partial(arabic) : null,
      );
    }
    if (!_sameReport(context)) return;
    _append(reply);
    state = state.copyWith(sending: false);
    _log(live: live);
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

  /// Nothing readable in the PDF: say so, and offer a clearer copy.
  static ChatMessage _unreadableReply(bool arabic) => ChatMessage(
    ChatRole.model,
    AssistantText.unreadable(arabic),
    arabic: arabic,
    actions: const [AssistantAction.uploadReport],
  );

  /// The app's language (a summary has no patient wording to follow) —
  /// `Intl.defaultLocale` is kept in step with it by the locale setting.
  bool _appInArabic() => Intl.getCurrentLocale().startsWith('ar');

  /// The deterministic guide to the app's other areas (appointments,
  /// records and uploads are buttons, handled before this).
  ChatMessage _offlineReply(String text) {
    final t = text.toLowerCase();
    bool has(List<String> ws) => ws.any(t.contains);
    ChatMessage say(String reply) => ChatMessage(ChatRole.model, reply);

    if (has([
      'bill',
      'invoice',
      'pay',
      'payment',
      'card',
      'wallet',
      'outstanding',
      'owe',
      'transaction',
    ])) {
      return say(
        'Billing & Payments (Home → Quick Access) shows your wallet '
        'balance with '
        'a Top up button, every invoice with a Pay button, and your saved '
        'cards, all in one place.',
      );
    }
    if (has([
      'nutrition',
      'calorie',
      'macro',
      'diet',
      'meal',
      'food',
      'bmr',
      'tdee',
      'weight',
    ])) {
      return say(
        'Nutrition (Home → Quick Access) has three views: Targets works '
        'out your daily '
        'calories and macros, Foods looks up nutrients, and Meal plan suggests '
        'allergen-safe meals.',
      );
    }
    if (has(['notification', 'alert', 'reminder', 'unread'])) {
      return say(
        'Tap the bell at the top of Home to open your Notifications — '
        'appointment reminders, lab results and billing alerts land there.',
      );
    }
    if (has([
      'profile',
      'password',
      'email',
      'phone',
      'family',
      'emergency',
      'blood type',
      'allergy',
      'allergies',
      'setting',
      'theme',
      'language',
    ])) {
      return say(
        'Everything about you is in My Profile (Home → Quick Access, or '
        'tap your picture): personal info, health details, '
        'payments, preferences (theme & language), notification channels and '
        'your family network. Tap a section to expand it.',
      );
    }
    return const ChatMessage(
      ChatRole.model,
      'I can take you to Appointments or Records, summarize a report PDF you '
      'choose, or point you to Nutrition, Payments, Notifications or your '
      'Profile. Which would you like?',
      actions: [
        AssistantAction.openAppointments,
        AssistantAction.openRecords,
        AssistantAction.uploadReport,
      ],
    );
  }
}

/// Live explanations read at most this many characters of a report.
const kReportExplainLimit = 12000;

const basicSummaryLabel =
    'Basic summary (made on this device by matching common test names — '
    'not AI):';

/// A plain account of why a live request did not produce an answer.
String reportAiFailureMessage(ReportAiFailureKind kind) => switch (kind) {
  ReportAiFailureKind.unavailable =>
    "The report AI service isn't available right now.",
  ReportAiFailureKind.timeout =>
    'The report AI service took too long to answer. You can try again.',
  ReportAiFailureKind.provider =>
    "The report AI service couldn't produce an answer. You can try again.",
  ReportAiFailureKind.rateLimited =>
    'Too many questions in a short time. Please wait a minute and try again.',
  ReportAiFailureKind.rejected =>
    "That request couldn't be sent (it may be too long).",
  ReportAiFailureKind.network =>
    "Couldn't reach the report AI service. Check your connection and try again.",
};

/// Disclosed whenever a long report was cut to [kReportExplainLimit] (the
/// server applies the same limit and returns its coverage).
String clippedReportNote(int length) =>
    'Note: this report is long, so only its first $kReportExplainLimit of '
    '$length characters were explained. Open the original in your Records '
    'for the full report.';

/// What common lab tests measure, in plain words — for the offline
/// explanation.
const _plainTests = <String, String>{
  'hba1c': 'average blood sugar over the last 2–3 months',
  'glucose': 'sugar in the blood',
  'cholesterol': 'fat in the blood',
  'ldl': 'the "bad" cholesterol',
  'hdl': 'the "good" cholesterol',
  'triglyceride': 'another type of fat in the blood',
  'hemoglobin': 'the part of red blood cells that carries oxygen',
  'haemoglobin': 'the part of red blood cells that carries oxygen',
  'ferritin': 'the body\'s iron stores',
  'vitamin d': 'vitamin D, important for bones',
  'b12': 'vitamin B12, important for nerves and blood',
  'tsh': 'thyroid function',
  'creatinine': 'how well the kidneys filter',
  'egfr': 'how well the kidneys filter',
  'alt': 'liver health',
  'ast': 'liver health',
  'wbc': 'white blood cells, which fight infection',
  'white blood': 'white blood cells, which fight infection',
  'platelet': 'cells that help blood clot',
  'sodium': 'a salt that balances body fluids',
  'potassium': 'a salt important for the heart and muscles',
  'crp': 'inflammation in the body',
};

/// A plain-language explanation of a document's text without a live model:
/// the tests it mentions, what they measure, and any marked high or low.
String explainDocumentOffline(String text, {required String title}) {
  final lines = text.split(RegExp(r'[\r\n]+'));
  final found = <String, String>{};
  final high = <String>{};
  final low = <String>{};
  for (final raw in lines) {
    final line = raw.toLowerCase();
    for (final MapEntry(key: test, value: meaning) in _plainTests.entries) {
      if (!RegExp('\\b${RegExp.escape(test)}').hasMatch(line)) continue;
      found.putIfAbsent(test, () => meaning);
      if (RegExp(r'\b(high|elevated|h)\b|↑').hasMatch(line)) high.add(test);
      if (RegExp(r'\b(low|decreased|l)\b|↓').hasMatch(line)) low.add(test);
    }
  }
  String name(String t) => t.length <= 4 ? t.toUpperCase() : t;
  final out = StringBuffer('Here is a simple summary of "$title".\n\n');
  if (found.isEmpty) {
    out.write(
      "I couldn't spot specific test results in it, so I can't summarise "
      'the findings myself. ',
    );
  } else {
    out.write('It includes:\n');
    for (final MapEntry(key: t, value: meaning) in found.entries.take(8)) {
      out.write('• ${name(t)} — $meaning\n');
    }
    out.write('\n');
    if (high.isEmpty && low.isEmpty) {
      out.write(
        'Nothing is clearly marked high or low in the text I could read. '
        'That does not confirm the results are normal. ',
      );
    } else {
      if (high.isNotEmpty) {
        out.write('Marked high: ${high.map(name).join(', ')}. ');
      }
      if (low.isNotEmpty) {
        out.write('Marked low: ${low.map(name).join(', ')}. ');
      }
      out.write('One result outside the range is not a diagnosis on its own. ');
    }
  }
  out.write(
    '\n\nIt is saved in your Records, and a clinician will review it. '
    'Please talk it through with your doctor.',
  );
  return out.toString();
}

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
