---
id: DOC-ZYRA-0329
type: DESIGN
status: CURRENT
feature: SERVER
purpose: Server design that connects the planned app to real data - Introductions, Preparing, Basic place, Journey Bio, Pause/Save removal, Request restart, plus the OA-315 server rules - for the Founder's yes before Codex builds area by area
links: [OA-ZYRA-317, OA-ZYRA-315, OA-ZYRA-319, OA-ZYRA-324, DOC-ZYRA-0280, DOC-ZYRA-0283, DOC-ZYRA-0290, DOC-ZYRA-0291, DOC-ZYRA-0294]
owner: Fable
---

# ZYRA — SERVER DESIGN — 30 OCT 2026 — V1 (DRAFT)

Written by Fable, 30 Oct 2026, on the Founder's "yes both" (29 Oct). Nothing here is built. This is one document for the
Founder's **yes**; Codex builds from it afterwards, one area at a time, in the order the Founder chose.

## 1. What this is, and what "yes" means

| Question | Answer |
|---|---|
| What is it | The plan for the **server** side (the Supabase database: tables, rules and functions) so the planned app - the Founder preview, DR-ZYRA-274 - can run on real members instead of sample people |
| Why now | The preview's rules are the approved blueprint (26 Oct). The database today starts Journeys from a mutual like, has no Preparing step, no Journey Bio, gives Basic no place, still carries Pause and Save, and has Request restart switched off (OA-ZYRA-317). Several rules live only in the app, which a tampered phone could skip (OA-ZYRA-315) |
| What "yes" means | The Founder agrees the design direction and the build order. **Nothing is built until he says yes.** Then the ZYRA chat queues **one brief per area** in `PRODUCT/APPROVED/SERVER/` with a WAITING line in `PRODUCT/APPROVED/BUILD_QUEUE.md`; Codex builds each line on GO, in order, with tests |
| What "yes" does not mean | No change to prices, plans or any blueprint rule. Where this design needs a decision, it is a question in §6; everything else follows an existing decision (cited by DR number) |
| What stays out | App Store purchases (OA-317 item 7), identity-check provider wiring (item 8), phone push and crash reporting (items 9-10). They need their own designs; this one leaves hooks for them |

**How to read §3.** Each area lists: what to add or change in the data; the server rules in plain words, with the technical
name in brackets (RPC = a function the app calls; trigger = an automatic rule that fires on a write; RLS = row-level
security, who may read or write a row directly); what the app calls; the states a thing can be in; who may see what; and which
blueprint rule each line enforces.

## 2. Today vs planned

What the live database does today comes from the 26 Oct read-only check (DOC-ZYRA-0294). Where that check did not look, the
table says **not verified - check in the live read-only pass** (the pass is re-run before any production change).

