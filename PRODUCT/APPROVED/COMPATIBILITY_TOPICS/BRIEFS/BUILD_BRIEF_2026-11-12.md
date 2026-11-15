---
id: DOC-ZYRA-0478
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - Guardian entry to the compatibility reader (LOCK 27 V2)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN COMPATIBILITY ENTRY — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
**Start only when Fable has specified the authorized result** (QUESTIONS 91–92, OA-ZYRA-317). If not, mark line 88 **BLOCKED** and stop.
Reference: `COMPATIBILITY_TOPICS/RECORD/COMPATIBILITY_TOPICS_SPEC_CURRENT_VERSION_V2.md` row "Guardian entry (V2)"; prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V187.html` (Seeker Journey page row for the look).

| Step | Detail |
|---|---|
| 1 | Guardian's Journey page: "Compatibility score" floating row like the Seeker's, shown only after both Seekers revealed; opens the reader (Guardian One every topic; Guardian Basic overall + locked pages with Guardian One wording) |
| 2 | Past summary: the same row, read-only, while the archive is readable (3 months) |
| 3 | Tests: row hidden before both reveals; Basic sees locked pages; Past row disappears after the archive window |
| 4 | Gate: `flutter analyze` clean; no new failures |
| 5 | iPhone on Shakeel's GO only; task note; commit within core rule 2; mark line 88 BUILT, FAILED or BLOCKED |
