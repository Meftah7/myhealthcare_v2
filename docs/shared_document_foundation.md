# Shared document foundation (Task 3)

These are proposed product rules. The clinic has not approved them. Schema 30
installs six unapproved sick-leave templates (English/Arabic × clinic/employer/
school). No account receives scoped grants automatically. The new official
verification path rejects unapproved policies. Existing export-generated codes
remain readable and are explicitly labeled legacy; they are not upgraded into
immutable official versions.

The review workflow is available at **Admin → Profile → Document policies**.
An administrator can explicitly enable clinic-wide policy management (audited,
with no signing privilege), review the English/Arabic copies, edit and save
draft wording, then acknowledge and approve each saved version. Approval records
the administrator and time. It does not issue a certificate or auto-approve the
other languages/audiences.

Approved wording is read-only. Create a new draft version to change it; approval
of that version atomically retires earlier approved policies for the same type,
language and audience. Existing issued snapshots stay unchanged. A stale review
cannot approve wording that another administrator has changed. Required fields
must remain in the template; diagnosis placeholders are limited to clinic copies.

## Proposed approval and disclosure rules

| Action | Proposed rule |
| --- | --- |
| Prepare | Staff/admin with an explicit preparation grant for the patient, visit department or clinic; preparation does not permit reading the whole chart. |
| Clinical signing | Explicit signing grant, active verified medical licence, staff profile, non-nurse job title, and care relationship; applies equally to an administrator who is also a clinician. |
| Administrative issuance | Separate scoped grant; cannot replace required clinical signing. Attendance/finance document types will be introduced with their own policies. |
| Policy approval | Administrator with settings permission, clinic-wide template grant and recent authentication; each version is approved separately and becomes immutable. |
| Employer/school copy | Patient name, attendance/leave dates, clinic, signer/licence and verification code. Omit diagnosis, medicines, allergies and unrelated history. |
| Clinic copy | Clinical reason may be included within clinical access rules. |
| Reprint | Stored approved bytes only; explicit scoped reprint grant or current self/proxy clinical access. Reprint is audited and cannot regenerate issuance identity. |
| Replacement/revocation | Retain original snapshots and codes. Require scoped authority and reason; replacement has its own version and code. |
| Operational verification | Frozen identity, issuer, issue time and validity; clinical content requires current clinical read access. |

The proposed wording lives in `ProposedDocumentPolicies`. Clinic approval must
confirm qualifications, dates, allowed disclosure and wording before official
use. Application approval records who accepted a particular policy version;
it does not assert legal certification.

## Operational presets

Presets suggest permissions; administrators must explicitly grant each one with
a reason and a clinic, patient or department scope. Grants may start later,
expire or be revoked. Department checks derive from the actual visit. No preset
includes clinical signing. Existing account roles and chart-access rules remain
independent of these grants.

| Preset | Suggested scoped permissions |
| --- | --- |
| Clinic administrator | Prepare, administrative issue, approved reprint, template management, operational assignment, revoke |
| Reception | Prepare, operational assignment |
| Billing | Administrative issue |
| Document desk | Prepare, approved reprint |
| Clinical supervisor | Prepare, approved reprint, operational assignment, revoke |

## Service and transaction contracts

`DocumentService` defines preparation, approval, issuance, rendering, download
and revocation before Task 4 builds screens. It is a contract, not an implemented
issuance/rendering pipeline. The existing export/download paths remain legacy.

- Preparation: validate patient/visit and scope, then commit request plus audit.
  A retry key must match the original payload.
- Approval: recheck qualifications, approved template, disclosure and optimistic
  version; commit transition plus audit. Draft policies never authorize issuance.
- Issuance: atomically persist frozen patient/issuer/content/template snapshots,
  verification binding, issue audit and pending delivery event. A failed binding
  must roll back issuance. Retry returns the same issued version.
- Rendering: follows issuance commit; store bytes and fingerprint together.
  Failure remains explicit and retryable; it never reports a ready official PDF.
- Download/reprint: authorize actual subject and validity, return stored bytes,
  recheck access before delivery, and audit separately from issuance.
- Revocation: atomically change verification validity and append the reason/audit;
  never edit or delete an issued content snapshot.
- Tasks: existing `TaskRepository` owns source refresh, status, priority and cover
  mutations. Source refresh preserves workflow fields. Status/outcome, cover and
  their history should commit together with optimistic version checks. Schema 30
  provides task sources and append-only history/outcome storage; Task 5 integrates
  richer task workflow screens and mutation history. Migration labels known old
  task IDs as legacy sources without inventing clinical provenance.

Schema 30 adds templates, requests, issued snapshots, artifacts, delivery events,
scoped grants and task source/history tables. Record read/correction storage from
schema 29 is reused. Existing verification codes keep their original references;
new bindings use unique issued-version IDs with separate validity/revocation
fields. SQLite guards freeze issued snapshots, approved template content and
bound verification content. Scoped-grant changes/expiry participate in live
session invalidation, including administrator clinical credentials.
