---
id: DOC-ZYRA-0387
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 19 - Seeker Guardian tab as Monogram Guardian cards, with Journey access side, the Guardian Basic chat sheet (ZYRA Family routes) and (V3) the Guardian's accept-a-Family-place page
links: [AD-AIOS-115, DR-ZYRA-233, DR-ZYRA-248, DR-ZYRA-252, DR-ZYRA-268, DR-ZYRA-289, DR-ZYRA-291]
owner: ZYRA chat
---

# GUARDIAN CARD — SPEC — V10 (LOCKED 11 NOV 2026, INVITATION STATES 20:25)

**V10 (11 Nov, prototype V176):** the invited Guardian card has two states and no "Send invitation again" while waiting. Founder: "for omar it says send invitation again then when clicked shows me qr code area but thats not needed - there should be something where if the expiery passes they can send again but dont have to scan or enter code again so maybe for that waiting pade we done need send inviation again" → clickable **"LOCK it (Recommended)"**. V9 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V9.md`.

**V9 (11 Nov 20:10, prototype V173):** the swipe becomes a carousel. Founder: "i want it more subtle waht i mean is as i swipe i can start seeing the next card. right now its swipw with inger on and it shows blank area". V8 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V8.md`.

**V8 (11 Nov, prototypes V168–V169):** the ••• menu becomes a full-screen bottom sheet, and the card moves with the swipe. Founder: "make this look better when i click 3 dots why can i see a outline and it loks ugly- do a small fix to fix this pelase". V7 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V7.md`.

**V7 (11 Nov 18:30, prototype V164):** Guardians per Seeker and the Seeker Basic Add card (§6.0b). Founder: "both seeker one and seeker basic you can have a max of 10 gurdians paid or free but with seker one it can be a optoins of 10 paid or 10 free but for seekr basic its only 1 free. the 9 other slots either stay empty or get filled by paid gurdians ie gurdian ones or he upgrades" → clickable **"LOCK rule + card (Recommended)"**. V6 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V6.md`.

## 6.0b Guardians per Seeker and the Seeker Basic Add card (V7)
| Item | Rule |
|---|---|
| Limit | Every Seeker: **up to 10 Guardians** (Main included). A Guardian supports at most 10 Seekers (unchanged) |
| Seeker One | Any mix of **Guardian Basic** and **Guardian One** |
| Seeker Basic | At most **1 Guardian on Guardian Basic**; every other Guardian (up to 10 in total) must be on **Guardian One** — paid by the Guardian, or by the Seeker's ZYRA Family place. Or the Seeker upgrades to Seeker One |
| Seeker Basic Add card | Replaces "Add more Guardians" (lock). Plus icon · **Add a Guardian** · "<n> of 10 Guardians. One Guardian can be on Guardian Basic; the rest need Guardian One." (when the Basic place is used: "Your Guardian Basic place is used, so new Guardians need Guardian One.") · two small boxes: **Free / Used** "Guardian Basic place" and **<n>** "Guardian One places" · link **Seeker One: any 10 Guardians ›** (→ existing upgrade page) |
| Pill | **Add a Guardian** (was "View Seeker One" for Basic) → the existing Add a Guardian page (LOCK 9) |
| Not yet designed | What a Guardian on Guardian Basic sees when a Seeker Basic's Guardian Basic place is already used (next design) |


