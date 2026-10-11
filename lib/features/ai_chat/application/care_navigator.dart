/// The Care Navigator — an in-app AI assistant that helps patients find their
/// way around and points medical questions to a real clinician.
///
/// Ported from the FirstSemMyHealth `ai-widget.js` + `ai_chat.php`: same
/// greeting, same emergency-keyword guard, same "navigation helper, not a
/// doctor" behaviour.
///
/// The local app never calls an AI provider from the device: provider keys
/// must stay server-side, and this app has no server session. Navigation help
/// is a deterministic guide and report explanations are a labelled on-device
/// summary. Live AI report explanations run on the shared server
/// (`POST /api/reports/explain`, services/shared_api), which holds the key
/// and checks the patient's access first.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../auth/application/session.dart';

enum ChatRole { user, model }

class ChatMessage {
  const ChatMessage(this.role, this.text, {this.isEmergency = false});
  final ChatRole role;
  final String text;
  final bool isEmergency;
}

const _greeting = ChatMessage(
  ChatRole.model,
  "Hello! 👋 I'm your Care Navigator. I can help you get around MyHealth — "
  'appointments, health records, medications, billing and your profile. '
  'What are you looking for?',
);

/// Lower-cased phrases that trigger the emergency response (from ai_chat.php).
const _emergencyPhrases = [
  'chest pain',
  'heart attack',
  "can't breathe",
  'cannot breathe',
  'difficulty breathing',
  'severe bleeding',
  'unconscious',
  'stroke',
  'seizure',
  'choking',
  'suicide',
  'overdose',
  'anaphylaxis',
  'allergic reaction',
  'not breathing',
];

const _emergencyReply = ChatMessage(
  ChatRole.model,
  '🚨 This sounds like it could be a medical emergency.\n\n'
  'Please act now:\n'
  '1. Call emergency services (999 / 911)\n'
  '2. Go to the nearest emergency room\n'
  '3. Do not wait for an online appointment\n\n'
  'If someone is with you, ask them to help while you call. '
  'The Care Navigator cannot replace emergency care.',
  isEmergency: true,
);

class CareNavigatorState {
  const CareNavigatorState({
    required this.messages,
    this.sending = false,
    this.report,
  });
  final List<ChatMessage> messages;
  final bool sending;

  /// The report the conversation is about (shown in the chat header with a
  /// link to its original), or null for general navigation help.
  final ({String id, String title})? report;

  CareNavigatorState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    ({String id, String title})? report,
  }) => CareNavigatorState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    report: report ?? this.report,
  );
}

/// Whether replies come from a live model. Always false in the local app:
/// no provider is called from the device (keys stay server-side), so the
/// chat header says it is an offline guide.
final careNavigatorLiveProvider = FutureProvider<bool>((ref) async => false);

class CareNavigator extends Notifier<CareNavigatorState> {
  @override
  CareNavigatorState build() {
    // A new account (sign-out, switch, linked-account change) starts a fresh
    // conversation: no report text or replies carry over between patients.
    ref.watch(currentUserProvider.select((u) => u?.id));
    return const CareNavigatorState(messages: [_greeting]);
  }

