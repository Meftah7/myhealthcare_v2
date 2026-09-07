/// The Care Navigator — an in-app AI assistant that helps patients find their
/// way around and points medical questions to a real clinician.
///
/// Ported from the FirstSemMyHealth `ai-widget.js` + `ai_chat.php`: same
/// greeting, same emergency-keyword guard, same "navigation helper, not a
/// doctor" behaviour. Uses the app's Gemini key when one is configured and a
/// deterministic offline responder otherwise, so the widget always answers.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../admin/application/settings_providers.dart';
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
  'chest pain', 'heart attack', "can't breathe", 'cannot breathe',
  'difficulty breathing', 'severe bleeding', 'unconscious', 'stroke',
  'seizure', 'choking', 'suicide', 'overdose', 'anaphylaxis',
  'allergic reaction', 'not breathing',
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
  const CareNavigatorState({required this.messages, this.sending = false});
  final List<ChatMessage> messages;
  final bool sending;

  CareNavigatorState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
  }) => CareNavigatorState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
  );
}

class CareNavigator extends Notifier<CareNavigatorState> {
  @override
  CareNavigatorState build() =>
      const CareNavigatorState(messages: [_greeting]);

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
      state = state.copyWith(
        messages: [...state.messages, _emergencyReply],
      );
      return;
    }

    state = state.copyWith(sending: true);
    String reply;
    try {
      reply = await _answer(text);
    } catch (_) {
      reply = _offlineReply(text);
    }
    state = state.copyWith(
      sending: false,
      messages: [...state.messages, ChatMessage(ChatRole.model, reply)],
    );
  }

  void reset() => state = const CareNavigatorState(messages: [_greeting]);

  Future<String> _answer(String text) async {
    final settings = await ref.read(appSettingsProvider.future);
    final key = await ref.read(aiKeyStoreProvider).read();
    if (!settings.usesRealAi || key == null || key.isEmpty) {
      return _offlineReply(text);
    }
    return _askGemini(text, apiKey: key, model: settings.modelId);
  }

  Future<String> _askGemini(
    String text, {
    required String apiKey,
    required String model,
  }) async {
    final name = ref.read(currentUserProvider)?.fullName ?? 'the patient';
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final history = state.messages
        .where((m) => !m.isEmergency)
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
        )
        .toList();

    final res = await dio.post<Map<String, dynamic>>(
      '/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt(name)},
          ],
        },
        'contents': history,
        'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 400},
      },
    );
    final candidates = res.data?['candidates'];
    final first = (candidates is List && candidates.isNotEmpty)
        ? candidates.first
        : null;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    final part = (parts is List && parts.isNotEmpty) ? parts.first : null;
    final out = part is Map ? part['text'] : null;
    if (out is! String || out.trim().isEmpty) return _offlineReply(text);
    return out.trim();
  }

  static String _systemPrompt(String name) =>
      'You are the Care Navigator for the MyHealth Care patient app, helping '
      '$name. Keep replies short (2-4 sentences) and friendly. You help people '
      'navigate the app: Home, Appointments (book/cancel/reschedule), Health '
      'Records (visit timeline + medications), Nutrition (macro targets, food '
      'lookup, meal plan), Billing and the Wallet (cards, bills), Notifications, '
      'and Profile. For any medical or symptom question, do NOT give medical '
      "advice: say you can't and suggest booking an appointment with a doctor. "
      'Never mention other patients or internal data.';

  /// Deterministic navigation help — used offline and as the mock.
  String _offlineReply(String text) {
    final t = text.toLowerCase();
    bool has(List<String> ws) => ws.any(t.contains);

    if (has(['book', 'appointment', 'appt', 'schedule', 'reschedule', 'cancel',
        'doctor', 'visit'])) {
      return 'Open the Appointments tab. "Book now" jumps to the soonest slot, '
          '"Schedule" lets you pick a date; you can also reschedule or cancel an '
          'upcoming visit there.';
    }
    if (has(['record', 'result', 'lab', 'timeline', 'history', 'note',
        'imaging', 'prescription', 'medication', 'medicine', 'meds', 'drug'])) {
      return 'Go to Records. The "Timeline" view lists your visits, '
          'labs and vitals; switch to "Medications" for your current and past '
          'prescriptions, or "Bills" for your invoices.';
    }
    if (has(['bill', 'invoice', 'pay', 'payment', 'card', 'wallet',
        'outstanding', 'owe', 'transaction'])) {
      return 'Billing shows every invoice with a Pay button, and Profile → '
          'Wallet keeps your saved cards, your current bill and past payments.';
    }
    if (has(['nutrition', 'calorie', 'macro', 'diet', 'meal', 'food', 'bmr',
        'tdee', 'weight'])) {
      return 'The Nutrition tab has three views: Targets works out your daily '
          'calories and macros, Foods looks up nutrients, and Meal plan suggests '
          'allergen-safe meals.';
    }
    if (has(['notification', 'alert', 'reminder', 'unread'])) {
      return 'Tap the bell at the top of Home to open your Notifications — '
          'appointment reminders, lab results and billing alerts land there.';
    }
    if (has(['profile', 'password', 'email', 'phone', 'family', 'emergency',
        'blood type', 'allergy', 'allergies', 'setting', 'theme', 'language'])) {
      return 'Everything about you is in Profile: personal info, health details, '
          'wallet, preferences (theme & language), notification channels and your '
          'family network. Tap a section to expand it.';
    }
    if (has(['symptom', 'pain', 'fever', 'sick', 'hurt', 'ache', 'rash',
        'dizzy', 'nausea', 'diagnos', 'treat', 'should i'])) {
      return "I can't give medical advice. Please book an appointment from the "
          'Appointments tab so a doctor can help you properly. If it feels '
          "urgent, don't wait — contact emergency services.";
    }
    return 'I can point you to Appointments, Records, Nutrition, Billing '
        '& Wallet, Notifications or your Profile. Which would you like?';
  }
}

final careNavigatorProvider =
    NotifierProvider<CareNavigator, CareNavigatorState>(CareNavigator.new);

/// How the floating widget is showing:
///  - [edge]  a slim tab tucked against the right edge (dismissed)
///  - [fab]   the round button, ready to open
///  - [panel] the chat panel is open
/// Kept out of [CareNavigator] so toggling it doesn't rebuild the conversation.
enum CareNavView { edge, fab, panel }

final careNavigatorViewProvider =
    StateProvider<CareNavView>((_) => CareNavView.fab);
