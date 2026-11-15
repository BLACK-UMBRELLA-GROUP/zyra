---
id: DOC-ZYRA-0308
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 2 V2 - Journey requests and Guardians (Seeker side) in the planned app - V1 plus accepting a request when Journey places are full (four cases, held ending, neutral waiting wording) and the Choose to begin page
links: [DR-ZYRA-284, DR-ZYRA-292, DR-ZYRA-162, DOC-ZYRA-0283, DOC-ZYRA-0290, DOC-ZYRA-0126]
owner: ZYRA chat
---

# JOURNEY REQUESTS AND GUARDIANS — SPEC — V2 (LOCKED 29 OCT 2026 · V2 LOCKED 31 OCT 2026)

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
| Introductions (`introductions`) | `introductions__empty.png` | none |
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
| Empty state | Icon: history clock. **No past requests.** / **Requests that were declined, expired or cancelled stay here.** |
| Moving into Past | Decline (Received) → Past as "You declined"; Cancel request (Sent) → Past as "Cancelled"; in the preview, sample data may seed one "Not taken up" and one "You declined" |
| Asking again | Unchanged rule: the sender can ask the same person again 30 days after "Not taken up" (DR-284 §3) — no new UI in this LOCK |
Masters: `requests__received.png`, `requests__received_expanded.png`, `requests__received_empty.png`, `requests__sent.png`,
`requests__sent_expanded.png`, `requests__sent_empty.png`, `requests__past.png`, `requests__past_empty.png`.

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
