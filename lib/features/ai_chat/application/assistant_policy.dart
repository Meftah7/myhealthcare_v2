/// The assistant's fixed replies and how it recognises a request, decided on
/// the device — so emergencies, medical questions and "where do I…?"
/// questions are answered the same way with or without a document or the
/// AI service.
///
/// The assistant answers no medical questions. [isMedicalQuestion] is a
/// conservative, layered check (vocabulary in English and Arabic, misspelling
/// tolerance, interpretation / advice / definition phrasing, follow-ups to an
/// earlier medical question). It is the same rule the gateway applies on the
/// server (services/report_ai/medical_policy.mjs) — both are checked against
/// services/report_ai/eval/medical_questions.json — and the gateway adds
/// provider flagging and output checks. No keyword list is perfect, which is
/// why the server enforces the rule too.
library;

import 'assistant_actions.dart';

/// Replies in Arabic when the patient writes Arabic.
bool isArabicText(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);

RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

// --- Emergencies --------------------------------------------------------------

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

// --- Medical questions ----------------------------------------------------------

const _stems = [
  'symptom', 'pain', 'ache', 'aching', 'hurt', 'fever', 'cough', 'rash', //
  'itch', 'dizz', 'nause', 'vomit', 'diarrh', 'constipat', 'headache',
  'migrain', 'bleed', 'swell', 'swollen', 'fatigue', 'faint', 'infect',
  'virus', 'viral', 'bacteri', 'covid', 'influenza', 'disease', 'illness',
  'diagnos', 'cancer', 'tumor', 'tumour', 'diabet', 'anemi', 'anaemi',
  'hypertens', 'hypotens', 'asthma', 'arthrit', 'depress', 'anxiety',
  'thyroid', 'kidney', 'liver', 'obes', 'pregnan', 'menstru', 'fertil',
  'contracept', 'treatment', 'treating', 'therap', 'surgery', 'drug',
  'capsule', 'dosage', 'antibiot', 'paracetamol', 'acetaminophen',
  'ibuprofen', 'aspirin', 'insulin', 'metformin', 'statin', 'side effect',
  'interaction', 'calori', 'weight loss', 'lose weight', 'exercis', 'workout',
  'alcohol', 'smok', 'prognos', 'life expectancy', 'healthy', 'unhealthy',
  'supplement', 'vitamin', 'cholesterol', 'glucose', 'blood sugar',
  'blood pressure', 'hba1c', 'hemoglobin', 'haemoglobin', 'creatinin',
  'ferritin', 'platelet', 'triglycerid', 'bilirubin', 'tsh', 'ldl', 'hdl',
  'crp', 'egfr', 'medic', 'prescri', 'allerg', 'vaccin', 'syndrome',
  'disorder', 'stomach', 'injur', 'wound', 'fracture', 'sprain', 'breathing',
];

const _words = {
  'flu', 'ill', 'sick', 'heart', 'chest', 'pill', 'pills', 'tablets', 'cure', //
  'cures', 'hurt', 'hurts', 'ache', 'aches', 'diet', 'dose', 'doses', 'treat',
  'sore', 'cold', 'lump', 'mole',
};

const _fuzzyWords = [
  'symptoms', 'symptom', 'diabetes', 'medicine', 'medicines', 'medication', //
  'medications', 'prescription', 'headache', 'diagnosis', 'diagnose',
  'infection', 'pregnant', 'pregnancy', 'antibiotic', 'antibiotics',
  'cholesterol', 'treatment', 'dizziness', 'nausea', 'cancer', 'insulin',
  'paracetamol', 'ibuprofen', 'hypertension', 'migraine', 'asthma', 'allergy',
  'anemia', 'anaemia', 'disease', 'illness', 'vitamin', 'dosage', 'glucose',
  'hemoglobin', 'haemoglobin', 'creatinine', 'diarrhea', 'diarrhoea', 'fever',
  'cough',
];

const _notFuzzy = {
  'cancel', 'cancels', 'canceled', 'cancelled', 'cancelling', 'answer', //
  'answers', 'message', 'messages', 'records', 'record', 'reports', 'report',
  'upload', 'uploads', 'document', 'documents', 'doctor', 'doctors',
  'appointment', 'appointments', 'summary', 'summarize', 'service',
  'services', 'profile', 'settings', 'language', 'arabic', 'english',
  'password', 'account', 'notification', 'notifications', 'download',
  'question', 'questions',
};

