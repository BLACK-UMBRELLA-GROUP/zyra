---
id: DOC-ZYRA-0175
type: SPEC
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA GUARDIAN NETWORK — BUILD CONTRACT
links: []
owner: ZYRA chat
---

# ZYRA GUARDIAN NETWORK — BUILD CONTRACT

**Document:** ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md
**Status:** CURRENT_VERSION — the complete build contract for `wali_network_screen.dart` and the Guardian Network feature. Completes and supersedes the overnight run's truncated `01_AGREED_RULES.md` (rules 1–21 carried forward; 22 onward written fresh against the RATIFIED D14 interaction model, spec §D14, 2026-08-23).
**Authority:** Rules 1–21 — the 2026-08-22 Fable↔Codex agreement, amended where D14 touches them (amendments marked **[D14]**). Rules 22–44 — D14, ratified by the Founder 2026-08-23. WORKING RULE markers remain where a D1–D13 decision is still open.
**Consumers:** every implementation pass (Fable deterministic builds, Codex Phase-2) verifies against THIS document. Per engine control AC-14, the terminator line at the end states the rule count; per AC-18, rules number 1..N with no gaps or repeats.

---

## PART A — ARCHITECTURE & CONTEXT RULES

**Rule 1 — No feed without an active Seeker context.**
The Guardian Network screen MUST NOT render any candidate feed, saved list, set-aside list, or process count unless exactly one linked Seeker is selected as the active context. A Guardian with zero eligible linked Seekers sees the GN-NO-SEEKER empty state. A Guardian whose selected Seeker has Network consent OFF sees GN-CONSENT-OFF. Neither state shows history, declined-candidate traces, or pressure surfaces of any kind.

**Rule 2 — Single-Seeker context, always.**
There is no merged or combined feed across multiple Seekers. The served card, set-aside list, Connections sections, process counts, and all per-card state are scoped to exactly one (guardian_id, seeker_id) pair at a time. Switching Seeker context swaps ALL of these simultaneously; no state bleeds across contexts.

**Rule 3 — Seeker selector behaviour.**
One eligible linked Seeker → context auto-selected; selector renders as a static label. Two or more → explicit selector required; no default; the screen does not proceed past the selector until a selection is made. "Eligible" means an active wali_links row AND Seeker Network consent ON; a linked Seeker with consent OFF is excluded from the selector without disclosing their consent state.

**Rule 4 — Composite key for all per-Seeker state.**
Every record of Guardian–Network interaction uses the composite key (guardian_id, seeker_id, candidate_id) as its primary scope. Nothing recorded under one seeker_id is readable, writable, or aggregatable under another. **[D14]** A Wali connection for one Seeker grants nothing for the Guardian's other Seekers.

## PART B — ELIGIBILITY & FILTERING RULES

**Rule 5 — `can_introduce()` is the master gate.**
Every feed inclusion and every process transition is gated server-side by `can_introduce(G, S, C)` (active wali link ∧ zyra_can_match ∧ Browse-visibility ∧ both Network consents). **[D14]** Checked at all five checkpoints: card serving, request send, request acceptance, each Wali proceed, and the final simultaneous reveal. The client never renders a speculative result before server confirmation.

**Rule 6 — Hard filters are absolute; the Guardian cannot widen them.**
A candidate failing any hard filter does not appear anywhere and cannot be the subject of any process. No toggle, override, or "near-matches" exists in v1. Soft preferences rank; they never exclude.

**Rule 7 — `zyra_can_match` is a live predicate, not a snapshot.**
Consumed as-is by `can_introduce()`; the Network adds no relaxation.

**Rule 8 — Blocks are terminal and immediate.**
A block in either direction removes both parties from each other's Network world instantly and silently, lapsing every open process between the pair ("No longer active"). Target latency under 30 seconds.

**Rule 9 — Safety holds are silent.**
A held Seeker simply does not appear; the absence is indistinguishable from ordinary feed variation.

**Rule 10 — Journey availability filter.** WORKING RULE *(D8 pending)*
A Seeker in an Active or Paused Journey is excluded from serving, not shown with a status indicator.

**Rule 11 — Network eligibility can never be weaker than Browse.**
A candidate unreachable under ordinary Browse rules does not appear. The Network is never a back-door.

