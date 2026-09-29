# Phase 9 usability kit

Extends `docs/usability_study.md` (P6-07) to every role and the Phase 9
measures. Synthetic accounts only (`docs/test_accounts.md`); no participant
enters real health information.

## Sample grid

Fill one row per participant. Aim for at least one participant in every
column value before comparing baseline and improved rounds.

| ID | Role | Age band | Language | Accessibility setup | Digital confidence | Round |
|---|---|---|---|---|---|---|
| P01 | patient / clinician / nurse-reception / billing / admin | 18–39 / 40–64 / 65+ | English / Arabic | none / screen reader / keyboard only / 200% text | low / medium / high | baseline / improved |

## Consent (read aloud, record verbal or written yes)

> This is a university prototype that uses invented patients only. We are
> testing the app, not you. Please do not type any real personal or health
> information. We record task times and notes, not your name. You can stop
> at any time without giving a reason. Recordings, if any, are deleted after
> analysis. Do you agree to take part?

Consent recorded: yes / no — Facilitator initials: ____ — Date: ____

## Facilitator script

1. Read consent. Confirm the language and accessibility setup.
2. "Think aloud as you go. I can't help with the task itself; I'll tell you
   when to move on."
3. Give one task card at a time. Start the timer when the card is read.
4. Help only after 60 seconds of no progress, or if asked twice. Log it.
5. After each task ask: "What happened just now?" (comprehension).
6. Stop at 5 minutes per task and mark it not completed.

## Tasks by role

| Role | Task | Scenario |
|---|---|---|
| Patient | Book the earliest appointment with a named department | 5 |
| Patient | Cancel it, then check the reminder disappeared | 7, 8 |
| Patient (guardian) | Book for a linked family member, not yourself | 4 |
| Patient | Pay an invoice; interpret a "payment pending" message | 16 |
| Clinician | From the queue, open the right patient and finish a note | 10, 11 |
| Clinician | Review an assigned result and hand it over | 13 |
| Nurse / reception | Check in a walk-in and find their open appointment | 10 |
| Billing | Reconcile a pending payment; explain what the patient was told | 16 |
| Admin | Find overdue messages and assign an owner | 14 |
| Admin | Open System analytics, read operational health, copy evidence | 19, 22 |

## Result template (one row per task)

| Participant | Task | Completed unaided | Assists | Wrong turns | Seconds | Understood outcome | Wrong patient/account | Lost context | Duplicate entry | Corrections | Unowned-work minutes | Queue delay | Issue ID |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

Definitions: *wrong turn* = navigating to a screen not on the direct path;
*lost context* = had to re-find the patient or re-enter data after moving
screens; *duplicate entry* = typed the same information twice.

## After the round

- Log each problem in `docs/phase9_pilot_backlog.md` with severity in the
  backlog's priority order.
- Fix, then run the same tasks with comparable participants (improved round).
- Agree targets only after the baseline and sample size are recorded here.

## Round summary (fill in)

| Round | Participants | Completion unaided | Median seconds | Wrong-patient errors | Notes |
|---|---|---|---|---|---|
| Baseline | | | | | |
| Improved | | | | | |
