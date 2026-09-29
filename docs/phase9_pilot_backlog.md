# Phase 9 pilot issue backlog

Priority: patient harm; identity/data exposure; finalized-data loss or false
confirmation; blocked tasks/unowned work; repeated confusion; cosmetic polish.

| ID | Evidence | Severity | Owner | Status | Release impact |
|---|---|---|---|---|---|
| P9-001 | Arabic/AT sessions not run | blocked task | unassigned accessibility reviewer | open | blocks gate |
| P9-002 | Security/privacy review absent | data exposure | unassigned reviewer | open | blocks pilot expansion |
| P9-003 | Clinical approval absent | patient harm | unassigned clinical owner | open | features stay disabled |
| P9-004 | Incident rehearsal: automated outage/duplicate/backup rehearsals pass (`test/phase9/incident_rehearsal_test.dart`); manual rollback and identity-alert rehearsal on hosted build not run | data loss | workspace owner | partly closed | blocks gate until manual run |
| P9-005 | View-only family link could load booking slots for the owner once Phase 8 disabled risk ranking (`test/features/family_link_test.dart`) | identity/data exposure | workspace owner | fixed — authorization now runs first in `rankedSlotsProvider` | none |
| P9-006 | Family-link cancel test depended on time of day (seeded appointment inside 2-hour cutoff) | blocked task (test) | workspace owner | fixed — test picks cancellable appointments | none |
| P9-007 | Scenario 14 evidence: off-duty cover test in `test/phase4/clinical_workflow_test.dart` | unowned work | workspace owner | closed — linked test | none |
| P9-008 | Scenario 15 evidence: referral lifecycle test in `test/phase4/clinical_workflow_test.dart` | unowned work | workspace owner | closed — linked test | none |

An issue closes only with linked test, observation, rehearsal or signed decision.
Cosmetic work cannot pass an open higher-severity issue.