| # | Gap | Live database today (DOC-ZYRA-0294) | Blueprint requires | The gap |
|---|---|---|---|---|
| 1 | Introductions - a request to **begin** a Journey (OA-317 item 1) | Journeys start from a mutual like (`likes` table, trigger `create_match_on_mutual_like`) plus one tap. `journey_requests` exists but serves only Request restart (`request_new_journey`) | "Request a Journey", accept/decline/cancel, Received/Sent/Past tabs, Basic 3 / One 25 pending, 7-day expiry, "Not taken up", 30-day wait after a decline, Hide stops requests, Main Guardian sees who the requests are with (DOC-0283 §3; DR-277, 280, 283, 284, 292, 300) | Whole request flow missing; like-based matching must stop |
| 2 | Preparing (item 2) | Nothing. One person's tap starts the Journey | Accepting reserves a place for **both**; each taps "I'm ready to begin" within 48 h; paid Additional Guardians agreed before beginning; starts at Salam only when both ready (DOC-0283 §4; DR-277, 280) | New state between accepted and active; places counted from it |
| 3 | Basic = 1 place (item 3) | The 24 Sep "paid-only" file that gave Basic 0 places was **never applied** (DOC-0294 §1). What production gives Basic today: **not verified - check in the live read-only pass** | Basic **1** place after the £4.99 joining fee; One **3** (DR-275, 282; DOC-0291 §6) | Place count must come from the plan, from one place |
| 4 | Journey Bio (item 4) | No such stage | Stage 2b after Compatibility: both reveal their Bio, then both continue (DOC-0283 §5; DR-280) | New stage, new reveal records |
| 5 | Pause and Save removed (item 5) | Repository: full Pause flow (13 pause-lock triggers, pause columns on `matches`, `suspend/resume/nudge` stubs) and a `saves` table. The 25 Aug "shared pause" file is not live; which older pause parts are live: **not verified** | No Pause, no Save (DR-274; DOC-0283 §1, §7; DOC-0292 §5). Pause My Profile (a visibility setting) **is** kept (DR-290) | Remove the Journey Pause flow and the Save action; keep Pause My Profile |
| 6 | Request restart (item 6) | Built (`request_new_journey`: 24-hour wait, 30-day expiry) but switched off | New request to the same person after a 24-hour wait, 7-day expiry; Basic no, One from the 5 most recent ended Journeys; old Journey never reopened (DOC-0283 §7; DR-277, 282) | Change the expiry and plan rule, switch on, route through the one request flow |
| 7 | Identity check (OA-315 a) | `zyra_my_identity_verification_allows_active_journey` exists but is **never called** - only the app checks | Identity check required before any Journey (DOC-0283 §5) | Server must refuse unverified requests, accepts and begins |
| 8 | Both answered (OA-315 b) | `open_family_review` checks the stage, not that both Seekers answered every question | Stages 4-7 move on only when both answered, then a 48-hour Family Review (DOC-0283 §5; DR-277) | Server must count answers |
| 9 | Message send rule (OA-319) | Live rule is the **safe** 9 Aug one (blocks, active conversation, active Journey, Seekers only). The weak 24 Sep file waits unapplied; replaying all files in order would fail at 5 Oct (a view column cannot be dropped that way). Guardian send path checks the Chat switch but not the Guardian's own paid role | Free chat only at stage 8, never into blocked or ended Journeys; Guardians write only with Chat allowed **and** a paid role (DOC-0293 §1, §2, §4; DR-131, 268, 289) | Rewrite the 24 Sep rule before it is ever applied; fix the replay; add the paid-role check |
| 10 | Guardian read boundary (OA-324, f02) | The 5 Oct f02 file is **not live**: production has no boundary stopping ended Journeys giving a Guardian detail, and no link-date check on the Circle's past topics | A Guardian sees a past Journey summary only with the Seeker's consent and only from the current link period; anonymous facts only (DR-233; DOC-0290 §5) | Apply f02 and make the Circle's archive resolver respect consent and link date |

Also in scope because the decisions name them for this design: Guardian limits by plan (DR-281, 282), server limits for
browsing, requests and revisits (DR-282, 283), Hide and Pause My Profile functions (DOC-0292 §7), monthly Unlocks (DR-288),
Family places cap 10 in total (DR-291), the first-link event for the one-time Main Guardian message (DR-294; OA-317 update 30 Oct),
and Past requests kept with no end date (DR-300).

## 3. Design per area (Founder's build order)

One principle across every area: **the server decides, the app only shows.** Every rule the preview shows must be refused by
a function or trigger, and each one gets a test that tries to break it while signed in as the wrong person (impersonation test,
OA-315 acceptance line). Functions keep the names the app already calls where those exist.

### 3.1 Requests and Guardians (first)

**Data**

| Table | Change | Rule it serves |
|---|---|---|
| `journey_requests` | Reuse, widen: `kind` (begin / restart), `status` (pending, accepted, declined, cancelled, expired), `sent_at`, `expires_at` (sent + 7 days), `decided_at`, `seen_by_recipient_at`, `seen_by_sender_at`. Rows are **kept** - no 30-day removal | DOC-0283 §3; DR-277 (7 days), DR-284, DR-300 (Past stays) |
| `profile_hides` (new) | Who hid whom, when. Hiding is private - the hidden person is never told | DOC-0292 §5 Hide; DR-095, DR-284 |
| `plan_limits` (new, reference) | One row per plan: Journey places, pending requests, Guardians per Seeker, browse count per 4 hours, revisits, restart allowed, monthly Unlocks. Every limit below reads this table, so a future change is one row, not a code change | DOC-0291 §6 (DR-282, 283, 275) |
| `notifications` | New kinds: request received, request accepted, "Not taken up", **Main Guardian set** (the one-time message, B1 DR-294) | DOC-0290 §3; DR-292, 294, 299 |
| `likes`, `passes`, `saves`, `matches.create_match_on_mutual_like` | Stop: the trigger that makes a match from two likes is removed; the tables stay read-only until the old app goes (§4) | DR-274, DR-280 |