final _appNounPhrase = _re(
  r'\b(medical|health) (records?|reports?|documents?|files?|appointments?|certificates?|history|centre|center|team|staff|app)\b',
);
final _sickLeave = _re(r'\bsick[- ]?(leave|notes?)\b');
final _asksForPlace = _re(
  r'\b(where|how (do|can) i (find|see|open|get to|view|check|upload|attach|send|book|download|message|contact)|open|go to|take me|show me (my|the)|find my|view my|i want to (upload|attach|book|see|find|open|message))\b'
  '|أين|وين|افتح|اعرض|كيف (أجد|اجد|أفتح|افتح|ارفع|أرفع)',
);
final _interpret = _re(
  r'\b(mean|means|meaning|indicat\w*|interpret\w*|normal|abnormal|serious|dangerous|danger|worr\w*|concerning|too (high|low)|is (it|this|that|mine) (high|low|ok|okay|fine|good|bad)|why (is|are) .* (high|low)|explain (my|the|these) (results?|values?|levels?|numbers?|tests?))\b',
);
final _advice = _re(
  r'\b(should i|shall i|can i (take|use|eat|drink|stop|start|skip)|could i|do i need|is it (safe|ok|okay|fine|bad|good)|how (much|many|often) (should|can|do)|what (should|can) i (do|take|eat)|recommend\w*|advi[cs]e|suggest\w*|better (to|for)|ok to|okay to|what to do|get better|go to (the )?(hospital|er|emergency room|doctor))\b',
);
final _definition = _re(
  r"\b(what (is|are|'?s) (a |an |the )?(?!my\b|your\b|the (date|time|name)\b)\w+|define|definition of|what does \w+ stand for|tell me about)\b",
);
final _factLookup = _re(
  r'\b((what|which) (value|values|number|result|results|level|reading|date|unit|units)\b.*\b(document|report|it|this|file)\b|\b(document|report|file) (list|lists|say|says|show|shows|state|states|give|gives)\b|what (is|was|were|are) my \w+( \w+)?(\s+(value|level|result|reading))?\s*\??$)',
);
final _followUp = _re(
  r'^\s*(and|also|what about|how about|what if|and if|then|so|ok so|but)\b'
  '|^\\s*(و|وماذا|ماذا عن|طيب|وإذا|واذا|لكن)',
);
final _resultWords = _re(
  r'\b(result|value|level|reading|test|number|score)s?\b',
);
final _adviceContext = _re(
  r'\b(eat|drink|sleep|take|weight|health|body|baby|feel|results?|values?)\b',
);
final _pronoun = _re(r'\b(it|that|this|those|them|one)\b');

const _arTerms = {
  'اعراض', 'عرضي', 'الم', 'الام', 'وجع', 'يؤلمني', 'يوجعني', 'حمي', 'حراره', //
  'سعال', 'كحه', 'صداع', 'دوخه', 'دوار', 'غثيان', 'استفراغ', 'تقيؤ', 'اسهال',
  'امساك', 'نزيف', 'تورم', 'تعب', 'ارهاق', 'مرض', 'امراض', 'سكري', 'سكر',
  'سرطان', 'ورم', 'انيميا', 'ربو', 'حساسيه', 'اكتئاب', 'تشخيص', 'علاج', 'دواء',
  'ادويه', 'حبوب', 'جرعه', 'جرعات', 'مضاد', 'انسولين', 'حامل', 'رجيم', 'حميه',
  'سعرات', 'رياضه', 'وزن', 'تدخين', 'كحول', 'شفاء', 'التهاب', 'عدوي', 'فيروس',
  'جرثومه', 'ضغط', 'كوليسترول', 'هيموجلوبين', 'جلوكوز', 'فيتامين', 'الغده',
  'الكلي', 'الكبد', 'قلب', 'صدر', 'معده', 'كسر', 'جرح', 'مكملات', 'اعراضي',
};
final _arInterpret = RegExp(
  'معنى|يعني|تعني|طبيعي|طبيعيه|خطير|خطيره|خطر|مقلق|اقلق|أقلق|مرتفع|منخفض|عالي|سيء|جيد ل',
);
final _arAdvice = RegExp(
  'هل (يجب|ينبغي|لازم|علي|عليّ|أحتاج|احتاج|يمكنني|استطيع|أستطيع|اقدر|أقدر)|'
  'انصح|أنصح|نصيحه|نصيحة|افضل|أفضل|ماذا (أفعل|افعل|اتناول|أتناول|آكل|اكل)|'
  'كم (حبه|حبة|جرعه|جرعة)',
);
final _arDefinition = RegExp(
  r'^(ما|ماهو|ماهي|ما هو|ما هي|ما معنى|ماذا يعني|عرف|عرّف)',
);
final _arLookup = RegExp(
  '(ما|كم|ماذا) (هو |هي |كان |كانت )?(قيمة|قيمه|مستوى|نتيجة|نتيجه|تاريخ|رقم|وحدة|وحده|يذكر|يقول)|'
  '(يذكر|يقول|يظهر) (المستند|التقرير)',
);
final _arScreen = RegExp(
  'ادويتي|أدويتي|الأدوية|الادوية|وصفاتي|الوصفات|سجلاتي|السجلات|نتائجي|تقاريري|'
  'اجازه مرضيه|إجازة مرضية|اجازة مرضية|حساسيتي',
);

