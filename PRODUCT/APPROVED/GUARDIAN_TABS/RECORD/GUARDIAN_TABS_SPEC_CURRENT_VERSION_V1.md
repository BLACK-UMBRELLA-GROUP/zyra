---
id: DOC-ZYRA-0326
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 8 - Guardian tabs and pages (Guardian One)
links: [DR-ZYRA-280, DR-ZYRA-292, DR-ZYRA-233, DOC-ZYRA-0278, DOC-ZYRA-0283]
owner: ZYRA chat
---

# GUARDIAN TABS — SPEC — V1 (LOCKED 29 OCT 2026)

Masters (430 × 932 @3x) in `../MASTERS/`, g01–g14. Same look as the Seeker app (titles, tiles, rows, pills, cards, the LOCK 6
tab bar, the LOCK 5 gold-icon rule). Sample Guardian: Hassan, Main Guardian of Adam, Additional Guardian of Yusuf.

## Tabs (left to right) — the app opens on My ZYRA

| # | Tab | Icon | Page |
|---|---|---|---|
| 1 | Network | group | Other families' Seekers, one details card at a time (g06) |
| 2 | Journeys | couple | The chosen Seeker's current Journey and Ended Journeys (g09) |
| 3 | **My ZYRA** (start) | grid | What needs you, across all your Seekers (g01, g14) |
| 4 | Seekers | shield | The Seekers you support (g10) |
| 5 | Profile | person | Your own account (g13) |

"Guardian Dashboard", Guardian Insights and the separate Updates card are removed.

## Pages

| Page | Content (see master) |
|---|---|
| **My ZYRA** (g01) | Greeting "Assalamu alaikum, Hassan. You support Adam and Yusuf." **Needs you** (gold eyebrow): the 48-hour Family Review card — title "Family Review for Adam and Sara", one line of what finished, hours left, "if you do nothing, the Journey continues"; **Continue** (gold outline) / **Pause**; then a tile per other item (e.g. "Adam · Connect with Guardian — Noor's Main Guardian asks to connect about Adam"). Several items stack, newest first. Rule, then **Quick access** tiles: Journey requests (counts per Seeker), Connect with Guardian (sent · received), Introductions you've made |
| My ZYRA — nothing due (g14) | "All caught up" (muted eyebrow) / "Nothing needs you right now." then Quick access |
| **Journey requests** (g02, g03) | Back; title; top-right switcher **"All Seekers ▾"** cycling All → for Adam → for Yusuf; Received / Sent segmented tabs; one card per request (photo, name, age · city, gold status "Journey request to Adam" / "Adam is waiting for a response"); line "You see these as their Main Guardian. Each Seeker decides on their own requests." Read only (DR-ZYRA-292). Only Seekers you are **Main** Guardian for appear |
| **Connect with Guardian** list (g04) | Back; Sent / Received tabs; card "Aisha's Main Guardian · For Aisha, 29 · London · Waiting for a response"; empty states as in the prototype |
| **Introductions you've made** (g05) | Back; list of people you put forward ("Suggested to Adam"); empty: "No introductions yet. Find someone in Network and choose Introduce to Adam." |
| **Network** (g06) | Title; top-right **"for Adam ▾"** (cycles your Seekers); details card like Profiles (round initial photo, "A., 29", city, Main Guardian "Father · ✓ Verified", Nationality, Ethnicity); row: ‹ · **Introduce to Adam** · **Connect with Guardian** · ›. After use the buttons read "Introduced" / "Request sent" |
| Introduce (g07) | "Put Aisha forward to Adam?" — "Adam sees Aisha in his Introductions, marked "Suggested by Hassan". Adam decides whether to send a Journey request. Aisha and her family are not told." **Introduce** / Not now (DR-ZYRA-280 §9) |
| Connect with Guardian (g08) | "Aisha's Main Guardian" — "Send a request to the Main Guardian supporting this Seeker. They choose whether to respond." **Send request** / Not yet |
| **Journeys** (g09) | Title; "for Adam ▾"; Journey card (photo, "Adam & Sara", name · age · city, gold "Stage 1 of 8 · Salam Exchange", "You: Main Guardian · View and Chat", **Open Journey**); tile Ended Journeys "Only what Adam shares with you" (DR-ZYRA-233) |
| **Seekers** (g10) | Title; + (invite your Seeker); a card per Seeker (initial, name, your role, gold current Journey); "You can support up to 10 Seekers." |
| Seeker page (g11, g12) | Back; name; Active · Linked date; YOUR ACCESS (Role, Journeys, Journey requests, Past summaries); JOURNEY (Current); **Open Journey** (Main only); **Enter <name>'s Guardian Circle**. Additional Guardian: Journeys "As Yusuf allows, Journey by Journey", Journey requests "Main Guardian only" |
| **Profile** (g13) | Avatar, name, ⇄ Switch; MEMBERSHIP (Guardian One · Manage membership; Your subscriptions); ABOUT ME (Relationship, Linked Seekers); SAFETY & SHARING (Safety & advice; Invite someone to ZYRA); PERSONALISATION (Appearance & haptics; Settings; Sign out) |

## Rules kept

| Rule | Source |
|---|---|
| A Guardian never sees a Seeker's past Journey summaries unless that Seeker switches sharing on | DR-ZYRA-233, LOCK 3 §3b |
| Journey requests are shown only to the Main Guardian, read only | DR-ZYRA-292, LOCK 2 |
| Pages opened from these tabs that already exist (the Journey page, Guardian Circle, invite) keep their current design | — |