**Server rules (plain words, technical name)**

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Send a request | RPC `zyra_send_journey_request(to)`: refuses if sender unverified (calls `zyra_my_identity_verification_allows_active_journey` - closes OA-315 a), target hidden either way, blocked either way, target's profile paused, a request or Journey already between them, a decline by that person inside 30 days, sender over the pending limit (Basic 3 / One 25), or the pair fails `zyra_can_match` (shared Guardian). Does **not** take a place | DOC-0283 §2-3; DOC-0292 §1, §6; DR-283, 284, 290 |
| Cancel | RPC `zyra_cancel_journey_request(id)` - sender only, pending only | DOC-0283 §3 |
| Accept | RPC `zyra_accept_journey_request(id)`: both verified; both have a free place (preparing + active < plan places); else refused with "places full". Creates the attempt in **preparing** and reserves both places (3.2) | DOC-0283 §2-4; DR-275, 280 |
| End & accept (One only) | RPC `zyra_end_and_accept(id, end_attempt)`: ends the chosen Journey and accepts in one step; refused on Basic | DOC-0283 §2; DOC-0291 §6 |
| Decline | RPC `zyra_decline_journey_request(id, hide)`: marks declined; sender's view says "Not taken up"; `hide=true` also writes `profile_hides` | DOC-0283 §3; DR-284 |
| Expiry | Scheduled job (`pg_cron`, daily) marks pending requests past `expires_at` as expired. Sender sees "Not taken up"; no 30-day wait after an expiry (only after a decline) | DR-277, 284 |
| Read my requests | RPC `zyra_my_journey_requests(tab)`: Received, Sent, Past (declined/expired/cancelled sent, plus received I declined), newest first by move date | DOC-0283 §3; LOCK 2 (DR-298) |
| Gold dot | RPC `zyra_mark_requests_seen(tab)` - the app clears the dot when the tab opens | LOCK 5 (DR-303) |
| Guardian limits | `zyra_request_guardian_link` / `zyra_accept_guardian_request` read `plan_limits`: Seeker Basic 1, One 10 (incl. Main); any Guardian at most 10 Seekers | DOC-0290 §2; DR-281, 282 |
| First-link event | Existing trigger `auto_designate_main_wali` and RPC `zyra_set_main_guardian` write one "Main Guardian set" notification with a `seen` flag - the one-time message shows once, on first link and on Make Main | DR-294 (B1), DR-298; OA-317 30 Oct (b) |
| Main Guardian sees requests | RPC `zyra_guardian_seeker_requests(seeker)`: Main Guardian only, pending sent and received, **public card fields only** (name, age, city, main photo link) | DOC-0290 §3; DR-292 |
| Circle read boundary | Apply the 5 Oct f02 rules; the Circle's past-topic resolver (`zyra_attempt_summary_for_guardian`, Circle cards) returns ended Journeys only when `guardian_journey_history_consents` is on for that link **and** the Journey ended after `wali_links.linked_at`; four anonymous fields only | DR-233; DOC-0290 §5; OA-324 |
| Introductions | Already built (`wali_suggestions`, `zyra_mark_suggestions_seen`) - keep; the Guardian Network "Introduce to <Seeker>" button writes the same row | DOC-0290 §7; DR-280 §9 |
| Connect with Guardian | New table `guardian_contact_requests` (from Guardian, to the Main Guardian of Seeker X, status pending/responded/declined, 30-day expiry) with send/respond/decline RPCs. Same shape as Guardian link requests. Can be its own brief (§6 Q6) | DOC-0290 §7; DR-280 §8, DR-306 |

**States.** Request: pending → accepted (becomes a preparing Journey) · declined · cancelled · expired. Declined and expired
both show to the sender as "Not taken up". Past tab items never leave (DR-300); keep-time is the DPIA's call (§6 Q3).

**Who sees what**

| | Seeker | Main Guardian | Additional Guardian |
|---|---|---|---|
| Own sent / received / past requests | Yes | Pending only, public card only (DR-292) | No |
| Who the other person's Guardians are | Explained in Profile "What Guardians can do", never per request (DR-299, LOCK 3) | - | - |
| Hidden-people list | Owner only | No | No |
| Introductions made for the Seeker | Yes ("Suggested by …") | Own suggestions | Own suggestions |

