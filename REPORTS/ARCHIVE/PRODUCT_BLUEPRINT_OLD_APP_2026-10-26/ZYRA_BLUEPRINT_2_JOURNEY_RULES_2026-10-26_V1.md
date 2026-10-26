---
id: DOC-ZYRA-0283
type: SPEC
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Journey) - every rule of a ZYRA Journey from the code - how one starts, the eight stages and what unlocks each, Family Reviews, pausing, ending, returning, limits, Guardians' part and milestones
links: [OA-ZYRA-309, OA-ZYRA-315, DOC-ZYRA-0256, DOC-ZYRA-0280, DOC-ZYRA-0278]
owner: Fable
---

> **READ FIRST (25 Oct 2026, DR-ZYRA-274).** This part describes the **old member app**, which is being replaced. The planned
> ZYRA is the Founder preview (the latest Codex design), where Pause, Save and restart are retired. This part will be redone from
> the planned app. Until then, use it only to understand what members' code does today.

# ZYRA BLUEPRINT — PART 2 — JOURNEY RULES — V1 (DRAFT)

Status: **DRAFT for Shakeel's review.** Written 25 Oct 2026 from the database functions and triggers in
`SOURCE/supabase/migrations` (the server, which has the final say) and from `screens/journey/journey_flow_screen.dart`,
`data/zyra_journey_stages.dart` and `data/journey_questions.dart` (the app). It describes **what the repository says**. One key
migration (24 Sep, "paid-only") is marked *repository/staging only*; whether the live database matches is part of the live check
in OA-ZYRA-312. Findings are in §11 and raised as OA-ZYRA-315.

## In one paragraph

Two Seekers of opposite gender who like each other become a **match**. Either one can then **begin a Journey**, which needs both of
them to hold a **paid Seeker membership** and to have room under their limit (**3 Active Journeys** each). A Journey walks through
**eight stages** — Salam, Compatibility Reveal, Guardian Gate, three question phases, Family Compatibility, then Open Conversation —
and from the Guardian Gate onward **both Main Guardians** are involved: after each question phase they get **48 hours** to say
continue or pause, and silence counts as continue. Either Seeker can **pause** (by agreement, up to **10 paused** each) or **end**
at any time for free; ZYRA never ends a Journey by itself. After an ending, a **return** ("new Journey") is designed but switched
off in the repository.

## 1. Words used

| Word | Means | In the database |
|---|---|---|
| Match | Two Seekers who liked each other | a row in `matches`, status `potential` |
| Journey | A match that has begun | `matches.status = 'active'` |
| Attempt | One run of a Journey; a return starts attempt 2, 3 … | `journey_attempts` |
| Main Guardian | The one Guardian (wali) per Seeker who decides at Family Reviews | `wali_links.is_main` |
| Pause | Both agree to freeze the Journey | `matches.pause_state = 'paused'` |

## 2. How a Journey starts

| Step | Rule | Enforced by |
|---|---|---|
| 1. Like | Liking someone removes any earlier Save or Pass of them (one state per profile) | triggers on `likes`, `saves`, `passes` |
| 2. Match | When the like is returned, a match is made **if** both are Seekers, finished onboarding, are of opposite gender, have not blocked each other, are not each other's Guardian and **do not share a Guardian**. Both get a "New Match" notification; the Timeline records "liked" and "match created" | `create_match_on_mutual_like` → `zyra_can_match` |
| 3. Begin | **Either** Seeker taps begin; the other is not asked. Re-checks the match rules, then both must be under their Active Journey limit | `promote_journey_to_active` |
| Limit | **3 Active Journeys** for a paid Seeker, **0** for anyone else — so an unpaid Seeker can match but cannot begin | `zyra_active_journey_cap`, checked again by a trigger on every change |
| Paid means | An active `seeker_premium` subscription (or within billing grace, or cancelled but still covered), or a funded Seeker seat on a Family plan | `zyra_has_paid_role` |
| Identity check | The app will not open the Journey until the member's identity check is **verified** and the duplicate check is **clear** | **app only** — see §11 |

