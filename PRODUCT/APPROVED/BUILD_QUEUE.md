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
| 6 | 2026-10-29 | `PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WAITING | | **LOCKed build** (LOCK 2, Journey requests and Guardians), spec corrected after line 4 preflight: LOCK record `REQUESTS_AND_GUARDIANS/RECORD/LOCK_RECORD.md` |
| 7 | 2026-10-29 | `PRODUCT/APPROVED/GUARDIAN_INFO/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WAITING | | **LOCKed build** (LOCK 3, What Guardians can do): `GUARDIAN_INFO/RECORD/LOCK_RECORD.md` |
| 8 | 2026-10-29 | `PRODUCT/APPROVED/PROFILES_DETAILS_CARD/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WAITING | | **LOCKed build** (LOCK 4, profile photo on the Profiles details card): `PROFILES_DETAILS_CARD/RECORD/LOCK_RECORD.md` |
| 9 | 2026-10-29 | `PRODUCT/APPROVED/TAB_ATTENTION/BRIEFS/BUILD_BRIEF_2026-10-29.md` | WAITING | | **LOCKed build** (LOCK 5, gold tab icon clears when the tab is opened): `TAB_ATTENTION/RECORD/LOCK_RECORD.md` |
