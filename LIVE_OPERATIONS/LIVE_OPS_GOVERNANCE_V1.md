# ZYRA Live Operations — Governance
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Contract Type:** LIVE OPS GOVERNANCE
**Governing Reference:** ZYRA_GOVERNANCE_V1

---

## 1. Purpose

Governs how the ZYRA Live Operations layer detects, escalates,
and resolves operational issues — both pre-launch (build health)
and post-launch (app availability, incidents).

---

## 2. Operational Phases

| Phase | Description | Current |
|-------|-------------|---------|
| PRE_LAUNCH | App not yet deployed — monitors build and doc health | ✅ Active |
| SOFT_LAUNCH | Limited release — monitors crash rates and user flows | Planned |
| FULL_LAUNCH | Full production — monitors all health signals | Planned |

---

## 3. Incident Severity

| Severity | Definition | Response Time |
|----------|-----------|---------------|
| P0 — CRITICAL | App unavailable for all users | Immediate |
| P1 — HIGH | Core feature broken for >10% users | 1 hour |
| P2 — MEDIUM | Non-critical feature degraded | 4 hours |
| P3 — LOW | Minor issue, workaround exists | Next session |

---

## 4. Incident Lifecycle

```
DETECTED → OPEN → IN_PROGRESS → RESOLVED → POSTMORTEM (P0/P1 only)
```

4.1 Every incident gets an ID: `INC-ZYRA-NNN`
4.2 P0 and P1 incidents require a postmortem within 48 hours.
4.3 No incident may remain OPEN for more than 7 days without escalation.

---

## 5. Escalation Path

Live Ops Runner → Lead Architect → Black Umbrella Group

---

## 6. SLA Definitions

| Metric | Target |
|--------|--------|
| App availability | 99.5% monthly |
| P0 resolution | < 2 hours |
| P1 resolution | < 8 hours |
| Build health | Green on every release |

---

## 7. Release Gates

Before any release to App Store / Play Store:
- [ ] BUILD_HEALTH check: PASS
- [ ] TEST_HEALTH check: PASS
- [ ] No open P0 or P1 incidents
- [ ] Release record created in RELEASES/
- [ ] Deployment Agent sign-off

---

## 8. Reporting

Live Ops reports to ZYRA Project System after every health check run.
Health score is included in the ZYRA ORGANISATION_STATE.md rollup.
Black Umbrella Group sees ZYRA live ops health in its nightly run.