The Journey opens at **Salam Exchange**.

## 3. The eight stages

| # | Stage (code) | Name members see | Guiding question | Moves on when | Who moves it |
|---|---|---|---|---|---|
| 1 | `salam_exchange` | Salam Exchange | — | **Both** have sent their salam | `zyra_advance_stage` |
| 2 | `compatibility_reveal` | Compatibility Reveal | — | **Both** chose to reveal their score **and both** tapped continue. Your score is shown only once both have revealed | `zyra_reveal_journey_compatibility`, `zyra_advance_stage` |
| 3 | `wali_gate` | Guardian Gate | — | **Both** Seekers have an active Main Guardian ("guardian required: you / them" otherwise) | `zyra_advance_stage` |
| 4 | `phase_1` | Faith & Values | Are we fundamentally compatible? | **8 questions**, answers up to **400 characters**. Both answer all, both mark done → **Family Review** | `open_family_review` |
| 5 | `phase_2` | Building a Life | Could we realistically build a life together? | **7 questions** → Family Review | `open_family_review` |
| 6 | `phase_3` | Navigating Life | Can we navigate life together? | **7 questions** → Family Review | `open_family_review` |
| 7 | `family_stage` | Family Compatibility | — | Each Seeker asks the **other side's Guardian 4 questions**, and each Guardian asks the **other Seeker 4 questions** → Family Review | `open_family_review` |
| 8 | `conversation` | Open Conversation | — | Last stage: free conversation opens; Timeline and Guardians stay part of it | — |

Every stage completion is written to the Journey **Timeline** (salam exchanged, compatibility revealed, guardian linked, phase 1–3
complete, family stage, conversation started). Guardian ↔ Guardian questions are marked "TBC" in the spec and are not built.

## 4. Family Reviews (after stages 4, 5, 6 and 7)

| Rule | Value |
|---|---|
| Opens | When a Seeker finishes a question stage; one review at a time per attempt |
| Window | **48 hours** |
| Who decides | Each Seeker's **Main Guardian** (other Guardians cannot) |
| Choices | **Continue** or **Pause** |
| Result | Any Pause → the review stops and the Journey stays at that stage. All Main Guardians say Continue → next stage straight away |
| Silence | If the 48 hours pass with no Pause, the Journey moves on as if both said Continue (applied the next time a Seeker or Main Guardian opens the Journey) |
| Reopen | A Main Guardian can reopen a paused review, which starts a fresh 48 hours and clears earlier answers |
| Opening Open Conversation | The moment the last review passes, the conversation switches on |

## 5. Main Guardian hold (any stage)

Once a Journey is active, **nothing ordinary can be written** — salam, answers, ratings, checkpoints, compatibility, family answers,
messages — unless **both Seekers have an active Main Guardian**. Pause and End still work. Enforced on 11 tables by a trigger
(`zyra_enforce_main_guardian_journey_hold`, DR-ZYRA-236).

## 6. Pausing

Pausing is a **shared decision**, one step at a time; each step notifies the other person. There is **no time limit** on any step
(`zyra_pause_decision_window` is empty on purpose).

| From | Action | By | To |
|---|---|---|---|
| Running | Ask to pause | either Seeker (A) | **Pause requested** — the conversation freezes at once |
| Pause requested | Agree | the other (B) | **Paused** |
| Pause requested | Ask to keep going | B | **Continue requested** |
| Continue requested | Keep going | A | Running again |
| Continue requested | Pause anyway | A | **Paused** (A has the final word on their own pause) |
| Paused | Ask to resume | either | **Resume requested** |
| Resume requested | Agree | the other | Running — if both are under their Active limit |
| Resume requested | Keep paused | the other | Paused |

