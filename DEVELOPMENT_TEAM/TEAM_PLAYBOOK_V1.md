# ZYRA Development Team — Playbook
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** DEVELOPMENT_TEAM_GOVERNANCE_V1

---

## 1. How to Start a Feature Build

### Step 1 — Confirm the spec is approved
Check ZYRA/SYSTEM/OUTSTANDING_ACTIONS/ — the feature must be APPROVED.
If IDEA or SPEC only, stop. Return to Lead Architect.

### Step 2 — Open a session
Run:
```
python -m ai_org.dev_team_runner --project ZYRA --feature FEATURE_NAME
```
This creates a session file in DEVELOPMENT_TEAM/SESSIONS/.

### Step 3 — Pipeline runs automatically
The dev_team_runner.py executes agents in sequence:
1. Product Manager Agent — spec validation
2. Architect Agent — architecture review
3. Impact Analysis Agent — impact assessment
4. Code Agent — code generation
5. Review Agent — code review
6. QA Agent — test generation
7. Documentation Agent — doc sync
8. Deployment Agent — release coordination

### Step 4 — Review the session report
Written to DEVELOPMENT_TEAM/RESOURCES/REPORTS/ after each run.

---

## 2. How to Resume a Blocked Session

If an agent returned ESCALATED:
1. Open the session file in SESSIONS/
2. Read the escalation reason
3. Resolve the blocker with Lead Architect
4. Re-run: `python -m ai_org.dev_team_runner --session SESSION-ID --resume`

---

## 3. How to Invoke a Single Agent

```
python -m ai_org.dev_team_runner --project ZYRA --agent CODE_AGENT --feature FEATURE_NAME
```

---

## 4. Quality Gate Checklist

Before marking a feature DONE:
- [ ] All 8 agents returned APPROVED
- [ ] Tests pass in SOURCE/
- [ ] Documentation updated
- [ ] Outstanding Action closed in register
- [ ] Decision recorded if architectural choice was made

---

## 5. Session Log Format

Every session log entry:
```
TIMESTAMP: YYYY-MM-DD HH:MM UTC
AGENT:     AGENT_NAME
ACTION:    What was done
VERDICT:   APPROVED | CHANGES_REQUESTED | ESCALATED
OUTPUT:    Path to deliverable (if any)
NOTES:     Brief explanation
```

---

## 6. Escalation Decision Tree

```
Agent blocked?
    ↓
Is spec ambiguous?  → Product Manager Agent → Lead Architect
Is it architectural? → Architect Agent → Lead Architect
Is it a code issue?  → Code Agent → Lead Architect
Is it a test failure? → QA Agent → Lead Architect
Is it a deploy issue? → Deployment Agent → Lead Architect
```
