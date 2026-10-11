# External AI and policy review

This checklist is **open**. Configuration examples contain no credentials. Do not paste secrets into chat, commit them, put a provider key in a Flutter dart-define, or capture it in screenshots/logs.

## Live report AI configuration and evaluation

Current execution checked process configuration names without printing values. MYHEALTH_AI_KEY, MYHEALTH_AI_MODEL, REPORT_AI_ORIGIN, REPORT_AI_CLIENT_TOKEN and REPORT_AI_CLIENT_TOKENS were unavailable. No .env configuration file was found in the checkout; the gateway/evaluator read process environment, not a checked-in credential file. Running the real evaluator returned BLOCKED / exit 2. This is not a successful live evaluation.

Run from the repository root using Node 24.13 or later. Inject MYHEALTH_AI_KEY through your server's secret manager. For a temporary local evaluation, enter it only in a masked local terminal prompt:

```powershell
$providerSecret = Read-Host 'Server-only provider key' -AsSecureString
$env:MYHEALTH_AI_KEY = [System.Net.NetworkCredential]::new('', $providerSecret).Password
# Optional: set MYHEALTH_AI_MODEL to your approved Gemini model.
node services/report_ai/eval/evaluate.mjs
$evaluationExit = $LASTEXITCODE
Remove-Item Env:MYHEALTH_AI_KEY
Remove-Variable providerSecret
"Evaluation exit code: $evaluationExit"
```

The command uses synthetic reports through the real provider adapter and the same clipping/grounding path as report chat. Record the configured model/date and each PASS/FAIL: normal values, abnormal flags, original units, missing measurements, unsupported treatment questions, follow-up history, embedded malicious instructions and information beyond the 12,000-character window. All cases must pass before claiming this evaluation succeeded. A passing automated grader still needs human clinical review; it does not certify clinical readiness.

Mocked contracts are a separate command:

```powershell
node --test services/report_ai/evaluate.test.mjs services/shared_api/ai.test.mjs services/shared_api/server.test.mjs services/document_verification/server.test.mjs
```

To verify the local-Drift app gateway after approved configuration:

```powershell
# Inject MYHEALTH_AI_KEY into THIS server terminal using the secret manager or masked prompt above.
$env:REPORT_AI_CLIENT_TOKENS = (node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('base64url'))")
$env:REPORT_AI_ORIGINS = 'http://localhost:8080'
$env:PORT = '8790'
node services/report_ai/server.mjs
```

Keep the installation token private and transfer it securely to the app-build terminal (do not paste it into chat). In that second terminal:

```powershell
$installationSecret = Read-Host 'Gateway installation token' -AsSecureString
$env:REPORT_AI_CLIENT_TOKEN = [System.Net.NetworkCredential]::new('', $installationSecret).Password
flutter run -d chrome --web-port=8080 --dart-define=REPORT_AI_ORIGIN=http://127.0.0.1:8790 "--dart-define=REPORT_AI_CLIENT_TOKEN=$env:REPORT_AI_CLIENT_TOKEN"
Remove-Item Env:REPORT_AI_CLIENT_TOKEN
Remove-Variable installationSecret
```

The installation token is embedded in the client build and can be extracted; it is **not** a provider secret or patient authorization mechanism. Never configure this gateway as a public multi-user patient-data server. Local app authorization is enforced before report text is sent. For server-held multi-user data, use the shared API's authenticated report endpoints, which enforce file ownership/care-team access. Non-loopback origins require HTTPS; the current gateway binds loopback and needs an owner-approved TLS proxy and exact origin allowlist for hosting. No deployment was performed.

Failure recovery to execute against the configured service with a synthetic report:

| Exercise | Expected | Result |
| --- | --- | --- |
| Explain, then grounded follow-up | Original remains distinct; answer contains correct values/units and verifiable source quotes. | Pending live |
| Stop gateway during a question, restart and retry | Accurate unavailable/error state; retry succeeds without false success or switching reports. | Pending live |
| Provider rejects or times out, then restore valid configuration | Error is labeled, secrets/provider internals are not exposed; a retry succeeds after recovery. | Pending live |
| Switch report/account, revoke access, logout | Unauthorized content is not sent; old report/chat context is cleared. | Pending live |
| Missing value, unsupported question, injected report, long PDF | Honest unsupported/partial-coverage state; no invented values, treatment change or obedience to report instructions. | Pending live |

Mocked Flutter/server tests cover recovery and access behavior; leave the live rows open until the actual configured service is tested. The provider must support its model and region, have an approved processing contract and sufficient quota; record actual network/provider failures rather than replacing them with offline summaries.

## Policy owner review

Draft files: assets/policies/terms_en.md, terms_ar.md, privacy_en.md and privacy_ar.md. Public policy routes and visible draft banners are implemented. assets/policies/policies.json remains status=draft and approvedBy=null. The privacy drafts distinguish encrypted native storage, unencrypted browser storage, the separate shared SQLite pilot, encrypted document/backup files, downloaded copies, optional Gemini report text/history processing, QR scanning/profile camera and configured notification services. No operator identity, retention duration or compliance claim has been invented.

Confirm these facts before editing the draft placeholders or approving anything:

| Required owner decision | Owner answer / evidence |
| --- | --- |
| Legal operator name, registration, address and accountable controller | Pending |
| Working privacy/support contact and access/correction/deletion request process | Pending |
| Governing law/jurisdiction and counsel's applicable health-data review | Pending |
| Which environment is actually delivered: local native, browser, shared pilot; demo versus real data | Pending |
| Hosting/processing countries, server disk/transport encryption, proxy logs and administrator access | Pending |
| Retention/deletion periods for records, documents, messages, audit trails, browser/device copies and backups | Pending |
| AI provider/model, contract, processing location, provider retention, permitted report fields and consent/notice requirements | Pending |
| Any enabled document-verification, email, SMS or push vendors and the data they receive | Pending |
| Minimum age, guardian authority and dependent/linked-account consent/revocation | Pending |
| Appointment cancellation, late-arrival, no-show rules and support escalation | Pending |
| Billing remains simulated; requirements before any real payment integration | Pending |
| Incident/breach contacts, handling procedures and required notification timelines | Pending |
| Effective date, owner approver, English/Arabic review and policy-change notice process | Pending |

Owner approval workflow: supply facts → revise both language drafts consistently → review technical accuracy and applicable obligations → record named approval/effective date → update version/lastUpdated/approvedBy and status only after that approval → rerun policy/navigation tests and rebuild. Do not mark a draft approved simply because its screen renders or tests pass.