| Limit | Value |
|---|---|
| Paused Journeys at once | **10** for a paid Seeker, **0** otherwise (so only paid Seekers can be paused) |
| Paused Journeys you can ask to resume | Only your **5 most recently paused** — see §11 |
| While paused | Nothing in the Journey can be written or advanced (pause lock on 13 tables); milestones are refused |
| A pause frees an Active slot | Yes — paused Journeys do not count towards the 3 |

## 7. Ending

| Rule | Value |
|---|---|
| Who | Either Seeker, at any stage, paused or not, **always free** |
| Reasons | not compatible · circumstances changed · marrying elsewhere · family decision · safety concern · prefer not to say (or none) |
| What happens | Journey and attempt ended, conversation closed, "Journey ended" added to the Timeline, the other person told "Your Journey with [name] has ended" |
| Safety concern | The other person (and their Guardians) see "prefer not to say" and no note; only the person who ended it sees the real reason |
| Automatic ending | **Never.** The reason `no_response` exists but a member cannot pick it and nothing sets it |

## 8. Returning after an ending (new Journey)

**Built but switched off.** On 24 Sep the request functions were revoked from members until OA-ZYRA-156 (attempt-owned rituals)
is proven. When switched on, the rules are:

| Rule | Value |
|---|---|
| Wait | **24 hours** after the ending |
| Who | Both must hold a paid Seeker membership; the match rules (§2) must still hold; no block or protection hold |
| Which | Only one of your **5 most recently ended** Journeys |
| Room | Both under their Active limit |
| One at a time | One pending request per match |
| Request lasts | **30 days**, then it counts as declined |
| Answers | Accept → attempt 2 (3 …) starts at **Compatibility Reveal** (Salam is not repeated) · Decline → the asker waits **30 days** · Decline forever → a permanent hold (appealable) · Expiry → 30-day wait |
| Withdraw | The asker can withdraw while pending |
| Recipient not paid | The asker is told "not available to reconnect right now" |

## 9. Guardians in a Journey

| Rule | Value |
|---|---|
| Main Guardian | Always sees and can chat in every Active Journey of their Seeker; decides Family Reviews |
| Other Guardians | See and chat by default; the **Seeker** can switch View and Chat off per Journey (Chat needs View) |
| Ended Journeys | A Seeker's active Guardians can see how it ended (with the safety-concern rule in §7) |
| Guardian Circle chat | Belongs to the Guardians part of the blueprint |

## 10. Milestones

| Rule | Value |
|---|---|
| Types | First meeting · Nikah |
| How | One Seeker proposes a date (not in the future); **the other must confirm** before it joins the Timeline |
| Limits | Once per attempt each; not while paused or ended; proposing again replaces your own pending one; if they already proposed, confirm theirs |

## 11. Found while mapping (OA-ZYRA-315)

| # | Finding | Why it matters |
|---|---|---|
| a | **The identity check is only in the app.** The server has `zyra_my_identity_verification_allows_active_journey` but nothing calls it; beginning, advancing and messaging do not check it | Anyone calling the server directly could take part in a Journey unverified |
| b | **Question stages are only checked in the app.** `open_family_review` checks the stage, not that both answered every question; the app hides the button until they have | Same — the server would let a stage be skipped |
| c | **Paused cap 10, but only the 5 most recent can be resumed.** Paused Journeys 6–10 can only be ended | Probably unintended; needs the Founder's intent |
| d | **The Journey lifecycle document is out of date.** DOC-ZYRA-0256 (V3, Aug) still describes Basic and ZYRA One, pause caps of 5/10 and one Active Journey | Agents reading it get the wrong rules |
| e | **Old functions kept as refusals:** `suspend_journey`, `resume_journey`, `nudge_paused_journey` (all "pause flow superseded") and `restart_journey` (always "needs mutual consent") | Dead code to retire after the freeze |
| f | **The 24 Sep "paid-only" migration is labelled repository/staging only** | Production may still run the older Basic/One rules — add to the live check |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | First draft from the server functions, triggers and app (OA-ZYRA-309) |
