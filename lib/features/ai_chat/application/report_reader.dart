/// Reads a report on the device, without any AI service: a short summary
/// with the report's own conclusion, and answers to questions taken from the
/// report's own lines. Used whenever the report AI service is not connected
/// (the public demo) or fails.
///
/// It only repeats what the text says — values, units and High/Low labels
/// exactly as written, quoted — and never judges, diagnoses or advises. When
/// the report does not say, it says so.
library;

/// Lab terms whose plain meaning helps a patient read the summary.
const _plainTests = <String, String>{
  'hba1c': 'average blood sugar over 2–3 months',
  'glucose': 'sugar in the blood',
  'cholesterol': 'fat in the blood',
  'ldl': 'the "bad" cholesterol',
  'hdl': 'the "good" cholesterol',
  'triglyceride': 'a type of fat in the blood',
  'hemoglobin': 'the part of red blood cells that carries oxygen',
  'haemoglobin': 'the part of red blood cells that carries oxygen',
  'ferritin': 'iron stores',
  'vitamin d': 'vitamin D',
  'b12': 'vitamin B12',
  'tsh': 'thyroid function',
  'creatinine': 'kidney filtering',
  'egfr': 'kidney filtering',
  'alt': 'liver health',
  'ast': 'liver health',
  'white blood': 'white blood cells, which fight infection',
  'wbc': 'white blood cells, which fight infection',
  'platelet': 'cells that help blood clot',
  'sodium': 'a salt that balances body fluids',
  'potassium': 'a salt important for the heart and muscles',
  'crp': 'inflammation',
};

final _high = RegExp(
  r'(?<![A-Za-z/])H(?![A-Za-z/])|\bhigh\b(?!\s*-?\s*density)|\belevated\b|↑',
);
final _highWord = RegExp(
  r'\b(high|elevated)\b(?!\s*-?\s*density)',
  caseSensitive: false,
);
final _low = RegExp(r'(?<![A-Za-z/])L(?![A-Za-z/])|↓');
final _lowWord = RegExp(
  r'\b(low|decreased)\b(?!\s*-?\s*density)',
  caseSensitive: false,
);
final _digit = RegExp(r'\d');
final _conclusionHead = RegExp(
  r'^\s*(final\s+)?(conclusions?|impressions?|comments?|summary|interpretation|assessment|opinion|diagnosis|findings?)\s*[:\-–]',
  caseSensitive: false,
);
final _conclusionHeadArabic = RegExp(
  r'^\s*(الخلاصة|الاستنتاج|التشخيص|الانطباع|ملاحظة|ملاحظات|التعليق)\s*[:：\-–]',
);
final _date = RegExp(
  r'\b(\d{4}-\d{2}-\d{2}|\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}|\d{1,2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{4})\b',
  caseSensitive: false,
);
final _typeLine = RegExp(
  r'^\s*(laboratory|lab|report|test|exam(ination)?|study|procedure|panel)\s*[:\-–]\s*(.{3,80})$',
  caseSensitive: false,
);
final _facility = RegExp(
  r'^\s*(hospital|clinic|laboratory|lab|facility|issued by|centre|center)\s*[:\-–]\s*(.{3,80})$',
  caseSensitive: false,
);

/// High / Low as the report itself labels a line (null when unlabelled).
String? reportLabel(String line) {
  if (_high.hasMatch(line) || _highWord.hasMatch(line)) return 'High';
  if (_low.hasMatch(line) || _lowWord.hasMatch(line)) return 'Low';
  return null;
}

List<String> _lines(String text) => [
  for (final raw in text.split(RegExp(r'[\r\n]+')))
    if (raw.trim().isNotEmpty) raw.trim().replaceAll(RegExp(r'\s+'), ' '),
];

String _clip(String line, [int max = 160]) =>
    line.length <= max ? line : '${line.substring(0, max - 1)}…';

bool _isResultLine(String line) {
  if (!_digit.hasMatch(line) || line.length > 200) return false;
  final lower = line.toLowerCase();
  return reportLabel(line) != null ||
      _plainTests.keys.any(
        (t) => RegExp('\\b${RegExp.escape(t)}').hasMatch(lower),
      ) ||
      RegExp(
        r'\d\s*(%|mg/dl|mmol/l|g/dl|g/l|µmol/l|umol/l|pmol/l|nmol/l|ng/ml|iu/l|u/l|miu/l|x10)',
        caseSensitive: false,
      ).hasMatch(line);
}