### 3.2 Journey (second)

**Data**

| Table | Change | Rule it serves |
|---|---|---|
| `journey_attempts` | New status **preparing** before active; columns `prepare_expires_at` (accepted + 48 h), `ready_a_at`, `ready_b_at`, `guardians_agreed_a_at`, `guardians_agreed_b_at`, `archive_until` (ended + 3 months) | DOC-0283 §4, §7; DR-277, 280 |
| `journey_stage_checkpoints` | Stage list gains **bio** between compatibility and guardian gate | DOC-0283 §5 (2b) |
| `journey_bio_reveals` (new) | Per attempt and Seeker: `revealed_at`, `continued_at` | DOC-0283 §5 (2b); DR-280 |
| `journey_guardian_assignments` | Column `agreed_at_start` - paid Additional Guardians the Seeker agreed to before beginning; the Seeker cannot switch these off for that Journey | DOC-0283 §6; DOC-0290 §3; DR-280 §7 |
| Pause | Remove: the 13 `zyra_reject_locked_journey_write` triggers, `transition_journey_pause`, `zyra_guard_paused_return_initiation`, the pause columns on `matches`, and the `suspend/resume/nudge/restart_journey` stubs (OA-315 c, e). Live presence of each: **not verified** - the pass lists them first | DR-274; DOC-0283 §7 |

**Server rules**

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Places | One helper `zyra_journey_places_used(profile)` counts attempts in preparing **or** active; the existing limit triggers (`zyra_enforce_one_active_match`, `_attempt`) compare it with `plan_limits` (Basic 1, One 3). Pending requests never count | DOC-0283 §2; DR-275, 282 |
| Ready | RPC `zyra_set_ready_to_begin(attempt)`: refused unless the caller has agreed their paid Additional Guardians for this Journey (`zyra_agree_journey_guardians(attempt)`) and is verified. When both are ready the same call moves the attempt to active at Salam and writes the Timeline milestone. One person alone never starts it | DOC-0283 §4; DR-277, 280 |
| Ready window runs out | Daily job: preparing attempts past `prepare_expires_at` → **expired**, places released, both told "Not started". Fable's proposal: no 30-day wait (nobody declined) - **§6 Q1** | DOC-0283 §8 (open) |
| Journey Bio | Stage advance (`zyra_advance_stage` family) from compatibility goes to bio; from bio only when both rows in `journey_bio_reveals` have `revealed_at` and `continued_at`. An earlier Compatibility Unlock stays usable here | DOC-0283 §5; DR-250, 280 |
| Both answered | `open_family_review(attempt, phase)` counts `journey_phase_answers` for **both** Seekers against the phase's question count and refuses if short - closes OA-315 b | DOC-0283 §5; DR-277 |
| Main Guardian hold | Apply the 18 Sep file (`zyra_enforce_main_guardian_journey_hold`); End stays allowed | DOC-0283 §5; DR-236 |
| Identity | Every Journey-starting RPC (send, accept, ready) calls the verification check | DOC-0283 §5; OA-315 a |
| End | Existing `zyra_end_match_internal`; sets `archive_until` | DOC-0283 §7 |
| Messages (OA-319) | Rewrite the unapplied 24 Sep send rule (`messages_insert`) to keep the 9 Aug checks (no block, conversation active, attempt active, Seekers) **and** add: conversation open only at stage 8; a Guardian may write only with Chat allowed **and** `zyra_has_paid_role`. Fix the replay by dropping and re-creating the participant view instead of replacing it. Proven by a full replay on a throw-away local database | DOC-0293 §1, §2, §6; DR-131, 268, 289 |

**States.** Attempt: preparing → active (Salam → Compatibility → **Bio** → Guardian Gate → Faith & Values → Building a
Life → Navigating Life → Family Compatibility → Open Conversation) → ended (read-only 3 months) · preparing → expired.
No paused state anywhere.

**Who sees what.** Seekers: their own attempts in every state. Main Guardian: every preparing and active Journey of their
Seeker, always (DR-232). Additional Guardians: active Journeys with View on, or agreed at start; never preparing, never ended
unless history consent is on for that link (DR-233). Nobody but the two Seekers reads an ended Journey's messages.

