---
id: DOC-ZYRA-0370
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 15 - My ZYRA tab (Seeker and Guardian), "Focus" design, and the full list of what lives there
links: [DR-ZYRA-274, AD-AIOS-115]
owner: ZYRA chat
---

# MY ZYRA (SEEKER + GUARDIAN) — SPEC — V6 (LOCKED 31 OCT 2026, TAB BAR ON PAGES + WHOLE-PAGE SWIPE + NAME 11 NOV)

**V6 (11 Nov):** only wording: "Green / Yellow / Red" becomes **Partner preferences** (LOCK 22 V7). V5 is in `../ARCHIVE/MY_ZYRA_SPEC_2026-11-11_V5.md`.

**V5 (11 Nov 14:47, prototype V157; Founder: "in my zyra we can swipe for exampel in needs you thers 1/2 what im thinking let whoel pages be abel to swipe lef tto right even if user is hovering over introductions for exampel but not clickign it … not includign nav bar of course" → clickable **"LOCK it (Recommended)"**):** see §4c. V4 is in `../ARCHIVE/MY_ZYRA_SPEC_2026-11-11_V4.md`.

**V4 (11 Nov, prototype V156; Founder: "in my zyra when clickcing on 4 tabs at bottom journey request-introductions-ended journey-notifications. it takes me to its own page- great but im thinking leave bottom nav bar showing on them pages" → clickable **"LOCK it (Recommended)"**):** see §4b. V3 is in `../ARCHIVE/MY_ZYRA_SPEC_2026-11-11_V3.md`.

Scope: the **Seeker** My ZYRA tab (`_dashboard()` in `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`), Seeker One and
Seeker Basic; **V2 adds the Guardian My ZYRA tab in the same Focus design (§6)** — Guardian One and Guardian Basic. Guardian content stays as LOCK 8 (now V3, which points here for layout). Colours: Ivory (LOCK 14 V3, queue line 39 lands first).

Masters (430 × 932 @3x; all re-rendered at prototype V104 for V3) in `../MASTERS/`: m01 needs_you_1_of_2 · m02 needs_you_2_of_2 · m03 several_requests ·
m04 all_caught_up · m05 new_member · m06 seeker_basic; Guardian (V2): gm01 family_review · gm02 connect_request · gm03 review_paused · gm04 all_caught_up · gm05 guardian_basic.

## 1. Layout (top to bottom; the page fills the screen — no empty space at the bottom)

| Part | Rule |
|---|---|
| Title | "My ZYRA" (same title style as every tab) |
| **Focus area** | Takes all free height; content centred horizontally and vertically, text centred. Shows **one "Needs you" item at a time**: round icon (64, gold icon on a quiet fill) · eyebrow "NEEDS YOU · 1 OF 2" (11.5, gold, letter-spacing .5; just "NEEDS YOU" when there is one item) · title (25, light 300, balanced lines) · detail (12.5, secondary text, max width 300) · gold filled pill button (height 44, padding 0 30) with the item's action |
| Stepping (V3, LOCK 18) | When there are 2+ items: **page dots at the top, under the title (Guardian: under the greeting)** — tappable; **swipe left/right** on the focus area moves between items. No ‹ › arrows. Order: **newest first** |
| All caught up | When no item: "ALL CAUGHT UP" (11, secondary) and "Nothing needs you right now." (21, light) in the same centred spot |
| Status chips | Under the focus area, centred and wrapping: pill chips (12, gold 16 icon) — see §3. Hidden when none apply |
| Quick access | Bottom row of **four equal tiles** (gap 8): icon tile 38, name (11.5), short status (10.5; gold when something is new) — see §4 |
| Tab bar | Unchanged (LOCK 6 V2 / LOCK 5 gold rule) |

Removed from today's page: the "New activity" heading with "View request →", the "Quick access" label and the three long list
tiles, the old "Now / Insights 🔒" switch. (The developer "Activity preview" bar goes with queue line 35.)

## 2. "Needs you" items (exact text; an item leaves the list once its target has been opened)