/// The report's stated conclusion line (with the next line when the heading
/// stands alone), or null when it states none.
String? reportConclusion(String text) {
  final lines = _lines(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_conclusionHead.hasMatch(line) &&
        !_conclusionHeadArabic.hasMatch(line)) {
      continue;
    }
    final body = line.replaceFirst(RegExp(r'^[^:：\-–]*[:：\-–]\s*'), '');
    if (body.trim().length < 3 && i + 1 < lines.length) {
      return _clip('$line ${lines[i + 1]}', 300);
    }
    return _clip(line, 300);
  }
  return null;
}

/// Where the report says it was issued, when it says so plainly.
String? reportIssuer(String text) {
  for (final line in _lines(text).take(15)) {
    final m = _facility.firstMatch(line);
    if (m != null) return m.group(2)!.trim();
  }
  return null;
}

String _kindOf(String text, String title) {
  for (final line in _lines(text).take(10)) {
    final m = _typeLine.firstMatch(line);
    if (m != null) return m.group(3)!.trim();
  }
  final t = '$title\n${text.length > 4000 ? text.substring(0, 4000) : text}'
      .toLowerCase();
  if (RegExp(
    r'x-ray|xray|\bmri\b|\bct\b|ultrasound|radiolog|scan',
  ).hasMatch(t)) {
    return 'Imaging report';
  }
  if (t.contains('discharge')) return 'Discharge summary';
  if (RegExp(r'prescription|\brx\b').hasMatch(t)) return 'Prescription';
  if (_plainTests.keys.any(t.contains)) return 'Lab results';
  return 'Medical document';
}

/// A short summary of [text] — the kind of report, its date, up to four
/// results exactly as written with the report's own High/Low labels — and
/// its conclusion: the one it states, or a plain count of what it labels.
String summarizeReportOnDevice(String text, {required String title}) {
  final lines = _lines(text);
  final results = [
    for (final l in lines)
      if (_isResultLine(l)) l,
  ];
  final labelled = [
    for (final l in results)
      if (reportLabel(l) != null) l,
  ];
  // Labelled results first, then the rest, in report order.
  final shown = [
    ...labelled,
    for (final l in results)
      if (!labelled.contains(l)) l,
  ].take(4);

  final out = StringBuffer('• Type: ${_kindOf(text, title)}');
  final date = _date.firstMatch(text)?.group(0);
  if (date != null) out.write('\n• Date on the report: $date');
  for (final line in shown) {
    final label = reportLabel(line);
    out.write('\n• ${_clip(line)}');
    if (label != null) out.write(' — the report labels this as $label');
  }
  final meanings = <String>{
    for (final line in shown)
      for (final MapEntry(key: test, value: meaning) in _plainTests.entries)
        if (RegExp('\\b${RegExp.escape(test)}').hasMatch(line.toLowerCase()))
          '${_displayName(test)}: $meaning',
  };
  if (meanings.isNotEmpty) {
    out.write('\n\nWhat these measure: ${meanings.take(4).join('; ')}.');
  }

  out.write('\n\nConclusion: ');
  final conclusion = reportConclusion(text);
  final high = labelled.where((l) => reportLabel(l) == 'High').length;
  final low = labelled.length - high;
  if (conclusion != null) {
    out.write('the report states “$conclusion”');
    if (labelled.isNotEmpty) {
      out.write(' It labels ${_count(high, low)}.');
    }
  } else if (labelled.isNotEmpty) {
    out.write(
      'the report labels ${_count(high, low)}. It does not state an overall '
      'conclusion.',
    );
  } else if (results.isNotEmpty) {
    out.write(
      'no result is labelled High or Low in the text I could read, and the '
      'report does not state an overall conclusion. That does not confirm '
      'the results are normal.',
    );
  } else {
    out.write(
      "I couldn't find test results or a stated conclusion in the text I "
      'could read.',
    );
  }
  out.write(
    '\n\nPlease ask a healthcare professional what this means for you.',
  );
  return out.toString();
}

/// How a lab term is usually written.
String _displayName(String test) => switch (test) {
  'hba1c' => 'HbA1c',
  'egfr' => 'eGFR',
  'vitamin d' => 'Vitamin D',
  'b12' => 'Vitamin B12',
  'white blood' => 'White blood cells',
  _ when test.length <= 4 => test.toUpperCase(),
  _ => '${test[0].toUpperCase()}${test.substring(1)}',
};

String _count(int high, int low) => [
  if (high > 0) '$high ${high == 1 ? 'result' : 'results'} as High',
  if (low > 0) '$low ${low == 1 ? 'result' : 'results'} as Low',
].join(' and ');

