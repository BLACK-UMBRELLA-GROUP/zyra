---
id: DOC-ZYRA-0479
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - compatibility reader shows 12 areas as bands, never area % (LOCK 27 V3, DR-ZYRA-250)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — COMPATIBILITY BANDS — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Founder 12 Nov: "Keep 28 Sep: bands, no exact % (Recommended)" · "Strong · Good · Some differences" · "75%+ / 50–74% / under 50%" · "'Not enough answers' in grey". The app built in lines 81 / 88 shows 6 topics with %; that conflicts with DR-ZYRA-250 D3/D4 and is replaced.
Reference: `COMPATIBILITY_TOPICS/RECORD/COMPATIBILITY_TOPICS_SPEC_CURRENT_VERSION_V3.md` section "Bands (V3)"; prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V194.html` (Profiles → ••• → Compatibility after an Unlock; screen list "Compatibility in a Journey · Seeker Basic").

| Step | Detail |
|---|---|
| 1 | Reader = **2 pages** everywhere it is used (Profiles after an Unlock, Journey, Guardian Journey row, Past, ended archive): page 1 Overall as today; page 2 **Every area** with the 12 D3 areas in fixed order and one band chip each (Strong / Good / Some differences / Not enough answers) — styles in the spec. Remove the 6-topic pages and every area / topic percentage, ring or tally |
| 2 | Locked (Seeker Basic without an Unlock for that person, Guardian Basic): page 2 lists the 12 names with a small lock + "Locked" and the spec's buttons; the app receives no band for locked areas |
| 3 | Data: the app takes **only band codes** per area. Until Fable's server answer (QUESTIONS 97–99) is built, the admitted preview uses clearly synthetic bands; live members see the locked or "Not enough answers" state — never invented bands |
| 4 | Wording: "topic" → "area" in this reader and its buttons ("See every area for Sara", "Seeker One shows every area in every Journey ›") |
| 5 | Visual check against the prototype copy on 430 × 932 and 375 × 667 |
| 6 | Tests: no percentage text on page 2; 12 rows in D3 order; locked shows no band; Not enough answers style; pager 1 / 2 loops |
| 7 | Gate: `flutter analyze` clean; no new failures |
| 8 | iPhone on Shakeel's GO only; task note; commit within core rule 2; mark queue line 91 BUILT or FAILED |