## PART C — CARD & INFORMATION VISIBILITY RULES

**Rule 12 — Approved field set for the served card (Rung 0).** **[D14 amends the photo row]**
The card displays exactly: first-name initial ✅ · age ✅ · region/country (never city) ✅ · Guardian relationship label ✅ · Verified Guardian badge ✅ · compatibility band (never a number) ✅ · **photo per the Seeker's photo level: card-level shows it here; after-connect (DEFAULT) and never show a neutral seal with no gap disclosed** · practice chip (D2 pending). Never: full name, city, occupation detail, Chapter 3/4 answers, other Guardians, network membership of others.

**Rule 13 — No free text anywhere on the card.**
Cards are 100% system-controlled; Guardians cannot add, annotate, or append text anywhere in the Network.

**Rule 14 — Recommendation-reason chips are taxonomy-controlled.**
Fixed system taxonomy only; no free text; no preference the Seeker did not set.

**Rule 15 — Progressive disclosure ladder is never inverted.**
No rung shows more than a higher rung permits; region-not-city at Rung 0 enforces the location case.

**Rule 16 — Uniform field set; no per-user sparseness.**
All-or-nothing display: a card either shows the full approved set or does not appear. (Uniform absence of a not-yet-built field is a completeness gap, not sparseness.)

## PART D — THE RATIFIED INTERACTION MODEL (D14)

**Rule 17 — v1 action set.** **[D14 replaces the 2026-08-22 set]**
The only Guardian actions in v1 are: **View · Save · Set aside · Suggest to [Seeker] · Request connection** — plus, inside a live process: **Connect with this family · Not for us · Withdraw · Proceed to the Seekers**. The Family Introduction Request flow is retired within Guardian Network. Guardian↔Guardian free text remains out of scope (D6).

**Rule 18 — View is silent.**
Opening a card or a Guardian profile is never notified to anyone and never aggregated into any user-visible display.

**Rule 19 — Save and Set aside are private.** **[D14 renames Pass]**
Save keeps a private per-Seeker shortlist. **Set aside** removes the served family from rotation for THIS Seeker context into a reversible list: manual restore anytime; the algorithm may re-serve after 30 days, only while eligible, and never recycles set-aside families while fresh eligible families remain. Neither action is ever visible to the other family or to any Seeker. Connected families never re-serve.

**Rule 20 — Suggestion is not consent.** *(unchanged by D14)*
"Suggest to [Seeker]" routes a candidate to one's OWN Seeker via the existing Introductions pipe; it is advisory, never a cross-family act, and never consent.

**Rule 21 — Decline reasons are never disclosed.**
Every closure, of anything, reaches the other side as the single neutral state with no reason. The Seeker's decline reasons never reach any Guardian.

**Rule 22 — The ladder.**
The Guardian Network process is exactly: Rung 0 Recommendation → Rung 1 Request connection → Rung 2 Connected → Rung 3 Proceed to the Seekers → Rung 4 Simultaneous introduction. No stage may be skipped, merged, or reordered; nothing reaches either Seeker before Rung 4.

**Rule 23 — Serving discipline.**
Discover serves ONE family at a time, algorithm-chosen for the selected Seeker context. No browsing ahead, no manual paging past an un-actioned card, no peeking at upcoming families. Advancement happens only by acting: View leaves the card current; Set aside or Request connection advances.

**Rule 24 — One process per Seeker pair; the merge rule.**
At most one Guardian Network process exists per Seeker pair. A request sent while a reverse request is pending acts as acceptance, never a duplicate. If Discover would serve a family whose Wali already has a pending incoming request for this pair, it renders the merge card — "This family has already requested connection." with primary action "Review request" opening the existing Incoming item — never a normal card.

**Rule 25 — Silence discipline.**
Default decline is silence. A request quietly expires after 14 days. After a first expiry, the original initiating Seeker-side waits 90 days before approaching the same pair again — bound to the Seeker pair and direction, Wali-switch-proof; the receiving family is never blocked from approaching in the other direction. A second quiet expiry, or an explicit "Not for us", closes the pair for 6 months in BOTH directions, equally Wali-switch-proof.

