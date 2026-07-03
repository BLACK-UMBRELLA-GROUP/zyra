# ZYRA Live Operations — Master Runbook
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** LIVE_OPS_GOVERNANCE_V1

---

## 1. Daily Health Check (automated)

Run:
```
python -m ai_org.live_ops_runner --project ZYRA --no-llm
```
Output written to LIVE_OPERATIONS/RESOURCES/REPORTS/

---

## 2. Incident Response

### P0 — App Down
1. Detect: BUILD_HEALTH check fails or crash rate > 50%
2. Open incident: `INC-ZYRA-NNN` in INCIDENTS/OPEN/
3. Notify Lead Architect immediately
4. Identify last good release in RELEASES/
5. Rollback if possible
6. Resolve incident, move to INCIDENTS/CLOSED/
7. Postmortem required within 48 hours

### P1 — Core Feature Broken
1. Detect: Health check flags specific feature failure
2. Open incident in INCIDENTS/OPEN/
3. Notify Lead Architect within 1 hour
4. Development Team investigates and patches
5. Resolve after fix deployed

### P2/P3 — Minor Issues
1. Log in INCIDENTS/OPEN/
2. Review next session
3. Resolve when fixed

---

## 3. Release Process

1. Verify BUILD_HEALTH: PASS
2. Verify TEST_HEALTH: PASS
3. Verify no open P0/P1 incidents
4. Deployment Agent sign-off
5. Create release record in RELEASES/
6. Tag version in SOURCE/pubspec.yaml
7. Submit to App Store + Play Store
8. Monitor for 24 hours post-release
9. Close release record

---

## 4. Monitoring Check Definitions

| Check | PASS Condition | FAIL Action |
|-------|---------------|-------------|
| BUILD_HEALTH | pubspec.yaml exists, version set | Open P1 incident |
| DOCS_HEALTH | All APP/ features have Summary.md | Log warning |
| TEST_HEALTH | test/ directory has ≥1 test file | Log warning |
| RELEASE_HEALTH | No open release blockers | Open P2 incident |
| INCIDENT_HEALTH | No open P0/P1 incidents | Escalate immediately |

---

## 5. Postmortem Template

See INCIDENTS/POSTMORTEMS/ — create `POSTMORTEM-INC-ZYRA-NNN.md`:

```
# Postmortem — INC-ZYRA-NNN
Date:
Severity:
Duration:
Impact:
Root Cause:
Timeline:
What went well:
What went wrong:
Action items:
```
