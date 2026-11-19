---
id: DOC-ZYRA-0308
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 2 V4 - Journey requests and Guardians (Seeker side) - V3 plus one card style for Ended Journeys and Introductions, Introductions Received/Past tabs, the Guardian's "Not taken forward", and what the other Seeker sees when a member deletes their account
links: [DR-ZYRA-284, DR-ZYRA-292, DR-ZYRA-162, DOC-ZYRA-0283, DOC-ZYRA-0290, DOC-ZYRA-0126]
owner: ZYRA chat
---

# JOURNEY REQUESTS AND GUARDIANS — SPEC — V4 (LOCKED 29 OCT 2026 · V2 31 OCT · V3 12 NOV · V4 12 NOV 2026)

**V4 (12 Nov):** §2.6 one card style for Ended Journeys and Introductions (+ Introductions Received · Past, Guardian sees "Not taken forward"); §2.7 a member deletes their account. Reference prototype V212 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`): My ZYRA → Ended Journeys / Introductions (load sample data with the admin Developer panel); side list **Member left ZYRA**. V3 is in `../ARCHIVE/REQUESTS_AND_GUARDIANS_SPEC_2026-11-12_V3.md`.

**V3 (12 Nov):** §2.2 Past — one card per person and the ask-again wait. Prototype V204 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`, My ZYRA → Journey requests → Past; tap the page title as the admin account → Developer → Past **Same person** to load 20 requests to Sara). V2 is in `../ARCHIVE/REQUESTS_AND_GUARDIANS_SPEC_2026-11-12_V2.md`.

Two sources of truth, in this order:
1. **Changed elements:** the pictures in `../MASTERS/` (430 × 932 logical, @3x = 1290 × 2796) and the words in §2 below.
2. **Everything else:** the 29 Oct baseline capture `PRODUCT/APPROVED/BASELINE/SCREENSHOTS/` (commit d08b2d1) stays exactly as it is.
The masters were drawn in the ZYRA chat prototype: match their **content, words, order and states**; take layout, fonts,
spacing, colours, back navigation and header from the app's existing components (the baseline), not from the prototype's drawing.

## 1. Screens in this LOCK

| Screen (planned-app id) | Baseline picture (stays) | Changes |
|---|---|---|
| Profiles tab (`_discover`), request button only | `seeker/browse_and_requests/profiles_tab__normal.png` | §2.1 |
| My ZYRA tab (`_dashboard`) | `seeker/profile_membership_settings/my_zyra_tab__normal.png` | none |
| Journey requests (`requests`) | `requests__received.png`, `requests__sent.png`, `*_empty.png` | §2.2 Past tab |
| Choose a place (`request_capacity`) | `request_capacity__full.png` | §2.3 |
| Accepting when places are full (Received and Sent cards, Choose a place, My ZYRA) | `requests__received.png`, `requests__sent.png`, `request_capacity__full.png` | §2.5 (V2) |
| Choose to begin, together (preparing) | `seeker/journey/journey__preparing.png`, `journey__self_ready.png`, `journey__both_ready.png` | §2.5 (V2) — words unchanged; reached from every accept |
| Introductions (`introductions`) | `introductions__empty.png` | §2.6 (V4) — Journey request card, tabs Received · Past |
| Ended Journeys (`ended`) | today's Ended Journeys page (line 93) | §2.6 (V4) — Journey request card, replaces the ••• menu |
| Guardian: Introductions you've made | today's page | §2.6 (V4) — muted **Not taken forward** on a declined one |
| Guardian tab, Add a Guardian, Guardian Circle | `seeker/guardians/*.png` | §2.4 one-time Main Guardian message |

## 2. Changes

### 2.1 Request button on a profile
| State | Label | Look |
|---|---|---|
| Not sent | **Request a Journey** | unchanged |
| Sent | **Request sent** (was "Journey invitation sent") | unchanged gold-outline sent style; tapping again still cancels; accessibility label "Request sent. Tap to cancel request" |
Masters: `profiles_tab__request_not_sent.png`, `profiles_tab__request_sent.png`.