const _screenStems = {
  'medic', 'prescri', 'allerg', 'vaccin', 'medications', 'medication', //
  'medicine', 'medicines', 'prescription', 'ادويه', 'دواء',
};

String _normaliseArabic(String token) {
  var t = token
      .replaceAll(RegExp('[ً-ْٰـ]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  for (final prefix in ['وال', 'بال', 'فال', 'كال', 'لل', 'ال']) {
    if (t.startsWith(prefix) && t.length - prefix.length >= 2) {
      t = t.substring(prefix.length);
      break;
    }
  }
  if (RegExp('^[وفبلك]').hasMatch(t) &&
      t.length >= 4 &&
      !_arTerms.contains(t)) {
    t = t.substring(1);
  }
  return t;
}

int _levenshtein(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var best = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (cur[j] < best) best = cur[j];
    }
    if (best > max) return max + 1;
    prev = cur;
  }
  return prev[b.length];
}

/// The medical words in [text] (English stems, misspellings, Arabic).
Set<String> medicalTerms(String text) {
  final found = <String>{};
  final lower = text
      .toLowerCase()
      .replaceAll(_sickLeave, ' ')
      .replaceAll(_appNounPhrase, ' ');
  final words = RegExp('[a-z0-9]+').allMatches(lower).map((m) => m.group(0)!);
  for (final stem in _stems) {
    if (stem.contains(' ')) {
      if (lower.contains(stem)) found.add(stem);
    } else if (words.any((w) => w.startsWith(stem))) {
      found.add(stem);
    }
  }
  for (final w in words) {
    if (_words.contains(w)) found.add(w);
    if (w.length < 6 || _notFuzzy.contains(w)) continue;
    final max = w.length >= 9 ? 2 : 1;
    for (final f in _fuzzyWords) {
      if (f[0] == w[0] && _levenshtein(w, f, max) <= max) {
        found.add(f);
        break;
      }
    }
  }
  for (final raw in text.split(RegExp('[\\s،,.!?؟:;()"\'«»]+'))) {
    if (raw.isEmpty) continue;
    final t = _normaliseArabic(raw);
    if (_arTerms.contains(t)) found.add(t);
  }
  return found;
}

/// A previous turn of the conversation, for follow-up detection.
typedef PolicyTurn = ({bool fromPatient, String text});

/// Whether [text] is (or could be) a medical question — refused with the
/// fixed reply. [history] are earlier turns: a follow-up to a medical
/// question counts too. With [hasDocument], factual lookups of what the
/// attached document lists stay allowed.
bool isMedicalQuestion(
  String text, {
  List<PolicyTurn> history = const [],
  bool hasDocument = false,
}) {
  final terms = medicalTerms(text);
  final arabic = isArabicText(text);
  final interpret =
      _interpret.hasMatch(text) || (arabic && _arInterpret.hasMatch(text));
  final advice = _advice.hasMatch(text) || (arabic && _arAdvice.hasMatch(text));
  final definition =
      _definition.hasMatch(text) ||
      (arabic && _arDefinition.hasMatch(text.trim()));

  final screensOnly =
      terms.isNotEmpty && terms.every((t) => _screenStems.contains(t));
  final navigation =
      _asksForPlace.hasMatch(text) &&
      !interpret &&
      !advice &&
      (screensOnly || (arabic && _arScreen.hasMatch(text) && screensOnly));
  final lookup =
      hasDocument &&
      (_factLookup.hasMatch(text) || _arLookup.hasMatch(text)) &&
      !interpret &&
      !advice;

  var medical = false;
  if (terms.isNotEmpty && !navigation && !lookup) medical = true;
  if (interpret &&
      (terms.isNotEmpty ||
          hasDocument ||
          _resultWords.hasMatch(text) ||
          RegExp('نتيج|قيم|مستوى|تحليل').hasMatch(text))) {
    medical = true;
  }
  if (advice &&
      (terms.isNotEmpty || hasDocument || _adviceContext.hasMatch(text))) {
    medical = true;
  }
  if (definition && terms.isNotEmpty && !lookup) medical = true;

  if (!medical && !navigation) {
    final lastUser = history.reversed.where((t) => t.fromPatient).firstOrNull;
    if (lastUser != null &&
        isMedicalQuestion(lastUser.text, hasDocument: hasDocument) &&
        (_followUp.hasMatch(text) ||
            interpret ||
            advice ||
            _pronoun.hasMatch(text))) {
      medical = true;
    }
  }
  return medical;
}

