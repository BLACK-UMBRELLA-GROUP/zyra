---
id: DOC-ZYRA-0502
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex fix brief - a member's own picture everywhere is their profile photo 1 (or the Profile-tab placeholder), PROFILE_TAB V4 section 7
links: [AD-AIOS-115]
owner: ZYRA chat
---

# FIX BRIEF — YOUR PICTURE EVERYWHERE — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Reference: prototype V222 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V224.html`). Layout from the app's existing components.

Spec: `PROFILE_TAB/RECORD/PROFILE_TAB_SPEC_CURRENT_VERSION_V4.md` §7. Founder saw the Profile tab placeholder but a gold "A" monogram for "You" in the Guardian Circle sheet.

| Step | Detail |
|---|---|
| 1 | Make one shared avatar widget for a member's own picture: photo 1 (same source as the Profile tab header) or, with no photo, exactly the Profile-tab placeholder |
| 2 | Find every place the signed-in member (and a Seeker as seen by their Guardians / Journey partner) is drawn — Circle sheet "You" row, Circle bubbles if any, Journey, Timeline, chats, My ZYRA, own Preview, Guardian-side views of the Seeker — and use the shared widget; list them in the task note |
| 3 | Guardians keep the LOCK 19 monogram ring |
| 4 | Tests: with a photo every place shows photo 1; without, every place shows the placeholder; changing photo 1 updates all |
| 5 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
