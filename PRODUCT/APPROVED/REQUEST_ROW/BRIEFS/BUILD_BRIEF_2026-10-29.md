---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 7 - Profiles request row as one pill
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — REQUEST ROW — 29 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and the three `../MASTERS/` pictures |
| 2 | In the planned app's Profiles footer (`_compactFooter` in `SOURCE/lib/widgets/zyra_browse_designs.dart`, used by the Founder preview), replace the three separate pills with the single pill in the spec. Keep every existing key, label, semantic label, enable/disable rule and request behaviour |
| 3 | Do not change the Guardian Network row, the ••• action bar, or the tab bar |
| 4 | Tests: one pill drawn; Previous / Request / Next each tap correctly; Previous disabled and faded on the first profile; "Request sent" gold state; screen-reader labels unchanged; tap areas ≥ 44. Analyser clean |
| 5 | Render the three master states into `REQUEST_ROW/BUILT/` (430 × 932 @3x) |
| 6 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