### 3.3 Browse (third)

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Who appears | `zyra_browse_ranked_ids` (apply the 5 Oct f04 file, then extend) excludes: hidden by me, people who hid me (**§6 Q2**), blocked either way, paused profiles, anyone with a pending request or preparing/active Journey with me, anyone with **no free place**. Ended-with-before people may appear | DOC-0292 §1; DR-095, 123, 280, 290 |
| When I can browse | Refused when my places are full, unless Seeker One | DOC-0283 §1; DR-282 |
| Basic 25 per 4 hours | New table `browse_views` (viewer, viewed, at); the ranked-ids RPC counts the last 4 hours against `plan_limits` and returns "limit reached" - replaces the phone-only counter | DOC-0292 §6; DR-282 |
| Filters | Age, country, nationality, ethnicity filtered in the RPC from profile fields (which fields exist live: **not verified**); distance needs a coarse stored location (city-level) - added only after the DPIA (OA-321) says how | DOC-0292 §3 |
| Hide / Pause My Profile | RPCs with the names the app already calls: `zyra_set_profile_hidden`, `zyra_my_hidden_profile_ids`, `zyra_set_my_profile_pause`, `zyra_my_profile_pause_state` | DOC-0292 §7; DR-095, 290 |
| Revisit declined (One, 10) | Counted from Past rows in the send RPC; exact meaning confirmed at the Browse LOCK | DOC-0291 §6 |
| Ranking by the six policies | Keep f04's legacy scorer for now; swapping to the approved scorer is a separate server-only brief after Browse works on real data | DOC-0292 §2; DR-250 |

Who sees what: a Seeker sees only cards the RPC returns; Guardians never browse Seekers' candidates (Network shows other
families' Seekers through the Guardian functions, DR-306).

### 3.4 Membership (fourth)

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Plans and places | `plan_limits` rows: Seeker Basic (1 place, 3 pending, 1 Guardian, 25 browse / 4 h, no restart, 0 Unlocks), Seeker One (3, 25, 10, unlimited, restart from 5 most recent, 3 Unlocks monthly), Guardian Basic (view, no chat), Guardian One (chat possible) | DOC-0291 §1, §6; DR-252, 275, 282, 283, 288 |
| Basic is paid | A Basic row in `subscriptions` exists only after the £4.99 joining fee; until App Store purchases exist (item 7) it is set by the developer functions, which stay test-account-only and leave before launch | DOC-0291 §1, §7; DOC-0294 §5 |
| Joining fee waived | Needs payment history - hook only (a `payment_events` table comes with item 7) | DOC-0291 §1 |
| Monthly Unlocks | `grant_zyra_one_credits` becomes a monthly grant per billing period with an expiry at period end; unused ones lapse | DOC-0291 §4; DR-288 |
| Family places | Cap changes from 10 of each to **10 in total**, any mix (`family_subscriptions` seat guard) | DOC-0291 §3; DR-291 |
| Dropping to Basic | Trigger on `subscriptions` end/downgrade switches that Guardian's Chat off in every Journey; it does not return by itself | DOC-0290 §4; DR-268 |
| Paid role | `zyra_has_paid_role` unchanged; the Circle and the Journey send rule both use it | DOC-0291 §5; DR-243, 248 |

### 3.5 Profile and settings (fifth)

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Pause My Profile | `profiles.paused_at`; Browse and request sending read it; Journeys, Guardians, plan and billing carry on | DOC-0295 §4; DR-290 |
| Hidden people | List and undo through the Hide RPCs (3.3) | DOC-0295 §4; DR-095 |
| Guardian privacy | Existing per-Journey View/Chat switches plus the f02 read boundary (3.1) | DOC-0295 §4; DR-232, 233 |
| Photo owner binding | Apply the 5 Oct f03 file | DOC-0295 §2 |
| Delete account | `delete_own_account` changes from cascade to **detach**: my Journeys end as "This member has left ZYRA", the other Seeker keeps Timeline and messages 3 months, Guardian links end, Circle shows "Former member", safety reports stay | DOC-0295 §5; DR-285 |
| Two roles, one login | A later, larger change (profile model holds one role today). Listed in §5 as its own brief after the six areas, not part of this yes | DOC-0295 §6; DR-285 |

### 3.6 Ended and restart (sixth)