### 2.2 Journey requests — third tab **Past** (DR-ZYRA-284 §1)
| Item | Rule |
|---|---|
| Tabs | **Received · Sent · Past**, three equal pills in one row, same pill style as today's two |
| What is in Past | Requests you sent that were declined, expired or cancelled, and requests you declined. They **stay in Past** — no expiry, no "listed until" date (Founder 29 Oct) |
| Card | Same card as Received/Sent (photo, **first name + surname**, line 2: **Sent <date>** or **Received <date>**); line 3 status in muted text: **Not taken up** (your sent request declined or expired — never "Declined", DR-284 §2), **Cancelled** (you cancelled it), **You declined** (you declined theirs). No expand, no actions |
| Order | Newest first, by the date the request moved to Past |
| **Same person more than once (V3)** | Past shows **one card per person and direction** (sent to them / received from them), never one card per request. A card with one request is unchanged. A card with 2 or more: line 2 **Last sent <date> · <n> requests** (or **Last received <date> · <n> requests**), line 3 the newest status in muted text, and the chevron of the Received/Sent cards. Tap opens it: a thin divider, then one muted row per request — **Sent <date>** left, status right — newest first, the newest **5** shown, then a gold text link **Show all <n>**. A grouped card sits in the list at the date of its newest request |
| **Ask-again line (V3)** | In an open card you sent, when the newest status is **Not taken up**: muted line **You can ask <first name> again from <date>.** The date is the newest request's "Not taken up" date plus the wait below |
| Empty state | Icon: history clock. **No past requests.** / **Requests that were declined, expired or cancelled stay here.** |
| Moving into Past | Decline (Received) → Past as "You declined"; Cancel request (Sent) → Past as "Cancelled"; in the preview, sample data may seed one "Not taken up" and one "You declined" |
| Asking again (V3) | Founder 12 Nov: no limit on how many times, the wait grows — **7 days** after each "Not taken up"; after **5** in a row to the same person, **14 days**; after **10** in a row, **30 days** (the most, it never grows past 30). Counted per pair, only consecutive "Not taken up" (declined or expired); the count starts again when a request between them is taken up. Server is the authority (Fable); the app only shows the date |
Masters: `requests__received.png`, `requests__received_expanded.png`, `requests__received_empty.png`, `requests__sent.png`,
`requests__sent_expanded.png`, `requests__sent_empty.png`, `requests__past.png`, `requests__past_empty.png`.
V3 grouped card: no master picture (charter rule 13); the prototype V204 state above is the reference, layout from the app's existing Past card.

### 2.3 Choose a place (all Journey places full, accepting a request)
| Item | Words |
|---|---|
| Title | **Your Journey places are full.** (unchanged) |
| Body | **Choose a Journey to end before beginning with <first name>, or keep your Journeys and leave the request for now.** |
| Primary button | **End & accept request** (was "End Journey & continue"); disabled until a Journey is chosen; then the existing confirmation "End Journey & accept request?" with its existing words and buttons |
| Secondary | **Keep my Journeys** (was "Cancel request"). Goes back; **the request stays in Received** (it is not cancelled) |
Masters: `request_capacity__full_nothing_chosen.png`, `request_capacity__full_journey_chosen.png`.

