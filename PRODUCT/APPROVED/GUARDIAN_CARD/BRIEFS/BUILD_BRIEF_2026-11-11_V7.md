---
id: DOC-ZYRA-0464
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - Guardians per Seeker and the Seeker Basic Add card (LOCK 19 V7); gold ring only on Seeker One profiles (PROFILES_DETAILS_CARD V2)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — BASIC GUARDIANS + GOLD RING = SEEKER ONE — 11 NOV 2026

**Copy exactly. No improvements.** No upgrades, no new packages. Unclear → file a `QUESTIONS.md` row and continue.
**ROADMAP row (charter rule 12):** "Test baseline and final interface pass". Do not tick it; only Fable edits ROADMAP.
Builds on line 78 (commit 7210bc1). No masters (charter rule 13): prototype **V165** is the reference.

| Step | Detail |
|---|---|
| 1 | **Guardians per Seeker — LOCK 19 V7 §6.0b** (`GUARDIAN_CARD/RECORD/GUARDIAN_CARD_SPEC_CURRENT_VERSION_V7.md`). Client rules (`lib/data/zyra_seeker_plan_limits.dart` and the Add a Guardian flow): every Seeker up to **10** Guardians (Main included); Seeker One any mix of Guardian Basic and Guardian One; Seeker Basic at most **1 Guardian on Guardian Basic**, every other Guardian on Guardian One |
| 2 | **Seeker Basic Add card — LOCK 19 V7 §6.0b.** Replace "Add more Guardians" (lock): plus icon · **Add a Guardian** · "<n> of 10 Guardians. One Guardian can be on Guardian Basic; the rest need Guardian One." (used: "Your Guardian Basic place is used, so new Guardians need Guardian One.") · two small boxes **Free / Used** "Guardian Basic place" and **<n>** "Guardian One places" · link **Seeker One: any 10 Guardians ›** (existing upgrade page) · pill **Add a Guardian** → Add a Guardian page (was "View Seeker One") |
| 3 | **Server rule:** not in this line. File a QUESTIONS row naming the server change needed for the Guardian-plan rule (the SERVER register is Fable's) |
| 4 | **Guardian side:** what a Guardian on Guardian Basic sees when a Seeker Basic's Guardian Basic place is already used is **not designed yet** — do not invent a screen; keep today's behaviour and list where it happens |
| 5 | **Gold ring = Seeker One — PROFILES_DETAILS_CARD V2** (`PROFILES_DETAILS_CARD/RECORD/PROFILES_DETAILS_CARD_SPEC_CURRENT_VERSION_V2.md`). The 56 × 56 gold ring + glow on the Profiles details-card photo shows **only for Seeker One** profiles; Seeker Basic profiles show the photo circle only (no ring, no glow). No-photo: One keeps ring + person icon; Basic shows the person icon in a plain circle. VoiceOver adds "Seeker One" when the ring shows. Use the profile's plan as the app already knows it; if the client has no plan field for other members, file a QUESTIONS row and keep the ring as today |
| 6 | **Tests:** limits (10; Basic max 1 Guardian Basic); Basic Add card text, boxes, link and pill; ring present for a Seeker One profile and absent for a Basic one |
| 7 | **Gate:** `flutter analyze` clean; no new failures against line 78. Evidence in `GUARDIAN_CARD/BUILT/V7/` (renders for the AIs only, charter rule 13) |
| 8 | **iPhone:** protected route only, on Shakeel's GO with the phone connected, telling him the build first |
| 9 | Task note; commit within core rule 2; mark queue line 79 BUILT or FAILED |
