/// The patient assistant's fixed replies and how it recognises a request,
/// decided on the device — so emergencies, medical-advice requests and
/// "where do I…?" questions are answered the same way with or without a
/// report, and with or without the report AI service.
///
/// The advice and emergency patterns are kept in step with the gateway
/// (services/report_ai/assistant.mjs), which applies them again server-side.
library;

import 'assistant_actions.dart';

/// Replies in Arabic when the patient writes Arabic.
bool isArabicText(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);

RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

final _emergency = [
  _re(
    r"\b(this is|it'?s|it is|i'?m having|i am having|having|we have|there'?s|there is) an? (medical )?emergency\b",
  ),
  _re(r'^\s*(help[\s!,.]*)?emergency([\s!,.]*help)?[\s!.]*$'),
  _re(r'\b(call|need|send) an ambulance\b'),
  _re(r"\bi (can'?t|cannot) breathe\b"),
  _re(
    r"\bi'?m (choking|having a heart attack|having a stroke|having a seizure|bleeding heavily|overdosing)\b",
  ),
  _re(
    r'\bi am (choking|having a heart attack|having a stroke|having a seizure|bleeding heavily|overdosing)\b',
  ),
  _re(r'\b(kill|hurt) myself\b|\bsuicid'),
  RegExp(
    'حالة طارئة|حالة طوارئ|أحتاج إسعاف|احتاج اسعاف|اطلبوا الإسعاف|'
    'لا (أستطيع|استطيع) التنفس|(أنتحر|انتحر|انتحار)',
  ),
];

/// The patient says plainly that this is an emergency. Not an assessment:
/// only an explicit statement triggers the fixed emergency message.
bool isEmergencyStatement(String text) =>
    _emergency.any((r) => r.hasMatch(text));

final _advice = [
  _re(r'\bdiagnos'),
  _re(r'\bshould i\b'),
  _re(
    r'\bdo i need (any |a |an |to take |to start |to stop )?(medicine|medication|meds|treatment|surgery|tablets?|pills?|insulin|antibiotics?)\b',
  ),
  _re(
    r'\bdo i have (a |an |any )?(disease|illness|condition|infection|cancer|diabetes|anaemia|anemia|deficiency)\b',
  ),
  _re(
    r'\b(can|may|must) i (stop|start|take|skip|change|increase|decrease|double|reduce|quit)\b',
  ),
  _re(
    r'\b(stop|start|change|increase|decrease|double|reduce|skip|quit) (taking )?(my|the|this) (medicine|medication|meds|dose|dosage|tablets?|pills?|insulin|treatment)\b',
  ),
  _re(r'\bwhat (illness|disease|condition|sickness|infection)\b'),
  _re(
    r'\b(serious|dangerous|life[- ]threatening|worr(y|ied|ying)|urgent|emergency level)\b',
  ),
  _re(r'\b(treatment|treat it|cure|remedy|prescribe)\b'),
  _re(
    r'\bwhat (does|do) (this|that|it|these|those|my results?|the results?) mean for me\b',
  ),
  _re(r'\bwhat should i do\b'),
  _re(r"\b(i feel|i'?m feeling|i am feeling|symptoms?)\b"),
  RegExp(
    'تشخيص|هل (يجب|ينبغي|لازم|علي|عليّ)|هل (أحتاج|احتاج)|'
    'هل (عندي|لدي|لديّ) (مرض|سكري|سكر|ضغط)|علاج|'
    '(أوقف|اوقف|أبدأ|ابدأ|أغير|اغير|أزيد|ازيد|أنقص|انقص).{0,20}'
    '(دواء|الدواء|جرعة|الجرعة)|خطير|خطيرة|أعراض|ماذا (أفعل|افعل)|'
    'ماذا يعني .{0,20}(لي|بالنسبة لي)',
  ),
];

/// A request for a diagnosis, medical advice, a symptom or urgency
/// assessment, treatment, or a medicine change — declined, never answered.
bool isAdviceRequest(String text) => _advice.any((r) => r.hasMatch(text));