| Rule | How the server enforces it | Blueprint |
|---|---|---|
| Archive | Ended Journeys readable by the two Seekers until `archive_until` (ended + 3 months): Bio, Compatibility, Guardians, messages. After that the read functions refuse; purge timing follows the DPIA | DOC-0283 §7; DOC-0293 §4; DR-268, 280 |
| Request restart | `request_new_journey` becomes a `journey_requests` row with `kind = restart`: refused on Basic, allowed on One only for the 5 most recent ended Journeys, only 24 hours after the ending, expires after **7** days (was 30). Acceptance creates a **new** attempt; the old one is never reopened. Release switch on | DOC-0283 §7; DOC-0291 §6; DR-277, 282 |
| Places | An ended Journey releases both places at once (already built) | DOC-0283 §7 |
| Ending reasons | Existing `zyra_match_ending`; "safety concern" shows to Guardians as "prefer not to say" | DOC-0290 §5; DR-268 |

## 4. Data to migrate or remove, and safety

**The 17 unapplied files (25 Aug - 5 Oct) - Fable's keep / rewrite / drop proposal (§6 Q5)**

| Files | Proposal | Why |
|---|---|---|
| 25 Aug shared pause decision | **Drop** | Pause is retired (DR-274) |
| 18 Sep Main-Guardian hold, known-person code matching, product telemetry | **Keep** | Blueprint rules; telemetry stays switched off |
| 19 Sep Guardian Circle messaging; Journey return gate | **Keep** Circle; **rewrite** the return gate for ended-then-restart (it was written for paused Journeys) | DOC-0290 §6; DOC-0283 §7 |
| 23 Sep retire legacy purchase functions | **Keep** | Nothing can be bought yet anyway |
| 24 Sep paid-only contract | **Rewrite** - Basic 1 place, safe send rule kept (3.2), view replay fixed | DR-275; OA-319 |
| 25-26 Sep Circle participants, sender identity, read receipts | **Keep** | DOC-0290 §6; DOC-0293 §3 |
| 5 Oct f01-f07 (report retention, Guardian read boundary, photo owner, Browse ranking, progress helpers, unlock hold and receipts) | **Keep**, applied in that order after the 24 Sep rewrite | OA-324 (f02), DOC-0292 (f04) |

**What goes, and in which stage**

| Item | Stage 1 (stop using) | Stage 2 (verify) | Stage 3 (remove) |
|---|---|---|---|
| Journey Pause flow (triggers, functions, `matches` pause columns) | Functions become refusals | Tests show nothing writes them; live check lists what exists | Drop |
| `saves`, `likes`, `passes`, mutual-like trigger | Trigger removed; tables read-only | Old member app gone (OA-316 Tier 3, DR-293) | Drop tables |
| Basic 0 → 1 place | `plan_limits` row | Existing Basic test rows re-counted | - |
| Test accounts (149 `@zyra.test`, `is_synthetic` rows per OA-ZYRA-190; whether the flag exists live: **not verified**) | Never returned by Browse or requests to a real member | Counted before launch | Removed with the developer functions before launch (OA-312) |

**Safety rules for every stage**

| Rule | Detail |
|---|---|
| Small verifiable stages (standing rule) | One area = one set of migration files; each file does one thing and is applied to a branch or local database first |
| Tests before and after | The SQL suites in `SOURCE/supabase/tests` (50 files: fixtures, assertions, race and lock-wait checks) run before and after every stage; each new rule adds an impersonation test; the full migration replay runs on a throw-away database (OA-319) |
| Nothing destructive without a backup | A point-in-time backup is confirmed before any production apply; drops only in Stage 3, never in the same change that stops the writes |
| Live pass first | The read-only check (DOC-0294) is re-run before Stage 1 of each area; "not verified" lines above are answered there |
| Developer functions | Stay test-account-only throughout; removal is a launch gate, not part of this design |

## 5. Build plan

