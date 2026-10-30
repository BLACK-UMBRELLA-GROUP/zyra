---
id: DOC-ZYRA-0311
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 3 - the "What Guardians can do" row in the Seeker Profile tab and its four swipeable cards
links: [DR-ZYRA-292, DR-ZYRA-232, DR-ZYRA-233, DR-ZYRA-110, DOC-ZYRA-0290]
owner: ZYRA chat
---

# WHAT GUARDIANS CAN DO — SPEC — V1 (LOCKED 29 OCT 2026)

Pictures: `../MASTERS/` (430 × 932 logical, @3x). Match content, words, order and behaviour exactly; take fonts, spacing,
colours, back navigation and card component from the app (the Profiles details card and Profiles bottom row), not from the
prototype's drawing.

## 1. The row (Seeker Profile tab only)
| Item | Rule |
|---|---|
| Where | First row of the **SAFETY & SHARING** section of the Seeker Profile tab, above the existing rows |
| Icon | Shield, gold (same icon family and size as the other Profile rows) |
| Title / subtitle | **What Guardians can do** / **Who sees what, and what you control** (subtitle in gold, like "Manage membership") |
| NEW tag | Small gold pill **NEW** before the chevron until the Seeker opens the page once (stored on the device) |
| Opens | The page in §2 |
| Guardian accounts | Not shown in the Guardian role's Profile tab |
Master: `profile_tab__what_guardians_can_do_row.png` (scrolled to the section).

## 2. The page
| Item | Rule |
|---|---|
| Title | **What Guardians can do** |
| Layout | Exactly the Profiles tab layout: page dots above the card (current dot = long gold pill), one large card, bottom row ‹ · button · › |
| Card style | The Profiles **details card**: centred gold-ring circle with a gold icon, title (light, large), gold subtitle, then rows separated by thin lines |
| Moving | Swipe left/right, tap right half = next / left half = previous, or the ‹ › buttons. ‹ is disabled on card 1, › on card 4. No wrap-around |
| Bottom button | **Manage your Guardians** → opens the Seeker Guardian tab |
| Accessibility | Each card is read as "<title>, card n of 4", rows in order |

## 3. The four cards (words exact)
| # | Icon | Title | Subtitle | Rows |
|---|---|---|---|---|
| 1 | Shield | **Your Main Guardian** | **<Main Guardian first name> · <relationship>** (e.g. Hassan · Father). No Main Guardian: **You have no Main Guardian yet** | Is part of every Journey you begin · Sees your Journey requests — sent and received — and who each is with · Sees that person's profile as anyone browsing would · Decides each 48-hour Family Review |
| 2 | Group | **Your Additional Guardians** | **You choose, Journey by Journey** | See a Journey only if you switch View on · Write in it only if you switch Chat on and they have Guardian One · Don't see your Journey requests |
| 3 | Couple | **Other Seekers’ Guardians** | **When you send someone a request** | Their Main Guardian sees that you asked to begin a Journey · They see your profile as anyone browsing would · Nothing more |
| 4 | Eye with line | **No Guardian ever sees** | **Yours stays yours** | Your private answers · Your Compatibility Unlock details · Your past Journey summaries — unless you switch that on for them |
Masters: `what_guardians_can_do__1_your_main_guardian.png` … `__4_no_guardian_ever_sees.png`.

## 3b. Fix first — make the app true to card 4 (added after Codex's preflight, queue line 7)
Codex found that the preview's **Guardian Circle** offers a Guardian past-Journey topics (start/end dates, "View Journey")
for the Seeker's past Journeys even when **Share past Journey summaries is off** and even for Journeys that ended before the
Guardian linked (`discussionArchiveFor`, shell ≈ lines 4730–4831). That breaks the approved rule DR-ZYRA-233 (past summaries
off by default, per Guardian, revocable) and would make card 4 untrue.
| Rule to enforce in the Founder preview | Source |
|---|---|
| A Guardian sees a past-Journey topic or archive in the Circle **only** if that Seeker has switched Share past Journey summaries **on** for that Guardian | DR-ZYRA-233 |
| Switching it off removes those topics at once; re-linking starts with it off | DR-ZYRA-233 |
| Past Journeys that ended before the Guardian linked follow the same switch (no extra access by default) | DR-ZYRA-233 |
| The Seeker's own Circle view is unchanged | — |
This enforces an approved rule; it changes no design. Build it before the page in §1–3.

## 4. Must not change
Every other Profile tab row and section; the Guardian tab; any rule, server or database. Words come from the approved rules
(DOC-ZYRA-0290 §3–5); if code behaviour disagrees with a sentence, stop and report — do not edit the sentence.

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed by the Founder |
| 2026-10-29 | V1 | §3b added after Codex's preflight (line 7 FAILED): Circle past topics must follow DR-ZYRA-233 so card 4 is true |