final _asksForPlace = _re(
  r"\b(where|how (do|can|should) i|how to|open|go to|take me|find|show me|i want to|i'd like to|i would like to|can i|let me|book|upload|attach)\b"
  '|أين|وين|كيف|افتح|أريد|اريد|أبغى|ابغى|ودي|احجز|أحجز|ارفع|أرفع',
);
final _aboutThisReport = _re(
  r'\b(this|the|in the|in this) (report|pdf|document)\b|هذا التقرير|في التقرير',
);
final _uploadIntent = _re(
  r'\b(upload|attach|import)\b'
  r'|\b(add|send|choose|select) (a |my |the |another |new )*(pdf|report|file|document)s?\b'
  '|ارفع|أرفع|رفع|تحميل',
);
final _appointmentsIntent = _re(
  r'\b(book|booking|appointments?|appt|schedule|reschedule|see a (doctor|clinician))\b'
  '|موعد|مواعيد|احجز|أحجز|حجز',
);
final _recordsIntent = _re(
  r'\b(records?|reports|my reports?|results|lab results?|labs?|documents|files|medications|medicines|prescriptions|history|timeline|imaging)\b'
  '|سجل|سجلات|سجلاتي|تقارير|تقاريري|نتائج|نتائجي|ملفاتي',
);

/// The screens a message asks to go to, in a stable order. Inside a report
/// conversation only an explicit "where / how do I / open…" question that is
/// not about the report itself counts as navigation.
List<AssistantAction> navigationRequests(
  String text, {
  required bool aboutReport,
}) {
  if (aboutReport &&
      (!_asksForPlace.hasMatch(text) || _aboutThisReport.hasMatch(text))) {
    return const [];
  }
  final upload = _uploadIntent.hasMatch(text);
  return [
    if (upload) AssistantAction.uploadReport,
    if (_appointmentsIntent.hasMatch(text)) AssistantAction.openAppointments,
    if (!upload && _recordsIntent.hasMatch(text)) AssistantAction.openRecords,
  ];
}

final _summaryRequest = _re(
  r'\b(summari[sz]e|summary|explain|analy[sz]e|read) (my|the|this|a|an)? ?(report|pdf|results?|document|file)'
  r'|\bwhat does (my|the|this) (report|pdf|result) say'
  '|لخص|لخّص|ملخص|اشرح|حلل|حلّل',
);

/// Asks for a report summary or about "my report" with none selected.
bool isSummaryRequest(String text) => _summaryRequest.hasMatch(text);

/// The assistant's fixed messages.
abstract final class AssistantText {
  static String emergency(bool ar) => ar
      ? 'إذا كانت هذه حالة طارئة، اتصل برقم الطوارئ المحلي الآن (999 في '
            'البحرين) أو توجّه إلى أقرب قسم طوارئ. لا يستطيع هذا المساعد '
            'المساعدة في حالات الطوارئ.'
      : 'If this is an emergency, call your local emergency number now (999 '
            'in Bahrain) or go to the nearest emergency department. This '
            'assistant cannot help in an emergency.';

  static String advice(bool ar) => ar
      ? 'يمكنني شرح ما يقوله تقريرك. يرجى سؤال مختص رعاية صحية عمّا تعنيه '
            'النتيجة بالنسبة لك.'
      : 'I can explain what your report says. Please ask a healthcare '
            'professional what the result means for you.';

  static String noReport(bool ar) => ar
      ? 'اختر تقرير PDF وسألخصه لك.'
      : "Choose a report PDF and I'll summarize it.";

  static String notFound(bool ar) => ar
      ? 'لم أجد هذه المعلومة في هذا التقرير.'
      : "I couldn't find that information in this report.";

  static String unreadable(bool ar) => ar
      ? 'لم أتمكن من قراءة ملف PDF هذا. يرجى رفع نسخة أوضح.'
      : "I couldn't read this PDF. Please upload a clearer copy.";

  static String partial(bool ar) => ar
      ? 'تمكنت من قراءة جزء فقط من هذا التقرير. هذا الملخص يغطي الجزء '
            'المقروء.'
      : 'I could only read part of this report. This summary covers the '
            'readable part.';

  static String navigation(AssistantAction action, bool ar) => switch (action) {
    AssistantAction.openAppointments =>
      ar
          ? 'افتح المواعيد لاختيار الطبيب ومعرفة الأوقات المتاحة.'
          : 'Open Appointments to choose a clinician and see available '
                'times.',
    AssistantAction.openRecords =>
      ar
          ? 'افتح السجلات لعرض تقاريرك المحفوظة.'
          : 'Open Records to view your saved reports.',
    AssistantAction.uploadReport =>
      ar
          ? 'افتح شاشة رفع التقرير واختر ملف PDF.'
          : 'Open the report upload screen and choose your PDF.',
  };

  /// When nothing else matched, in Arabic (the English guide covers more
  /// areas).
  static const fallbackArabic =
      'يمكنني مساعدتك في الوصول إلى المواعيد أو السجلات أو رفع تقرير، '
      'وتلخيص تقرير PDF تختاره. ماذا تريد؟';
}
