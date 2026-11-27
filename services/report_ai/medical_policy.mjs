// The assistant answers no medical questions. This module decides, on the
// server, whether a message is (or could be) one — so the rule holds even
// for callers that bypass the app — and provides the fixed replies.
//
// Layers (none is enough on its own; together they are conservative):
//   1. explicit emergencies -> the fixed emergency message (no assessment);
//   2. medical vocabulary (English stems + fuzzy matching for misspellings,
//      Arabic tokens after normalisation), interpretation / advice /
//      definition phrasing, and follow-ups to an earlier medical question;
//   3. the provider is told to flag medical questions, and a flag means the
//      fixed refusal — its wording is never shown;
//   4. output checks: replies and summaries are scanned for medical or
//      interpretive language that the source does not contain.
// Exceptions that stay allowed: plain navigation ("where are my
// medications?") and factual lookup in an attached document ("what value
// does the document list for glucose?").
//
// Kept in step with lib/features/ai_chat/application/assistant_policy.dart;
// both are checked against eval/medical_questions.json.

export const ACTIONS_FOR_MEDICAL = Object.freeze(['open_messages', 'book_appointment']);

export const POLICY_MESSAGES = Object.freeze({
  en: Object.freeze({
    medical: 'I can help you use the app and summarize your document, but I can’t answer medical questions. Please message your doctor or book an appointment to discuss this.',
    emergency: 'If this is an emergency, call your local emergency number now (999 in Bahrain) or go to the nearest emergency department. This assistant cannot help in an emergency.',
  }),
  ar: Object.freeze({
    medical: 'يمكنني مساعدتك في استخدام التطبيق وتلخيص مستندك، لكن لا يمكنني الإجابة عن الأسئلة الطبية. يرجى مراسلة طبيبك أو حجز موعد لمناقشة سؤالك.',
    emergency: 'إذا كانت هذه حالة طارئة، اتصل برقم الطوارئ المحلي الآن (999 في البحرين) أو توجّه إلى أقرب قسم طوارئ. لا يستطيع هذا المساعد المساعدة في حالات الطوارئ.',
  }),
});

export const isArabic = text => /[؀-ۿ]/.test(String(text));

// --- Emergencies -------------------------------------------------------------

