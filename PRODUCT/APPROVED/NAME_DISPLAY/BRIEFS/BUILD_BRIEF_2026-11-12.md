---
id: DOC-ZYRA-0491
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 33 - one-line names in list cards, fitted names on the profile page, name limits 30 / 40
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — NAME DISPLAY — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `NAME_DISPLAY/RECORD/NAME_DISPLAY_SPEC_CURRENT_VERSION_V1.md` (LOCK 33). Reference: prototype V214 → strip **Name test → Long names**.

| Step | Detail |
|---|---|
| 1 | Build after line 98 (it moves Ended Journeys and Introductions onto the request card, so the rule lands in one component) |
| 2 | **List cards:** in the shared request card, the name text = first name + surname, `maxLines: 1`, `TextOverflow.ellipsis`, inside an `Expanded` column so it never pushes the chevron; no font shrinking. Semantics label carries the full name |
| 3 | **Profile page:** `widgets/zyra_profile_name_block.dart` (and any other big-name header) — first name `maxLines: 1`, scaled down to fit to at least 75 % of `nameSize`, then ellipsis; surname `maxLines: 2`, ellipsis |
| 4 | Find every other place a full name is drawn (search for `firstName`/`surnameLine` in widgets and screens) and apply step 2 or 3; list them in the task note |
| 5 | **Limits:** `ZyraOnboardingNameField` and the profile edit name fields: first name **30**, surname **40** (was 60); counter visible from 5 left. Existing longer names load and save unchanged unless edited. Server check is Fable's (QUESTIONS 135) |
| 6 | Tests: long sample names ("Fatima-Zahra" / "Abdul-Rahman Al-Hashimi", "Zainab" / "Malik-Abdulkareem Bin Yusuf") — every list card one line and equal height on 375 × 667 and 430 × 932; profile first name fits or ellipsises, surname ≤ 2 lines; limits 30 / 40 enforced |
| 7 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