**Rule 26 — "Not for us" is internal.**
The receiving Wali's explicit clear removes the request from their queue immediately and is NEVER distinguishable to the sender from any other closure.

**Rule 27 — The single external closed state.**
Every closure — explicit decline, expiry, withdrawal, eligibility failure, Main-Wali change, safety restriction — presents externally as exactly **"No longer active"**. No reasons, no decline notifications, nothing shown to either Seeker. One external state for many internal causes; the interface is never a rejection ledger.

**Rule 28 — What Connected (Rung 2) unlocks.**
Reciprocally and simultaneously: the verified Main-Wali profile · Wali relationship to the Seeker · region · verification status · the other Seeker's ordinary Browse-level profile · photo per that Seeker's photo level · the structured exchange. Both sides receive the same unlock at the same moment.

**Rule 29 — What Connected never unlocks.**
Contact information · exact address or location · private compatibility answers · any numeric compatibility score · family-network membership · message history · safety or moderation history · previous Journey history · response-speed or responsiveness indicators of any kind.

**Rule 30 — Access ends with the process.**
On any closure: reciprocal profile access, structured exchange, and photo serving end immediately; nothing reopens from history. The Connections history retains only: Seeker initial · region · relevant date · "No longer active". Stated honestly: what was already seen cannot be unseen — ZYRA simply stops serving it.

**Rule 31 — Dual proceed; honest withdrawal.**
Rung 3 requires each Main Wali to confirm independently. Either may withdraw at any time before both have confirmed: silent in notification terms, reasonless, nameless — but the other side's state updates truthfully to "No longer active" on their next open. A Connected process never expires automatically; withdrawal is the only exit, and the live-process cap is the standing pressure against abandoned connections.

**Rule 32 — Simultaneous reveal; the dashboard boundary.**
When both Walis have confirmed, the introduction appears to BOTH Seekers at the same moment, and each decides independently under all ordinary ZYRA rules. From that moment the Guardian Network page's involvement ends: Seeker-side progress renders on the Guardian Dashboard and never returns to this page.

**Rule 33 — Seeker consent controls.**
Three separate, prospective Seeker controls: (1) participate in Guardian Network — a Wali link alone never publishes a Seeker into the Network; (2) photo level (Rule 34); (3) pause recommendations — stops future serving without ending live processes. No control is ever bundled into another.

**Rule 34 — Photo levels.**
The Seeker chooses: show on the card (Rung 0) / show after the Walis connect (Rung 2) — **the DEFAULT** / never. Photo consent is separate from participation consent, independently changeable, prospective only. Where no photo is authorised at the current rung, the neutral seal renders with no gap or explanation disclosed.

**Rule 35 — Eligibility recheck at five checkpoints.**
`can_introduce()` and every related gate run at: card serving · request send · request acceptance · each Wali proceed · the final reveal. Any failure between checkpoints closes the process neutrally per Rule 27.

**Rule 36 — Calm delivery.**
No per-request push notifications. One badge count (unaccepted Incoming). At most one daily digest when unread incoming requests exist. Incoming lists oldest first. Notification and lock-screen copy carries zero Seeker identifiers — "You have a new Guardian Network request." is the model sentence.

**Rule 37 — Authority.**
Request connection, Connect with this family, Not for us, Withdraw, and Proceed to the Seekers are MAIN-Wali-only acts. Additional Guardians: view served recommendations, Save, Set aside, and advise their own family; their Connections view shows neutral status only ("handled by [Main]") with no reciprocal cards and no shadow channel. If the Main Wali changes before Rung 3 completes, open processes close as "No longer active"; the successor starts deliberately.

**Rule 38 — Entitlement.**
The Network page requires Guardian+ per Guardian: a linked Seeker's ZYRA One covers the MAIN Wali's access; an Additional Guardian requires their own Guardian+. Payment buys ACCESS only — authority remains Rule 37's regardless of who pays. WORKING RULE *(pricing wording to be mirrored into ZYRA_PRICING at its next bump)*.

**Rule 39 — No search, no enumeration.**
Guardians never query the population: no name/Guardian/family search, no enumerable profile URLs, no exports, no lookahead. The algorithm serves eligible families; that sentence appears in the product documentation and holds at every layer.

