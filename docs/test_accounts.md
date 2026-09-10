# Test / demo accounts

Every account the app seeds on first launch, for the report and for testers.

- **Password for every account below:** `password`
- Accounts are created by `lib/data/seed/seeder.dart` when the database is empty
  (first launch, or after deleting the local `.sqlite`).
- Email uses an **un-padded** number (`patient7@…`); the internal user id uses a
  **padded** one (`patient_007`). Log in with the email.
- Names, ages, conditions, allergies and history are randomly generated but the
  seeder's RNG is fixed, so the same data appears on every fresh seed.

## Admin (1)

| Email | Role | Notes |
| --- | --- | --- |
| `admin@myhealth.demo` | admin | User management, departments, system analytics, audit log, AI settings. id `admin_01`. |

## Staff (12)

Doctors. Weekday schedule Sun–Thu, 08:00–20:00, 20-minute slots.

| Email | id | Department |
| --- | --- | --- |
| `staff1@myhealth.demo` | `staff_01` | Family Medicine |
| `staff2@myhealth.demo` | `staff_02` | Family Medicine |
| `staff3@myhealth.demo` | `staff_03` | Family Medicine |
| `staff4@myhealth.demo` | `staff_04` | Internal Medicine |
| `staff5@myhealth.demo` | `staff_05` | Internal Medicine |
| `staff6@myhealth.demo` | `staff_06` | Internal Medicine |
| `staff7@myhealth.demo` | `staff_07` | Cardiology |
| `staff8@myhealth.demo` | `staff_08` | Cardiology |
| `staff9@myhealth.demo` | `staff_09` | Paediatrics |
| `staff10@myhealth.demo` | `staff_10` | Paediatrics |
| `staff11@myhealth.demo` | `staff_11` | Obstetrics & Gynaecology |
| `staff12@myhealth.demo` | `staff_12` | Obstetrics & Gynaecology |

## Patients (60)

`patient1@myhealth.demo` … `patient60@myhealth.demo` (ids `patient_001` …
`patient_060`), all with password `password`.

Useful ones for a demo:

| Email | Why |
| --- | --- |
| `patient1@myhealth.demo` | General-purpose patient login used in the widget tests. |
| `patient3@myhealth.demo` | Chronic patient — most history, lab panels, abnormal values, imaging results, a sick-leave certificate and a message thread. Used across the booking / timeline / care tests. |
| `patient5@myhealth.demo` | Has a scheduled home-visit request. |

## Phase 10 seeded data (services & documents)

| Feature | Where it lands |
| --- | --- |
| Sick-leave certificates | Every other patient (`patient1`, `patient3`, `patient5`, …). Patient → **Records → Sick leave**, or the **Sick leave** home quick action → **Certificate PDF**. |
| Imaging / radiology results | ~⅓ of visits leave an imaging record. Patient → **Records → Imaging** → open a study → **Report PDF**. |
| Message threads ("Ask your doctor") | `patient1`, `patient3`, `patient5`, `patient7`, `patient9` each have a thread with an **unread doctor reply**. Patient → **Ask your doctor**; the doctor sees it under **Dashboard → Messages**. |
| Home-visit requests | `patient2` (requested — waiting), `patient5` (scheduled), `patient10` (completed). Admin triages at **Dashboard → Home visits**. |
| Referral requests (doctor → admin) | Two pending, on `patient4` and `patient9`. Admin actions them at **Dashboard → Referrals**: "Another department" opens a walk-in ticket; "Another hospital" produces a referral letter in the patient's **Records**. |
| Department walk-ins | One waiting Cardiology ticket (`patient8`). A Cardiology doctor (`staff7`) sees it under **Dashboard → Department walk-ins** and taps **Start** to open a consultation. |

## The consultation flow

From **Schedule**, a doctor taps an appointment block → a ticket sheet with
**Call patient / Patient arrived / Patient not shown**. "Patient arrived" opens
`/staff/consultation/<id>`: write a clinical note, add medications, or **Request
a referral** (the admin decides where). **Complete consultation** saves the note
+ medications to the patient record. Everything typed is held in a draft, so
leaving the page and returning resumes it.

Staff can also issue a fresh sick note from a patient's chart (**Patients → open a
patient → + → Issue sick leave**).

Ages span ~8–83. Roughly a quarter of patients carry a raised hidden no-show
tendency (this is what the no-show model is trained to detect); older patients
accumulate more chronic conditions.

## Accounts created only inside tests (not in the running app)

These live in throwaway in-memory databases during `flutter test` and never
reach a real install — listed only for completeness:

| Email | Test file |
| --- | --- |
| `sara@example.com`, `dup@example.com`, `k@example.com`, `p@example.com`, `l@example.com`, `r@example.com` | `test/data/repositories_test.dart` |
| `a@clinic.test`, `b@clinic.test`, `c@clinic.test`, `r@clinic.test`, `t<timestamp>@clinic.test` | `test/data/admin_repositories_test.dart` |
| `dr<timestamp>@e.com`, `p<timestamp>@e.com` | `test/services/risk_detection_test.dart` |

## Resetting

Delete the app-support database file and relaunch to re-seed:

- Windows: `%APPDATA%\bh.edu.uob\myhealthcare\` (or the app-support dir shown by
  `path_provider`) — remove the `.sqlite` file.
- Or, from Admin → AI Settings, use the re-seed action.
