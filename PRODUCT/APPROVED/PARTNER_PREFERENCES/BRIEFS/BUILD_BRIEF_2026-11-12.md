---
id: DOC-ZYRA-0498
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - amber reads "Open to this" and the legacy amber quick check (LOCK 30)
links: [AD-AIOS-115, DR-ZYRA-250]
owner: ZYRA chat
---

# BUILD BRIEF — AMBER "OPEN TO THIS" + QUICK CHECK — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Reference: `PARTNER_PREFERENCES/RECORD/PARTNER_PREFERENCES_SPEC_CURRENT_VERSION_V5.md`; prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V201.html`.

| Step | Detail |
|---|---|
| 1 | Light labels → **Prefer this · Open to this · Not for me** on every traffic-light screen (e.g. `traffic_light_question_screen.dart`, `values_preferences_flow.dart`, `chapter2_flow.dart`, Founder preview Partner preferences); legend "Prefer · Open to this · Not for me". Answer options that are themselves named "No preference" stay |
| 2 | Quick check card, "n to check" on category and question rows, Check tag + "Saved before as “No preference”…" line, any tap confirms, toasts — exactly as the spec |
| 2b | **Set-up lights (LOCK 30 V2):** at the top of Partner preferences → Deen & Islamic Practice, the FROM YOUR PROFILE SET-UP section with "Your partner's sect" (Sunni / Shia / Other), "Someone from outside your preferred sect" and "Someone who reverted to Islam", same Check flow; they count in "n to check" but not in the 325 totals; taps write back to the set-up answers |
| 2c | **Counterpart variants (LOCK 30 V3):** show only the counterpart-gender variant of each gender-specific question (text and options), hide questions the counterpart is never asked; unmatched controls show "Not set" and stay unconfirmed |
| 2d | **Totals (LOCK 30 V4):** every "n of N" / "n/N" for partner preferences (My ZYRA pill and item, Edit profile, category and question rows) = choices this Seeker can see after the V3 filter, set-up lights excluded; remove every fixed 325 |
| 2e | **Result needs a check (LOCK 30 V5):** reader state "One quick check first" + Check my answers → combined Quick check page (three groups, both readers, Done · n left / Done) → write → back to the result; never reveal which items relate to the person; ordinary Quick check stays visible-only. The prototype counts 320 for the male viewer (women's q26 variant shown, q39 hidden) |
| 3 | My ZYRA Needs-you item "A few preferences need a quick check" while any remain |
| 4 | Data: send the explicit reconfirmation through the owner-only write Fable specifies in QUESTIONS 105. **If row 105 is not answered when this line starts, build steps 1–3 against the preview data only and mark this line QUESTION for the live write** |
| 5 | Visual check against the prototype copy at 430 × 932 and 375 × 667 |
| 6 | Tests: no light labelled "No preference" or "Neutral"; untouched legacy amber stays to-check; tapping amber again clears the tag and sends the reconfirmed mark; ordinary saves never send it; Needs-you item appears / disappears |
| 7 | Gate: `flutter analyze` clean; no new failures |
| 8 | iPhone on Shakeel's GO only; task note; commit within core rule 2; mark queue line 92 BUILT, FAILED or QUESTION |