**Rule 40 — The live-process cap.**
Maximum THREE live Guardian Network processes per Seeker context, counting: Sent awaiting the other Wali · Connected (Rung 2) · awaiting proceed (Rung 3). Not counting: unaccepted Incoming · set-aside · closed · Rung-4-passed. Accepting an Incoming that would exceed the cap requires first closing a live process. The cap is identical for ZYRA Basic and ZYRA One — approach volume is never monetised.

**Rule 41 — Analytics at every stage.**
Every stage emits a tracked event — card_served, card_viewed, guardian_viewed, set_aside, restored, request_sent, request_withdrawn, incoming_reviewed, connected, not_for_us, proceed_confirmed, introduction_revealed, closure_seen — carrying Seeker-context, rung, and cause attributes. Server-side, permanent, privacy-safe: an analytics row never exposes cross-family identity beyond what the acting user already sees. In the UI draft, events log through a PROVISIONAL in-file tracker pending the real pipeline.

**Rule 42 — Naming.**
Exact strings: "Request connection" (opening action) · "Awaiting their Wali" (sender state) · "Connect with this family" (receiver accept) · "Connected" (established) · "Proceed to the Seekers" (final Wali action) · "No longer active" (every closed state) · "Set aside" (reversible pass) · "Not for us" (receiver's internal clear).

**Rule 43 — Supersession.**
Within Guardian Network, Rules 22–42 supersede the Family Introduction Request chain and the earlier ambiguous use of "Suggest" for cross-family action. Rule 20's own-Seeker Suggest is explicitly unchanged. The truncated 2026-08-22 contract (01_AGREED_RULES.md, rules 22+) is void; THIS document is the contract.

**Rule 44 — Build discipline for every draft.**
All mock data is in-file and marked PROVISIONAL; developer state switching is excluded from RELEASE builds (kReleaseMode-gated — available in debug and profile builds, because the Founder tests on-device unplugged, which requires profile mode on iPhone); no production permission is invented to make a mock work; the production (non-developer) path renders only the entitlement gate and empty states until the backend exists; every applied draft passes flutter analyze and receives a contradiction review against THIS contract before any "ready" claim (engine controls AC-6/AC-11).

---

## AMENDMENT — GN DRAFT 3 (Founder directive, 2026-08-23, applied same day)

The Founder's Dashboard/Network restructure ("dashboard is where everything lives about the user") changes WHERE two surfaces render, not what the model does. Binding deltas, register OA-ZYRA-248:

1. The Connections context (Incoming · Sent · Connected · History, with the live-count line) renders ON THE WALI DASHBOARD as its CONNECTIONS section (`GNConnectionsPanel`, `wali_gn_shared.dart`). The Network page is Discover only.
2. The top slider on BOTH pages is the Guardian's Seekers BY NAME (`GNSeekerSlider`) — the Discover/Connections view toggle is retired. A gold dot on a Seeker's chip marks waiting incoming requests (the calm-delivery spirit of the badge rule is unchanged: one quiet indicator, no identifiers pushed).
3. Seeker selection is ONE shared state (`GNContext`): choosing a Seeker on either page selects them on both. Per-Seeker context isolation is unchanged — the shared part is only WHICH context is open.
4. The Discover merge card's "Review request" no longer switches pages; it opens the incoming request in place (`showGNIncomingSheet`). The same request appears in the Dashboard's CONNECTIONS section — one state, two doors; the one-process-per-pair rule is unchanged.
5. The build-discipline rule's "mock data is in-file" now reads "in the GN library (`wali_gn_shared.dart`)" — one screen's file cannot feed two screens. All other discipline in that rule (PROVISIONAL marking, kReleaseMode gating, analyze gate, contradiction review) is unchanged, and the Dashboard renders NONE of this in release builds.

Rule numbering above is unchanged; where a rule's text says the "Connections view/page", read "the Dashboard's CONNECTIONS section". Draft 2.2 (v10) was superseded unapplied — its six feedback fixes are folded into Draft 3 (v11, `02_DRAFT_v11_dashboard_merge.dart`).

— END OF CONTRACT — Rule 44 of 44 —
