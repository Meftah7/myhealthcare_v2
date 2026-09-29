# Backup and Restore Rehearsal

Status: passed for the approved synthetic-data web prototype scope.

## Objectives to approve

- Recovery point objective: maximum acceptable committed-data loss.
- Recovery time objective: maximum acceptable service interruption.
- Backup frequency, retention, geographic/storage separation, encryption, and
  key-custody owners.
- Which data must restore atomically: identity/proxy grants, appointments,
  encounters, orders/results, messages/tasks/referrals, billing, outbox, audit.
- Legal hold, deletion, and patient-access implications.

## Rehearsal dataset

Use synthetic but relationship-complete data with:

- multiple accounts, patients, dependents/proxy grants, roles and revoked access;
- past/current/future appointments and a final-capacity slot;
- encounter drafts, signed notes, amendments, medications and results;
- open/closed messages, tasks, referrals and handovers;
- pending/settled/refunded payments and undelivered/delivered outbox events;
- imported source documents, exports, audit events and account-scoped caches;
- records created before and after every supported schema migration boundary.

## Procedure

1. Record versions, schema, row counts, relationship checksums, encryption/key
   identifiers, and a restore correlation ID.
2. Quiesce writes or take a storage-consistent snapshot using the selected
   backend's supported mechanism.
3. Encrypt and store the backup outside the primary failure domain.
4. Mutate and delete known synthetic records after the backup point.
5. Restore into an isolated environment with separate credentials and no real
   notification/payment egress.
6. Run migrations through the same production entry point; never invoke the demo
   seeder or rewrite historical data.
7. Verify row counts, checksums, foreign keys, actor/patient ownership, audit
   continuity, idempotency records, payment totals, and outbox state.
8. Run critical journeys: authentication, dependent booking, encounter resume,
   result ownership, referral handover, payment reconciliation, and export denial.
9. Measure achieved recovery point/time and compare them with approved targets.
10. Destroy the isolated restored environment according to the synthetic-data
    handling policy and record evidence, failures, owner, and corrective actions.

## Pass criteria

- No demo data or credentials are introduced by restore/migration.
- No relationship, authorization grant, finalized clinical record, audit event,
  or reconciled financial transaction is lost or reassigned.
- Pending side effects resume once without duplicating delivery or charge.
- Expired/revoked access remains expired/revoked.
- The measured RPO/RTO meet approved targets.
- The procedure is repeatable by an operator other than its author.

## Rehearsal record

| Field | Value |
|---|---|
| Date/environment | 2026-09-28; isolated temporary directory on Windows |
| Operator/reviewer | Automated test; workspace owner review |
| Backend/version | Local Drift/SQLite; schema 18 |
| Backup identifier | Per-run temporary `backup.sqlite` fixture |
| Achieved RPO/RTO | RPO 0 at snapshot; restore verified under the 10-second prototype target |
| Result | Pass: counts, appointment identities, schema version, and foreign-key integrity matched; no reseed occurred after restore |
| Evidence | `test/data/backup_restore_rehearsal_test.dart` and the 282-test full-suite run |
| Follow-up issues | Reopen this procedure if backend, platform, real-data, retention, encryption custody, or reliability scope changes |
