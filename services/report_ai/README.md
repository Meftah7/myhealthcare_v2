# Report AI gateway

The server side of the **MyHealth Report Assistant** in the full local-Drift
app (the Care Navigator chat). The app keeps clinical data on the device and
has no server account, so it cannot use the shared API. This small service is
the only place the AI provider key exists. The provider is **DeepSeek**
(Chat Completions API); there is no fallback to another provider.

## What the assistant does

1. **Summarizes the selected PDF** in 2–5 short bullets and answers follow-up
   questions using only that report — numbers, signs and units exactly as
   written, "The report labels this as High/Low", short verbatim quotes.
2. **Guides the patient to a screen** with a real button. The assistant may
   suggest only an action id from `ACTION_IDS` in [assistant.mjs](assistant.mjs):
   `open_appointments`, `open_records`, `upload_report`. The app maps the id to
   its own route or action, chooses the button label, checks the signed-in
   patient may open it, and navigates only when they tap. The model never
   produces a route or URL, and nothing books a visit, submits a form or
   changes patient data.

It never diagnoses, suggests illnesses, gives medical advice, assesses
symptoms, judges urgency, recommends treatment or tells a patient to change a
medicine; never decides itself whether a result is normal or dangerous; never
guesses missing or unreadable text; never follows instructions inside the
PDF; never uses another document.

Navigation help, emergency and medical-advice replies work **without a PDF
and without this gateway**: the app answers them itself
(`lib/features/ai_chat/application/assistant_policy.dart`).

## Endpoints

| Endpoint | Body | Reply |
| --- | --- | --- |
| `GET /v1/health` | — | `{explain, chat}` configuration flags |
| `POST /v1/reports/explain` | `{text, lang?}` (`lang`: `en`/`ar`) | `{draft, answer, quotes, readable, coverage}` |
| `POST /v1/reports/chat` | `{text, question, history}` | `{draft, answer, supported, quotes, ungroundedClaim, action, refusal, coverage}` |

`action` is `null` or one of `ACTION_IDS`.

## What can reach the patient

The model must reply with JSON; [assistant.mjs](assistant.mjs) validates every
reply on the server:

- **Summary:** 1–5 bullets, each ≤ 300 characters, every number found in the
  report (a bullet with an invented number is dropped), no links or page
  numbers. `readable: false` becomes the fixed "I couldn't read this PDF…".
- **Answer:** shown only when the model claims support **and** at least one
  quote is found verbatim in the report **and** every number in the answer is
  in the report. Otherwise the fixed "I couldn't find that information in this
  report." (or, for a navigation suggestion, the app's own text for that
  screen). The model's unsupported wording is never shown.
- **Refusals:** a question asking for a diagnosis, advice, a judgement of
  seriousness/urgency or a medicine change is answered with the fixed
  "I can explain what your report says. Please ask a healthcare professional
  what the result means for you." and `action: open_appointments` — **without
  calling the provider**. An explicit emergency gets the fixed
  emergency-services message and no action.
- **Anything else** — unreadable JSON, a cut-off reply, links or routes in the
  text, DeepSeek errors or timeouts — is a plain `502`; the app shows a plain
  fallback message. Provider responses and error bodies are never forwarded.

Fixed messages follow the patient's language (Arabic when the question is in
Arabic; the app's language for summaries).

## Other safeguards

- **Untrusted report text:** sent as a delimited message after the rules,
  which tell the model to treat it as source material only.
- **Coverage:** the model sees at most the first 12,000 characters;
  `coverage.complete` is false when the report was longer, and the app says
  "I could only read part of this report…".
- **Bounds:** report ≤ 50,000 characters, question ≤ 1,000, history ≤ 12 turns
  of ≤ 2,000 characters, body ≤ 192 KB, 30 requests/minute per client token.
- **Failures:** 401 unknown client, 400 invalid, 429 rate limited, 502
  provider failure or invalid reply (no provider details), 503 not configured.
- **Privacy:** no request bodies, questions, report text or credentials are
  logged; responses are `Cache-Control: no-store`.

## Authorization boundary

The gateway authenticates the **client installation** (a token compared by
SHA-256 hash), not the patient. Patient/report authorization is enforced in
the app before anything is sent: the Care Navigator re-reads the record
through the access-checked record repository and sends only that report's
extracted text. For server-held, multi-user data use the shared API's
`POST /api/reports/explain` and `POST /api/reports/chat`, which check the
signed-in patient (or current care-team clinician) and the PDF original's
ownership on the server (that service has its own provider configuration).

## Data policy: synthetic reports only until approved

- The public demo (GitHub Pages) has **no gateway configured**, so no report
  text leaves the browser; it shows the labelled on-device summary.
- Use **synthetic reports** (like [eval/cases.mjs](eval/cases.mjs)) with a
  configured gateway in demos.
- A **production** build (`APP_MODE=production`) never sends report text to
  the gateway unless it is built with
  `--dart-define=REPORT_AI_REAL_DOCUMENTS_APPROVED=true`. Set that only after
  DeepSeek and the deployment are approved for real patient documents (data
  processing agreement, region, retention).

## Run locally

Node 24.13+. Configure secrets in the environment (a secret manager in
production) — never in Git or a client build. See [env.example](env.example)
(placeholders only).

```powershell
$env:DEEPSEEK_API_KEY = '<your-deepseek-api-key>'  # server only
$env:DEEPSEEK_MODEL = 'deepseek-flash'             # optional (default)
$env:REPORT_AI_CLIENT_TOKENS = (node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('base64url'))")
$env:REPORT_AI_ORIGINS = 'http://localhost:8080'   # web builds only
node services/report_ai/server.mjs                 # loopback :8790
```

or copy `env.example` to `services/report_ai/.env` (ignored by Git), fill it
in and run `node --env-file=services/report_ai/.env services/report_ai/server.mjs`.

Build the app with the gateway origin and one client token (an installation
credential, revocable by removing it from `REPORT_AI_CLIENT_TOKENS` — not a
provider key):

```powershell
flutter run --dart-define=APP_MODE=demo --dart-define=REPORT_AI_ORIGIN=https://<gateway-host> --dart-define=REPORT_AI_CLIENT_TOKEN=<token>
```

`http://localhost`/`127.0.0.1` is accepted for local testing; any other origin
must be HTTPS. Without both values the app reports the report AI as "not
connected", shows its labelled on-device summary, and answers report
questions with a "not connected" notice — never canned answers. Navigation
buttons work either way.

## Evaluation

`eval/cases.mjs` holds synthetic reports and questions: normal and flagged
values, units, missing information, diagnosis and medicine requests, a
two-part question, navigation inside a report, Arabic, embedded malicious
instructions, a long report whose answer lies past the 12,000-character
window, and summary cases (normal, injected, unreadable). Grade DeepSeek with:

```powershell
$env:DEEPSEEK_API_KEY = '<your-deepseek-api-key>'
node services/report_ai/eval/evaluate.mjs
```

Without `DEEPSEEK_API_KEY` it prints `BLOCKED` and exits 2. `node --test
services/report_ai/evaluate.test.mjs` runs mocked contract tests of the
grader, the validation, the DeepSeek request and the gateway — those are
**not** a live-provider evaluation.
