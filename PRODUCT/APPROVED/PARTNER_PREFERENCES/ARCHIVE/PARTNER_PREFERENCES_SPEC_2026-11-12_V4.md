---
id: DOC-ZYRA-0500
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 30 - amber light reads "Open to this" (DR-ZYRA-250 D1) and the one-time quick check of legacy amber answers
links: [AD-AIOS-115, DR-ZYRA-250]
owner: ZYRA chat
---

# PARTNER PREFERENCES — SPEC — V4 (LOCKED 12 NOV 2026, SET-UP LIGHTS + COUNTERPART VARIANTS + TOTALS 12 NOV)

**V4 (12 Nov, QUESTIONS 114):** the "of N" total follows the V3 filter — the obvious consequence of the Founder's V3 choices, no new choice needed. V3 is in `../ARCHIVE/PARTNER_PREFERENCES_SPEC_2026-11-12_V3.md`.

**V3 (12 Nov, QUESTIONS 107):** which Chapter 3 controls a Seeker sees when a question has gender-specific variants (e.g. q26, q39) — follows the Founder's **DR-ZYRA-250 D2** and was confirmed by the Founder 12 Nov 10:50 (clickable): **"Only the other person's version (Recommended)"** and **"Yes, only the other gender sees it (Recommended)"**. V2 is in `../ARCHIVE/PARTNER_PREFERENCES_SPEC_2026-11-12_V2.md`.

**V2 (12 Nov, Codex question on line 92):** Quick check also covers the profile set-up (Chapter 2) **sect** lights and the **revert** light. Founder clickable **"Inside Deen, top section (Recommended)"** + **"Yes, same section (Recommended)"** (prototype V197 → V198). V1 is in `../ARCHIVE/PARTNER_PREFERENCES_SPEC_2026-11-12_V1.md`.

**Founder, 12 Nov (clickable, prototype V195 → V196):** "LOCK it (Recommended)" + My ZYRA item "Yes (Recommended)". Raised by Codex QUESTIONS 105 (line 89). Decision source: **DR-ZYRA-250 D1** (28 Sep): Green = Prefer this = 1 · **Amber = Open to this = 0.5** · Red = Not for me = 0; existing amber saved as "No preference" must not be reinterpreted; only affected legacy amber controls need reconfirmation; do not reset the bank. Reference: prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V199.html` (screen list "Partner preferences · Quick check (legacy amber)"; My ZYRA). No masters (charter rule 13).

| Item | Rule |
|---|---|
| Light words | Everywhere the three lights appear (Partner preferences, sign-up Chapter 3, edit screens): **Prefer this · Open to this · Not for me**. Legend on Partner preferences: **Prefer · Open to this · Not for me**. "No preference" / "Neutral" no longer appear as a light label (an answer *option* that is itself called "No preference" stays) |
| Who must check | Only options whose saved light is a **legacy amber** (saved before the new meaning, flagged by the server as needing reconfirmation). Nothing else is reset |
| **Set-up lights (V2)** | Partner preferences → **Deen & Islamic Practice** starts with a section labelled **FROM YOUR PROFILE SET-UP** (small caps, gold) holding the Chapter 2 lights, then a small caps **PARTNER PREFERENCES** label before the Chapter 3 questions (Chapter 3 flow unchanged from V1). Rows: **"Your partner's sect"** (one option card each for Sunni · Shia · Other, three lights each) · **"Someone from outside your preferred sect"** (one light) · **"Someone who reverted to Islam"** (one light). Same question page, lights, Check tag, "Saved before as “No preference”. Tap a light to confirm." line and any-tap-confirms rule. These rows count in the card's and Needs-you "n answers to check", **not** in the "of 325" Chapter 3 totals. A tap writes back to the same set-up answers (sect matrix, outside-sect flexibility, revert flexibility) — Fable's Q105 write. Sign-up Chapter 2 itself keeps its own screens (only the light words change) |
| **Counterpart variants (V3)** | For every question with gender-specific wording or options, the Seeker sees **only the variant the counterpart answers** — the counterpart's question text and option words, with this Seeker's three lights (e.g. q26: a man sees the women's variant, a woman sees the men's variant). A question the counterpart is never asked (e.g. q39 Masjid attendance is asked of men, so it shows only to women) is not shown. These rows look and behave like every other row, including Check tags for legacy amber |
| **Unmatched controls (V3)** | A shown control with no saved light in the owner-only response is **"Not set"** (not "to check") and never counts as confirmed; a saved light for a variant the Seeker no longer sees is left untouched and unconfirmed (Codex default, QUESTIONS 107) |
| **Totals (V4)** | Every "n of N" for partner preferences (My ZYRA status pill "Preferences n/N", the My ZYRA status item, Edit profile row "n of N set", Partner preferences category and question rows) uses **N = the number of partner choices this Seeker can see** after the V3 counterpart filter (e.g. **320** for the current male fixture), worked out from the displayed bank — **never a fixed 325**. **Set-up lights (sect, outside-sect, revert) are not counted** in N or n; they only count in "n to check". Category totals are the same count per category |
| Quick check card | Top of Partner preferences while any remain: ivory card, gold border 50 %, small caps **QUICK CHECK**, title **"n answers to check"**, text **"The amber light now means “Open to this”. Tap a light again on each one, even if it stays amber, so it counts."**, gold **Check now** → opens the first question with an option to check |
| Lists | Category rows show **"n to check"** in gold before the count; question rows show **"n to check"** instead of the count |
| Question page | Each option to check has a gold border, a small **Check** tag and the line **"Saved before as “No preference”. Tap a light to confirm."** Tapping **any** light on that option — including amber again — is the explicit reconfirmation; the tag goes at once; after the last one on a question a toast "Saved. n left to check." / "All checked. Thank you." |
| My ZYRA | While any remain, a **Needs you** item for the Seeker: **"A few preferences need a quick check"** · "The amber light now means “Open to this”. Tap each one again so it counts." · gold **Check now** (same action as the card). It goes when all are checked |
| Never | Never auto-confirm, never convert untouched legacy amber, never count an untouched option as reconfirmed; until confirmed the scorer keeps that answer at `needs_reconfirmation` (Codex default, QUESTIONS 105) |
| App → server | The app sends, per tapped option, the option key, the chosen light and an explicit **reconfirmed** mark through the owner-only write that **Fable specifies in QUESTIONS 105** (server design, charter rule 14). An ordinary save never carries the mark |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-12 | V1 | First version |
| 2026-11-12 | V4 | Totals = visible partner choices after the V3 filter, set-up lights excluded, never fixed 325 (QUESTIONS 114). V3 archived |
| 2026-11-12 | V3 | Counterpart variants per D2 and unmatched controls (QUESTIONS 107). V2 archived |
| 2026-11-12 | V2 | Set-up sect + revert lights inside Deen, top section. V1 archived |