| Item | Shows when | Icon | Title · detail | Button → opens |
|---|---|---|---|---|
| Journey request (one) | 1 unseen received request | mail | "Journey request from Amira" · "Amira would like to begin a Journey with you." | "View request" → Journey requests (Received) |
| Journey requests (several) | 2+ unseen received requests — replaces the single item | mail | "3 Journey requests" · "Amira, Sara and Noor would like to begin a Journey with you." (2 → "Amira and Sara"; 4+ → "Amira, Sara and 2 others") | "View requests" → Journey requests (Received) |
| Request accepted | Your sent request was accepted | check | "Sara accepted your Journey request" · "Review the next step before beginning together." | "View Journey" → that Journey |
| Request declined | Your sent request was declined | x | "Aisha declined your Journey request" · "The request is closed. No Journey has begun." | "View request" → Journey requests (Past) |
| Introduction | A Guardian put someone forward | group | "Hassan introduced Noor" · "Review the person your Guardian has put forward." | "View introduction" → Introductions |
| Journey ready | A Journey needs your next step | couple | "Your Journey with Maryam is ready to continue" · "Open the Journey to review its next step together." | "Continue Journey" → that Journey |
| Family Review opened | Guardians opened Family Review | shield | "Family Review opened" · "Your Guardians are reviewing your Journey with Sara." | "View Journey" → that Journey |
| Milestone to confirm | A milestone waits for you | check | "Milestone to confirm" · "Confirm the step you and Sara reached." | "Open Timeline" → that Journey's Timeline |
| Circle message | New message in Guardian Circle | chat | "New message in Guardian Circle" · "Hassan has added to your Circle conversation." | "Open Circle" → Guardian Circle |
| Guardian joined | A Guardian link was confirmed | shield | "Yusuf joined your Guardians" · "Review the confirmed Guardian link." | "View Guardian" → Guardian tab |
| Guardian invitation expiring | Your invitation ends soon | shield | "Guardian invitation expiring" · "Your invitation to Yusuf ends soon." | "View Guardian" → Guardian tab |
| Journey ended | A Journey ended | history | "Your Journey with Noor has ended" · "It stays in your read-only Ended Journeys." | "View Ended Journeys" → Ended Journeys |

Names are the real people's first names. Sources: the app's existing activity items and dashboard update keys
(`ZyraMyZyraActivity…`, `dashboard_updates.guardian.review_opened`, `…milestone_proposed`, `…wali_invite_expiring`).

## 3. Status chips (shown while they apply; this order)