**V6 (11 Nov evening, prototype V161) replaces the two-sided card.** Founder: "i dont like detiles and journey access having 2 pages for 1 guardian so lets try fit everything on one page meaning detials and journey access pill goes - the profile card gets bigger and u can swipe or tap right left for next gurdian" → "yes compact left" · "just swipe or tap no icons or naything" · "theres too much dead space … remove any dead space" → clickable **"1 · Quiet list + •••"**. **§6.0 below governs the Seeker Guardian tab main page; where §2–§4 describe front/access sides, ‹ › or the Details · Journey access pills, §6.0 replaces them.** V5 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V5.md`. No masters (charter rule 13); prototype V161 is the reference.

## 6.0 One-page Guardian card (V6)
| Part | Rule |
|---|---|
| Page | Title **Guardian** with Circle and + buttons (unchanged) · page dots, one per Guardian, no dot for the Add card (V5) · **one card** filling the space to 16 pt above the tab bar (LOCK 24). **No pills under the card** |
| Moving (V9 carousel) | The Guardian cards sit side by side in one horizontal track, **24 pt apart** (neighbours are off-screen at rest). While dragging, the current card and its neighbour move **together with the finger**, so the next (or previous) card slides into view — never an empty area. Released past about 60 pt (or a quick flick), the track settles on the neighbour (~0.24 s, ease-out); a short drag springs back. Resistance at the first / last card. The Add card is the last card in the track. Edge taps and dot taps animate the same track. A swipe starting on a chip never toggles it. Reduce Motion: instant change. Use a horizontal PageView-style controller (viewport fraction 1, 24 pt page gap) |
| Top (compact) | Monogram 60 (1 pt gold ring, initial 28 pt weight 200 in gold) on the left; name 27 pt light; role in small caps 11 pt, letter-spacing 1.2 (**MAIN GUARDIAN** gold, **ADDITIONAL GUARDIAN** muted); **•••** at the top right |
| ••• menu (V8) | A **full-screen bottom sheet** like the other sheets (Guardian Basic sheet): the whole screen dims (scrim `rgba(30,22,16,.38)`, tab bar included), sheet `#F7F2EA`, top corners 26, soft shadow, grab handle; small muted line "<name> · <role>"; rows **Make Main Guardian** / **Remove as Main Guardian** · **Remove <name>** (`#AC453E`) · a rounded **Cancel** pill. Tap outside closes. The card itself shows no outline, corners or scrim of its own while the sheet is open. Same confirms as today |
| Details list | Thin-line rows: **Relationship** · **Membership** · **Linked** (invited: **Status** · Waiting for <name>), label muted left, value right |
| JOURNEY ACCESS | Small gold label, then one row per Journey place, rows **sharing the remaining height evenly** (no empty space). Journey row: photo 42 · first name 15 pt · "Stage <n> of 8 · <stage>" 11 pt muted · a 3 pt gold progress bar (stage / 8) · **View** and **Chat** chips on the right (on = gold outline, light gold fill, `#845F24` label with ✓; off = muted outline). Guardian Basic: Chat is a dashed chip with a lock that opens the Guardian Basic sheet (§6). Turning View off turns Chat off |
| Free place row | Dashed gold "+" circle, **Free Journey place**, small "<name>'s access is set when a Journey begins" |
| Bottom | **Past Journey summaries** switch (per Guardian, default off) |
| Invited Guardian (V10) | Same top (no •••) and details; role **INVITATION SENT** (expired: **INVITATION EXPIRED**); Status row "Waiting for <name>" (expired: "Expired <date>"). Journey area = one dashed box: **Waiting** — mail icon, "Waiting for <name> to accept", "Invitation sent <date>. <name> has until <date> to accept in their app. Access starts once they accept.", small muted **Cancel invitation** (confirm). **No resend button while waiting.** **Expired** (7 days passed) — "!" icon, "The invitation has expired", "<name> didn't accept within 7 days (ended <date>). Send it again — no code needed.", full-width pill **Send again** → resends the same invitation at once (no code, no QR, no Add a Guardian page), toast "Invitation sent again to <name>. He has until <date>.", card returns to Waiting with new dates. Replaces the V3 §5 correction that opened Add a Guardian. Prototype-only: "Demo: 7 days pass" |
| Add card | Unchanged (V5): the Add a Guardian card with its single **Add a Guardian** / **View Seeker One** pill |
| No dead space | Rows grow to fill; nothing leaves an empty band in the card, at 1, 2 or 3 Journey places |


