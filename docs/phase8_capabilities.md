# Phase 8 capability scope

## Release decisions

| Capability | Release claim | Owner | Mode | Safe fallback |
| --- | --- | --- | --- | --- |
| Nutrition | Calorie and macro estimate with an example daily split; not a prescribed diet or diary | Patient product owner | Offline | Calculator remains available without network or AI |
| Operations analytics | Historical appointment demand compared with active staff schedule templates; not a prediction | Clinic operations administrator | Offline | Deterministic calculation with an honest failed/stale state |
| Live clinical AI | Draft generation is not approved for release use until consent, retention, evaluation and ownership are signed off | Unassigned clinical safety owner | Disabled | Demo uses labelled mock/offline drafts; production reports unavailable |
| No-show risk | Not approved for care or release use | Unassigned qualified model owner | Disabled | Chronological slots remain available; do not display or persist a score |

Nutrition inputs are keyed by the authenticated account and cleared at sign-out.
The existing session-security tests verify that account switching does not expose
the previous account's inputs. A future dependent diary must use the dependent's
patient identifier rather than the acting account identifier.

## Metric contract

Historical demand counts non-cancelled appointments by clinic-local weekday and
hour. It reports the busiest hour and a relative demand band based on the observed
distribution. The source window is the earliest through latest included
appointment. Cancelled appointments are excluded. Freshness is the calculation
time. A capacity flag is produced only when the observed count exceeds appointment
slots derived from active staff schedule templates; missing schedules never imply
adequate coverage.

## AI and risk governance

AI summary providers remain behind `AiService` and return failures across the
boundary. Clinical summaries are drafts for human review; core booking, charting,
and messaging do not depend on AI. API keys remain in secure storage and are sent
in headers. Live-provider consent, retention policy, named clinical validation,
and evaluation approval are release blockers, not facts the application may infer.

The no-show model stays registered as disabled until a qualified owner records
validation and approves its evaluation data. Its parity tests prove implementation
consistency only; they do not establish clinical or operational validity.

## Gate evidence

- `test/phase8/capability_scope_test.dart`: ownership, safe fallbacks, account /
  dependent isolation, schedule-derived capacity, exclusions and stale state.
- `test/phase8/ai_governance_test.dart`: live-AI release gate, provenance,
  mandatory draft review and unavailable-provider behavior.
- Booking, charting and messaging repositories do not depend on an AI provider.
  Booking regression tests run with both live AI and risk scoring disabled.
- The analytics UI exposes source rows with search, responsive table/cards,
  20-row incremental paging, calculation freshness and retry on failure.
