---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-31)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 22 - Unity pass, pages with no LOCK of their own moved into ZYRA's styles (V1 - Compatibility score, Compatibility Unlocks, Safety)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# UNITY PASS — SPEC — V3 (LOCKED 31 OCT 2026)

## 1. Purpose and scope
On 31 Oct the Founder asked for every page to use ZYRA's five styles: Monogram, Photo card, Floating cards, Chat and Bottom sheet. Pages are reviewed one section at a time. Sections that touch a page already under its own LOCK go into that LOCK (Filters → LOCK 10 V7; Guardian chat → LOCK 8 V4). **This spec holds the pages that have no LOCK of their own.** It grows by version as more sections are locked.

| Version | Section | Pages | Founder |
|---|---|---|---|
| V1 | 3 of 9 · Big ring | Compatibility score (locked state), Compatibility Unlocks, Safety | "After A · Monogram (Recommended)" |
| V2 | 5 of 9 · Flat lists | Report profile | "After B · Monogram + cards (Recommended)" |
| V3 | 7 of 9 · Empty pages | **Every empty state, app-wide** (Seeker and Guardian) | "After A · Monogram + action (Recommended)" |

Prototype: V124. Masters: `../MASTERS/x01–x06`, `e01–e02` (Guardian empty masters in `GUARDIAN_TABS/MASTERS/` g05, g16, g20, g23) (1290 × 2796, Ivory, @3x).

## 2. Shared Monogram head
A 96 pt circle with a 1 pt gold ring (`rgba(169,121,46,.7)`) and gold content inside. Below it: title 26 pt light, a gold small-caps line (11 pt, letter-spacing 1.2), and an optional muted line (12.5 pt). The head sits centred in the free space above the page's action. There's no empty block at the bottom.

## 3. Pages
| Page | Layout | Master |
|---|---|---|
| **Compatibility score** (locked; opened from a profile) | Title "Compatibility score". Head: lock icon · "You and <first name>" · "READY TO REVEAL". Floating card with two rows: **Your overall score and six areas** — "Faith & Values, Family, Lifestyle and more" · **Uses 1 Unlock** — "It stays unlocked for <first name>, also in a Journey Bio". Bottom: gold **Unlock compatibility** (existing unlock action); text button "<n> Unlock(s) left · **Get more**" → Compatibility Unlocks. The revealed state is unchanged | x01 |
| **Compatibility Unlocks** | Title "Compatibility Unlocks". Head: the number of Unlocks left in the ring · "Unlock left" / "Unlocks left" · Seeker One: "3 MORE EACH MONTH WITH SEEKER ONE", Seeker Basic: "SEEKER ONE INCLUDES 3 EACH MONTH". Floating row: lock icon, **Your match, revealed** / "One profile. Every score.", ‹ "1 / 8" › (the existing 8 "What's included" cards). Three pack tiles: **1 Unlock £2.99** "For one profile" · **3 Unlocks £6.99** "£2.33 each" · **5 Unlocks £9.99** "£2.00 each". The chosen tile has a gold border and light gold fill, and 3 Unlocks is the default. Bottom: gold **Continue** (purchasing not available yet, as today); "Purchase terms · Purchasing isn't available yet". The "Unlocks remaining" box and the (i) button are replaced by the head | x02, x03 |
| **Report profile** (V2) | Title "Report profile". Head: 72 pt round photo with gold ring · "<First> <Surname>" 22 light · gold small caps "CHOOSE THE REASON". One floating card with the seven reasons as radio rows (gold radio when chosen; first chosen by default): Impersonation or fake profile · Nudity or sexual content · Harassment or abusive behaviour · Minor or underage · Violence or disturbing content · Privacy or personal information · Something else. Bottom: **Submit report** outline (still a draft — LOCK 16 V2), then **Hide profile** (muted) and **Block profile** (red) → existing flows and the LOCK 16 warning sheets | x05, x06 |
| **Safety** | Title "Safety". Head centred on the page: shield icon · "Choose a profile to report" · "Open the person's profile and choose Report. You can then pick the reason that fits best." **The disabled "Submit report" button is removed** (it did nothing) | x04 |

## 3b. Empty state (V3, app-wide)
One shared widget: 96 pt circle with a 1 pt gold ring (`rgba(169,121,46,.65)`) holding the gold outline icon (34); title 21 light; muted text 12.5 (line height 1.5, about 270 wide); optional gold-outline action pill (40 high) that opens an **existing** page. Centred in the free space. Loading spinners are not empty states and stay as they are.

| Empty state (known) | Title / text | Action |
|---|---|---|
| Profiles — no profiles in this view | today's text | — |
| Profiles — couldn't load | today's text | — |
| Journey requests — received / sent / past | today's texts | — |
| Introductions (Seeker) (e01) | "No introductions yet" / "People your Guardians put forward will appear here." | — |
| Ended Journeys (Seeker) (e02) | **"No ended Journeys" / "When a Journey ends, it's kept here with its Timeline."** (new line) | — |
| Guardian Journey requests — received / sent | today's texts | — |
| Connect with Guardian · Sent (g16) | today's text | **Open Network** |
| Connect with Guardian · Received (g20) | today's text | — |
| Introductions you've made (g05) | today's text | **Open Network** |
| Ended Journeys (Guardian) (g23) | today's text | — |
| Any other "no … yet" state found in the app | today's text | — |

## 4. Rules
- Prices come from the existing Unlock pack data, never typed in.
- Larger Text: rows and tiles grow taller; nothing clips.
- No member counts.

## 5. Open finding (not in this LOCK)
Profile → "Safety & advice" opens this Safety page, but the page holds report instructions only. The Founder will decide whether to rename the row or add real advice.

## 6. Version history
| Date | Version | Change |
|---|---|---|
| 2026-10-31 | V1 | Unity review 3 of 9 (Big ring) → "After A · Monogram" |
| 2026-10-31 | V2 | Unity review 5 of 9 (Flat lists) → Report profile "After B · Monogram + cards" |
| 2026-10-31 | V3 | Unity review 7 of 9 (Empty pages) → app-wide Monogram empty state, "After A · Monogram + action" |
