# Phase 5 — Billing, documents, notifications, and external effects

Status of the Phase 5 backlog in `WHOLE_APP_REVIEW_TODO.md`. Schema v24
(Phase 4's v25 migration follows it). Evidence: `test/phase5/`.

Release scope still applies: there are no real payments, no remote delivery,
and no outside uploads. Every external effect sits behind an interface with a
local, clearly labelled implementation. Nothing is shown as paid, sent or
reviewed unless it actually was.

## Payments

### Ledger

`payment_transactions` records every charge, wallet top-up and refund. Each
row carries:
- kind, method and status (initiated → authorized → settled | failed |
  voided);
- amount;
- the provider, our request reference (the provider's idempotency key), and
  the provider's own reference;
- a masked method descriptor, reason, failure code, actor, and timestamps
  (created, settled, reconciled).

Database rules enforce the ledger whatever code writes to it:

- A payment row can never be deleted.
- A finished payment (settled, failed or voided) cannot change status.
- A payment's amount, kind, invoice and patient cannot change.
- At most one charge per invoice can be in flight or settled.
- An invoice's status can only move pending → paid → refunded, or
  pending → cancelled.

### Provider boundary

`PaymentGateway` (`services/payments/payment_gateway.dart`) has three
operations: `charge`, `refund` and `lookup`. Each is keyed by our request
reference.

The prototype ships only `SimulatedPaymentGateway`:
- Its ledger (`simulated_gateway_charges`) plays the part of the provider's
  own records.
- Test cards follow Stripe's convention: `4000 0000 0000 0002` is declined,
  `4000 0000 0000 9995` has insufficient funds.
- Tests can inject two faults: `unreachable` and `responseLost`.

### How a card payment runs

1. **Record the attempt.** In one transaction, check the invoice is open and
   owned and has no charge in flight, write the transaction as `initiated`,
   and remember the idempotency key.
2. **Ask the provider** to charge, using the attempt's request reference.
3. **Apply the answer** in a second transaction:
   - captured: the transaction is settled and the invoice becomes paid;
   - declined: the transaction fails and the invoice stays open.

If the answer never arrives, the user sees `PaymentPendingFailure` ("we could
not confirm this payment yet; you have not been charged twice"). The invoice
stays unpaid and the transaction stays `initiated`.

### Recovery and reconciliation

- **Retry with the same key.** The patient's sheet keeps its key after an
  unknown outcome. Retrying re-asks the provider with the same reference,
  which returns the original outcome, so there is no second charge.
- **Reconciliation** (`reconcile` / `reconcilePending`) looks up every
  in-flight attempt with the provider:
  - the provider captured it: settle it;
  - the provider declined it: fail it;
  - the provider has no record after 2 minutes: release it as `not_received`
    (nothing was charged).
- **When it runs:** at app start (a system task), whenever the patient's
  payments are loaded, from the pay sheet's "Check payment status", and from
  the admin "Reconcile payments" button.
- **Wallet top-ups** work the same way. The balance is credited only when the
  provider confirms the charge.

### Admin actions

- **No "mark paid".** Setting an invoice to paid is refused; admins use
  "Record desk payment" instead, which needs a receipt number and creates a
  settled `offline` transaction.
- **Cancelling** is refused while a card payment for the invoice is still
  being confirmed.
- **Refunds** need the `refundPayments` permission (admin only) and a
  reason. They are bounded by what is left unrefunded, and a refund cannot
  itself be refunded. Where the money goes back depends on how it was paid:
  - card payments: back through the provider;
  - wallet payments: back to the wallet;
  - desk and pre-ledger payments: recorded as returned at the desk.

  A full refund marks the invoice `refunded`.
- **Auditing:** every step is audited under `billing.*`.

### Payment screens

- **Patient invoices:** an invoice with a payment still being confirmed shows
  "Confirming payment…" with "Check payment status" instead of the Pay
  button.
- **Patient payment history** lists each attempt with its status and
  provider reference.
- **Admin billing screen:** each invoice shows its payment history with a
  Refund action, plus the Reconcile button.

## Notification delivery

### Channels

- **Queued:** only channels the prototype can deliver are queued, in-app
  always plus browser alerts when enabled (`reminderChannelsFor`). This
  fixed an earlier bug: the risk plan only named `push`, so turning push off
  meant no reminders at all.
- **SMS and email:** the toggles are shown but disabled, marked "Not
  available in this prototype". An old SMS or email row is suppressed as
  `channel_unavailable`, never "sent".

### How reminders are delivered

`ReminderDispatcher` (`services/notifications/reminder_dispatcher.dart`)
handles each channel differently:

- **In-app:** in one transaction, the reminder is marked delivered and its
  notice is queued through the outbox, so it cannot be delivered twice or
  lost in between. The notice deep-links to the appointment.
- **Browser alert:** goes out through `DeviceNotifier`, which uses the web
  Notification API; other platforms have no alert channel.
  - If permission is refused or the device has no support, the reminder is
    marked `failed` and not retried. The in-app copy still arrives.
  - A transient failure is retried with backoff (1, 2, 4… minutes). After
    `maxAttempts` it is marked `failed`.
- **Race safety:** every change applies only while the reminder is still
  queued.

### App-closed behaviour

Nothing runs while the app is closed. At start-up, and on a self-armed timer
while the app is open, due reminders are caught up:

| Situation when the app reopens | Outcome |
|---|---|
| Visit still ahead | Delivered, with "(Sent when you reopened the app.)" if more than an hour late |
| Visit started or passed | `suppressed` / `missed_while_closed` |
| Visit cancelled, closed, or rescheduled away | `suppressed` / `appointment_closed` (rescheduling also rebuilds reminders at the new time) |

The push toggle's text no longer promises alerts "even when the app is
closed". Settings shows the real browser permission state, with an "Allow
browser alerts" button when the browser hasn't been asked yet.

## Document import

- **Choosing the patient:** the patient, or someone they manage, picks who
  the document is for.
- **Issuer:** "Issued by" is required. The repository refuses an import
  without one.
- **The original file:**
  - The PDF is checked by magic bytes, a 20 MB limit, and a text-extraction
    timeout and page cap.
  - It is stored in `document_files` on every platform (web previously kept
    only the file name), with its SHA-256.
  - It is read back only through `RecordRepository.sourceFile`, which is
    authorized and audited as `record.source.download`.
- **Review status:** every import starts `pendingReview` and reads "Not
  reviewed by a clinician". A treating clinician can accept it or reject it
  (a rejection needs a reason) from the chart's record sheet, and only once.
  Audited as `record.import.*`.
- **Failure recovery:** a failed read or save keeps every field. The save's
  idempotency key makes retrying safe.
- **Provenance card:** the patient's record screen shows who issued the
  document, when it was imported, the original file, and the review status,
  with "Open original file" and "Export as PDF".

## Exports

- **Authorized and audited:** every export first calls
  `ExportRepository.authorizeExport`, which uses the same access as reading
  the chart and records a `document.export` audit entry. A denial means
  nothing is built. The document's identity strip must match the record's
  patient.
- **Provenance on every PDF:** issuer, source, document date, status and
  reference. For imports it adds the original file name, size and SHA-256.
  The status is one of Final, Record extract, Issued, Not reviewed by a
  clinician, Reviewed by X, or Not accepted.
- **Selectable text:** documents are text, not images. The tests confirm the
  provenance by extracting the real text from the PDF.
- **Bilingual:** the PDF string table (`services/pdf/pdf_strings.dart`) has
  English and Arabic. Arabic documents are laid out right-to-left, with Noto
  Naskh Arabic embedded as a fallback font (SIL OFL, licence in
  `assets/fonts/`). Names and clinical free text are printed as recorded.
- **Download errors:** the download button says what stopped the export (no
  access, missing original, or couldn't build) and offers "Try again" except
  after an access denial.
- **Charts:** the vitals report adds a plain-text summary for each
  measurement (count, range, latest) next to the reading table.
  Patient-entered readings are marked `*`. No export depends on a chart.

## Open decisions

- A real payment provider, and its webhook-driven reconciliation, would
  replace the simulated gateway and its polling. Refund permission policy and
  who may record desk payments need a finance owner.
- An SMS/email provider, and a push server with a service worker, for
  delivery while the app is closed.
- A fluent Arabic review of the document wording (Phase 7).
- The retention period for imported originals stored in the database.