| Chip text | Shows when | Opens |
|---|---|---|
| "Finish setup" (person) | Account setup not finished | Account setup (today's "View account setup") |
| "No Guardian yet" (shield) | No Guardian connected | Guardian tab |
| "1 of 3 places in use" (couple) — Basic: "1 of 1 place in use" | Setup finished | Journey tab |
| "Notifications off" (bell) | Notification permission not allowed | Settings → Phone access (LOCK 12 V2) |
| "Preferences 0/325" (tune) | Not every partner preference is set; numbers = the member's own set / total from the app | Edit profile → Partner preferences |

## 4. Quick access tiles (always there)

| Tile | Short status | Opens |
|---|---|---|
| Journey requests (inbox) | "{n} new" (gold) if unseen received; else "{n} sent"; else "None" | Journey requests |
| Introductions (group) | "1 new" (gold) / "None yet" | Introductions |
| Ended Journeys (history) | "{n} ended" / "None" | Ended Journeys |
| Notifications (bell) | "{n} new" (gold) / "Nothing new" | Notifications list (today's `notifications` page) |

## 4b. Tab bar on the quick-access pages (V4)
| Item | Rule |
|---|---|
| Which pages | The pages opened from the My ZYRA quick-access tiles. Seeker: **Journey requests · Introductions · Ended Journeys · Notifications**. Guardian: **Journey requests · Connect with Guardian · Introductions · Notifications** (and the Guardian Basic locked tiles' Guardian One page is unchanged, no tab bar) |
| Tab bar | The full tab bar (LOCK 6 V3, always full size) stays at the bottom of these pages, with **My ZYRA** as the current tab. Page content keeps 16 pt above it (LOCK 24) |
| Taps | Tapping any tab goes to that tab's root page (leaves the page). Tapping **My ZYRA** returns to the My ZYRA root. Back (button or swipe) still returns to My ZYRA |
| Deeper pages | Pages opened **from** these pages (a request's detail, a chat, a profile) keep today's behaviour, no tab bar |
| Same page from elsewhere | When one of these pages is opened from somewhere else (e.g. Ended Journeys from the Journey tab), it shows the tab bar only if it is opened from My ZYRA |

## 4c. Whole-page swipe (V5)
| Item | Rule |
|---|---|
| Where | My ZYRA root, Seeker and Guardian |
| Swipe | A horizontal swipe **anywhere on the page** (title, Needs you card, chips, quick-access tiles, empty space) moves to the next / previous **Needs you** item, the same as swiping the card today; the page dots and "1 of 2" follow. **Not** the tab bar |
| Starting on a tile | A swipe that starts on a tile or button never opens it. A plain tap still opens it |
| Direction | Counts as a swipe only when it is clearly sideways (horizontal movement larger than vertical, about 50 pt or more); otherwise the page scrolls up / down as today |
| Ends | At the first / last item the swipe does nothing (no wrap) |

## 5. Rules

No member counts anywhere; no hearts. Larger Text: chips and tiles grow, the page scrolls rather than clipping. Tapping
anything gives the standard haptic (queue line 22). The gold My ZYRA tab icon rule (LOCK 5) is unchanged.

## 6. Guardian My ZYRA (V2, Founder 31 Oct "LOCK Focus")

Same layout as §1 (title, focus area with one item at a time, ‹ dots › + swipe, all-caught-up, chips, four tiles, tab bar),
plus the LOCK 8 greeting under the title: "Assalamu alaikum, Hassan. You support Adam and Yusuf." (12.5, secondary).

| "Needs you" item | Shows when | Icon | Title · detail | Buttons → |
|---|---|---|---|---|
| Family Review open | Review open for one of your Seekers' Journeys | shield | "Family Review for Adam and Sara" · "Faith & Values is complete. Continue, or pause the move to the next stage. 41 hours left — if you do nothing, the Journey continues." | gold **Continue** + outline **Pause** side by side (rules as LOCK 8) |
| Family Review paused | You or another Main Guardian paused | shield | "Family Review for Adam and Sara" · "You paused the move to Building a Life. Adam and Sara stay on Faith & Values. When your families have spoken, reopen the review for a fresh 48 hours." | gold **Reopen review** |
| Connect request received | Another family's Main Guardian asks (Guardian One) | chat | "Adam · Connect with Guardian" · "Noor's Main Guardian asks to connect about Adam." | "View request" → Connect with Guardian (Received) |
| Guardian invitation | A Seeker invited you | shield | "Yusuf invited you to be his Guardian" · "Look at the invitation and choose whether to accept." | "View invitation" → the invitation |
| Circle message | New message in a Seeker's Guardian Circle | chat | "New message in Adam's Guardian Circle" · "Sara's father has added to the families' conversation." | "Open Circle" → that Circle |
| Connect accepted | Your sent Connect request was accepted (Guardian One) | check | "Aisha's Main Guardian accepted" · "Your private chat about Adam and Aisha is open." | "Open chat" → Guardian chat |
| Family Review answer | Another family answered | shield | "Family Review answer recorded" · "Sara's family chose Continue for Adam and Sara." | "Open Journey" → that Journey |

Chips (always, one per Seeker you support): "Adam · {Journey stage or 'Paused by family'}" → that Journey; "Yusuf · no Journey" → Seekers tab.

Quick access tiles: **Journey requests** ("{n} new" gold; Main Guardian only, read only) · **Connect with Guardian** ("{n} new" gold / "{n} sent")
· **Introductions** ("{n} made") · **Notifications** ("{n} new" / "Nothing new"). **Guardian Basic:** Connect with Guardian and Introductions show as
locked tiles (small lock + "Guardian One") that open the Guardian One page; their "Needs you" items never appear.
