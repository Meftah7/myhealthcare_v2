# Phase 4 — Clinical encounter, results, referrals and handover

Status of the Phase 4 backlog in `WHOLE_APP_REVIEW_TODO.md`. Schema v25 (the
Phase 5 billing/document work already in the tree is v24). Evidence:
`test/phase4/clinical_workflow_test.dart`.

All clinical rules here are **demonstration rules on synthetic data**
(release scope: university prototype). None is clinically validated; each is
named in one place so a qualified clinical owner can replace it.

## What is modelled

| Concept | Where | Notes |
|---|---|---|
| Encounter draft | `encounter_drafts` (v23), `EncounterDraftRepository` | Autosaved while typing (debounced, one save at a time); versioned; restored after restart; only the appointment's clinician may write it. |
| Signed note | `signed_notes` (v23), `EncounterRepository.finalize` | One per appointment (id derived from it). Database triggers block update and delete. |
| Amendment | `signed_note_amendments` | Append-only (triggers); `EncounterRepository.amend`. |
| Medication order | `medications` rows filed at finalization | Deterministic ids per encounter line, so no path can file an order twice. |
| Result review | `result_reviews` (v25), `ResultReviewRepository` | Opened in the same transaction that files an abnormal / critical / range-less lab result. |
| Observation provenance | `lab_values.source`, `provenance`, `verification_status`, `verified_by_staff_id`, `verified_at` | `provenance` records the rule set (`demo-lab-rules-v1`) and whether the issuing lab supplied critical limits. |
| Referral workflow | `referral_requests` owner / coverage / due / priority / handover note | `transition` and `handover`. |
| Task ownership | `staff_tasks.priority`, `coverage_staff_id`, `escalated_at` | Owner plus cover; closed tasks are final. |
| Message queue | `care_messages.queue_owner_staff_id`, `coverage_staff_id`, `response_due_at` | Patient messages only; staff replies are not queued. |

## Rules

**Finalization.** `EncounterRepository.finalize` does all of this in one
transaction: sign the note, file the visit note and medication orders, queue
prescription notices through the outbox, complete the visit, close any
walk-in, delete the draft, and audit. It runs at most once per appointment. A
retry with the same idempotency key, a fresh key after a restart, or a double
tap returns the note that is already signed and writes nothing more.

**Lab classification** (`domain/clinical/lab_rules.dart`):

- A value with no reference range is `unknown`, never `normal`. It shows as
  "No range" with a help icon.
- Critical uses the lab-supplied critical limits when given. Otherwise it
  falls back to the demo heuristic: below `refLow × 0.75` or above
  `refHigh × 1.5`.
- The review priority and due time follow from the flags:

| Flags present | Priority | Due |
|---|---|---|
| Critical | urgent | 1 h |
| Low or high | priority | 24 h |
| Unknown only | routine | 72 h |

**Result review lifecycle.**

- The allowed moves are unassigned → assigned → inReview → resolved. Any open
  state can move to escalated, and escalated goes back to inReview or to
  resolved.
- The owner can change but can never be cleared.
- A handover by the current holder needs a note.
- Only an active doctor can own a review or be escalated to.
- A nurse holding a result can escalate it. Only a doctor with
  `reviewResults` can start or resolve it.
- Resolving records the outcome and marks the result's values verified by the
  resolving clinician.
- Every move is version-checked and audited.

**Referrals.** The allowed path is pending → clarificationRequested →
accepted → arranged → closed, and a referral can be rejected from pending or
clarification.

- The older one-step `decide` (actioned/rejected) still works for the admin
  screen.
- Every step names an owner, who must be an active staff member or admin.
- Changing the owner needs a handover note.
- `handover` changes the owner without changing the state.
- Asking for clarification notifies the requesting clinician through the
  outbox.

**Tasks.**
- The owner or the covering clinician may update a task.
- Status changes are open ↔ inProgress → done or dismissed; done and
  dismissed are final.
- Escalation needs a different, active clinician as cover. It is audited.

**Messages.**
- A patient message is owned by the thread's clinician and due within
  `CareMessageQueue.responseWindow` (24 hours).
- If the clinician is off shift or inactive, an on-duty colleague in the same
  department is recorded as cover. The cover may reply in the thread, and the
  reply is audited as `care_message.cover_reply`.
- `awaitingReply` lists what is still unanswered, for the clinician or for
  admin oversight.
- Patients see the promise: a reply within one working day, and this is not
  an emergency channel.

## Responsibilities (who may do what)

Enforced in the repositories via `RolePermissions`; the UI only reads the
same table to decide what to offer.

| Work | Doctor | Nurse | Admin (clinic operations and billing) | Patient / proxy |
|---|---|---|---|---|
| Draft an encounter | ✓ | ✓ | – | – |
| Sign / finalize an encounter | ✓ (`signEncounter`) | – | – | – |
| Prescribe | ✓ | – | – | – |
| Amend a signed note | ✓ (care relationship) | ✓ (care relationship) | – | – |
| Resolve / start a result review | ✓ (`reviewResults`) | – | – | – |
| Escalate a held result | ✓ | ✓ | – | – |
| Assign / reassign result reviews | own handover | – | ✓ (`manageCareTeams`) | – |
| Work tasks (status, escalate) | ✓ (`manageTasks`) | ✓ | – | – |
| Move / hand over referrals | request only | – | ✓ (`decideReferrals`) | – |
| Invoices, refunds | – | – | ✓ (`manageBilling`, `refundPayments`) | pay own / managed |

There is no separate reception or billing-clerk role in the prototype.
Reception work (walk-in queue) sits with nurses and doctors
(`manageWalkInQueue`). Billing sits with the admin role. Splitting either
into its own role is a permission-table change, not a code change.

## Screens

- **Consultation:**
  - The draft status reads "Saving draft…", "Draft saved HH:mm", "Draft not
    saved" (with Retry save) or "Changed on another screen" (with Load saved
    draft). The note never leaves the screen on failure.
  - Leaving mid-typing still saves.
  - Nurses see "A doctor signs and completes this visit" instead of the
    Complete button.
- **Patient chart:** every timeline record opens a result sheet with the
  values, their source and verification, and the review panel (status,
  priority, owner, cover, due or overdue, plus Start, Mark reviewed and
  Escalate for the holder).
- **Staff dashboard:** "Results to review" lists what the clinician owns or
  covers, most urgent first, with overdue items in red. A failed read shows
  an error, never an empty all-clear.
- **Patient message thread:** shows the reply-time and not-for-emergencies
  banner.

## Open decisions

- Clinical ownership of the lab rules, the review windows and the 24-hour
  messaging promise.
- Whether coverage should also apply to results automatically when their
  owner goes off shift. Today, results are covered only when escalated.
- Break-glass access and reception/billing-clerk roles (carried from
  Phase 1).