  bool _isEmergency(String text) {
    final t = text.toLowerCase();
    return _emergencyPhrases.any(t.contains);
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(ChatRole.user, text)],
    );

    if (_isEmergency(text)) {
      state = state.copyWith(messages: [...state.messages, _emergencyReply]);
      return;
    }

    // The same labelled offline guide in every app mode (no provider call
    // from the device), so demo and production never disagree.
    final reply = _offlineReply(text);
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(ChatRole.model, reply)],
    );
    unawaited(
      ref
          .read(aiUsageRepositoryProvider)
          .log(
            feature: AiFeature.careNavigator,
            usedLiveModel: false,
            userId: ref.read(currentUserProvider)?.id,
            // Only its size is kept (see AiUsageRepositoryImpl.analyticsSummary).
            summary: text,
          ),
    );
  }

  void reset() => state = const CareNavigatorState(messages: [_greeting]);

  /// The patient uploaded [record] (a PDF) from the chat: say so, then
  /// explain what it says in plain words. Never a diagnosis.
  Future<void> explainDocument(MedicalRecord record) async {
    if (state.sending) return;
    final text = (record.extractedText ?? '').trim();
    // A different report starts a clean conversation, so answers about one
    // report are never mixed with another's.
    final switching = state.report != null && state.report!.id != record.id;
    final previous = switching ? const [_greeting] : state.messages;
    state = CareNavigatorState(
      sending: true,
      report: (id: record.id, title: record.title),
      messages: [...previous, ChatMessage(ChatRole.user, '📄 ${record.title}')],
    );
    String reply;
    if (text.isEmpty) {
      reply = _noTextReply;
    } else {
      // The local app explains on the device, labelled as such; live AI
      // explanations need the MyHealth server (keys never live on devices).
      reply =
          '$basicSummaryLabel\n\n'
          '${explainDocumentOffline(text, title: record.title)}';
    }
    state = state.copyWith(
      sending: false,
      messages: [...state.messages, ChatMessage(ChatRole.model, reply)],
    );
    unawaited(
      ref
          .read(aiUsageRepositoryProvider)
          .log(
            feature: AiFeature.careNavigator,
            usedLiveModel: false,
            userId: ref.read(currentUserProvider)?.id,
            summary: record.title,
          ),
    );
  }

  static const _noTextReply =
      "I saved the file to your Records, but I couldn't read any text in it "
      '(it may be a scanned image). Your doctor can still open the original '
      'file.';

  /// Deterministic navigation help (the offline guide).
  String _offlineReply(String text) {
    final t = text.toLowerCase();
    bool has(List<String> ws) => ws.any(t.contains);

    if (has([
      'book',
      'appointment',
      'appt',
      'schedule',
      'reschedule',
      'cancel',
      'doctor',
      'visit',
    ])) {
      return 'Open the Appointments tab. "Book now" jumps to the soonest slot, '
          '"Schedule" lets you pick a date; you can also reschedule or cancel an '
          'upcoming visit there.';
    }
    if (has([
      'record',
      'result',
      'lab',
      'timeline',
      'history',
      'note',
      'imaging',
      'prescription',
      'medication',
      'medicine',
      'meds',
      'drug',
    ])) {
      return 'On Home, scroll to Quick Access and open Health Records. The '
          '"Timeline" view lists your visits, '
          'labs and vitals; switch to "Medications" for your current and past '
          'prescriptions, or "Bills" for your invoices.';
    }
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
      return 'Billing & Payments (Home → Quick Access) shows your wallet '
          'balance with '
          'a Top up button, every invoice with a Pay button, and your saved '
          'cards, all in one place.';
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
      return 'Nutrition (Home → Quick Access) has three views: Targets works '
          'out your daily '
          'calories and macros, Foods looks up nutrients, and Meal plan suggests '
          'allergen-safe meals.';
    }
    if (has(['notification', 'alert', 'reminder', 'unread'])) {
      return 'Tap the bell at the top of Home to open your Notifications — '
          'appointment reminders, lab results and billing alerts land there.';
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
      return 'Everything about you is in My Profile (Home → Quick Access, or '
          'tap your picture): personal info, health details, '
          'payments, preferences (theme & language), notification channels and '
          'your family network. Tap a section to expand it.';
    }
    if (has([
      'symptom',
      'pain',
      'fever',
      'sick',
      'hurt',
      'ache',
      'rash',
      'dizzy',
      'nausea',
      'diagnos',
      'treat',
      'should i',
    ])) {
      return "I can't give medical advice. Please book an appointment from the "
          'Appointments tab so a doctor can help you properly. If it feels '
          "urgent, don't wait — contact emergency services.";
    }
    return 'I can point you to Appointments, Records, Nutrition, Payments, '
        'Notifications or your Profile. Which would you like?';
  }
}

/// Live explanations read at most this many characters of a report.
const kReportExplainLimit = 12000;

const basicSummaryLabel =
    'Basic summary (made on this device by matching common test names; '
    'AI explanation is not available in this app):';

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
///  - [edge]  a slim tab tucked against the nearest side (dismissed)
///  - [fab]   the round button, ready to open
///  - [panel] the chat panel is open
/// Kept out of [CareNavigator] so toggling it doesn't rebuild the conversation.
enum CareNavView { edge, fab, panel }

final careNavigatorViewProvider = StateProvider<CareNavView>(
  (_) => CareNavView.fab,
);

/// Where the patient has parked the floating button. [dx] / [dy] are fractions
/// (0–1) of the free area — `dx` is which side it gravitates to, `dy` its
/// height. Persisted per device so it stays where they put it.
class CareNavPlacement {
  const CareNavPlacement({this.dx = 1, this.dy = 0.82});

  final double dx;
  final double dy;

  /// The button (and, once dismissed, the edge tab) sits on the right half.
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
      dy: double.tryParse(parts[1]) ?? 0.82,
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
