# Usability study protocol + instrument (P6-07)

**Status: ready to run — needs 5–8 participants.** This file is the protocol and
the questionnaire. Fill in the Results section after the sessions; the numbers
feed P7-03 (results chapter).

## Goal

Answer: *can a first-time user complete the core patient and staff tasks without
help, and how do they rate the experience?* Target: SUS ≥ 68 (above average),
task completion ≥ 80 %.

## Participants

5–8 people, no prior exposure to the app. Mix of:

- 3–5 acting as **patients** (any adult; no clinical background needed)
- 2–3 acting as **staff** (ideally someone with healthcare admin or clinical
  experience, but not required)

Nielsen's rule of thumb: 5 users surface ~85 % of usability problems. 8 gives a
safer SUS mean.

## Setup

- Build: `flutter run -d windows` (release) on the test laptop, or the packaged
  Windows exe.
- Fresh seeded database each session (delete the app-support `.sqlite`, relaunch).
- AI left in **mock mode** so nothing depends on network.
- Screen + audio recording with consent. One facilitator, one note-taker.
- Demo accounts (password `password`):
  - patient: `patient1@myhealth.demo`
  - staff: `staff1@myhealth.demo`
  - admin: `admin@myhealth.demo`

## Tasks

### Patient (give the patient login)

| # | Task | Success criteria | Notes to capture |
|---|------|------------------|------------------|
| P1 | Find your next appointment | Reads it off the home screen | Time, hesitation |
| P2 | Book an appointment in the earliest low-risk slot | Booking confirmed | Did they notice the risk ranking? |
| P3 | Find your most recent lab result and say whether any value is abnormal | Opens the record, reads the abnormal indicator | Colour-only reliance? |
| P4 | Open the AI health summary and say what it is for | Reaches the summary, mentions "not medical advice" | Did the disclaimer register? |
| P5 | Reschedule the appointment from P2, then cancel it | Both actions complete | Confidence, undo-seeking |

### Staff (switch to the staff login)

| # | Task | Success criteria | Notes to capture |
|---|------|------------------|------------------|
| S1 | Run a panel scan and say how many patients need attention | Taps scan, reads the flag count | Discoverability of the scan action |
| S2 | Open the highest-priority task and explain why it is ranked first | Reads the per-task rationale | Was the rule vs AI score understood? |
| S3 | Open a flagged patient's chart and add a clinical note | Note saved, visible on the timeline | Form friction |
| S4 | Prescribe a medication for that patient | Medication appears under active meds | |
| S5 | Check this week's schedule for the busiest day | Identifies the day from the week grid | |

Stop a task at 3 minutes or on request; record as "failed / assisted".

## After each role: SUS questionnaire

Standard 10-item System Usability Scale, 1 = Strongly disagree … 5 = Strongly
agree. Administer once for the patient tasks and once for the staff tasks (or
once overall for participants who did both).

1. I think that I would like to use this system frequently.
2. I found the system unnecessarily complex.
3. I thought the system was easy to use.
4. I think that I would need the support of a technical person to be able to use
   this system.
5. I found the various functions in this system were well integrated.
6. I thought there was too much inconsistency in this system.
7. I would imagine that most people would learn to use this system very quickly.
8. I found the system very cumbersome to use.
9. I felt very confident using the system.
10. I needed to learn a lot of things before I could get going with this system.

### Scoring

- Odd items: score − 1.
- Even items: 5 − score.
- Sum the adjusted items (0–40), multiply by 2.5 → SUS score 0–100.
- Report mean, SD, and min/max across participants. Benchmark: 68 = average.

## Debrief (5 min, open-ended)

- What was the most confusing moment?
- What did you expect to be able to do that you couldn't?
- One thing you'd change.

## Results (fill in)

| Participant | Role(s) | Tasks passed / total | SUS | Notable issues |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |

- **Mean SUS:** _tbd_ (SD _tbd_)
- **Task completion rate:** _tbd_ %
- **Top 3 issues:** _tbd_
- **Actions taken before the defense:** _tbd_