// --- Navigation -------------------------------------------------------------------

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
  r'\b(records?|reports|my reports?|results|lab results?|labs?|documents|files|history|timeline|imaging)\b'
  '|سجل|سجلات|سجلاتي|تقارير|تقاريري|نتائج|نتائجي|ملفاتي',
);
final _messagesIntent = _re(
  r'\b(message|messages|chat with|talk to|write to|contact) (my |a |the )?(doctor|clinician|care team|physician)s?\b'
  r'|\bmy messages\b|\binbox\b'
  '|راسل|مراسلة|رسالة للطبيب|رسائلي|محادثة الطبيب|أكلم الطبيب|اكلم الطبيب',
);
final _medicationsIntent = _re(
  r'\b(my )?(medications?|medicines?|meds|prescriptions?|drugs)\b'
  '|أدويتي|ادويتي|الأدوية|الادوية|وصفاتي|الوصفات',
);
final _sickLeaveIntent = _re(
  r'\bsick[- ]?(leave|note)s?\b|\bmedical certificates?\b'
  '|إجازة مرضية|اجازة مرضية|الإجازات المرضية',
);
final _profileIntent = _re(
  r'\b(profile|password|personal (info|information|details)|my account|account settings|settings|language|dark mode|theme)\b'
  '|ملفي|الملف الشخصي|كلمة المرور|الإعدادات|الاعدادات|اللغة',
);

/// The screens a message asks to go to, in a stable order. Inside a document
/// conversation only an explicit "where / how do I / open…" question that is
/// not about the document itself counts as navigation.
List<AssistantAction> navigationRequests(
  String text, {
  required bool aboutReport,
}) {
  if (aboutReport &&
      (!_asksForPlace.hasMatch(text) || _aboutThisReport.hasMatch(text))) {
    return const [];
  }
  final upload = _uploadIntent.hasMatch(text);
  final sickLeave = _sickLeaveIntent.hasMatch(text);
  return [
    if (upload) AssistantAction.uploadReport,
    if (_appointmentsIntent.hasMatch(text)) AssistantAction.openAppointments,
    if (_messagesIntent.hasMatch(text)) AssistantAction.openMessages,
    if (_medicationsIntent.hasMatch(text)) AssistantAction.openMedications,
    if (sickLeave) AssistantAction.openSickLeave,
    if (_profileIntent.hasMatch(text)) AssistantAction.openProfile,
    if (!upload && !sickLeave && _recordsIntent.hasMatch(text))
      AssistantAction.openRecords,
  ];
}

final _summaryRequest = _re(
  r'\b(summari[sz]e|summary|explain|analy[sz]e|read) (my|the|this|a|an)? ?(report|pdf|results?|document|file)'
  r'|\bwhat does (my|the|this) (report|pdf|result|document) say'
  '|لخص|لخّص|ملخص|اشرح|حلل|حلّل',
);

final _smallTalk = _re(
  r'^\s*(hi|hello|hey|hiya|good (morning|afternoon|evening)|thanks|thank you|thx|ok|okay|cool|great|bye)\b[\s!.,]*(there|so much|a lot)?[\s!.,]*$'
  r'|^\s*(مرحبا|مرحبًا|اهلا|أهلا|السلام عليكم|شكرا|شكرًا|تمام|حسنا|حسنًا)[\s!.,؟]*$',
);

/// A greeting or thanks — nothing to look up.
bool isSmallTalk(String text) => _smallTalk.hasMatch(text);

