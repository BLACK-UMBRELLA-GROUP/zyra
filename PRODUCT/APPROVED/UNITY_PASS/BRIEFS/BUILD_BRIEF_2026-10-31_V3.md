---
id: DOC-ZYRA-0429
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V3 - Monogram empty state app-wide (with LOCK 8 V8 masters)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNITY PASS V3 (EMPTY STATES, APP-WIDE) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 55, 59 and 60; before line 44.

| Step | Detail |
|---|---|
| 1 | Read `UNITY_PASS/RECORD/` (spec **V3** §"Empty state") with masters e01, e02, and `GUARDIAN_TABS/RECORD/` (spec **V8**) with masters g05, g16, g20, g23 |
| 2 | Make **one shared empty-state widget**: 96 pt circle with 1 pt gold ring `rgba(169,121,46,.65)` holding the gold outline icon (34); title 21 light; muted text 12.5 (line 1.5, max ~270 wide); optional gold-outline action pill (40 high) that opens an **existing** page |
| 3 | Use it for **every** empty state in the app (spec V3 table lists the known ones — Seeker and Guardian). Search for any other "no … yet" state and use the widget there too; list them in the task note. Loading spinners stay as they are |
| 4 | Actions only where the text already points somewhere: "Connect with Guardian · Sent" and "Introductions you've made" → **Open Network** (Network tab). No other new buttons |
| 5 | New copy only on Seeker Ended Journeys: title "No ended Journeys", text "When a Journey ends, it's kept here with its Timeline." All other texts stay as today |
| 6 | Remove each old empty layout (no dead code). Tests: each listed state shows the widget; Open Network targets; Larger Text. Analyser clean |
| 7 | Render e01, e02 into `UNITY_PASS/BUILT/V3/` and g05, g16, g20, g23 into `GUARDIAN_TABS/BUILT/V8/` with master-beside-build; task note; commit within core rule 2; mark queue line 61 BUILT or FAILED |
