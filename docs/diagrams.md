# MyHealth Care — System Diagrams

Diagrams for the project report, derived from the code (schema v29, 46 tables,
339 Dart files). All are Mermaid; GitHub renders them inline, and
[mermaid.live](https://mermaid.live) exports PNG/SVG for the report.

1. [Layered architecture](#1-layered-architecture)
2. [Deployment / runtime](#2-deployment--runtime)
3. [Use cases](#3-use-cases)
4. [Entity relationship (full schema)](#4-entity-relationship-full-schema)
5. [Sequence — sign-in and role routing](#5-sequence--sign-in-and-role-routing)
6. [Sequence — booking with no-show prediction (RQ2)](#6-sequence--booking-with-no-show-prediction-rq2)
7. [Sequence — AI health summary (RQ1)](#7-sequence--ai-health-summary-rq1)
8. [Sequence — consultation to signed note](#8-sequence--consultation-to-signed-note)
9. [Activity — risk detection and task prioritisation (RQ3)](#9-activity--risk-detection-and-task-prioritisation-rq3)
10. [State — appointment lifecycle](#10-state--appointment-lifecycle)
11. [State — walk-in ticket and invoice](#11-state--walk-in-ticket-and-invoice)
12. [Transactional outbox](#12-transactional-outbox)
13. [ML pipeline (offline training → on-device inference)](#13-ml-pipeline-offline-training--on-device-inference)

---

## 1. Layered architecture

Feature-first presentation over a domain/data core. Features depend only on
domain interfaces; Drift is the single implementation behind them.

```mermaid
flowchart TB
  subgraph P[Presentation — lib/features/*/presentation]
    direction LR
    PH[Patient workspace<br/>home · timeline · records · vitals<br/>booking · billing · family · nutrition · AI chat]
    ST[Staff workspace<br/>dashboard · schedule · patient chart<br/>consultation · AI scribe · tasks · results]
    AD[Admin workspace<br/>users · departments · billing<br/>analytics · audit · AI settings]
  end

  subgraph A[Application — Riverpod providers / notifiers]
    APP[features/*/application<br/>session · booking · ai_summary · staff_providers …]
  end

  subgraph APPSHELL[App shell — lib/app]
    R[go_router<br/>role-gated routes]
    TH[Theme · settings · l10n EN/AR RTL]
  end

  subgraph D[Domain — lib/domain]
    E[Entities<br/>Patient · Appointment · MedicalRecord · StaffTask …]
    RI[Repository interfaces<br/>18 abstract repositories]
    ID[Identity & permissions<br/>Principal · UserRole · capabilities]
    CL[Clinical rules<br/>lab_rules · lab_history]
  end

  subgraph S[Services — lib/services]
    AI[ai: AiService<br/>Gemini · Mock · Fallback · governance]
    ML[ml: NoShowPredictor<br/>FeatureExtractor]
    RU[rules: RiskDetection<br/>TaskGenerator]
    SC[scheduling: SlotRecommender]
    NO[notifications: ReminderScheduler<br/>ReminderDispatcher]
    AU[auth: AccessPolicy<br/>PasswordHasher]
    CR[crypto: DocumentCipher<br/>DeviceKeyStore]
    PDF[pdf: reports · clinic_pdf]
    PAY[payments: PaymentGateway<br/>simulated]
    QR[qr: document verification]
  end

  subgraph DA[Data — lib/data]
    RIMPL[Repository implementations]
    OB[sync: Outbox · Idempotency]
    DB[(Drift / SQLite<br/>AppDatabase v29 · 46 tables)]
    SEED[seed: synthetic dataset<br/>60 patients · 12 staff · 5 depts]
  end

  P --> A --> RI
  APPSHELL --> P
  A --> S
  RI -.implemented by.-> RIMPL
  RIMPL --> AU
  RIMPL --> OB --> DB
  RIMPL --> DB
  SEED --> DB
  S --> E
  RIMPL --> E
```

## 2. Deployment / runtime

Offline-first: every platform runs the full stack against a local database.
The only network calls are optional (Gemini API).

```mermaid
flowchart LR
  subgraph Device[User device — Web / Windows / Android / iOS]
    UI[Flutter UI] --> RP[Riverpod]
    RP --> REPO[Repositories]
    REPO --> SQL[(SQLite<br/>web: browser storage)]
    RP --> PRED[No-show model<br/>assets/models/no_show_model.json]
    RP --> SEC[flutter_secure_storage<br/>AI key · device key]
    REPO --> FILES[Encrypted document files]
    RP --> LN[Local notifications]
  end
  RP -. optional HTTPS .-> GEM[Google Gemini API]
  GH[GitHub Pages<br/>meftah7.github.io/myhealthcare_v2] -->|serves web build| UI
  PY[tools/ml — Python<br/>offline training] -->|exports JSON weights| PRED
```

## 3. Use cases

```mermaid
flowchart LR
  Patient((Patient))
  Staff((Staff / Clinician))
  Admin((Admin))
  Gemini[[Gemini AI]]

  subgraph System[MyHealth Care]
    UC1([Register / sign in / recover account])
    UC2([View unified health timeline])
    UC3([Import record / PDF])
    UC4([View vitals, labs, medications])
    UC5([Get AI health summary])
    UC6([Book / reschedule / cancel appointment])
    UC7([Receive risk-adaptive reminders])
    UC8([Pay invoice · wallet · saved card])
    UC9([Message care team])
    UC10([Manage family links])
    UC11([Request home visit / sick leave])
    UC12([View today's schedule + no-show risk])
    UC13([Run walk-in queue])
    UC14([Open patient chart])
    UC15([Conduct consultation · AI scribe · sign note])
    UC16([Review results · acknowledge risk flags])
    UC17([Work prioritised task board])
    UC18([Issue referral · sick leave · prescription])
    UC19([Verify document by QR])
    UC20([Manage users, staff, departments, hours])
    UC21([Billing, refunds, reconciliation])
    UC22([Analytics · forecast · audit log · AI log])
    UC23([Configure AI settings · reseed demo])
    UC24([Export PDF reports])
  end

  Patient --- UC1 & UC2 & UC3 & UC4 & UC5 & UC6 & UC7 & UC8 & UC9 & UC10 & UC11 & UC24
  Staff --- UC1 & UC12 & UC13 & UC14 & UC15 & UC16 & UC17 & UC18 & UC19 & UC24
  Admin --- UC1 & UC19 & UC20 & UC21 & UC22 & UC23
  UC5 -.-> Gemini
  UC15 -.-> Gemini
```

## 4. Entity relationship (full schema)

All 46 tables, grouped by `lib/data/db/tables/*.dart`. Columns are limited to
keys and the most important fields.

```mermaid
erDiagram
  %% Identity (users.dart, identity.dart, family.dart)
  departments ||--o{ staff_profiles : staffs
  users ||--o| patient_profiles : has
  users ||--o| staff_profiles : has
  users ||--o{ staff_credentials : holds
  users ||--o{ care_team_assignments : "assigned to"
  users ||--o{ family_links : links
  users ||--o{ account_recovery_tokens : recovers
  users ||--o{ password_reset_requests : requests

  %% Scheduling (appointments.dart)
  users ||--o{ schedule_templates : "works per"
  users ||--o{ availability_exceptions : "is away"
  users ||--o{ appointments : "patient / staff"
  departments ||--o{ appointments : hosts
  appointments ||--o{ reminders : triggers

  %% Clinical records (records.dart)
  users ||--o{ medical_records : "owns / authors"
  appointments |o--o{ medical_records : produces
  medical_records ||--o{ lab_values : contains
  medical_records ||--o{ document_files : attaches
  medical_records ||--o{ record_reads : "read by"
  medical_records ||--o{ record_corrections : "corrected by"
  medical_records ||--o{ result_reviews : "reviewed in"
  users ||--o{ vitals : records
  users ||--o{ medications : "prescribed / takes"
  appointments ||--o| encounter_drafts : drafts
  appointments ||--o| signed_notes : "signed as"
  signed_notes ||--o{ signed_note_amendments : amends
  users ||--o{ document_verifications : issues

  %% Care services (care.dart)
  appointments |o--o{ sick_leave_certificates : issues
  appointments |o--o{ referral_requests : refers
  departments ||--o{ walk_in_tickets : queues
  walk_in_tickets |o--o| appointments : "becomes"
  departments ||--o{ home_visit_requests : serves
  users ||--o{ care_messages : sends

  %% Billing (billing.dart)
  appointments |o--o{ invoices : bills
  users ||--o{ invoices : owes
  invoices ||--o{ payment_transactions : "paid by"
  invoices |o--o{ wallet_transactions : settles
  users ||--o{ payment_methods : saves
  users ||--o{ simulated_gateway_charges : charged

  %% AI and rules (ai.dart)
  users ||--o{ ai_summaries : summarised
  users ||--o{ staff_tasks : "assigned / about"
  users ||--o{ risk_flags : flagged
  users ||--o{ risk_source_aliases : aliases

  %% System (system.dart, sync.dart, notifications.dart)
  users ||--o{ notifications : receives
  users ||--o{ audit_log : performs
  users ||--o{ ai_usage_log : uses
  users ||--o{ feedbacks : reports
  outbox_events }o..o{ notifications : delivers
  idempotency_records }o..|| users : guards
  app_settings ||..|| app_settings : singleton

  users {
    text id PK
    text role "patient|staff|admin"
    text email
    text passwordHash
    bool isActive
  }
  appointments {
    text id PK
    text patientId FK
    text staffId FK
    text departmentId FK
    datetime slotStart
    text status
    real noShowRisk
    text riskBand
  }
  medical_records {
    text id PK
    text patientId FK
    text authorStaffId FK
    text appointmentId FK
    text recordType
    datetime occurredAt
  }
  lab_values {
    text id PK
    text recordId FK
    text analyte
    real value
    text unit
  }
  invoices {
    text id PK
    text patientId FK
    text appointmentId FK
    real amount
    text status
  }
  ai_summaries {
    text id PK
    text patientId FK
    text inputHash
    text modelId
    text promptVersion
  }
  staff_tasks {
    text id PK
    text staffId FK
    text patientId FK
    text status
    real ruleScore
  }
  risk_flags {
    text id PK
    text patientId FK
    text severity
    text source "rule|ai"
    text acknowledgedBy FK
  }
```

## 5. Sequence — sign-in and role routing

```mermaid
sequenceDiagram
  actor U as User
  participant UI as LoginScreen
  participant S as Session (Riverpod)
  participant AR as AuthRepository
  participant PH as PasswordHasher
  participant DB as SQLite
  participant R as go_router

  U->>UI: email + password
  UI->>S: signIn()
  S->>AR: login(email, password)
  AR->>DB: select user by email
  AR->>PH: verify(password, salt, hash)
  alt valid and active
    AR->>DB: insert audit_log (auth.login)
    AR-->>S: Ok(User)
    S-->>R: session changed (Principal + role)
    R-->>U: redirect to /patient · /staff · /admin home
  else too many attempts
    AR->>DB: insert audit_log (auth.login_locked)
    AR-->>S: Err(locked)
  else invalid / inactive
    AR->>DB: insert audit_log (auth.login_failed)
    AR-->>S: Err(AuthFailure)
    S-->>UI: localized error
  end
```

## 6. Sequence — booking with no-show prediction (RQ2)

```mermaid
sequenceDiagram
  actor P as Patient
  participant UI as Booking screens
  participant BP as rankedSlotsProvider
  participant AR as AppointmentRepository
  participant FE as FeatureExtractor
  participant M as NoShowPredictor
  participant AP as AccessPolicy
  participant DB as SQLite
  participant RS as ReminderScheduler
  participant OB as Outbox

  P->>UI: choose department → doctor → day
  UI->>BP: watch ranked slots
  BP->>AR: openSlots(staffId, day)
  AR->>DB: templates − exceptions − booked
  AR-->>BP: open slots
  loop each slot
    BP->>FE: features(patient history, slot)
    BP->>M: predict(vector)
    M-->>BP: risk + per-feature contributions
  end
  BP-->>UI: slots sorted by lowest risk, earliest tie-break
  P->>UI: confirm slot
  UI->>AR: book(BookingRequest)
  AR->>AP: authorize booking (denial audited)
  AR->>DB: BEGIN TRANSACTION
  AR->>DB: check exception · overlap · template slot
  AR->>DB: insert appointment (noShowRisk, riskBand, ticket, room)
  AR->>OB: enqueue notification event
  AR->>DB: COMMIT
  AR->>RS: scheduleFor(appointment, band)
  RS->>DB: insert reminders (low 1 · medium 2 · high early + confirm)
  AR-->>UI: Ok(Appointment)
```

## 7. Sequence — AI health summary (RQ1)

```mermaid
sequenceDiagram
  actor U as Patient / Staff
  participant UI as AI summary screen
  participant SP as aiSummaryProvider
  participant CB as PatientContextBuilder
  participant C as AiSummaryRepository (cache)
  participant F as FallbackAiService
  participant G as GeminiAiService
  participant MK as MockAiService
  participant L as AiUsageLog

  U->>UI: open summary
  UI->>SP: watch
  SP->>CB: build context (records, labs, vitals, meds)
  CB-->>SP: PatientContext + hash
  SP->>C: cachedFor(hash)
  alt cache hit
    C-->>SP: AiSummary
  else miss
    SP->>F: summarizeRecords(ctx)
    F->>G: Gemini API (if key + AI enabled)
    alt success
      G-->>F: JSON → SummaryParser
    else failure / no key
      F->>MK: deterministic summary
    end
    F-->>SP: HealthSummary
    SP->>L: log usage (model, user)
    SP->>C: save(inputHash, modelId, promptVersion)
  end
  SP-->>UI: summary · key events · trends · red flags
  Note over UI: "AI-generated — informational only" banner
```

## 8. Sequence — consultation to signed note

```mermaid
sequenceDiagram
  actor D as Clinician
  participant Q as Schedule / walk-in queue
  participant CS as Consultation screen
  participant SC as AI scribe
  participant CR as ConsultationRepository
  participant AR as AppointmentRepository
  participant BR as BillingRepository
  participant DB as SQLite

  D->>Q: call in patient
  Q->>AR: markCalledIn / markArrived
  D->>CS: open /staff/consultation/:appointmentId
  CS->>CR: forAppointment() → draft
  D->>SC: dictate / notes
  SC-->>CS: suggested visit note (needs review)
  CS->>CR: save(draft) (autosave)
  D->>CS: add vitals · labs · prescription · referral · sick leave
  D->>CS: sign & complete
  CS->>CR: finalize() → SignedNote (immutable)
  CS->>AR: completeVisit()
  AR->>DB: status = completed
  D->>BR: issue(invoice) from patient chart / admin billing
  Note over CR: later changes only via amend() → SignedNoteAmendment
```

## 9. Activity — risk detection and task prioritisation (RQ3)

```mermaid
flowchart TD
  A[New vitals / lab values / meds / appointments] --> B[RiskDetectionService]
  B --> C{Rule checks}
  C -->|out-of-range vitals| F[risk_flags]
  C -->|abnormal lab per lab_rules| F
  C -->|medication gap| F
  C -->|overdue follow-up| F
  F --> G[TaskGenerator]
  G --> H[staff_tasks with ruleScore]
  H --> I[Staff dashboard<br/>task board sorted by priority]
  F --> J[Risk-flag panel]
  J --> K{Clinician acknowledges?}
  K -->|yes| L[acknowledgedBy set · audited]
  I --> M[open → inProgress → done / dismissed]
```

## 10. State — appointment lifecycle

```mermaid
stateDiagram-v2
  [*] --> booked: book()
  booked --> confirmed: confirm reminder
  booked --> cancelled: cancel()
  confirmed --> cancelled: cancel()
  booked --> booked: reschedule()
  confirmed --> confirmed: reschedule()
  booked --> inProgress: arrived / called in
  confirmed --> inProgress: arrived / called in
  inProgress --> completed: completeVisit()
  booked --> noShow: markOverdueNoShows()
  confirmed --> noShow: markOverdueNoShows()
  completed --> [*]
  cancelled --> [*]
  noShow --> [*]
```

## 11. State — walk-in ticket and invoice

```mermaid
stateDiagram-v2
  state "Walk-in ticket" as W {
    [*] --> waiting: create()
    waiting --> called: claim()
    called --> inProgress: openWalkInVisit()
    inProgress --> done: resolve()
    waiting --> cancelled: cancel()
    called --> cancelled: cancel()
  }
  state "Invoice" as I {
    [*] --> pending: issue()
    pending --> paid: pay / wallet / saved card / offline
    pending --> cancelled
    paid --> refunded: refund()
  }
```

## 12. Transactional outbox

A change and its side effect commit together; delivery happens later and
never blocks or undoes the change.

```mermaid
sequenceDiagram
  participant Repo as Any repository
  participant DB as SQLite
  participant OB as Outbox
  participant D as OutboxDispatcher
  participant N as Notifications

  Repo->>DB: BEGIN
  Repo->>DB: write domain change
  Repo->>OB: enqueue(notification.deliver)
  OB->>DB: insert outbox_events
  Repo->>DB: COMMIT
  Repo->>D: kick()
  loop drain with backoff
    D->>DB: read pending events
    D->>N: deliver (idempotent)
    alt ok
      D->>DB: mark delivered
    else fail
      D->>DB: attempts++ / exhausted
    end
  end
```

## 13. ML pipeline (offline training → on-device inference)

```mermaid
flowchart LR
  subgraph Offline[tools/ml — Python]
    G[generate_dataset.py] --> F[features.py]
    F --> T[train_no_show.py<br/>logistic regression, class-balanced]
    T --> E[evaluate.py<br/>docs/ml_results.md · roc_curve.png]
    T --> X[export → no_show_model.json]
    X --> PAR[export_parity.py<br/>Python ≡ Dart check]
  end
  subgraph App[Flutter app — pure Dart]
    X --> L[NoShowModel.load]
    A[Appointment + patient history] --> FE[FeatureExtractor]
    FE --> P[NoShowPredictor.predict]
    L --> P
    P --> R1[Slot ranking]
    P --> R2[Risk badge on staff schedule]
    P --> R3[Reminder escalation by band]
  end
```
