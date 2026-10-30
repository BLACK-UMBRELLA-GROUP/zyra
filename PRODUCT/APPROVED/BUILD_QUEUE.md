---
id: DOC-ZYRA-0302
type: REGISTER
status: CURRENT
feature: GOVERNANCE
purpose: Build queue - every ZYRA instruction for Codex (LOCKed builds and Founder-named tasks) waits here; Codex builds WAITING lines at 04:00 or on GO (charters rule 9)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD QUEUE - ZYRA

Only the ZYRA chat (Claude) writes here. **Every ZYRA instruction for Codex comes through this queue** (Founder, 29 Oct
2026: "any instruction you have for codex should be go so change anything so that happens") - Shakeel only ever types GO.
Two kinds of line: a **LOCKed build** (after Shakeel says LOCK; Fable checks it has a LOCK record) and a **Founder-named
task** (captures, fixes, clean-up steps Shakeel asked for; the Note says "Founder-named task" and quotes or points to his
words in the ZYRA chat note). Every line points at a brief file with exact steps. Codex builds every WAITING line in
order: at his 04:00 job, or at once on GO in the ZYRA Codex chat. Codex changes only the Status column and adds the
task-note date; he never adds a line. A FAILED line stays until the ZYRA chat decides. Newest line at the bottom.

| # | Added | Brief path | Status (WAITING / BUILT / FAILED) | Built on | Note |
|---|---|---|---|---|---|
| 1 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/CAPTURE_BRIEF_2026-10-29.md` | WITHDRAWN | 2026-10-29 | Founder-named task, not a LOCK. FAILED 15:33 (phone disconnected, no matching simulator, native route held). Withdrawn by the ZYRA chat, replaced by line 2 |
| 2 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/CAPTURE_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | Same brief, step 1 rewritten: phone → simulator (may create) → visual-test render at 430×932 @3x. Founder-named task, not a LOCK; screenshots only, no app code change |
| 3 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/RECAPTURE_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | Founder-named task, not a LOCK: recapture the blank Invite a Guardian picture (and any other blank ones); no app code change |
| 4 | 2026-10-29 | `PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WITHDRAWN | 2026-10-29 | **LOCKed build** (LOCK 2). FAILED in preflight: Past master order contradicted the spec; first-link trigger had no event. Both fixed in the spec (change log); replaced by line 6 |
| 5 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/PROFILES_PHOTOS_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | Founder-named task: remove the unused "Original photos" Profiles layout (DR-ZYRA-276) and capture the Details-first photo pages; quote in the brief |
| 6 | 2026-10-29 | `PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WITHDRAWN | 2026-10-29 | **LOCKed build** (LOCK 2, Journey requests and Guardians), spec corrected after line 4 preflight: LOCK record `REQUESTS_AND_GUARDIANS/RECORD/LOCK_RECORD.md` — FAILED again 18:4x: Past masters on disk still showed "listed until"/"30 days" (ZYRA chat's file copy had not landed); masters re-rendered and verified; replaced by line 11 |
| 7 | 2026-10-29 | `PRODUCT/APPROVED/GUARDIAN_INFO/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WITHDRAWN | 2026-10-29 | **LOCKed build** (LOCK 3, What Guardians can do): `GUARDIAN_INFO/RECORD/LOCK_RECORD.md` — FAILED in preflight: the preview Circle showed past Journey summaries with sharing off (breaks DR-ZYRA-233 and card 4). Spec §3b added; replaced by line 13 |
| 8 | 2026-10-29 | `PRODUCT/APPROVED/PROFILES_DETAILS_CARD/BRIEFS/BUILD_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | **LOCKed build** (LOCK 4, profile photo on the Profiles details card): `PROFILES_DETAILS_CARD/RECORD/LOCK_RECORD.md` |
| 9 | 2026-10-29 | `PRODUCT/APPROVED/TAB_ATTENTION/BRIEFS/BUILD_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | **LOCKed build** (LOCK 5, gold tab icon clears when the tab is opened): `TAB_ATTENTION/RECORD/LOCK_RECORD.md` |
| 10 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/SIGNUP_CAPTURE_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | Founder-named task: capture the sign-up and onboarding screens (both roles) for the prototype's Sign up layout; no app code change |
| 11 | 2026-10-29 | `PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BRIEFS/BUILD_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | **LOCKed build** (LOCK 2, Journey requests and Guardians) — Past masters now match the spec (no expiry). LOCK record `REQUESTS_AND_GUARDIANS/RECORD/LOCK_RECORD.md` |
| 12 | 2026-10-29 | `PRODUCT/APPROVED/WEB_COPY/BRIEFS/WEB_COPY_BRIEF_2026-10-29.md` | FAILED | 2026-10-30 | Founder-named task ("Yes, make a real web copy"). **Gated:** build only after Fable's review says `WEB COPY: SAFE TO BUILD`; until then stays WAITING |
| 13 | 2026-10-29 | `PRODUCT/APPROVED/GUARDIAN_INFO/BRIEFS/BUILD_BRIEF_2026-10-29.md` | FAILED | 2026-10-29 | **LOCKed build** (LOCK 3, What Guardians can do) — now includes the DR-ZYRA-233 Circle fix first (spec §3b). `GUARDIAN_INFO/RECORD/LOCK_RECORD.md` |
| 14 | 2026-10-29 | `PRODUCT/APPROVED/TAB_BAR/BRIEFS/BUILD_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | **LOCKed build** (LOCK 6, tab bar: gold underline, 40% small bar until touched): `TAB_BAR/RECORD/LOCK_RECORD.md` |
| 15 | 2026-10-29 | `PRODUCT/APPROVED/BASELINE/BASIC_AND_GUARDIAN_JOURNEY_CAPTURE_BRIEF_2026-10-29.md` | BUILT | 2026-10-29 | Founder-named task (29 Oct 19:25, quote in the brief): capture Seeker Basic, Guardian Basic and the Guardian's view of a Journey in every state for the prototype; screenshots only, no app code change |
| 16 | 2026-10-29 | `PRODUCT/APPROVED/REQUEST_ROW/BRIEFS/BUILD_BRIEF_2026-10-29.md` | FAILED | 2026-10-29 | **LOCKed build** (LOCK 7, Profiles request row as one pill, option A4): `REQUEST_ROW/RECORD/LOCK_RECORD.md` |
| 17 | 2026-10-29 | `PRODUCT/APPROVED/GUARDIAN_TABS/BRIEFS/BUILD_BRIEF_2026-10-29.md` | FAILED | 2026-10-29 | **LOCKed build** (LOCK 8, Guardian five tabs and pages; after lines 13 and 14): `GUARDIAN_TABS/RECORD/LOCK_RECORD.md` |
| 18 | 2026-10-30 | `PRODUCT/APPROVED/GUARDIAN_INFO/BRIEFS/BUILD_BRIEF_2026-10-30.md` | BUILT | 2026-10-30 | **LOCKed build** (LOCK 3, What Guardians can do), spec **V2**: Circle shows past Journeys only when shared, with first names and dates (Founder 30 Oct "Show the name"). `GUARDIAN_INFO/RECORD/LOCK_RECORD.md` |
