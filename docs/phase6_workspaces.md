# Phase 6 — Shared interaction system and role workspaces

Status of the Phase 6 backlog in `WHOLE_APP_REVIEW_TODO.md`. There is no
schema change. Evidence: `test/phase6/`, plus the updated dashboard, home and
settings tests.

The existing clinical-premium visual system is kept (`DESIGN.md`). This phase
changes what each screen puts first and how failures read, not its look.

## Shared components

| Component | File | Contract |
|---|---|---|
| `AsyncDataView<T>` | `core/presentation/data_state_view.dart` | One widget for every read state; see below. |
| `AccessBoundaryView` | same | Protected content is gone. Explains the boundary, and offers "Sign in again" only when the session ended — never a retry that cannot succeed. |
| `describeFailure` / `showMutationFeedback` | `core/presentation/feedback.dart` | Maps a typed failure to a localized message and at most one recovery action; see below. An action with no handler on that screen is left out rather than offered and ignored. |
| `OperationalList<T>` | `core/presentation/operational_list.dart` | Search and arbitrary filters, stable selection across refreshes, freshness, paging, wide tables and phone cards. The admin review queue uses owner, age and status filters. |
| Existing | `states.dart`, `paging_widgets.dart`, `status_badges.dart`, draft status (Phase 4), document download button (Phase 5), confirmation overlay | Unchanged. `DataState.fromAsync` now takes `staleAfter`. |

### How `AsyncDataView` renders each read state

It is built on the Phase 2 `DataState`, so "we don't know" and "there is
nothing" can't be confused:

| State | What the screen shows |
|---|---|
| Loading | A placeholder, so the layout stays stable |
| Refreshing | The data, with a thin progress line |
| Stale | The data, with when it was last updated |
| Offline | The data, with a banner |
| Failed, with earlier data | The earlier data, with "Couldn't refresh" and Try again |
| Failed, with nothing | An error with a retry — never the empty state |
| Conflict | The data, with Reload |
| Access lost | The access boundary |
| Ready | The content, or the empty state only after a successful read that returned nothing |

### Failure feedback

| Failure | What it says | Action offered |
|---|---|---|
| Access denied | The access boundary | None |
| Session expired | Your session has ended | Sign in again |
| Re-authentication needed | Confirm your password | None |
| Conflict | Someone changed this first | Reload |
| Payment pending | Not yet confirmed; you have not been charged twice | Check payment status |
| Offline / network | Couldn't reach MyHealth Care | Try again |
| Validation, not found, declined, file | The repository's own specific message | None |
| Anything else | A generic localized message (internal error text is never shown) | Try again |

**Adoption:** every surface built in this phase uses these components. About
54 older screens still print `failure.message` themselves. They are safe,
because the repositories write those messages for users, but they don't yet
get localized recovery actions. They are listed as remaining work.

## Screen frame

- **34 ordinary screens** moved from a hand-built `Scaffold` to `AppScaffold`
  (`tools/migrate_app_scaffold.py`). They use `centerBody: false`, so each
  layout is unchanged, and they now share one app-bar treatment.
- **Deliberate exceptions**, which keep their own frame:
  - sign in, registration and password recovery (full-screen flows);
  - the booking flow (full-screen);
  - the message thread (chat);
  - the staff schedule (calendar);
  - the patient chart (list-detail workspace);
  - the clinical scribe (a full-screen tool).

## Role workspaces

### Admin

The dashboard now leads with ownership and correction:

- **Hero** says how much is waiting and opens the most clinically urgent
  queue.
- **"Needs attention"** lists one row per exception queue, each with a
  count, a breakdown, and "Waiting since" the oldest item:
  - results nobody owns, overdue, or escalated;
  - patient messages past their reply time;
  - open referrals, flagging those without an owner or overdue;
  - notifications not delivered;
  - payments to confirm or refund;
  - overdue invoices (not every unpaid one);
  - password resets;
  - home visits;
  - feedback.
- **Failed and empty queues:** a queue that fails to load says "Couldn't
  check: …" on its own row. Queues checked and empty collapse into "Checked
  and clear: …".
- **Removed from the first screen:** system totals and 90-day appointment
  analytics, which are one tap away under Analytics.
- **New "Work needing attention" screen** (`/admin/dashboard/work`):
  - assign or hand over result reviews;
  - see overdue messages, with their owner and cover;
  - see delivery problems, and "Retry failed deliveries", which puts failed
    outbox events back in the queue (audited).

### Staff

- **Dashboard sections:** "Results to review" (Phase 4) and a new "Awaiting
  your reply" section. The latter lists patient messages the clinician owns
  or covers, earliest due first, overdue in red, with "Covering for Dr X"
  where it applies.
- **Covered threads:** a covered thread opens as the owner's thread, via the
  route's `owner` parameter, so the reply lands in the thread the patient is
  reading. The repository lets the covering clinician read that thread (as
  well as send, which Phase 4 already allowed). Nobody else can.

### Patient home

The home screen is now in priority order:

1. Allergy alert.
2. **"Needs your attention"**:
   - new care-team replies;
   - an overdue bill;
   - payments still being confirmed;
   - family-link requests.

   The strip is hidden only when every source was read and nothing is
   waiting. A failed source shows "Couldn't check".
3. The next appointment, as the screen's single anchor. Neighbouring tickets
   that peek in at the edges are no longer tappable slivers or read twice by
   screen readers.
4. Health figures.
5. Booking and quick actions.

## Settings

- **Grouping:** preferences are grouped by where they are kept.
  - **"On this device":** theme, text size, language, motion and high
    contrast. Saved in this browser and used by anyone who signs in here.
  - **"For your account":** alert channels. Saved per person on this device.
- **Resets:** each group keeps its own reset (appearance, or notifications),
  and a setting that fails to save says so and rolls back.
- **Clinic-wide settings** (hours, AI) stay on administrator pages.

### Motion and high contrast (behaviour and persistence)

- **Motion**:
  - `system` follows the OS reduce-motion setting (the default);
  - `reduced` removes non-essential animation whatever the OS says;
  - `full` keeps it.
  - Stored per device (`ui.motionPreference`) and applied app-wide in
    `app.dart`.
- **High contrast** switches to the high-contrast light and dark themes, with
  stronger text and borders. Stored per device (`ui.highContrast`).
- **Both:** sit in the "On this device" group and are cleared by "Reset
  appearance".

## Completion

- All 54 legacy raw failure messages now pass through `describeFailure`.
- Indexed role shells keep tabs stable and nested detail pages subordinate.
- Staff selection persists across chart, inbox, tasks, and schedule.
- Secondary clinical screens now use quieter inline condition metadata.
