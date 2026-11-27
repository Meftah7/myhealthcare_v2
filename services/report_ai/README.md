# Report AI gateway

The server side of the **MyHealth assistant** (the Care Navigator chat) in the
full local-Drift app. The app keeps clinical data on the device and has no
server account, so it cannot use the shared API. This small Node service is
the only place the AI provider key exists. The provider is **DeepSeek** (Chat
Completions API); there is no fallback to another provider.

> **Not Gemini.** The staff features that use Google Gemini (see
> [docs/ai_setup.md](../../docs/ai_setup.md)) are a separate integration. The
> patient chatbot and document summaries are controlled only by this gateway
> and the app's `REPORT_AI_ORIGIN` / `REPORT_AI_CLIENT_TOKEN` build settings.

## What the assistant does

1. **Conversation** (`POST /v1/chat`): answers questions about using the app
   and points to the right screen with a real button. The app sends the
   current message once plus a bounded history (≤ 12 turns, each ≤ 2,000
   characters).
2. **Document summaries** (`POST /v1/documents/summarize`): the patient
   attaches a PDF, `.docx`, `.doc` or `.txt` file (≤ 20 MiB), sees its name,
   size, type and status, and presses **Send**. The app extracts the text on
   the device, keeps the original in Records, and uploads only the extracted
   text (with real upload progress). The reply is a short overview plus the
   main points, stating only what the document says.
3. **Factual lookup** in an attached document (`POST /v1/reports/chat`):
   "What value does the document list for glucose?" is answered with the value
   as written and a verbatim quote.
4. **Navigation**: the model may suggest only an action id from `ACTION_IDS`
   in [assistant.mjs](assistant.mjs): `open_appointments`, `book_appointment`,
   `open_records`, `upload_report`, `open_messages`, `open_medications`,
   `open_sick_leave`, `open_profile`. The app maps the id to its own route,
   chooses the label, checks the patient may open it, and navigates only when
   they tap. Nothing books a visit, sends a message or changes data on its own.

## Medical questions are refused

The assistant does **not** answer medical questions — symptoms, diagnoses,
definitions of conditions or tests, what a result means, whether it is
normal, treatment, medicines and doses, diet / exercise / pregnancy advice,
prognosis or urgency — including hypothetical, "for a friend", misspelled,
Arabic, multi-turn and "ignore your rules" variants, and instructions hidden
inside a document. Every such question gets the fixed refusal

> I can help you use the app and summarize your document, but I can’t answer
> medical questions. Please message your doctor or book an appointment to
> discuss this.

