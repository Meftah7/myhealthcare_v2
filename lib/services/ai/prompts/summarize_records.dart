/// Versioned summarization prompt with a strict JSON output contract (P3-04).
library;

const summarizePromptVersion = 'summarize-v1';

const _jsonContract = '''
Return ONLY a single JSON object, no markdown fences, matching exactly:
{
  "summary": "<3-6 sentence plain-language overview in markdown>",
  "keyEvents": [
    {"date": "YYYY-MM-DD", "title": "<short>", "description": "<optional>", "category": "<diagnosis|procedure|medication|hospitalisation|vaccination|other>"}
  ],
  "trends": [
    {"metric": "<e.g. HbA1c, Blood pressure, Weight>", "direction": "up|down|stable", "summary": "<one line>"}
  ],
  "redFlags": [
    {"severity": "info|warning|urgent", "description": "<what and why>"}
  ]
}
Rules:
- Use only information present in the record. Do not invent values or diagnoses.
- keyEvents: at most 8, most clinically significant, newest first.
- trends: only metrics with at least two data points.
- redFlags: only genuine concerns (out-of-range labs, medication gaps, overdue
  follow-ups). Empty array if none.
- Dates must be ISO (YYYY-MM-DD).
''';

String buildSummarizePrompt(String contextText) =>
    '''
You are a clinical documentation assistant helping a patient understand their
own health record. You are not giving medical advice.

$_jsonContract

--- PATIENT RECORD ---
$contextText
--- END RECORD ---
''';

/// System prompt for the Messages API (P3-05).
const summarizeSystemPrompt =
    'You are a careful clinical summarisation assistant. You output only valid '
    'JSON in the exact requested shape. You never fabricate clinical data.';