**V5 (11 Nov 14:05, prototype V152; Founder: "change it to 2 pills detials and journey access and they can swipe the user by swiping the profile cards" → "yeh to pillsa re ok but … i want it to swipe between user and also … net to 3 dots they is there a plus button remove that"):** two pills replace ‹ › ; swiping the card moves between Guardians; tapping the card no longer flips it; no **+** after the dots. V4 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V4.md`.

**V4 (11 Nov, prototype V146; Founder clickable "A · Dot per Guardian + '+' (Recommended)"):** page dots count Guardians, not card sides; the card never moves up and down; pill 16 pt above the tab bar (LOCK 24). V3 is in `../ARCHIVE/GUARDIAN_CARD_SPEC_2026-11-11_V3.md`. No masters re-rendered (charter rule 13): k01–k22 stay for everything else; for the dots, the prototype is the reference.

## 1. Purpose and scope
The Seeker's **Guardian tab** main page becomes one **Monogram card per Guardian**, with a flip side for **Journey access**, a last card to **add a Guardian**, and a **Guardian Basic chat sheet** that offers the approved ZYRA Family routes.
Prototype: V106 (Guardian tab). Masters: `../MASTERS/k01–k22` (1290 × 2796, Ivory, @3x).

**In scope:** the Seeker Guardian tab main page (Seeker One and Seeker Basic), its header, card front, access side, invited card, add card, ‹ › pill, and the Guardian Basic chat sheet with its price and invite-sent steps.
**Not in scope:** the Guardian Circle page (LOCK 20); Add a Guardian / Code page (LOCK 9); What Guardians can do (LOCK 3); the Guardian's own app (LOCK 8);  any server, store product or price change.

## 2. Page layout (top to bottom)
| Part | Rule | Master |
|---|---|---|
| Header | Title **Guardian**; right: round **Guardian Circle** button with the LOCK 17 gold unread bubble, round **+** (Seeker One → Add a Guardian; Seeker Basic → the existing "Add more Guardians" upgrade) | k01 |
| Page dots (V4) | LOCK 18: under the title, centred. **One dot per Guardian** in card order (linked and invited), **no dot or + for the Add card** (V5). The current Guardian's dot is the long gold dot; on the Add card no dot is lit. 3 Guardians = 3 dots. Switching to the access side does **not** change the dots. Tapping a dot opens that Guardian (Details side) | prototype V146 |
| Card | One large card filling the space between dots and pill (no dead space). Main Guardian's card has the gold border (`rgba(232,201,138,.6)`). **V4: the card is static — it does not scroll, drag or bounce up and down.** Only when Larger Text makes the content taller than the card may the content inside the card scroll, with no bounce | k01 |
| Pills (V5) | Under the card, **16 pt above the tab bar** (LOCK 24). **Linked Guardian:** two pills side by side, 8 pt apart, each 52 high, fully rounded, ivory glass: **Details** · **Journey access**. The selected one has a gold outline (`rgba(169,121,46,.6)`), small-gold label `#845F24` weight 500 and a soft shadow; the other has the normal border and muted label. Tapping a pill shows that side. **Invited Guardian:** one full-width pill **Send invitation again** (gold outline, gold label). **Add card:** one full-width pill **Add a Guardian** (Seeker Basic: **View Seeker One**). The ‹ › arrows are removed | prototype V152 |
| Moving between Guardians (V5) | **Swipe the card** left / right (also on the invited and Add cards). Tapping the card does nothing (no flip); the pills change the side. Changing Guardian always opens the Details side | prototype V152 |
| Tab bar | Unchanged (LOCK 6), Guardian tab selected | k01 |

Card order: Main Guardian first, then Additional Guardians (linked date order), then invited Guardians, then the **Add a Guardian** card last.

## 3. Card front (linked Guardian)
| Item | Rule | Master |
|---|---|---|
| Monogram | 110 × 110 circle, 1 pt gold ring `rgba(169,121,46,.7)`, first initial 52 pt weight 200 in gold | k01 |
| Name | 34 pt light, 18 pt above | k01 |
| Role | Small caps 11.5 pt, letter-spacing 1.2: **MAIN GUARDIAN** in gold; **ADDITIONAL GUARDIAN** in muted | k01, k05 |
| Rows | Thin-line rows with a gold icon: relationship (person icon) · membership (shield icon: "Guardian One", "Guardian Basic", or "Guardian One · Family place") · "Linked <date>" (check icon) | k01, k05 |
| Past Journey summaries | Last row: label + switch, per Guardian, default **off** (DR-ZYRA-233; follows LOCK 3 V2 §3b) | k01 |
| Tap (V5) | Tapping the card does nothing; the **Journey access** pill opens the access side | prototype V152 |

## 4. Access side (linked Guardian)
| Item | Rule | Master |
|---|---|---|
| Title | Small gold caps **JOURNEY ACCESS**; no other text | k02 |
| Tiles | One tile per Journey place, sharing the card height equally (Seeker One 3 places, Seeker Basic 1) | k02, k03, k18 |
| Journey tile | Photo on the left (34 %, max 150), first name, "Stage n of 8 · <stage>", then two pill switches **View** and **Chat** (gold border + light gold fill + ✓ when on) | k02 |
| Free place | Dashed tile: "Free place · <Name>'s access is set when a Journey begins" | k02, k04 |
| Defaults | View on. Chat on for the Main Guardian, off for Additional Guardians. Chat can only be on while View is on | k02, k06 |
| Guardian Basic | Chat pill is dashed, muted, with a lock: **🔒 Chat**. Tap opens the sheet (§6) | k06 |
| Buttons | Bottom row: **Remove as Main** / **Make Main** (existing confirm flows) and **Remove** in red `#B84A42` (existing confirm flow) | k02, k06 |
| Tap / pill | Tapping the card flips back; pill centre reads **Details** | k02 |