(or the fixed Arabic text) with the **Message my doctor** and **Book an
appointment** buttons. A mixed request ("explain my symptoms and book an
appointment") refuses the medical part and still offers booking. Emergency
statements get the fixed emergency-services message.

It is enforced in layers, in the app and again on the server, so a modified
client cannot bypass it:

1. **Before the provider** — [medical_policy.mjs](medical_policy.mjs) (and its
   Dart port, `lib/features/ai_chat/application/assistant_policy.dart`) checks
   the message and recent history: medical vocabulary in English and Arabic,
   tolerant of small misspellings, plus "what does X mean / is it normal /
   should I …" patterns. A refused question never reaches DeepSeek.
2. **Prompts** — every system prompt forbids medical content and tells the
   model to set `medical: true` instead of answering.
3. **Output validation** — a reply flagged `medical`, a reply that contains
   medical vocabulary the user didn't ask about, or a document answer that
   adds interpretation not present in the source is replaced by the fixed
   refusal or by the verbatim quotes.

The cases in [eval/medical_questions.json](eval/medical_questions.json) are
checked by both the Node and the Flutter tests. **This is not perfect**:
keyword and pattern checks plus model instructions reduce the risk, they
cannot guarantee that every possible phrasing is caught or that every
harmless question passes. Report misses so they can be added to the cases.

## Endpoints

All requests need `Authorization: Bearer <client token>`; browsers must come
from an origin listed in `REPORT_AI_ORIGINS`.

| Endpoint | Body | Reply |
| --- | --- | --- |
| `GET /v1/health` | — | `{ready, chat, summarize, explain, provider}` |
| `POST /v1/chat` | `{message, history?}` (reply follows the message's language) | `{reply, action, actions, medical, emergency}` |
| `POST /v1/documents/summarize` | `{text, lang?, fileName?, sourceChars?, extractionComplete?}` + optional `Idempotency-Key` header | `{draft, overview, points, quotes, readable, partial, partialNote, coverage}` |
| `POST /v1/reports/chat` | `{text, question, history?}` | factual answer with quotes, or a refusal |
| `POST /v1/reports/explain` | `{text, lang?}` | older summary shape (compatibility) |

Errors are JSON `{error, code}`:

| Status | `code` | Meaning |
| --- | --- | --- |
| 401 | `unauthorized` | unknown client token |
| 403 | `origin_not_allowed` | browser origin not in `REPORT_AI_ORIGINS` |
| 400 / 413 / 415 | `invalid`, `too_large` | bad or oversized request |
| 429 | `rate_limited` | 30 requests/min per client, 6 summaries/min |
| 503 | `not_configured` | no `DEEPSEEK_API_KEY` |
| 503 | `provider_unavailable`, `provider_busy` | DeepSeek rejected the key / is rate limiting |
| 504 | `provider_timeout` | DeepSeek took too long |
| 502 | `provider_failed`, `invalid_reply` | DeepSeek failed or its reply failed validation |

The app shows a matching message for each (with **Retry** where it helps) and
never shows a canned reply as if it came from the AI.

## Long documents

The gateway accepts up to 120,000 characters of extracted text. Text longer
than one 12,000-character chunk is summarized chunk by chunk (at most 10
chunks) and the partial summaries are combined. `coverage` reports
`sourceChars`, `receivedChars`, `processedChars`, `chunks` and `complete`;
when anything was left out (the file was longer than the app or gateway
limit, or extraction stopped early) the summary is labelled partial and says
how much was read. Repeating a request with the same `Idempotency-Key` within
10 minutes returns the first result instead of calling DeepSeek again.

## Other safeguards

- **Untrusted text:** document text is sent as delimited source material
  after the rules; lines that look like instructions are not used to ground
  answers.
- **Grounding:** every number in a summary point or answer must appear in the
  document, and answers need a verbatim quote, or they are dropped.
- **DeepSeek request:** `thinking` disabled and `response_format: json_object`,
  so the token budget goes to the answer; empty or cut-off replies are
  rejected.
- **Privacy:** no request bodies, messages, document text, credentials or
  provider responses are logged; responses are `Cache-Control: no-store`; the
  provider call is aborted if the client disconnects.

## Authorization boundary

The gateway authenticates the **client build** (a token compared by SHA-256
hash), not the patient. In a web build that token is visible in the public
JavaScript, so treat it as an identifier for rate limiting and revocation —
**not** a secret and not patient authorization. Patient/document access is
enforced in the app before anything is sent. For server-held, multi-user data
use the shared API (`services/shared_api`), which checks the signed-in user.

## Data policy: synthetic documents until approved

- Use **synthetic documents** (like [eval/cases.mjs](eval/cases.mjs)) with a
  configured gateway in demos and smoke tests.
- A **production** build (`APP_MODE=production`) never sends document text
  unless it is built with `--dart-define=REPORT_AI_REAL_DOCUMENTS_APPROVED=true`.
  Set that only after DeepSeek and the deployment are approved for real
  patient documents (data processing agreement, region, retention).

## Run locally

Node 24.13+. Secrets go in the environment (a secret manager in production) —
never in Git or a client build. See [env.example](env.example) (placeholders
only).

```powershell
$env:DEEPSEEK_API_KEY = '<your-deepseek-api-key>'  # server only
$env:REPORT_AI_CLIENT_TOKENS = '<client-token>'    # 32+ chars; see env.example
$env:REPORT_AI_ORIGINS = 'http://localhost:8080'   # exact origins of the web app
node services/report_ai/server.mjs                 # http://127.0.0.1:8790
```

or copy `env.example` to `services/report_ai/.env` (ignored by Git), fill it
in and run `node --env-file=services/report_ai/.env services/report_ai/server.mjs`.

Then run the app against it:

```powershell
flutter run -d chrome --web-port 8080 --dart-define=APP_MODE=demo `
  --dart-define=REPORT_AI_ORIGIN=http://127.0.0.1:8790 `
  --dart-define=REPORT_AI_CLIENT_TOKEN=<client-token>
```

`http://localhost` / `127.0.0.1` is accepted for local testing; any other
gateway origin must be HTTPS. For a release web build served from
`build/web`, also allow the gateway in the page's Content-Security-Policy:
`node tools/set_csp_connect.mjs build/web/index.html http://127.0.0.1:8790`.

Without both build settings the assistant shows **"AI not configured"**,
document summaries are made on the device and labelled "not AI", and
navigation and FAQ still work.

## Deploy

GitHub Pages only serves static files, so the gateway runs elsewhere:

1. Host `server.mjs` (Node 24.13+) on a server or container you control,
   behind an HTTPS reverse proxy (for example Caddy or nginx with a TLS
   certificate) that forwards to it. Keep `HOST=127.0.0.1` when the proxy is
   on the same machine; use `HOST=0.0.0.0` only inside a container or private
   network.
2. Set `DEEPSEEK_API_KEY`, `REPORT_AI_CLIENT_TOKENS` (one token per build) and
   `REPORT_AI_ORIGINS` to the **exact** web origin(s), for GitHub Pages
   `https://<user>.github.io` (an origin has no path, so not
   `/myhealthcare_v2`). No wildcards.
3. Check it: `curl https://<gateway-host>/v1/health -H "Authorization: Bearer <client-token>"`
   should return `"ready":true`.
4. In the GitHub repository, **Settings → Secrets and variables → Actions →
   Variables**, add `REPORT_AI_ORIGIN=https://<gateway-host>` and
   `REPORT_AI_CLIENT_TOKEN=<client-token>`. The Pages workflow passes them to
   the build and adds exactly that origin to the page's `connect-src`. (They
   are variables, not secrets, because the token is public in the built
   JavaScript anyway.)
5. To revoke a build, remove its token from `REPORT_AI_CLIENT_TOKENS` and
   restart the gateway.

## Evaluation

`eval/cases.mjs` holds synthetic documents and questions (lookups, chat,
summaries, a long document whose conclusion is past the first chunk, injected
instructions, Arabic) and `eval/medical_questions.json` the medical-policy
cases. Grade DeepSeek live with:

```powershell
$env:DEEPSEEK_API_KEY = '<your-deepseek-api-key>'
node services/report_ai/eval/evaluate.mjs
```

Without `DEEPSEEK_API_KEY` it prints `BLOCKED` and exits 2.
`node --test services/report_ai/evaluate.test.mjs` runs mocked contract tests
of the policy, validation, DeepSeek request shape and gateway — those are
**not** a live-provider evaluation.
