---
id: DOC-ZYRA-0393
type: SPEC
status: ARCHIVED (2026-10-31)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 8 - Guardian tabs and pages (Guardian One), V2 - Family Review pause, Connect received + private chat, Network rule
links: [DR-ZYRA-280, DR-ZYRA-292, DR-ZYRA-233, DR-ZYRA-110, DR-ZYRA-277, DR-ZYRA-306, DOC-ZYRA-0278, DOC-ZYRA-0283]
owner: ZYRA chat
---

# GUARDIAN TABS — SPEC — V2 (LOCKED 30 OCT 2026)

V1 (DOC-ZYRA-0326) is in `../ARCHIVE/GUARDIAN_TABS_SPEC_2026-10-30_V1.md`, its 14 masters in `../ARCHIVE/MASTERS_V1/`.
**What changed** (queue line 20 stopped on three gaps):
1. Family Review: when it opens in the preview, what **Pause** does, and the paused state with **Reopen review** (g15) — from DR-ZYRA-110.
2. g01 said "0 sent · 0 received" while showing a received Connect request → now "0 sent · 1 received".
3. Connect with Guardian **Received** (g17), accepted (g18), the **private chat** (g19) and both empty states (g16, g20). Founder 30 Oct:
   Accept opens a **private chat** between the two Guardians.
4. Stage text made consistent with the Family Review: Journeys / Seekers / Seeker page say "Stage 4 of 8 · Family Review" (was "Salam Exchange").
5. New Network rule (Founder 30 Oct): a Seeker whose only Guardian is a **Guardian Basic** is **not shown in Network**.

Masters (430 × 932 @3x) in `../MASTERS/`, **g01–g20** (all re-rendered from prototype V59; g02–g08, g10, g12, g13 look the same as V1).
Same look as the Seeker app (titles, tiles, rows, pills, cards, the LOCK 6 tab bar, the LOCK 5 gold-icon rule).
Sample Guardian: Hassan, Main Guardian of Adam, Additional Guardian of Yusuf. Adam is in a Journey with Sara.

## Tabs (left to right) — the app opens on My ZYRA

| # | Tab | Icon | Page |
|---|---|---|---|
| 1 | Network | group | Other families' Seekers, one details card at a time (g06) |
| 2 | Journeys | couple | The chosen Seeker's current Journey and Ended Journeys (g09) |
| 3 | **My ZYRA** (start) | grid | What needs you, across all your Seekers (g01, g14, g15) |
| 4 | Seekers | shield | The Seekers you support (g10) |
| 5 | Profile | person | Your own account (g13) |

"Guardian Dashboard", Guardian Insights and the separate Updates card are removed.

## Pages