## 5. Invited Guardian card and Add card
| Card | Rule | Master |
|---|---|---|
| Invited | Monogram at 55 % opacity, role **INVITATION SENT**, rows: relationship · "Not joined yet" · "Waiting for <Name>". No flip, no summaries row. Pill centre **Send invitation again** → opens the unchanged **Add a Guardian** page (LOCK 9: Your ZYRA Code with Copy · QR · Share, or enter their code). There is no separate resend. **Preview data:** the Founder preview seeds one invited Guardian exactly as k07 (Omar · Brother, "Waiting for Omar"), sample only, no server | k07 |
| Add (Seeker One) | Dashed gold card: + icon, **Add a Guardian**, "Share your ZYRA Code, or scan theirs. You choose who joins." Pill centre **Add a Guardian** → Code page (LOCK 9) | k08 |
| Add (Seeker Basic) | Dashed card: lock icon, **Add more Guardians**, "Seeker Basic includes 1 Guardian. Seeker One lets you add up to 10." Pill centre **View Seeker One** → existing upgrade page | k19 |

## 6. Guardian Basic chat sheet
Bottom sheet over a dimmed page (`rgba(30,22,16,.38)`; tap outside closes), ivory `#F7F2EA`, radius 26 at the top, grab handle.

### 6.1 First step — depends on the Seeker's ZYRA Family
| Family state | Third row (plus icon) | Gold button | Master |
|---|---|---|---|
| No Family | **Pay for <Name> with ZYRA Family** — "Put your membership and <Name>'s Guardian One in one monthly plan. You'll see the price first." | **See the price** → §6.2 | k09 |
| Family with a free Guardian place | **Give <Name> your free Guardian place** — "Your ZYRA Family has a Guardian One place free. It costs you nothing more." | **Give <Name> the place** → §6.3 directly | k11 |
| Family with no free Guardian place | **Add a Guardian place for <Name>** — "Your ZYRA Family has no free Guardian place. You'll see the new price first." | **Add a place** → §6.2 | k12 |

Always shown: header (monogram 44, "<Name> can view, but not chat", "<Name> is on Guardian Basic"); row 1 eye icon **What <Name> can do now** — "See the Journeys you let them view, follow each stage, and read your Guardian Circle." (V2, LOCK 20); row 2 chat icon **Chat comes with Guardian One** — "With Guardian One, <Name> can also chat in your Journeys when you turn Chat on."; row 4 person icon **Or <Name> upgrades** — "Guardian One is also in Profile → Membership in <Name>'s app."; text button **Not now** closes.

### 6.2 Price step
| Item | Rule | Master |
|---|---|---|
| Title | "Cover <Name> with ZYRA Family" / "Guardian One for <Name>, in your monthly plan" | k10 |
| Lines | **Now ·** current plan and monthly price (muted) · **New ·** ZYRA Family · n places and the new monthly price (gold) | k10, k13 |
| Prices | From the ZYRA Family formula (Pricing V6 §2; server `zyra_family_formula_monthly_pence`). Never hard-coded. Masters show: no Family £29.99 → 2 places £49.98; full Family 2 places £49.98 → 3 places £66.47 | k10, k13 |
| Small print | No Family only: "You keep Seeker One as your own Family place; your current membership is replaced." Always: "Starts today; Apple adjusts this month's charge. <Name> still has to accept." | k10 |
| Buttons | Gold **Continue with Apple** → §6.3; text **Back** → §6.1 | k10 |

### 6.3 Invite sent
| Item | Rule | Master |
|---|---|---|
| Title | "Invite sent to <Name>" / "Guardian One · ZYRA Family place" | k14 |
| Rows | mail icon **<Name> accepts in their app** — "<Name> has 7 days to accept. If they don't, the place stays free for you." · chat icon **Then you choose Chat** — "Once <Name> accepts, the Chat switch opens here. It stays off until you turn it on." | k14 |
| Buttons | Gold **Done**; text **Cancel invite** (withdraws the invite, place stays free, sheet closes) | k14 |
| Card after | Locked pill reads **🔒 Invited**; tapping it reopens §6.3 | k15 |
| After accept | Membership row "Guardian One · Family place"; Chat becomes a normal switch, **off** | k16 |