const _stopWords = {
  'what',
  'whats',
  'my',
  'the',
  'is',
  'was',
  'were',
  'are',
  'level',
  'levels',
  'result',
  'results',
  'report',
  'value',
  'values',
  'does',
  'did',
  'say',
  'says',
  'about',
  'how',
  'much',
  'many',
  'tell',
  'show',
  'please',
  'can',
  'you',
  'your',
  'this',
  'that',
  'and',
  'for',
  'with',
  'from',
  'have',
  'has',
  'give',
  'number',
  'test',
  'tests',
  'there',
  'any',
  'which',
  'when',
  'who',
  'where',
  'its',
  'mine',
  'me',
  'pdf',
  'document',
  'file',
  'read',
  'reading',
};

/// Spelling variants only — never a different test.
const _variants = {
  'haemoglobin': 'hemoglobin',
  'hemoglobin': 'haemoglobin',
  'anaemia': 'anemia',
  'anemia': 'anaemia',
  'sugar': 'glucose',
};

/// An answer to [question] from the report's own lines: the matching lines
/// as quotes, with the report's High/Low labels. Null when the report does
/// not contain it.
({String answer, List<String> quotes})? answerFromReportOnDevice(
  String text,
  String question, {
  required bool arabic,
}) {
  final lines = _lines(text);
  final q = question.toLowerCase();
  String intro(String en, String ar) => arabic ? ar : en;

  if (RegExp(
    r'conclusion|impression|overall|bottom line|الخلاصة|الاستنتاج|النتيجة النهائية',
  ).hasMatch(q)) {
    final conclusion = reportConclusion(text);
    if (conclusion == null) return null;
    return (
      answer: intro(
        'The report states this conclusion:',
        'يذكر التقرير هذه الخلاصة:',
      ),
      quotes: [conclusion],
    );
  }

  if (RegExp(
    r'\b(high|low|abnormal|flagged|out of range|marked|labelled|labeled)\b|مرتفع|منخفض|غير طبيعي',
  ).hasMatch(q)) {
    final wantHigh = RegExp(r'\bhigh\b|مرتفع').hasMatch(q);
    final wantLow = RegExp(r'\blow\b|منخفض').hasMatch(q);
    final flagged = [
      for (final l in lines)
        if (_isResultLine(l))
          if (reportLabel(l) case final label?)
            if ((!wantHigh && !wantLow) ||
                (wantHigh && label == 'High') ||
                (wantLow && label == 'Low'))
              l,
    ];
    if (flagged.isEmpty) {
      return (
        answer: intro(
          'No result is labelled ${wantLow && !wantHigh
                  ? 'Low'
                  : wantHigh && !wantLow
                  ? 'High'
                  : 'High or Low'} '
              'in the text I could read.',
          'لا توجد نتيجة موصوفة بأنها مرتفعة أو منخفضة في النص الذي تمكنت من قراءته.',
        ),
        quotes: const [],
      );
    }
    return (
      answer: intro(
        'The report labels these results:\n${[for (final l in flagged.take(5)) '• ${_clip(l)} — ${reportLabel(l)}'].join('\n')}',
        'يصف التقرير هذه النتائج:\n${[for (final l in flagged.take(5)) '• ${_clip(l)} — ${reportLabel(l) == 'High' ? 'مرتفعة' : 'منخفضة'}'].join('\n')}',
      ),
      quotes: [for (final l in flagged.take(5)) _clip(l, 300)],
    );
  }

  final words = {
    for (final w in RegExp(
      r'[a-zA-Z0-9]+',
    ).allMatches(q).map((m) => m.group(0)!))
      if (w.length >= 3 && !_stopWords.contains(w)) w,
  };
  final terms = {...words, for (final w in words) ?_variants[w]};
  // "Vitamin D" is one term: a line about vitamin B12 is not an answer.
  final vitaminD = q.contains('vitamin d');
  if (vitaminD) terms.remove('vitamin');
  if (terms.isEmpty && !vitaminD) return null;

  final scored = <(String, int)>[];
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (vitaminD && !lower.contains('vitamin d')) continue;
    final hits =
        terms
            .where((t) => RegExp('\\b${RegExp.escape(t)}').hasMatch(lower))
            .length +
        (vitaminD ? 1 : 0);
    if (hits > 0) scored.add((line, hits));
  }
  if (scored.isEmpty) return null;
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  final best = scored.first.$2;
  final picked = [
    for (final (l, s) in scored)
      if (s == best) l,
  ].take(3).toList();
  final labels = [
    for (final l in picked)
      if (reportLabel(l) case final label?)
        arabic
            ? 'يصف التقرير هذه النتيجة بأنها ${label == 'High' ? 'مرتفعة' : 'منخفضة'}.'
            : 'The report labels this as $label.',
  ];
  return (
    answer: [
      intro('Here is what the report says:', 'هذا ما يقوله التقرير:'),
      ...labels.toSet(),
    ].join('\n'),
    quotes: [for (final l in picked) _clip(l, 300)],
  );
}
