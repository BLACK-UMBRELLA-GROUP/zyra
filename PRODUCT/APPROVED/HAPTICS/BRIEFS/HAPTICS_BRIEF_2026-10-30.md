---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - every tappable control in the planned app gives haptic feedback at the member's chosen level
links: [DOC-ZYRA-0282, OA-ZYRA-314]
owner: ZYRA chat
---

# HAPTICS ON EVERY BUTTON — BRIEF — 30 OCT 2026

**Founder, 30 Oct 2026** (comment on the prototype's request pill): **"ensure this and all buttons have haptic feedback"**.
Founder-named task, not a new design: it uses the existing haptic setting (blueprint part 5 §6). Today the Founder preview has
about 275 tap handlers in `lib/dev/` and about 31 haptic calls.

| Step | Detail |
|---|---|
| 1 | Read blueprint part 5 §6 and `theme/zyra_interaction_style.dart` (`ZyraHapticLevel` Off / Subtle (default) / Light / Medium / Strong; `emitSelectionHaptic()`) |
| 2 | **Rule:** every enabled tappable control in the planned app (Founder preview, both roles, every page, sheet and dialog — buttons, pills, chevrons, tabs, rows, tiles, chips, switches, segmented controls, cards that open something, the ••• bar, the request pill) calls `ZyraInteractionStyle.emitSelectionHaptic()` once per tap, at the member's level. Off = nothing. Disabled controls, scrolling, swiping photos and typing give none |
| 3 | **How:** put the call in the shared tap components (the preview's pill / button / row / tile / icon-button widgets and the navigation bar) so every current and future control gets it in one place; add direct calls only where a control does not use a shared component. One haptic per tap — never two (remove a duplicate where a component and its caller both fire) |
| 4 | Fix OA-ZYRA-314 in the same task: `screens/journey/journey_flow_screen.dart` calls the phone directly four times — route them through `emitSelectionHaptic()` so Off is respected |
| 5 | Tests: a sample of taps on each tab root and on a sheet fire exactly one haptic at Subtle; none at Off; none on a disabled control; the level change in Personalisation applies at once. A list in the task note of every tappable control type and where its haptic comes from. Analyser clean |
| 6 | No visual change, so no pictures. Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
