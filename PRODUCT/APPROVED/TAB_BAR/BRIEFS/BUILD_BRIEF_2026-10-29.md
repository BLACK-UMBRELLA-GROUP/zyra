---
id: DOC-ZYRA-0321
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 6 - tab bar underline and small idle state
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — TAB BAR — 29 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and the four `../MASTERS/` pictures |
| 2 | Change the planned app's bottom bar (`ZyraShellNavigation` / `FloatingNavItem`, Floating Glass style) for both roles: underline instead of the ring; small idle state; first tap on the small bar only expands; back to small after 3 s or on scroll; accessibility rules in the spec |
| 3 | Keep the LOCK 5 gold rule working in both states. Do not change the ••• action bar |
| 4 | Tests: underline on the current tab; idle width 156 / full 390; first tap expands without switching; tab switch on the full bar; collapse after 3 s and on scroll; VoiceOver/Larger Text keep it full; Reduce Motion instant. Analyser clean |
| 5 | Render the four master states into `TAB_BAR/BUILT/` (430 × 932 @3x) |
| 6 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