| # | Queue line (suggested brief title) | Depends on | ZYRA chat LOCK first? | Server-only? |
|---|---|---|---|---|
| 0 | SERVER 0 - Live pass and catch-up: re-run the read-only check, apply the kept files in order, 24 Sep rewrite, replay test | Founder yes + Q5 | No | Yes |
| 1 | SERVER 1 - Requests and Guardians: request flow, hides, plan limits, Guardian limits, first-link event, Main Guardian request view, f02 boundary | 0 | LOCK 2 and LOCK 3 exist (DR-298, 301); Guardian tabs LOCK 8 (DR-306) | Mostly; app wiring follows |
| 2 | SERVER 2 - Journey: preparing, ready, places, Journey Bio, both-answered, identity, Pause removal Stage 1-2, send rule | 1 | Preparing and Journey Bio screens need a LOCK (none yet) | Rules yes; screens after LOCK |
| 3 | SERVER 3 - Browse: visibility, limits, filters, Hide and Pause My Profile functions | 1, 2 | Browse LOCKs exist for the card and row (DR-302, 305); Filters not locked | Yes |
| 4 | SERVER 4 - Membership: plan_limits final, monthly Unlocks, Family cap, downgrade switch | 1 | Membership page not locked - rules can go first | Yes |
| 5 | SERVER 5 - Profile and settings: Pause My Profile, hidden list, f03, account deletion detach | 3, 4 | Settings pages need LOCK 7-style baseline (chat note 29 Oct) | Rules yes |
| 6 | SERVER 6 - Ended and restart: archive window, restart through requests, switch on | 2 | Ended section placement open (chat note 29 Oct, Past Journeys) | Yes |
| 7 | Later, own designs: two roles one login (DR-285), approved-policy ranking (DR-250), payments (item 7), push (DR-278) | 1-6 | - | - |

Each line: a brief in `PRODUCT/APPROVED/SERVER/BRIEFS/`, "Built from: DOC-ZYRA-0329 §3.x", tests named, and a WAITING line in
`BUILD_QUEUE.md`. Codex reports problems before building (charter rule 8); Fable files the decision at 04:15.

## 6. Open questions for the Founder

| # | Question | Options |
|---|---|---|
| Q1 | When the 48-hour "I'm ready" window runs out, what happens? | **A** Journey expires, places released, both told "Not started", either can request again at once (Fable recommends) · **B** same, but 30-day wait like a decline |
| Q2 | When you hide someone, should you also disappear from **their** Browse? | **A** Yes, both ways (Fable recommends - no clue that they were hidden) · **B** No, only your Browse changes |
| Q3 | Past requests stay listed with no end date (DR-300). How long does the server keep those rows? | **A** Forever while the account exists · **B** Fable and the DPIA (OA-321) set a limit, e.g. 12 months, and the tab says so |
| Q4 | If a Seeker pauses their profile, what happens to requests they already sent? | **A** They stay pending (Fable recommends) · **B** They are cancelled |
| Q5 | The 17 unapplied database files - keep / rewrite / drop as in §4? | **A** Yes, as proposed · **B** Tell me which to change |
| Q6 | Connect with Guardian (Guardian to another Seeker's Main Guardian) - build it in Requests and Guardians, or later? | **A** In SERVER 1 · **B** Its own brief after SERVER 6 (Fable recommends - keeps line 1 smaller) |

## 7. Sources read

| Source | Used for |
|---|---|
| `AGENTS.md` ("What we are building", "Locked design workflow") | Scope, workflow, queue rules |
| OA-ZYRA-317, 315, 319, 324 (`SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md`) | The gaps, decisions already taken, 30 Oct additions |
| DOC-ZYRA-0283 Journey, 0290 Guardian, 0291 Membership, 0292 Browse, 0293 Messaging, 0295 Profile rules | The rules each line enforces |
| DOC-ZYRA-0280 blueprint part 3 (data) | Tables, triggers and functions in the repository |
| DOC-ZYRA-0294 live database check (26 Oct) | What production really has |
| `BLACK UMBRELLA GROUP/REPORTS/DAILY/2026-10/2026-10-29_ZYRA_CHAT_NOTE.md` | LOCKs 2-8, DR-299, Past with no end date, first-link gap |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1_INDEX.md` rows DR-ZYRA-274 to 307 | Decision titles cited |
| `SOURCE/supabase/tests` (listing only) | Test suites named in §4 |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-30 | V1 | First draft for the Founder's yes (Fable; OA-ZYRA-317 "yes both", 29 Oct) |

## Approval

| Date | Who | Words |
|---|---|---|
| 2026-10-30 08:15 | Founder (clickable, in the ZYRA chat) | §6: Q1 "Expires, can ask again"; Q2 "Both ways"; Q3 decided 30 Oct (12 months then anonymised, DR-ZYRA-300 note); Q4 "Stay waiting"; Q5 "Yes, Fable's plan"; Q6 "After the core" |
| 2026-10-30 11:10 | Founder (clickable, admin chat) | "Yes, approved" - the whole design. The ZYRA chat queues SERVER 0 first, then areas 1-6 in order |