### 2.4 One-time message when a Guardian becomes Main (DR-ZYRA-292, wording approved 29 Oct)
| Item | Rule |
|---|---|
| When | Once, to the **Seeker**, at the moment a Guardian becomes their Main Guardian. **In this build:** when the Seeker makes a Guardian Main (the preview's existing local Make Main action), shown again each time Main changes. **Deferred:** the first accepted Guardian link (auto Main) — the preview has no link-accepted event; it is added when real linking is connected (OA-ZYRA-317). Do not invent a link flow |
| Title | **<Guardian first name> will be your Main Guardian** |
| Body | **<Name> is part of every Journey you begin. <Name> will also see your Journey requests — the ones you send and the ones you receive — and who each is with. <Name> sees that person's profile as anyone browsing would. Nothing more.** |
| Button | **Continue** (closes it) |
| Look | Centred, the Guardian's initial in the gold-ring avatar used on the Guardian tab |
Master: `guardian_main__first_main_message.png`.

### 2.5 Accepting a request when Journey places are full (V2, Founder 31 Oct)
**Rule (Founder, 31 Oct):** a Journey begins preparing only when **both** people have a free place. Whoever is full chooses
which of their Journeys ends. **Nobody loses a Journey for nothing:** if both are full, the ending chosen by the person who
accepts is **held** and happens only when the other person confirms. Sending a request from Profiles is **unchanged**
(requests never take a place). The other person is **never told** that someone is full (neutral wording below).

| Case (you accept a request from Hana) | What happens | Masters |
|---|---|---|
| **Both have space** | Accept request → **Choose to begin, together** at once (both places reserved) | `accept__both_space_preparing.png`, `preparing__both_ready.png` |
| **You're full** | Accept request → Choose a place (§2.3 words) → pick → **End & accept request** → that Journey ends → Choose to begin, together | `accept__you_full_choose.png` |
| **Hana's full** | Accept request → card shows **You accepted · waiting for Hana** + muted line **Waiting for Hana to confirm. Nothing changes for you until then.** Hana gets Choose a place on her side (same page, sent wording below). Hana confirms → Choose to begin, together. Hana does not go ahead → the request moves to **Past · Not taken up**; nothing changes for you | `accept__other_full_waiting.png` |
| **Both full** | Accept request → Choose a place with body **Choose which Journey would end to begin with <first name>. Nothing ends until <first name> confirms too.** and primary **Accept request** (disabled until a Journey is chosen) → card **You accepted · waiting for Hana** + **Waiting for Hana to confirm. Your Journey with <chosen first name> ends only when she confirms.** Hana confirms → your chosen Journey ends and both go to Choose to begin, together. Hana does not go ahead → your chosen Journey carries on; request → Past · Not taken up | `accept__both_full_nothing_chosen.png`, `accept__both_full_choose.png`, `accept__both_full_waiting.png` |

**Your sent request is accepted while you are full** (the mirror of "Hana's full" and "Both full"):
| Item | Words / behaviour |
|---|---|
| Sent card status | **Accepted · choose a place** (gold), actions **View profile**, **Choose a place** (gold text), **Let it go** |
| My ZYRA · Needs you | First item: icon check, **<first name> accepted your request**, **Your Journey places are full. Choose a Journey to end, or let the request go.**, button **Choose a place** |
| Choose a place (sent) | Title **<first name> accepted your request.** Body **Your Journey places are full. Choose a Journey to end to begin with <first name>, or keep your Journeys and let the request go.** Primary **End & begin with <first name>** (disabled until chosen) → that Journey ends → Choose to begin, together. Secondary **Keep my Journeys** = let it go |
| Let it go / Keep my Journeys | The request moves to **Past** with status **You let it go**; the other person sees **Not taken up** (DR-284 §2 unchanged) |
Masters: `sent__waiting_demo_accept.png`, `sent__accepted_you_full.png`, `my_zyra__accepted_choose_place.png`, `sent__accepted_choose_place.png`, `requests__past_let_go.png`.

**Choose to begin, together** (today's preparing page, words unchanged): header **Journey with <first name>**; card title
**Choose to begin, together.**; body **You both accepted the invitation. Each person still chooses to begin. Until then, no
conversation or private compatibility result opens.**; **You: not yet confirmed / ready** (gold); **<first name>: waiting /
ready** (muted); **I'm ready to begin** (→ disabled **You are ready**); **Begin your Journey** enabled only when both are ready
→ the Journey starts at Stage 1 Salam Exchange in the place that was freed; **End Journey** below the card frees the place.

**Preview only (Founder preview):** with no second person, the cards carry demo buttons exactly as today's "Demo: Sara confirms
readiness": **Demo: <first name> accepts** (Sent card), **Demo: <first name> confirms** and **Demo: <first name> doesn't go
ahead** (waiting card), **Demo: <first name> confirms readiness** (preparing). They never appear outside the preview.

### 2.6 One card style for every list (V4, Founder 12 Nov: "my journey request card and ended journey request cards look different id want them to be same copying journey request style" · "that shoudl apply to all inc introductions")
Ended Journeys and Introductions use **the Journey request card** exactly (Received/Sent card: photo, **first name + surname**, line 2 **<age> · <city>**, line 3 status in gold, chevron; tap opens the buttons, one card open at a time; same button style and order as Received).

| List | Line 3 | Buttons when open (top to bottom) |
|---|---|---|
| Ended Journeys | **Journey ended · Timeline kept** | gold **View Timeline** → read-only page **Journey with <first name>** (QUESTIONS 164, Founder 18 Nov "Inside View Timeline"): person card (photo, name, <age> · <city>, gold "Journey ended · Timeline kept"), one card with rows **Timeline** · **Journey Bio** · **Guardians** (each opens today's archived read-only page), line "Read only · nothing here can be changed"; master `ended_journeys__view_timeline_read_only.png` · **Request a new Journey** · red **Remove from my Journeys** → LOCK 28 confirm (TIME_RULES line 93 step 5b wording). Replaces the ••• menu |
| Introductions → Received | **Put forward by <Guardian> · <relation>** | gold **View profile** · **Request a Journey** (sends the request; it carries on in Journey requests → Sent) · **Decline** |
| Introductions → Past | muted: **Journey requested** / **You declined** | none (Past card: line 2 **Introduced <date> · from <Guardian>**) |

Introductions gets the request tabs: **Received · Past** (two equal pills). Past keeps every introduction you requested or declined, newest first, no expiry (like Journey requests Past). Empty Past: history icon, **No past introductions.** / **Introductions you declined or took forward stay here.** Toasts: "Request sent to <name>. It’s in Journey requests → Sent." · "Declined. <Guardian> sees “Not taken forward”."
**Guardian side:** in **Introductions you’ve made**, a declined introduction's status line reads muted **Not taken forward** (no reason given); others keep "Suggested to <Seeker>".
Masters (V4, added 16 Nov for QUESTIONS 161; rendered at 430 × 932 @3x from the published prototype, same content as V212): `ended_journeys__list.png`, `ended_journeys__open.png`, `ended_journeys__empty.png`, `introductions__received.png`, `introductions__received_open.png`, `introductions__received_empty.png`, `introductions__past.png` (one **You declined**, one **Journey requested**), `introductions__past_empty.png`, `guardian_introductions_made__not_taken_forward.png`. **Sample fixture (QUESTIONS 163, 17 Nov):** Seeker Adam; Guardians Hassan (Father, Main), Khadija (Mother), Yusuf (Brother). Received: Noor Patel from **Hassan**, Hana Saeed from Khadija, Amira Rahman from Yusuf. Past: **Noor (from Hassan) · You declined**, Hana (from Khadija) · Journey requested. The Guardian master is **Hassan's** preview (his Network: Aisha, Noor): Noor Patel · muted **Not taken forward**, Aisha Khan · Suggested to Adam (made after the Received picture). A decline shows as "Not taken forward" only to the Guardian who made that introduction (match on candidate **and** introducing Guardian, never candidate alone). The Received empty state keeps today's words (**No introductions yet** / **People your Guardians put forward will appear here.**). The Ended Journeys empty state keeps today's words. **Loading and error:** no new state — these lists use the app's existing list loading and error components unchanged (baseline). Take layout, fonts and the tab bar from the app's Journey request card and pills, not from the drawing (sources of truth above).

### 2.7 A member deletes their account (V4, Founder 12 Nov 17:19–17:25)
Every Journey with that person — active or ended — **disappears for the other Seeker at once**, with its Timeline and Guardian Circle; Journey requests, Past items and introductions with that person go too, and the Journey place is freed. One My ZYRA Needs-you item, **no name kept**: **One of your Journeys has ended** / **This profile is no longer active. Your place is free for a new Journey.** / gold **Open Journey**. The words "This member has left ZYRA" and "Former member" are not used anywhere (Founder also rejected "Account unavailable"). The sealed safety copy stays on the server only (12 months).

## 3. Must not change
The Founder preview's other pages; the Guardian tab's layout and controls; the Guardian Circle; Add a Guardian; any server,
database or migration; the old member app (`HomeShell` and its files); surnames stay on cards (DR-ZYRA-162, Founder 29 Oct).

## 4. Known gap (Founder's choice B, 29 Oct)
The other person is **not** told at the request that the Seeker's Main Guardian can see it. The explanation moves to a
Profile section "What Guardians can do", not yet designed. Do **not** add any "Main Guardian can see this request" line
anywhere in this build.

## 5. Not decided in this LOCK (V2)
How long an acceptance waits for the other person to confirm (none set; the existing 7-day request expiry, DR-ZYRA-277, is
not extended or shortened here). Server rules for holding an ending are server work, logged by Fable, not built here.

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed by the Founder (LOCK_RECORD.md) |
| 2026-10-29 | V1 | Founder (18:42, before the build): "no i think we remomve listed date and ensure it stays there" — Past items stay; no "listed until" date; masters `requests__past.png` and `requests__past_empty.png` redrawn. (A Founder change before any build, recorded here rather than as a new version because nothing was built from V1 yet) |
| 2026-10-29 | V1 | Corrections after Codex's preflight (queue line 4 FAILED): §2.2 order defined by move date and `MASTERS/requests__past.png` redrawn newest first; §2.4 first-link trigger deferred to OA-ZYRA-317 (no link event in the preview). No design change |
| 2026-10-31 | V2 | Founder LOCK (31 Oct, clickable "LOCK it (Recommended)"): §2.5 accepting when places are full — four cases, held ending in Both full ("Yes, hold the ending"), neutral waiting wording ("Neutral wording"), sent-side choose a place, Choose to begin page reached from every accept. 12 new masters. V1 archived |
| 2026-11-12 | V3 | Founder LOCK (clickables 12 Nov ~17:00): Past repeat requests "A · One card per person"; repeat limit typed answer "no limit cos they other person might be busy but maybe after 5 attemmots it can go up 14 days then another 5 30 days with 30 days being max limit" → §2.2 grouped card, ask-again line and the 7 / 14 / 30-day wait (replaces V2's 30-day line, already superseded by QUESTIONS 118). V2 archived |
| 2026-11-12 | V4 | Founder LOCK (17:14–17:25): §2.6 one card style — clickable "LOCK it (Recommended)"; Guardian "\"Not taken forward\" (Recommended)"; Introductions "Into a Past tab"; §2.7 account deletion — "Ends and goes at once (Recommended)", "D · Profile no longer active". V3 archived |
| 2026-11-16 | V4 | Correction after Codex's preflight (queue line 98 FAILED, QUESTIONS 161): §2.6 masters rendered and listed (9 files); §1 rows for Introductions, Ended Journeys and the Guardian's list now name §2.6; loading/error = existing components. No design change (content as LOCKed, prototype V212 → V230) |
| 2026-11-17 | V4 | Correction after Codex's preflight (queue line 98 FAILED, QUESTIONS 163): one owner for the declined sample introduction - `introductions__past.png` and `guardian_introductions_made__not_taken_forward.png` re-rendered so the declined one is Noor from Hassan (Hassan's Network), Hana from Khadija is Journey requested; sample fixture and the decline-match rule written in §2.6. Old pictures in `../_to_delete/2026-11-17_Q163_superseded_masters/`. No design change (prototype V231: Guardian list matches decline on candidate and Guardian) |
| 2026-11-18 | V4 | QUESTIONS 164 (line 98 preflight): archived Journey Bio and Guardians stay reachable — Founder clickable "Inside View Timeline (Recommended)": View Timeline opens the read-only Journey page with Timeline · Journey Bio · Guardians rows; card actions unchanged. Master `ended_journeys__view_timeline_read_only.png` (prototype V275). No other change |