| Page | Content (see master) |
|---|---|
| **My ZYRA** (g01) | Greeting "Assalamu alaikum, Hassan. You support Adam and Yusuf." **Needs you** (gold eyebrow): the Family Review card — title "Family Review for Adam and Sara", "Faith & Values is complete. Continue, or pause the move to the next stage. 41 hours left — if you do nothing, the Journey continues."; **Continue** (gold outline) / **Pause**; then a tile per other item ("Adam · Connect with Guardian — Noor's Main Guardian asks to connect about Adam", opens Connect with Guardian on **Received**). Several items stack, newest first. Rule, then **Quick access** tiles: Journey requests ("Adam 1 received · 1 sent · Yusuf none"), Connect with Guardian ("0 sent · 1 received" — counts this Guardian's own Connect requests, never members), Introductions you've made ("0 for Adam") |
| **My ZYRA — review paused** (g15, new) | Same card after **Pause**: "You paused the move to Building a Life. Adam and Sara stay on Faith & Values. When your families have spoken, reopen the review for a fresh 48 hours." One full-width gold-outline **Reopen review**. The Connect tile stays under it |
| My ZYRA — nothing due (g14) | "All caught up" (muted eyebrow) / "Nothing needs you right now." then Quick access. Shown when no review is open or paused and no Connect request waits |
| **Journey requests** (g02, g03) | Back; title; top-right switcher **"All Seekers ▾"** cycling All → for Adam → for Yusuf; Received / Sent segmented tabs; one card per request (photo, name, age · city, gold status "Journey request to Adam" / "Adam is waiting for a response"); line "You see these as their Main Guardian. Each Seeker decides on their own requests." Read only (DR-ZYRA-292). Only Seekers you are **Main** Guardian for appear |
| **Connect with Guardian** list | Back; Sent / Received tabs. **Sent** (g04): card "Aisha's Main Guardian · For Aisha, 29 · London · Waiting for a response". **Sent empty** (g16): "No requests sent yet." / "Find a family in Network and choose Connect with Guardian." **Received** (g17): card with photo, "Noor's Main Guardian", "For Noor, 25 · Nottingham", gold "Asks to connect about Adam", **Accept** (gold outline) / **Not now** side by side; under the card "Accepting opens a private chat between you and Noor's Main Guardian about Adam and Noor. Only the two of you see it." **Accepted** (g18): gold "Connected · private chat" and a full-width **Open chat**. **Received empty** (g20, after Not now): "No requests received yet." / "When another family's Guardian asks to speak about Adam, it appears here." Not now tells the sender "Not taken up" (same wording as Journey requests) |
| **Guardian chat** (g19, new) | Back; title "Noor's Main Guardian", subtitle "About Adam and Noor"; empty chat with a small gold lock and "A private chat between the two Main Guardians. Only you two see it. Keep it respectful — you can report anything here."; composer "Message" + gold send button. Message bubbles, report and block reuse the existing chat components. In the preview: sending shows a toast "Messages send in the app." |
| **Introductions you've made** (g05) | Back; list of people you put forward ("Suggested to Adam"); empty: "No introductions yet. Find someone in Network and choose Introduce to Adam." |
| **Network** (g06) | Title; top-right **"for Adam ▾"** (cycles your Seekers); details card like Profiles (round initial photo, "A., 29", city, Main Guardian "Father · ✓ Verified", Nationality, Ethnicity); row: ‹ · **Introduce to Adam** · **Connect with Guardian** · ›. After use the buttons read "Introduced" / "Request sent". **Only Seekers whose Main Guardian is Guardian One appear** — a Seeker with only a Guardian Basic is never shown here (Founder 30 Oct) |
| Introduce (g07) | "Put Aisha forward to Adam?" — "Adam sees Aisha in his Introductions, marked "Suggested by Hassan". Adam decides whether to send a Journey request. Aisha and her family are not told." **Introduce** / Not now (DR-ZYRA-280 §9) |
| Connect with Guardian (g08) | "Aisha's Main Guardian" — "Send a request to the Main Guardian supporting this Seeker. They choose whether to respond." **Send request** / Not yet |
| **Journeys** (g09) | Title; "for Adam ▾"; Journey card (photo, "Adam & Sara", name · age · city, gold stage line, "You: Main Guardian · View and Chat", **Open Journey**); tile Ended Journeys "Only what Adam shares with you" (DR-ZYRA-233). Stage line: review open "Stage 4 of 8 · Family Review"; paused "Stage 4 of 8 · Paused by family"; after Continue "Stage 5 of 8 · Building a Life" |
| **Seekers** (g10) | Title; + (invite your Seeker); a card per Seeker (initial, name, your role, gold "Journey with Sara · Family Review" / "No current Journey"); "You can support up to 10 Seekers." |
| Seeker page (g11, g12) | Back; name; Active · Linked date; YOUR ACCESS (Role, Journeys, Journey requests, Past summaries); JOURNEY (Current "With Sara · Family Review"); **Open Journey** (Main only); **Enter <name>'s Guardian Circle**. Additional Guardian: Journeys "As Yusuf allows, Journey by Journey", Journey requests "Main Guardian only" |
| **Profile** (g13) | Avatar, name, ⇄ Switch; MEMBERSHIP (Guardian One · Manage membership; Your subscriptions); ABOUT ME (Relationship, Linked Seekers); SAFETY & SHARING (Safety & advice; Invite someone to ZYRA); PERSONALISATION (Appearance & haptics; Settings; Sign out) |

## Family Review (DR-ZYRA-110, DR-ZYRA-277) — how it behaves

| Item | Rule |
|---|---|
| When it opens | After both Seekers finish a question stage (Faith & Values, Building a Life, Navigating Life) or Family Compatibility. In the **Founder preview** the sample opens with Adam and Sara's review already open, 41 hours left (a seeded sample state; no timer runs) |
| Who decides | Each Seeker's **Main** Guardian only. Additional Guardians and Seekers see status, no buttons |
| Continue | If all expected Main Guardians choose Continue it resolves at once; otherwise silence for 48 hours = continue. Preview: Continue → stage moves to Building a Life, toast "The Journey continues to Building a Life.", My ZYRA shows g14 when nothing else waits |
| Pause | Any Main Guardian's Pause stops the move at once (no timer). Adam and Sara are told their families are taking more time. Preview: Pause → g15, toast "Paused. Adam and Sara are told their families are taking more time." |
| Reopen review | Any active Main Guardian on the Journey can reopen a paused review: earlier answers are cleared and a fresh 48 hours starts. Preview: Reopen → g01 with "48 hours left", toast "Review reopened. 48 hours from now." |
| Server | Built (`open_family_review`, `wali_review_decision`, `resolve_family_review_if_due`, `reopen_family_review`). The preview stays local; connecting it is server work (OA-ZYRA-317) |

## Connect with Guardian — rules

| Rule | Detail |
|---|---|
| Who can send | Guardian One only (Guardian Basic sees the locked card — not part of this LOCK) |
| Who receives | The Main Guardian of the Seeker shown in Network. Because Guardian-Basic-only Seekers are not in Network, every receiver is Guardian One, so both sides can chat |
| Accept | Opens a **private chat between the two Guardians** about the two Seekers. Neither Seeker sees it. Report and block work as in other chats |
| Not now | The sender sees "Not taken up"; the card leaves Received |
| Server | Missing today: DOC-ZYRA-0329 `guardian_contact_requests` (§6 Q6 "After the core"); the chat and the Network filter are added to that later brief. The preview is local only |

## Rules kept

| Rule | Source |
|---|---|
| A Guardian never sees a Seeker's past Journey summaries unless that Seeker switches sharing on | DR-ZYRA-233, LOCK 3 §3b |
| Journey requests are shown only to the Main Guardian, read only | DR-ZYRA-292, LOCK 2 |
| Pages opened from these tabs that already exist (the Journey page, Guardian Circle, invite) keep their current design | — |
| No member counts anywhere | Founder 30 Oct |
