# AI provider setup — Google Gemini (free tier)

The app is **provider-agnostic**: everything AI goes through the `AiService`
interface (`lib/services/ai/ai_service.dart`). Two implementations ship:

| Implementation | When it runs | Cost |
| --- | --- | --- |
| `MockAiService` | default; also whenever the live call fails | free, offline, deterministic |
| `GeminiAiService` | when AI is enabled, mock mode is off, **and** a key is stored | Google Gemini **free tier** |

`FallbackAiService` wraps them: it calls Gemini first and silently drops to the
mock on any error (no network, bad key, rate limit, malformed response). A bad
conference-room network can never blank a screen.

## Why Gemini free tier

- No credit card required for the free tier.
- `gemini-2.0-flash` (the app default, `model_id` in `app_settings`) is fast and
  well within free-tier limits for a demo (a handful of summaries).
- One-class swap if the supervisor prefers another provider later — only
  `GeminiAiService` would change.

## Getting a key (do this yourself — never paste a key to the assistant)

1. Go to <https://aistudio.google.com/app/apikey> and sign in with a Google
   account.
2. **Create API key** → copy it. It looks like `AIza...`.
3. Add it to the app one of two ways:

   **a. In the app (persists, recommended for the demo laptop)**
   - Sign in as `admin@myhealth.demo` (password `password`).
   - Admin → **AI settings** → paste the key → turn **Mock mode** off.
   - The key is held in the OS secure store (`flutter_secure_storage`), never
     logged, never committed.

   **b. At build time (handy for CI / a one-off run)**
   ```
   flutter run   --dart-define=GEMINI_API_KEY=AIza...
   flutter build windows --dart-define=GEMINI_API_KEY=AIza...
   ```
   A stored key (option a) always wins over the `--dart-define` value.

## Switching between mock and live

`Admin → AI settings`:

- **AI enabled** (default on) — master switch for all AI features.
- **Mock mode** (default **on**) — force the deterministic mock even if a key is
  present. Leave it on for offline demos / the defense rehearsal (P7-04); turn it
  off to show the live Gemini path.

Effective provider = live Gemini only when `AI enabled` **and** `Mock mode off`
**and** a key is available; otherwise the mock.

## What the AI is used for

- Patient **health summary** (`summarizeRecords`) — narrative + key events +
  trends + red flags, parsed from a strict JSON contract (`summary_parser.dart`).
- The staff **task prioritisation** hook (P5-10) currently uses a deterministic
  ranker; the Gemini path slots in here later without touching the UI.

All AI output carries the "informational only, not medical advice" disclaimer
(`AiDisclaimerBanner`).