const EMERGENCY = [
  /\b(this is|it'?s|it is|i'?m having|i am having|having|we have|there'?s|there is) an? (medical )?emergency\b/i,
  /^\s*(help[\s!,.]*)?emergency([\s!,.]*help)?[\s!.]*$/i,
  /\b(call|need|send) an ambulance\b/i,
  /\bi (can'?t|cannot) breathe\b/i,
  /\bi'?m (choking|having a heart attack|having a stroke|having a seizure|bleeding heavily|overdosing)\b/i,
  /\bi am (choking|having a heart attack|having a stroke|having a seizure|bleeding heavily|overdosing)\b/i,
  /\b(kill|hurt) myself\b|\bsuicid/i,
  /حالة طارئة|حالة طوارئ|أحتاج إسعاف|احتاج اسعاف|اطلبوا الإسعاف|لا (أستطيع|استطيع) التنفس|(أنتحر|انتحر|انتحار)/,
];
export const isEmergencyStatement = text => EMERGENCY.some(re => re.test(String(text)));

// --- Vocabulary ----------------------------------------------------------------

// English stems: a word starting with one of these is medical.
const STEMS = [
  'symptom', 'pain', 'ache', 'aching', 'hurt', 'fever', 'cough', 'rash', 'itch', 'dizz', 'nause',
  'vomit', 'diarrh', 'constipat', 'headache', 'migrain', 'bleed', 'swell', 'swollen', 'fatigue',
  'faint', 'infect', 'virus', 'viral', 'bacteri', 'covid', 'influenza', 'disease', 'illness', 'diagnos',
  'cancer', 'tumor', 'tumour', 'diabet', 'anemi', 'anaemi', 'hypertens', 'hypotens', 'asthma',
  'arthrit', 'depress', 'anxiety', 'thyroid', 'kidney', 'liver', 'obes', 'pregnan', 'menstru',
  'fertil', 'contracept', 'treatment', 'treating', 'therap', 'surgery', 'drug', 'capsule',
  'dosage', 'antibiot', 'paracetamol', 'acetaminophen', 'ibuprofen',
  'aspirin', 'insulin', 'metformin', 'statin', 'side effect', 'interaction', 'calori',
  'weight loss', 'lose weight', 'exercis', 'workout', 'alcohol', 'smok', 'prognos',
  'life expectancy', 'healthy', 'unhealthy', 'supplement', 'vitamin', 'cholesterol',
  'glucose', 'blood sugar', 'blood pressure', 'hba1c', 'hemoglobin', 'haemoglobin', 'creatinin',
  'ferritin', 'platelet', 'triglycerid', 'bilirubin', 'tsh', 'ldl', 'hdl', 'crp', 'egfr',
  'medic', 'prescri', 'allerg', 'vaccin', 'syndrome', 'disorder',
  'stomach', 'injur', 'wound', 'fracture', 'sprain', 'breathing',
];

// Whole words only (as prefixes they would catch "fluent", "tablet
// computer" or "illustration").
const WORDS = new Set([
  'flu', 'ill', 'sick', 'heart', 'chest', 'pill', 'pills', 'tablets', 'cure', 'cures', 'hurt',
  'hurts', 'ache', 'aches', 'diet', 'dose', 'doses', 'treat', 'sore', 'cold', 'lump', 'mole',
]);

// "medical records", "medical report": app things, not medical questions.
const APP_NOUN_PHRASE = /\b(medical|health) (records?|reports?|documents?|files?|appointments?|certificates?|history|centre|center|team|staff|app)\b/gi;

// Full words for misspelling matches ("diabtes", "symtoms", "medecine").
const FUZZY_WORDS = [
  'symptoms', 'symptom', 'diabetes', 'medicine', 'medicines', 'medication', 'medications',
  'prescription', 'headache', 'diagnosis', 'diagnose', 'infection', 'pregnant', 'pregnancy',
  'antibiotic', 'antibiotics', 'cholesterol', 'treatment', 'dizziness', 'nausea', 'cancer',
  'insulin', 'paracetamol', 'ibuprofen', 'hypertension', 'migraine', 'asthma', 'allergy',
  'anemia', 'anaemia', 'disease', 'illness', 'vitamin', 'dosage', 'glucose', 'hemoglobin',
  'haemoglobin', 'creatinine', 'diarrhea', 'diarrhoea', 'fever', 'cough',
];

const NOT_FUZZY = new Set([
  'cancel', 'cancels', 'canceled', 'cancelled', 'cancelling', 'answer', 'answers', 'message',
  'messages', 'records', 'record', 'reports', 'report', 'upload', 'uploads', 'document',
  'documents', 'doctor', 'doctors', 'appointment', 'appointments', 'summary', 'summarize',
  'service', 'services', 'profile', 'settings', 'language', 'arabic', 'english', 'password',
  'account', 'notification', 'notifications', 'download', 'question', 'questions',
]);

// Plain app screens: these words alone, in a "where / open" request, are
// navigation, not a medical question.
const SCREEN_WORDS = /\b(medications?|medicines?|meds|prescriptions?|allerg(y|ies)|vaccinations?|sick[- ]?(leave|notes?)|records?|results?|lab results?|reports?|documents?|imaging)\b/gi;
const ASKS_FOR_PLACE = /\b(where|how (do|can) i (find|see|open|get to|view|check|upload|attach|send|book|download|message|contact)|open|go to|take me|show me (my|the)|find my|view my|i want to (upload|attach|book|see|find|open|message))\b|أين|وين|افتح|اعرض|كيف (أجد|اجد|أفتح|افتح)/i;
const SICK_LEAVE = /\bsick[- ]?(leave|notes?)\b/gi;

// Interpretation, advice and definitions.
const INTERPRET = /\b(mean|means|meaning|indicat\w*|interpret\w*|normal|abnormal|serious|dangerous|danger|worr\w*|concerning|too (high|low)|is (it|this|that|mine) (high|low|ok|okay|fine|good|bad)|why (is|are) .* (high|low)|explain (my|the|these) (results?|values?|levels?|numbers?|tests?))\b/i;
const ADVICE = /\b(should i|shall i|can i (take|use|eat|drink|stop|start|skip)|could i|do i need|is it (safe|ok|okay|fine|bad|good)|how (much|many|often) (should|can|do)|what (should|can) i (do|take|eat)|recommend\w*|advi[cs]e|suggest\w*|better (to|for)|ok to|okay to|what to do|get better|go to (the )?(hospital|er|emergency room|doctor))\b/i;
const DEFINITION = /\b(what (is|are|'?s) (a |an |the )?(?!my\b|your\b|the (date|time|name)\b)\w+|define|definition of|what does \w+ stand for|tell me about)\b/i;
const FACT_LOOKUP = /\b((what|which) (value|values|number|result|results|level|reading|date|unit|units)\b.*\b(document|report|it|this|file)\b|\b(document|report|file) (list|lists|say|says|show|shows|state|states|give|gives)\b|what (is|was|were|are) my \w+( \w+)?(\s+(value|level|result|reading))?\s*\??$)/i;
const FOLLOW_UP = /^\s*(and|also|what about|how about|what if|and if|then|so|ok so|but)\b|^\s*(و|وماذا|ماذا عن|طيب|وإذا|واذا|لكن)/i;

// Arabic: compared token by token after normalisation, so that a word like
// "تحميل" (upload) never matches "حمل".
const AR_TERMS = new Set([
  'اعراض', 'عرضي', 'الم', 'الام', 'وجع', 'يؤلمني', 'يوجعني', 'حمي', 'حراره', 'سعال', 'كحه', 'صداع',
  'دوخه', 'دوار', 'غثيان', 'استفراغ', 'تقيؤ', 'اسهال', 'امساك', 'نزيف', 'تورم', 'تعب', 'ارهاق',
  'مرض', 'امراض', 'سكري', 'سكر', 'سرطان', 'ورم', 'انيميا', 'ربو', 'حساسيه', 'اكتئاب', 'تشخيص',
  'علاج', 'دواء', 'ادويه', 'حبوب', 'جرعه', 'جرعات', 'مضاد', 'انسولين', 'حامل', 'رجيم', 'حميه',
  'سعرات', 'رياضه', 'وزن', 'تدخين', 'كحول', 'شفاء', 'التهاب', 'عدوي', 'فيروس', 'جرثومه', 'ضغط',
  'كوليسترول', 'هيموجلوبين', 'جلوكوز', 'فيتامين', 'الغده', 'الكلي', 'الكبد', 'قلب', 'صدر',
  'معده', 'كسر', 'جرح', 'مكملات', 'اعراضي',
]);
const AR_INTERPRET = /معنى|يعني|تعني|طبيعي|طبيعيه|خطير|خطيره|خطر|مقلق|اقلق|أقلق|مرتفع|منخفض|عالي|سيء|جيد ل/;
const AR_ADVICE = /هل (يجب|ينبغي|لازم|علي|عليّ|أحتاج|احتاج|يمكنني|استطيع|أستطيع|اقدر|أقدر)|انصح|أنصح|نصيحه|نصيحة|افضل|أفضل|ماذا (أفعل|افعل|اتناول|أتناول|آكل|اكل)|كم (حبه|حبة|جرعه|جرعة)/;
const AR_DEFINITION = /^(ما|ماهو|ماهي|ما هو|ما هي|ما معنى|ماذا يعني|عرف|عرّف)/;
// "ما هي قيمة … في المستند؟" — asking what the document states.
const AR_LOOKUP = /(ما|كم|ماذا) (هو |هي |كان |كانت )?(قيمة|قيمه|مستوى|نتيجة|نتيجه|تاريخ|رقم|وحدة|وحده|يذكر|يقول)|(يذكر|يقول|يظهر) (المستند|التقرير)/;
const AR_SCREEN =/ادويتي|أدويتي|الأدوية|الادوية|وصفاتي|الوصفات|سجلاتي|السجلات|نتائجي|تقاريري|اجازه مرضيه|إجازة مرضية|اجازة مرضية|حساسيتي/;

function normaliseArabic(token) {
  let t = token
    .replace(/[ً-ْٰـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي');
  for (const prefix of ['وال', 'بال', 'فال', 'كال', 'لل', 'ال']) {
    if (t.startsWith(prefix) && t.length - prefix.length >= 2) { t = t.slice(prefix.length); break; }
  }
  if (/^[وفبلك]/.test(t) && t.length >= 4 && !AR_TERMS.has(t)) t = t.slice(1);
  return t;
}

function levenshtein(a, b, max) {
  if (Math.abs(a.length - b.length) > max) return max + 1;
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    let best = i;
    for (let j = 1; j <= b.length; j++) {
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
      best = Math.min(best, cur[j]);
    }
    if (best > max) return max + 1;
    prev = cur;
  }
  return prev[b.length];
}

/** The medical words in [text] (English stems, misspellings, Arabic). */
export function medicalTerms(text) {
  const found = [];
  const lower = String(text).toLowerCase().replace(SICK_LEAVE, ' ').replace(APP_NOUN_PHRASE, ' ');
  const words = lower.match(/[a-z0-9]+/g) ?? [];
  for (const stem of STEMS) {
    if (stem.includes(' ')) {
      if (lower.includes(stem)) found.push(stem);
    } else if (words.some(w => w.startsWith(stem))) {
      found.push(stem);
    }
  }
  for (const w of words) if (WORDS.has(w)) found.push(w);
  for (const w of words) {
    // Short words and ordinary app words are too close to real ones
    // ("never"/"fever", "cancel"/"cancer"): exact matches only for those.
    if (w.length < 6 || NOT_FUZZY.has(w)) continue;
    const max = w.length >= 9 ? 2 : 1;
    const hit = FUZZY_WORDS.find(f => f[0] === w[0] && levenshtein(w, f, max) <= max);
    if (hit) found.push(hit);
  }
  for (const raw of String(text).split(/[\s،,.!?؟:;()"'«»]+/)) {
    if (!raw) continue;
    const t = normaliseArabic(raw);
    if (AR_TERMS.has(t)) found.push(t);
  }
  return [...new Set(found)];
}

const SCREEN_STEMS = new Set(['medic', 'prescri', 'allerg', 'vaccin', 'medications', 'medication', 'medicine', 'medicines', 'prescription', 'ادويه', 'دواء']);

/**
 * Whether [text] is (or could be) a medical question. [history] are earlier
 * turns ({role, text}); a follow-up to a medical question counts too.
 * [document] is the attached document's text, when there is one: factual
 * lookups of what it lists stay allowed.
 */
export function isMedicalQuestion(text, { history = [], hasDocument = false } = {}) {
  const message = String(text);
  const terms = medicalTerms(message);
  const arabic = isArabic(message);
  const interpret = INTERPRET.test(message) || (arabic && AR_INTERPRET.test(message));
  const advice = ADVICE.test(message) || (arabic && AR_ADVICE.test(message));
  const definition = DEFINITION.test(message) || (arabic && AR_DEFINITION.test(message.trim()));

  // Plain navigation to an app screen ("Where are my medications?").
  const screensOnly = terms.length > 0 && terms.every(t => SCREEN_STEMS.has(t));
  const navigation = ASKS_FOR_PLACE.test(message) && !interpret && !advice &&
    (screensOnly || (arabic && AR_SCREEN.test(message) && terms.every(t => SCREEN_STEMS.has(t))));
  // "What value does the document list for glucose?" — a lookup, not a
  // medical question, but only with a document and no interpretation.
  const lookup = hasDocument && (FACT_LOOKUP.test(message) || AR_LOOKUP.test(message)) && !interpret && !advice;

  let medical = false;
  if (terms.length > 0 && !navigation && !lookup) medical = true;
  if (interpret && (terms.length > 0 || hasDocument || /\b(result|value|level|reading|test|number|score)s?\b/i.test(message) || /نتيج|قيم|مستوى|تحليل/.test(message))) medical = true;
  if (advice && (terms.length > 0 || hasDocument || /\b(eat|drink|sleep|take|weight|health|body|baby|feel|results?|values?)\b/i.test(message))) medical = true;
  if (definition && terms.length > 0 && !lookup) medical = true;

  // A follow-up to an earlier medical question ("and for my mother?").
  if (!medical && !navigation) {
    const lastUser = [...history].reverse().find(t => t.role === 'user');
    if (lastUser && isMedicalQuestion(lastUser.text, { hasDocument }) &&
        (FOLLOW_UP.test(message) || interpret || advice || /\b(it|that|this|those|them|one)\b/i.test(message))) {
      medical = true;
    }
  }
  return medical;
}

// --- Output checks -------------------------------------------------------------

const INTERPRETIVE_OUTPUT = /\b(means?|meaning|indicat\w*|suggest\w*|consistent with|likely|unlikely|could (be|mean|indicate)|may (be|indicate|mean|suggest)|might|risk|recommend\w*|should|consult|see a doctor|treatment|diagnos\w*|normal|abnormal|healthy|concerning|worrying|dangerous|serious)\b/gi;

/**
 * Interpretive or advisory words in [output] that [source] does not itself
 * contain — added meaning the reply must not carry.
 */
export function addedInterpretation(output, source) {
  const src = String(source).toLowerCase();
  const added = [];
  for (const m of String(output).matchAll(INTERPRETIVE_OUTPUT)) {
    if (!src.includes(m[0].toLowerCase())) added.push(m[0].toLowerCase());
  }
  return [...new Set(added)];
}

/** Medical vocabulary in a general chat reply that the user did not use. */
export function medicalContentIn(reply, userMessage = '') {
  const said = new Set(medicalTerms(userMessage));
  return medicalTerms(reply)
    .filter(t => !SCREEN_STEMS.has(t) && !said.has(t));
}
