---
id: DOC-ZYRA-0469
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - LOCK 25 Seeker One and Guardian One upgrade pages and the Guardian One monogram ring
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UPGRADE PAGES (LOCK 25) — 11 NOV 2026

**Copy exactly. No improvements.** No upgrades, no new packages, no App Store product changes. Unclear → `QUESTIONS.md` row.
**ROADMAP row (charter rule 12):** "Test baseline and final interface pass". Do not tick it; only Fable edits ROADMAP.
Spec: `UPGRADE_PAGES/RECORD/UPGRADE_PAGES_SPEC_CURRENT_VERSION_V1.md`. No masters (charter rule 13): prototype **V167**.

| Step | Detail |
|---|---|
| 1 | **Seeker One page** (spec §1–§3): replace the membership-section screen opened from Seeker Basic's "See Seeker One" and every Seeker upgrade link with the new page: header, price / trial line, Basic vs One table (rows in §3 order, sharing the card height), note, **Start 14 days free** (existing purchase / Apple sheet path; if none exists, the button shows today's "not available yet" message), **Not now** |
| 2 | **Guardian One page** (spec §1, §2, §4): the same for Guardian Basic's "See Guardian One" and the locked Guardian One tiles; **Start 7 days free** |
| 3 | **Honest table rule** (spec §5): hide every row whose feature is not in this build, and the trial words unless the App Store product offers that trial; list which rows are hidden in the task note. "Chaperoned video calls · Coming later" always shows |
| 4 | **Guardian One monogram ring** (spec §6): Guardian card (LOCK 19) and every Guardian monogram — gold ring only for Guardian One (Family place included); Basic: no ring, muted initial on a faint fill |
| 4b | **Guardian ••• menu as a full-screen sheet — LOCK 19 V8** (`GUARDIAN_CARD/RECORD/GUARDIAN_CARD_SPEC_CURRENT_VERSION_V8.md`, row "••• menu (V8)"). Founder: the in-card menu shows the card outline and square corners. Present it as a modal bottom sheet over the whole screen (scrim over everything incl. the tab bar; sheet `#F7F2EA`, top radius 26, handle, "<name> · <role>" line, Make Main / Remove as Main · Remove <name> red · rounded Cancel pill); tap outside closes; nothing drawn inside the card. Prototype V168 |
| 4c | **Guardian card motion — LOCK 19 V8, row "Moving (V8 motion)".** The card follows the finger while dragging (resistance at the ends); past ~60 pt it slides off (~0.18 s) and the next card slides in from that side (~0.26 s ease-out); short drags spring back; edge and dot taps use the same slide-in; a swipe starting on a View/Chat chip never toggles it; Reduce Motion = instant. Use one horizontal page controller / drag owner for the card. Prototype V169 |
| 4d | **Profiles details card, design 2 — PROFILES_DETAILS_CARD V3** (`PROFILES_DETAILS_CARD/RECORD/PROFILES_DETAILS_CARD_SPEC_CURRENT_VERSION_V3.md`). Replace the small-avatar card face with: 124 pt round photo (gold ring only for Seeker One, V2 rule — same server-plan limitation as line 79 / Q84), first name 34 light, surname 22 muted, and a 2 × 2 grid of tiles AGE · LOCATION · NATIONALITY · ETHNICITY at the bottom; no dead space; photo paging unchanged. Prototype V171 |
| 5 | **Tests:** both pages open from each entry; rows in order; hidden rows follow §5; buttons; ring shown for Guardian One only; ••• opens a full-screen sheet and Cancel / outside tap close it; the card moves with the drag and a chip under the finger is not toggled by a swipe; the Profiles card shows the 124 pt photo and the four tiles |
| 6 | **Gate:** `flutter analyze` clean; no new failures against line 79. Evidence in `UPGRADE_PAGES/BUILT/` (renders for the AIs only, charter rule 13) |
| 7 | **iPhone:** protected route only, on Shakeel's GO with the phone connected, telling him the build first |
| 8 | Task note; commit within core rule 2; mark queue line 80 BUILT or FAILED |
