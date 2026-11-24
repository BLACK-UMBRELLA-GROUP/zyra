---
id: DOC-ZYRA-MEMBERSHIPPAGE-V1
type: SPEC
status: CURRENT
feature: MEMBERSHIP PAGE (paid members)
purpose: Spec for LOCK 42 - Profile → Membership for Seeker One and Guardian One; replaces the old dark membership__section_current page
owner: ZYRA chat
---

# MEMBERSHIP PAGE — SPEC — V1 (LOCKED 23 NOV 2026)

## Purpose
The Membership page is where a paid member checks their plan, what it gives them and how to cancel. The 23 Nov walkthrough found it still in the old dark style; this replaces it. Founder 23 Nov (Claude chat, clickable): "Lock and queue (Recommended)". Fixed prototype reference: `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ARCHIVE/ZYRA_PROTOTYPE_2026-11-23_V315.html`.

## 1. Where it opens
| Member | Profile → Membership opens |
|---|---|
| Seeker One | This page |
| Guardian One | This page |
| Basic members | The existing plans / upgrade page (no change) |

## 2. Layout (mb01–mb03)
Settings style (LOCK 37), from top to bottom:

1. **Plan card**
   - ONE ring badge, plan name (21 pt light) and the billing line in grey: "£29.99 a month · renews <date>" (Guardian One: £19.99).
   - During a free trial the billing line is green `#326B4C`: "Free trial · first payment of £29.99 on <date>" (mb02).
   - A thin line, then four "what you have" rows with icons:
     - **Seeker One:** 3 Journey places · Unlimited profiles and every filter · Every Compatibility topic · 3 Unlocks a month · 10 Guardians on any plan.
     - **Guardian One:** See the Journeys your Seekers allow · Chat in a Journey, when your Seeker allows it · Guardian Circle: read and write · Network, Introductions and Connect with Guardian.
2. **MORE** rows, values right-aligned:
   - Seeker: Compatibility Unlocks (<n> left) · ZYRA Family places (<n> free).
   - Guardian: Covered by a ZYRA Family?
   - Both: Compare plans · Restore purchases.
3. **Cancel membership** card, pinned to the bottom (line 119 rule kept): ✕ in red, "Cancel membership", "Turn off renewal in App Store. You keep <plan> until <date>." Tapping it opens the App Store subscriptions page.

## 3. Rules
- Prices and dates come from the membership catalogue and the purchase record, never typed twice.
- Members paid for by a ZYRA Family see their payer in the billing line ("Paid by <name> · ZYRA Family"); that wording follows the existing Family spec.

## 3b. Correction 24 Nov (QUESTIONS 211)
**Dates and trial state**
- Founder preview: one sample membership record per preview account, read-only sample data. Date **6 Dec 2026** (the same date as em08/em09 and mb01–mb05). Trial on or off is a field in that record (default off; tests set it). No new developer switch.
- Guardian One trial (Q205, 14 days): "Free trial · first payment of £19.99 on 6 Dec" in green (mb04).
- Real app with no verified purchase record: price only ("£29.99 a month"), no date and no trial wording; the Cancel card's second line is just "Turn off renewal in App Store." Nothing is guessed.

**Paid by a ZYRA Family (mb05)**
- Billing line: "Paid by <name> · ZYRA Family" in grey; no trial line.
- The red Cancel membership card is **replaced**, in the same place, by a quiet gold-outlined card with no action: people icon, "Covered by <name>’s ZYRA Family", "Only <name> can change or cancel this place." Only the payer can cancel a Family place.
- Guardian row "Covered by a ZYRA Family?" shows the value "Yes".

**MORE rows — where each goes**
| Row | Opens |
|---|---|
| Compatibility Unlocks (Seeker) | The existing Compatibility Unlocks store page |
| ZYRA Family places (Seeker) | Preview toast "Opens ZYRA Family." (no approved Family page yet) |
| Covered by a ZYRA Family? (Guardian) | Toast "A Seeker can cover you with a place in their ZYRA Family. You pay nothing." · when covered: "<name> covers you with a place in his ZYRA Family. You pay nothing." |
| Compare plans | The existing plans page that Basic members open from Profile → Membership (spec §1), for the same role |
| Restore purchases | Toast "ZYRA checks your Apple ID for earlier purchases." (Q205) |

## 4. Masters
`MEMBERSHIP_PAGE/MASTERS/mb01_seeker_one`, `mb02_seeker_one__free_trial`, `mb03_guardian_one`, `mb04_guardian_one__free_trial`, `mb05_guardian_one__family_paid`, at 430 × 932 @3x.

## 5. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-23 | First version (LOCK 42) |
| V1 correction | 2026-11-24 | §3b (QUESTIONS 211): sample date and trial source, no-record rule, Family-paid card, MORE row destinations; masters mb04, mb05; prototype V339 |