/// Asks for a document summary or about "my report" with none attached.
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

  /// The fixed reply to any medical question.
  static String medical(bool ar) => ar
      ? 'يمكنني مساعدتك في استخدام التطبيق وتلخيص مستندك، لكن لا يمكنني '
            'الإجابة عن الأسئلة الطبية. يرجى مراسلة طبيبك أو حجز موعد '
            'لمناقشة سؤالك.'
      : 'I can help you use the app and summarize your document, but I can’t '
            'answer medical questions. Please message your doctor or book an '
            'appointment to discuss this.';

  /// When the patient has no doctor they can message yet.
  static String messagingEligibility(bool ar) => ar
      ? 'تتاح المراسلة بعد زيارة مكتملة مع طبيب، ويمكنك حجز موعد الآن.'
      : 'Messaging opens after a completed visit with a doctor. You can book '
            'an appointment now.';

  static String noReport(bool ar) => ar
      ? 'اضغط زر الإرفاق واختر مستندًا (PDF أو Word أو ملفًا نصيًا)، ثم اضغط '
            '«لخّص».'
      : 'Tap the attachment button and choose a document (PDF, Word or text), '
            'then tap Summarize.';

  static String notFound(bool ar) => ar
      ? 'لم أجد هذه المعلومة في هذا المستند.'
      : "I couldn't find that information in this document.";

  static String unreadable(bool ar) => ar
      ? 'لم أتمكن من قراءة هذا المستند. يرجى إرفاق نسخة أوضح.'
      : "I couldn't read this document. Please attach a clearer copy.";

  static String partial(bool ar) => ar
      ? 'يغطي هذا الملخص جزءًا فقط من المستند.'
      : 'This summary covers only part of the document.';

  static String navigation(AssistantAction action, bool ar) => switch (action) {
    AssistantAction.openAppointments =>
      ar
          ? 'افتح المواعيد لاختيار الطبيب ومعرفة الأوقات المتاحة.'
          : 'Open Appointments to choose a clinician and see available '
                'times.',
    AssistantAction.bookAppointment =>
      ar
          ? 'احجز موعدًا لاختيار العيادة أو الطبيب والوقت المناسب لك.'
          : 'Book an appointment to choose a clinic or doctor and a time '
                'that suits you.',
    AssistantAction.openRecords =>
      ar
          ? 'افتح السجلات لعرض تقاريرك المحفوظة.'
          : 'Open Records to view your saved reports.',
    AssistantAction.uploadReport =>
      ar
          ? 'اضغط زر الإرفاق واختر ملف PDF أو Word أو ملفًا نصيًا.'
          : 'Tap the attachment button and choose a PDF, Word or text '
                'file.',
    AssistantAction.openMessages =>
      ar
          ? 'افتح الرسائل لمراسلة الأطباء الذين زرتهم.'
          : 'Open Messages to write to a doctor you have seen.',
    AssistantAction.openMedications =>
      ar
          ? 'افتح الأدوية لعرض أدويتك الحالية والسابقة.'
          : 'Open Medications to see your current and past medicines.',
    AssistantAction.openSickLeave =>
      ar
          ? 'افتح الإجازات المرضية لعرض شهاداتك وتنزيلها.'
          : 'Open Sick leave to see and download your certificates.',
    AssistantAction.openProfile =>
      ar
          ? 'افتح ملفي الشخصي لتحديث بياناتك وكلمة المرور والتفضيلات.'
          : 'Open My Profile to update your details, password and '
                'preferences.',
  };

  /// Inside a document conversation, for a greeting or thanks.
  static String reportHint(bool ar) => ar
      ? 'اسألني عمّا يذكره هذا المستند، مثل: «ما النتائج الموصوفة بأنها '
            'مرتفعة؟» أو «ما الخلاصة المذكورة؟»، أو اسألني أين تجد شيئًا في '
            'التطبيق.'
      : 'Ask me what this document states — for example, "Which results are '
            'labelled High?" or "What conclusion does it state?" — or ask me '
            'where to find something in the app.';

  /// The offline guide when nothing else matched, in Arabic.
  static const fallbackArabic =
      'يمكنني نقلك إلى المواعيد أو السجلات أو الرسائل أو الأدوية، أو تلخيص '
      'مستند ترفقه. ماذا تريد؟';

  static String uploadFailed(bool ar) => ar
      ? 'لم أتمكن من حفظ هذا الملف في سجلاتك. حاول مرة أخرى.'
      : "I couldn't save this file to your Records. Try again.";
}
