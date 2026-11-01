---
id: DOC-ZYRA-0308
type: SPEC
status: ARCHIVED (2026-10-31, replaced by REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V2.md)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 2 - Journey requests and Guardians (Seeker side) in the planned app - what stays exactly as the 29 Oct baseline, what changes, with words, states and numbers
links: [DR-ZYRA-284, DR-ZYRA-292, DR-ZYRA-162, DOC-ZYRA-0283, DOC-ZYRA-0290, DOC-ZYRA-0126]
owner: ZYRA chat
---

# JOURNEY REQUESTS AND GUARDIANS — SPEC — V1 (LOCKED 29 OCT 2026)

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

## 3. Must not change
The Founder preview's other pages; the Guardian tab's layout and controls; the Guardian Circle; Add a Guardian; any server,
database or migration; the old member app (`HomeShell` and its files); surnames stay on cards (DR-ZYRA-162, Founder 29 Oct).

## 4. Known gap (Founder's choice B, 29 Oct)
The other person is **not** told at the request that the Seeker's Main Guardian can see it. The explanation moves to a
Profile section "What Guardians can do", not yet designed. Do **not** add any "Main Guardian can see this request" line
anywhere in this build.

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed by the Founder (LOCK_RECORD.md) |
| 2026-10-29 | V1 | Founder (18:42, before the build): "no i think we remomve listed date and ensure it stays there" — Past items stay; no "listed until" date; masters `requests__past.png` and `requests__past_empty.png` redrawn. (A Founder change before any build, recorded here rather than as a new version because nothing was built from V1 yet) |
| 2026-10-29 | V1 | Corrections after Codex's preflight (queue line 4 FAILED): §2.2 order defined by move date and `MASTERS/requests__past.png` redrawn newest first; §2.4 first-link trigger deferred to OA-ZYRA-317 (no link event in the preview). No design change |