### 6.4 The Guardian accepts or declines the place (V3, Guardian app, Guardian Basic)
Example: Adam gives his father Hassan a Guardian One place (the same page shows for Ibrahim, Omar, or anyone invited).

| Item | Rule | Master |
|---|---|---|
| Where it appears | Guardian **My ZYRA → Needs you**, first: shield icon · **<Seeker> has given you Guardian One** · "A place in <Seeker>'s ZYRA Family. You pay nothing. Choose by <date>." · gold **View** | k20 |
| Page | Header back + title **Guardian One**. Monogram 96 with the Seeker's initial · title **<Seeker> has given you Guardian One** (24 light) · gold small caps **ZYRA FAMILY PLACE** | k21 |
| Card | Four rows (gold icon, title, muted line): **What Guardian One adds** (membership icon) — "Chat in <Seeker>'s Journeys when he turns it on, plus Connect with Guardian and Introductions." · **<Seeker> pays** (payments) — "It's a place in <Seeker>'s ZYRA Family. You pay nothing." · **Your role stays the same** (people) — "You stay <Seeker>'s <relationship> and <Main / Additional> Guardian. Chat stays off until <Seeker> turns it on." · **Choose by <date>** (history) — "If you don't accept, the place stays free for <Seeker>." (date = invite + 7 days) | k21 |
| Buttons | Gold **Accept Guardian One**; text **Decline** | k21 |
| Accept | The Guardian becomes Guardian One; Profile membership row **Guardian One** · "Family place · paid by <Seeker>"; locked tiles open; the Seeker's card shows k16 (Chat switch, off). Uses the existing identity check if the Guardian has not passed it (DR-ZYRA-221) | k22 |
| Decline | Page closes; toast "Declined. The place stays free for <Seeker>."; the Seeker's card returns to Guardian Basic and the place stays free | — |
| Pronoun | Follows the Seeker (he / she) | — |

## 7. Rules carried (all already approved)
| Rule | Source |
|---|---|
| Guardian Basic can view, cannot chat | DR-ZYRA-268 |
| A Seeker may buy Guardian One places in ZYRA Family and give them; up to 10 places in total | DR-ZYRA-291, Pricing V6 §2 |
| The invited person must consent, be verified and match the role; invites expire after 7 days | Pricing V6 §4 |
| Paying never links anyone, never changes Main, never turns Chat on | Pricing V6 §1, DR-ZYRA-289 |
| A removed member keeps funded access to renewal; that place can't be reused before then | Pricing V6 §4 |
| Owner must hold a place for their own role (why "You keep Seeker One as your own Family place") | Pricing V6 §4 |
| A Guardian who already has Guardian One (own or another Family) is not Basic, so the sheet never shows | Pricing V6 §1 |
| No member counts anywhere | Founder standing rule |

## 8. Build stage in this line
Seeker side and the Guardian's accept page (§6.4), **local preview** like LOCK 8 V2 Connect: the price step reads the real formula; **Continue with Apple**, **Give the place** and **Cancel invite** change local state only — no charge, no server write. Real store products and the Family invite server path are OA-ZYRA-317 items 3 and 7.

## 9. Pending (not in this LOCK)
| Item | Owner |
|---|---|
| — | Nothing pending (the Guardian's accept page was designed in V3, §6.4) |

## 10. Version history
| Date | Version | Change |
|---|---|---|
| 2026-10-31 | V1 | Founder: "LOCK it" (Monogram card) and "LOCK it in 19" (Basic sheet with ZYRA Family routes, V106) |
| 2026-10-31 | V2 | Basic sheet row 1 adds "and read your Guardian Circle" (LOCK 20, Founder "Read only"); masters k09, k11, k12 re-rendered (V1 pictures in `ARCHIVE/MASTERS_V1/`) |
| 2026-10-31 | V3 | The Guardian accepts or declines a ZYRA Family place — My ZYRA Needs-you item and full page (Founder: "After A · Full page (Recommended)"); masters k20–k22 |
| 2026-10-31 | V3 | Correction after Codex question 5 (line 48): §5 invited card — "Send invitation again" opens Add a Guardian (LOCK 9); the preview seeds the k07 sample. My spec wrongly said "existing resend". No design change |
