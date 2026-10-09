# Task 8 acceptance

Checked locally on 9 October 2026. This report distinguishes the local clinic
application from the shared pilot. Task 7's full clinic remote integration is
unfinished; these results do not approve a public clinical deployment.

## Reproducible gate

Exact versions are in `toolchain.json`: Flutter 3.47.2, Dart 3.13.2 and Node
24.13.0. The previous documentation/CI pin was Flutter 3.44.4; this gate is
aligned with the installed SDK actually used for the checks below.

On Windows with dependencies installed:

```powershell
./tools/validate.ps1 -FlutterRoot C:/flutter -IntegrationDevice windows
```

The script refuses a version mismatch and stops on a failing check. It checks
formatting without rewriting files, analyzes with errors/warnings fatal, runs
Flutter and Node suites, builds shared/local web releases and optionally runs
the real platform database check. Omitting the integration device emits a warning
and does not satisfy platform acceptance. Existing informational lints remain
visible. CI performs the same portable checks before its existing Pages build;
no deployment was performed during this task. A separate Windows CI job runs the
real-engine database test on pull requests/manual dispatch; it was configured
here, not executed on GitHub.

## Coverage

| Task 8 requirement | Automated evidence | Scope / remaining check |
| --- | --- | --- |
| Generation preserves completed/dismissed state and deadlines | `test/services/task_correctness_test.dart` | Both final states, AI, owner and cover checked. |
| Disjoint panels and private rationale | `task_correctness_test.dart`, `test/security/authorization_test.dart` | Unrelated generation/read/write and admin clinical rationale refused. |
| Storage/version failures reported honestly | `task_correctness_test.dart` | Original storage failure, partial generation and ranker conflicts. |
| Urgent work and stable ordering | `task_correctness_test.dart` | Urgency precedes deadline/AI; deterministic ID ties. |
| Issuance retry exactly once | `test/services/document_service_test.dart`, shared server suite | Immutable snapshot, issue audit, render retry and delivery deduplication. |
| Mismatched sources/issuer, invalid dates, retained inputs | Document service and Records workflow suites; document form inspection | Invalid calendar dates, source patient, current credential, upload failure/duplicate form retention. `document_workspace_screen.dart` resets preparation inputs/retry key only on success. |
| Nurse/admin signing and approved reprint | Document service suite | Signing authority refused; approved explicit reprint permission checked. |
| Frozen identity/bytes and replacements | Document service suite | All proposed document types, profile edits, old copies and renewed approval. |
| Revocation/render/verification failures | Document service and shared server suites | Failed rendering cannot report ready; registry failure rolls back; revoked stored downloads fail. |
| Employer disclosure and minimal verification | Document service suite | Policy disclosure rules and exact minimal verification fields. |
| Beyond first page, imports/review | `test/features/records_history_test.dart`, `records_workflow_test.dart` | 260 records, originals, patient-scoped duplicates, pending review, reopen/backup. |
| Proxy subjects and live revocation | Records workflow, `test/security/live_access_revocation_test.dart`, authorization suites | Subject switching, view/manage permissions, active-screen invalidation and next-action denial. |
| Cover source access/outcomes | `test/services/task_workflow_test.dart`, task correctness suite | Receiver acceptance, source-patient match, temporary care access, outcomes, expiry and unrelated denial. |
| EN/AR, long/mixed PDF pagination, accessibility | `test/features/small_phone_readability_test.dart`, `accessibility_test.dart`, `test/services/document_pdf_acceptance_test.dart` | EN/AR at 320px and OS scales 1/2/3; 90 mixed-direction paragraphs retained across A4 pages with reference/date on every page. Physical grayscale printing and fluent Arabic visual review remain open. |
| Shared cross-device and interrupted delivery retries | `services/shared_api/server.test.mjs`, `load.mjs`, Flutter shared client/workspace tests | Independent authenticated clients, duplicate/contending writes, server worker after client departure, retry deduplication. Full clinic screens await Task 7 adapters; no real multi-device browser session was claimed. |
| Pinned format/analyze/tests/build/platform | Script and CI described above | See recorded results below. |
| Existing workflows, migrations and recovery | Full Flutter suite, `test/data/stuck_migration_test.dart`, `backup_restore_rehearsal_test.dart`, shared backup tests | Auth, scheduling, consultations, payments, authorization, local schema recovery and encrypted shared restore. |

## Corrections made during acceptance

Restored the slideshow Pause/Resume control and fixed enlarged-text goal selection
and document labels. Updated stale tests for the current admin navigation and
theme control, gave the appointment-filter test its preferences dependency and
made the Timeline browse test scroll to its existing footer. The user's Records
layout, staff Profile and Inbox quick action remain in place. Two existing carousel
tests disagreed about the presence of a Pause button; both now check the accessible
control and retain their swipe/arrow/timer assertions.

The long single-paragraph PDF check exposed a rendering failure: a non-spanning
padding wrapper prevented text taller than one page from continuing. Paragraphs
now use spanning text directly with separate spacing. The regression check
verifies all 500 repeated clauses and the final marker survive across pages.

Six existing Dart files needed formatting; those changes are whitespace only.
The new PDF stress checks exercise real bundled fonts and text extraction rather
than a mock renderer. Extracted Arabic text does not prove correct visual shaping
or translation; that remains a human review.

## Recorded results

- Focused fixes: 29 Flutter checks passed.
- Real EN/AR PDF pagination and long single note: 3 checks passed.
- Document/PDF/carousel regression rerun: 30 checks passed (overlapping the above).
- Shared API/load/public verification: 11 Node checks passed.
- Formatting: 497 Dart files, zero changes required.
- Analysis: no errors or warnings; 141 informational findings.
- Final full Flutter suite: 643 checks passed, zero failures.
- Pinned `flutter analyze --no-fatal-infos`: passed, no errors/warnings; the same 141 informational findings remain.
- Shared pilot release web build: passed (84.6 seconds).
- Local demo release web build: passed (112.2 seconds).
- Windows real-engine integration: attempted, blocked before test execution with
  `Unable to find suitable Visual Studio toolchain`. Install a supported Visual
  Studio C++ desktop workload and rerun the gate with `-IntegrationDevice windows`.
  No Windows integration pass is claimed; the separate CI job remains unexecuted.
- UI pattern detector: no findings; PowerShell gate parsing and whitespace checks passed.

Logs from this run are in the ignored `.tmp/task8-*` files. Reproduce with the
gate rather than treating local logs as a deployment artifact.

## Open acceptance work

1. Finish Task 7 remote integration, provider configuration and Arabic-capable
   shared rendering before testing every clinic flow across devices.
2. Review EN/AR exported pages visually with long identities/notes, confirm Arabic
   shaping and mixed direction, and print representative drafts/issued pages in
   grayscale. Text extraction and A4 dimensions are insufficient for print approval.
3. Run appropriate real-engine database integration on each intended target.
   This machine currently lacks the suitable Visual Studio toolchain for Windows.
   Public HTTPS, durable hosting/offsite recovery and physical-device checks follow
   the later hosting/platform decision.
