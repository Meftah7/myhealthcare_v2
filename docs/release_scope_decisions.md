# Release Scope Decisions

Status: approved for Phase 0 prototype scope by the workspace owner  
Decision date: 2026-09-28

## Selected scope

| Decision | Approved Phase 0 value |
|---|---|
| Intended release | Assessed university prototype using synthetic data only. It is not approved for clinical care or real patient data. |
| Launch platform | Web on current evergreen Chromium browsers. Android, iOS, and Windows are source targets, not release targets for this prototype. |
| Accountability | Workspace owner `iamxj` owns the prototype artifact and demonstrations. Clinical-safety, privacy/security, and operations approval are not claimed; those roles become mandatory before any pilot or live-data scope change. |
| Authoritative store | Local Drift/SQLite is authoritative for one prototype instance. There is no shared multi-user clinical backend. |
| Identity/recovery | Local synthetic demonstration accounts and prototype recovery flows only. No connection to a real identity provider. |
| External features | Real payments, remote notifications, messaging delivery, uploads to external systems, and live clinical AI are out of scope. Demo/local behavior must stay labeled and production mode must fail closed when a live provider is absent. |
| Clinical policy | UI workflows are demonstrations only. Emergency copy directs users to emergency services; no diagnosis, prescribing, referral, or clinical-governance claim is approved. |
| Privacy and records | Synthetic data only. Do not enter, import, transmit, or retain real patient information. Prototype artifacts follow repository access and deletion controls. |
| Reliability | Prototype target: file-level backup before assessed demonstrations, RPO 0 at the captured snapshot, restore in under 10 seconds on the test workstation, rehearsal on schema changes. |
| Support/monitoring | Workspace owner supports scheduled demonstrations. No 24/7 service, production monitoring, or incident-response commitment. |

## Change-control boundary

A controlled pilot, production clinic use, real patient data, additional launch
platform, or live external provider reopens Phase 0. That change requires named
qualified clinical-safety, privacy/security, and operations owners; applicable
legal review; an authoritative shared backend; native/platform evidence; and new
backup, recovery, accessibility, and incident-response approval.
