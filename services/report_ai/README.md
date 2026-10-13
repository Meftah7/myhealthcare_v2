# Report AI gateway

Live report explanations and grounded follow-up questions for the **full
local-Drift myhealth app**. The app keeps clinical data on the device and has
no server account, so it cannot use the shared API. This small service is the
only place the AI provider key exists.

## What it does

| Endpoint | Body | Reply |
| --- | --- | --- |
| `GET /v1/health` | — | `{explain, chat}` configuration flags |
| `POST /v1/reports/explain` | `{text}` | `{draft: true, answer, coverage}` |
| `POST /v1/reports/chat` | `{text, question, history}` | `{draft: true, answer, supported, quotes, ungroundedClaim, coverage}` |

- **Grounding:** the model must return JSON with verbatim `quotes`; the server
  keeps only quotes found in the report text it was given, and an answer that
  claims support without one verifiable quote is returned as `supported:
  false` (`ungroundedClaim: true`).
- **Untrusted report text:** sent as a delimited content part; the
  instructions tell the model to ignore instructions inside it.
- **Coverage:** the model sees at most the first 12,000 characters;
  `coverage.complete` is false when the report was longer, and the app
  discloses it.
- **Bounds:** report ≤ 50,000 characters, question ≤ 1,000, history ≤ 12 turns
  of ≤ 2,000 characters, body ≤ 192 KB, 30 requests/minute per client token.
- **Failures:** 401 unknown client, 400 invalid, 429 rate limited, 502
  provider failure (no provider details leaked), 503 not configured.
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
ownership on the server.

## Run locally

Node 24.13+. Configure secrets in the environment (a secret manager in
production) — never in Git or a client build.

```powershell
$env:MYHEALTH_AI_KEY = '<provider key — server only>'
$env:MYHEALTH_AI_MODEL = 'gemini-2.5-flash'        # optional
$env:REPORT_AI_CLIENT_TOKENS = (node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('base64url'))")
$env:REPORT_AI_ORIGINS = 'http://localhost:8080'   # web builds only
node services/report_ai/server.mjs                 # loopback :8790
```

Build the app with the gateway origin and one client token (an installation
credential, revocable by removing it from `REPORT_AI_CLIENT_TOKENS`):

```powershell
flutter run --dart-define=REPORT_AI_ORIGIN=https://<gateway-host> --dart-define=REPORT_AI_CLIENT_TOKEN=<token>
```

`http://localhost`/`127.0.0.1` is accepted for local testing; any other origin
must be HTTPS. Without both values the app reports the report AI as "not
connected", shows its labelled on-device summary, and answers follow-up
questions with a "not connected" notice — never canned answers.

## Evaluation

`eval/cases.mjs` holds synthetic test reports (normal and abnormal values,
units, missing information, unsupported/treatment questions, follow-up
context, embedded malicious instructions, a long report whose answer lies past
the 12,000-character window). Grade a real provider with:

```powershell
$env:MYHEALTH_AI_KEY = '<provider key>'
node services/report_ai/eval/evaluate.mjs
```

Without `MYHEALTH_AI_KEY` it prints `BLOCKED` and exits 2. `node --test` in
this folder runs mocked contract tests of the grader, the grounding check and
the gateway — those are **not** a live-provider evaluation.
