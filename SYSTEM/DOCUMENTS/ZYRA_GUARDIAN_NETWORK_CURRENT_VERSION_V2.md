---
id: DOC-ZYRA-0178
type: SPEC
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Network: Source of Truth
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Network: Source of Truth

**Version:** V2
**Status:** CURRENT_VERSION — mixed authority: **D14 (the interaction model, §D14 below) is RATIFIED 2026-08-23 and binding.** §marked **[APPROVED — EXISTING]** sections restate already-ratified rules and are binding now; §marked **[PROPOSED]** sections and the remaining **D-numbered decisions (D1–D13)** still await Founder ratification. Where an older section conflicts with D14, **D14 wins** — affected sections carry a supersession banner.
**Date:** 2026-08-23
**Owner:** Founder · **Author:** Fable (product rules / documentation, per the Founder's joint directive of 2026-08-22: Fable defines, Codex builds first-draft UI, then Phase-2 alignment)
**Supersedes:** ZYRA_GUARDIAN_NETWORK_2026-08-22_V1.md (archived). On ratification of the remaining D-list, the GUARDIAN NETWORK — ARCHITECTURE section of `WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` is superseded by this document (V6 keeps everything else).
**D14 provenance:** Founder-directed advisor debate (Fable ↔ ChatGPT, three rounds, 2026-08-23), joint recommendation ratified by the Founder in full ("Ratify all", R-a…R-g + clarifications). Record: `REPORTS/ARCHIVE/GN_MODEL_DEBATE_2026-08-23/`. Register: OA-ZYRA-247.
**Authority map:** this is the ONE Guardian Network product specification. `ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md` owns build obligations; `ZYRA_GN_HANDOVER_2026-09-19_V1.md` owns actual implementation. `APP/Guardian Network/GUARDIAN_NETWORK_2026-08-22_V1.md` is superseded history only.

---

## D14 — THE RATIFIED INTERACTION MODEL [RATIFIED 2026-08-23 — BINDING]

**One sentence:** the Guardian Network is a Main-Wali ↔ Main-Wali connection space where one family may respectfully approach another; nothing reaches either Seeker until both Walis have independently agreed, and then both Seekers receive the introduction at the same moment.

**The ladder (replaces the §7 FIR chain within Guardian Network):**

| Rung | Name | What happens |
|---|---|---|
| 0 | Recommendation | Algorithm serves ONE family at a time for the selected Seeker context. No browsing ahead, no search, no enumeration — **Guardians never query the population; the algorithm serves eligible families** (ratified restatement of §1/§12). Card: initial · age · region · band · relationship label · verified badge · photo per the Seeker's photo level (below). Actions: **View · Set aside · Request connection** |
| 1 | Request connection | Main Wali sends (live-process cap below). Receiving Main Wali sees it in Connections → Incoming with the reciprocal privacy-matched card; sender sees "Awaiting their Wali". Receiver: **Connect with this family** (accept) or **Not for us** (internal clear, never shown to sender). A pending reverse request acts as acceptance — one process per Seeker pair, and Discover merges a would-be card with its pending incoming request ("This family has already requested connection" → Review request) |
| 2 | Connected | Reciprocal, simultaneous, consent-limited unlock: verified Main-Wali profile · relationship · region · verification status · the Seeker's ordinary Browse-level profile · photo per photo level · structured exchange (no free text — D6 unchanged). Never: contact details, exact location, private answers, numeric scores, network membership, message/safety/Journey history, response-speed indicators |
| 3 | Proceed to the Seekers | Each Wali confirms independently; either may withdraw first (silent, reasonless; the other side's state updates honestly on next open). Connected processes never auto-expire |
| 4 | Simultaneous introduction | Both Seekers receive it at the same moment and decide independently under all ordinary rules. Seeker-side progress lives on the Guardian Dashboard — never on this page |

**Silence discipline (replaces §12.7 cooldown draft):** default decline is silence — 14-day quiet expiry; sender sees only **"No longer active"**, one external state for every internal cause (decline · expiry · withdrawal · eligibility failure · Main-Wali change · safety). No reasons, no decline notifications, nothing to either Seeker, ever. After a first expiry the ORIGINAL INITIATING side waits 90 days (Wali-switch-proof; the receiving family is never blocked from approaching in the other direction). Second expiry, or an explicit "Not for us" → 6-month pair cooldown, both directions, Wali-switch-proof.

**Live-process cap:** maximum **3 live Guardian Network processes per Seeker context** — counting Sent-awaiting + Connected + awaiting-proceed; NOT counting unaccepted Incoming, set-aside, closed, or Rung-4-passed. Accepting over cap requires closing one first. **Identical for Basic and ZYRA One — approach volume is never monetised** (ZYRA One may add insight/tools later, never pressure volume).

**Access ends with the process:** on any closure, reciprocal profile access, structured exchange and photo serving end; history keeps only initial · region · date · "No longer active"; nothing reopens from history. Honesty clause: what was seen cannot be unseen — ZYRA simply stops serving it.

**Seeker consent controls (three, separate, prospective):** participate in Guardian Network (a Wali link alone never publishes a Seeker here) · photo level — **card / after-the-Walis-connect (DEFAULT) / never** · pause recommendations. Photo consent is separate from participation consent and changeable prospectively.

**Eligibility recheck:** `can_introduce()` and all gates run at serve, send, accept, each proceed, and reveal; any failure closes the process neutrally.

**Calm delivery:** no per-request push; one badge (unaccepted Incoming); at most one daily digest; oldest first; notification copy carries zero Seeker identifiers ("You have a new Guardian Network request.").

**Authority:** send/accept/withdraw/proceed are Main-Wali-only (D7 direction confirmed). Additional Guardians: view, set aside, advise inward; Connections shows them neutral status only ("handled by [Main]") — no reciprocal cards, no shadow channel. A Main-Wali change closes open processes as "No longer active"; the successor starts deliberately.

**Entitlement (Founder clarification 2026-08-23):** the Network page requires Guardian+ per guardian. A linked Seeker's ZYRA One covers the **Main Wali's** access; Additional Guardians need their own Guardian+ (£24.99/mo or £14.99/wk — ZYRA_PRICING_CURRENT_VERSION_V2, mirrored 2026-08-23) — payment buys ACCESS, never authority.

**Surface layout (Founder directive, 2026-08-23 — GN Draft 3):** the WALI DASHBOARD is the home of everything about the user. The Connections context (Incoming · Sent · Connected · History, with the live-count line) renders there as the Dashboard's CONNECTIONS section; the Network page is Discover only. The top slider on BOTH pages is the Guardian's Seekers by name; Seeker selection is one shared state — select on either page and the other follows. The Discover merge card reviews an incoming request in place. Build record: contract amendment "GN DRAFT 3", `wali_gn_shared.dart`, OA-ZYRA-248.

**Set aside (replaces "Pass" in Guardian Network):** reversible; manual restore anytime from a quiet secondary entry under Discover; algorithm may re-serve after 30 days, only while eligible, never recycling while fresh eligible families remain. Connected families never re-serve.

**Analytics (Founder requirement 2026-08-23):** every stage emits a tracked event — card_served · card_viewed · guardian_viewed · set_aside · restored · request_sent · request_withdrawn · incoming_reviewed · connected · not_for_us · proceed_confirmed · introduction_revealed · closure_seen — with Seeker-context, rung, and cause attributes; server-side, privacy-safe (no cross-family identity leakage in analytics rows beyond what the actor already sees).

**Supersession within this document:** the D14 ladder supersedes the §7 "Family Introduction Request" chain and its states in §14; the §6 photo row; the §12.7 cooldown draft; the §13 incoming-FIR notification tier (now Standard + digest). "Suggest to Seeker" is UNCHANGED — a private advisory nudge to one's OWN Seeker, never a cross-family act. D1–D13 remain open; where D5/D8 overlap D14, D14 governs the Guardian Network and the remainder of those decisions stays open.

**Naming (ratified):** Request connection → Awaiting their Wali → Connect with this family → Connected → Proceed to the Seekers → No longer active · Set aside.

---

## 0. Sources reviewed, and how to read this document

Reviewed in full or in relevant part before a word was written:
`WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` (incl. its approved GUARDIAN NETWORK — ARCHITECTURE section, 2026-07-04) · `WALI_REQUIREMENT_AND_ACCESS_POLICY_CURRENT_VERSION_V1.md` (PROPOSED) · `ZYRA_GUARDIAN_ROMANTIC_RULES_CURRENT_VERSION_V1.md` (incl. §7d visibility closure) · `ZYRA_GUARDIAN_VISIBILITY_AND_TRUST_MODEL_V1_DRAFT.md` · `ZYRA_COUNTERPART_CARD_SPEC_DRAFT_2026-08-08.md` · `ZYRA_TRUST_MODEL_ADVERSARIAL_PASS_2_2026-08-08.md` · `ZYRA_GUARDIAN_SURVEILLANCE_AUDIT_2026-08-08.md` · `ZYRA_DUAL_ROLE_ARCHITECTURE_REVIEW_CURRENT_VERSION_V1.md` (CLOSED) · `ZYRA_DUAL_ROLE_LINKING_MATCHING_RULES_FOR_REVIEW_2026-08-07.md` · `ZYRA_RELATIONSHIP_MATRIX_COMPLETENESS_AUDIT_2026-08-08.md` · `ZYRA_GUARDIAN_OPEN_TOPICS_CURRENT_VERSION_V1.md` · `ZYRA_JOURNEY_ENTITLEMENT_DECISION_CURRENT_VERSION_V1.md` · `ZYRA_NOTIFICATION_SPECIFICATION_CURRENT_VERSION_V1.md` · `JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V4.md` · `BROWSE_UX_SPEC_CURRENT_VERSION_V4.md` · `ZYRA_PRICING_CURRENT_VERSION_V1.md` · `ZYRA_ACCOUNT_TYPE_UX_REVIEW_CURRENT_VERSION_V1.md` · `SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md` · `ZYRA_GOVERNANCE_CURRENT_VERSION_V4.md` · Decision Register entries DR-075/076, DR-ZYRA-081/083/086/095/097/104/105/106/107/110/111/123/124/136/137/140/152/157/160/165/171 · `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md` (relationship lifecycle).

**The single most important finding:** Guardian Network is NOT a blank page.
An architecture was ratified 2026-07-04 inside WALI_ARCHITECTURE (cards,
flow, tabs, entitlement gate, seeker-level filtering), a Guardian home shell
with a Network tab already exists in the app behind the Guardian+ gate, the
`wali_suggestions` table and the Seeker-side Introductions card UI already
exist, and the eligibility predicates (`zyra_can_match`, Tier-0/Tier-1,
blocks) are already live in RLS. This document therefore does three things:
restates what is already decided (so Codex builds against it, not around
it), reconciles the contradictions that have grown between documents
(§15), and isolates the genuinely new decisions for the Founder (§16).

---

## 1. Purpose — [APPROVED — EXISTING, restated with new precision]

**Guardian Network is the family channel of ZYRA: the surface where a
Guardian searches on behalf of a Seeker they represent, and where two
families — through their Guardians — agree that an introduction is worth
presenting to their Seekers.**

It exists to do what Seeker Browse cannot:

1. **Family-first discovery.** In the families ZYRA serves, marriages are
   often explored guardian-to-guardian before the two people ever speak.
   Browse cannot express that; the Network is that path made first-class.
2. **Representation for low-agency Seekers.** A Seeker who does not want to
   swipe — or whose family leads the search — is still fully served: their
   Guardian works the Network on their behalf, inside their rules (§3).
3. **A modest first contact.** Guardian↔Guardian agreement precedes any
   Seeker-to-Seeker exposure, preserving gender separation at the first
   step in a way Browse structurally cannot.
4. **A second pair of eyes — inside the fence.** The Guardian may surface
   candidates the Seeker's own browsing missed, but only from within the
   Seeker's own stated boundaries. Wisdom is added; authority is not moved.

**What Guardian Network must never become** (Founder's list, each bound to
the control that prevents it):

| Must never be | Prevented by |
|---|---|
| A second Seeker Browse | Guardian browses ONLY as agent-of-a-linked-Seeker; no seeker context → no feed (§4); Browse remains Seeker-only (DR-076, PROFILE DECISION SYSTEM) |
| A searchable directory / enumeration of people or families | No name search, no free query, no username lookup — the feed is a ranked recommendation list only; batch oracles capped (I10); never reveals who else is in anyone's network (Adversarial Pass 2 §3) |
| A way around Seeker preferences | Eligibility = the Seeker's own engine result (§2–3); Guardian cannot cross hard filters |
| A way around blocks | `zyra_can_match` (blocks both directions) is a hard gate at every Network action (§2, §9) |
| A gender-segregation bypass | Card exposure is minimal pre-introduction (§6); the represented Seekers' gender complementarity is a hard filter; the Guardian's own gender grants nothing |
| A surveillance surface | Notification digest rule P2; no browse-activity of anyone is shown (DR-104 boundary); audit trail + Seeker-visible sharing record (§8); "support and guidance, not surveillance" is the governing principle of the whole Guardian system |

---

## 2. Eligibility — who can appear, for whom — [APPROVED mechanics, PROPOSED completions]

**The rule that outranks the table: Guardian Network eligibility can never
be weaker than the systems it feeds** (Founder §9 requirement — met by
construction: the same predicates gate both).

A card for Seeker **B** (represented by Guardian **G_B**) appears in the
feed Guardian **G_A** sees for their Seeker **A** only if ALL of:

| # | Gate | Class | Source of enforcement | Authority |
|---|---|---|---|---|
| E1 | `zyra_can_match(A, B)` is TRUE — gender complementarity, not same person, both Seekers, no block either direction, no Guardian link either way (Tier-0), no shared Guardian (Tier-1, active-or-removed) | **HARD FILTER** | live predicate, already in RLS | APPROVED (DR-ZYRA-123/124, Romantic Rules §1) |
| E2 | B is Browse-visible to A under ordinary rules — active, published, not hidden | **HARD FILTER** | Adversarial Pass 2 A3: an introduction must never surface someone who has made themselves unreachable | APPROVED principle, unbuilt predicate |
| E3 | G_A holds an active `wali_links` row to A; G_B holds one to B | **HARD FILTER** | `wali_links` status='active' | APPROVED (existing linking system) |
| E4 | B has Network consent ON (C3, §8) | **HARD FILTER** | consent record — unbuilt | PROPOSED (D1) |
| E5 | A's hard requirements and dealbreakers are satisfied by B, and B's by A — the same seeker-level compatibility filtering Browse uses, both directions | **HARD FILTER** | compatibility engine | APPROVED (WALI_ARCH: "same engine, hard requirement rules and visibility logic as Browse", seeker-level filtering principle) |
| E6 | Neither A nor B is under a safety hold / suspension | **HARD FILTER** | safety system; silence rule P4 — a held profile simply does not appear, with no distinguishable gap | APPROVED (Safety system, Notification spec P4) |
| E7 | B is journey-available (not in an Active Journey; paused occupies the slot per DR-140 as it does everywhere) | **HARD FILTER** for feed inclusion | matches state | PROPOSED default (D8 notes the alternative: show with 🔴 Unavailable per DR-097) |
| E8 | Guardian availability — G_B's account in good standing | **HARD FILTER** | account status | APPROVED (trivially) |

**Classification of the Founder's §2 input list:**

| Input | Class |
|---|---|
| Gender | HARD FILTER (E1) |
| Age | HARD FILTER where the Seeker set a bound; RANKING inside the band |
| Country / location | HARD FILTER where the Seeker requires it; RANKING otherwise |
| Distance | RANKING SIGNAL only (no GPS precision on cards, ever) |
| Background / ethnicity | OPTIONAL FILTER if the Seeker set a preference; RANKING otherwise — never Guardian-settable beyond the Seeker's own setting |
| Languages | RANKING SIGNAL |
| Religious practice | HARD FILTER where the Seeker marked it a dealbreaker; RANKING otherwise |
| Marriage preferences | HARD FILTER (dealbreakers) / RANKING (soft) |
| Children / family preferences | same split |
| Education / work preferences | RANKING SIGNAL (OPTIONAL FILTER if Seeker set one) |
| Compatibility | RANKING SIGNAL — the engine's score, one question = one contribution (DR-ZYRA-211); displayed only as a band (§6) |
| Hard dealbreakers | HARD FILTER, absolute, Guardian cannot widen (§3) |
| Journey availability | HARD FILTER (E7) |
| Existing relationship state | HARD FILTER via E1 + §9 table |
| Guardian availability | HARD FILTER (E3/E8) |
| Safety eligibility | HARD FILTER (E6) |
| **NOT USED, ever:** raw Chapter 3/4 answers (never leave the Seeker), anyone's Browse activity or Save/Consider/Pass history (DR-104 boundary), last-active times, message content, journey stage detail of any existing Journey (DR-097: availability status is the only journey fact ever surfaced about anyone) | NOT USED |

**The Guardian algorithm invents no marriage criteria of its own** — every
gate above is either the Seeker's own setting or a platform safety rule.

### The enforcement predicate — `can_introduce()` [PROPOSED formalisation of an approved concept]

Romantic Rules §1 names `can_introduce()` as the third predicate
(unbuilt). Adopting Adversarial Pass 2 A3, this document proposes its
definition — the server-side gate for EVERY Network act (feed inclusion,
suggestion, introduction request):

```
can_introduce(G, S, C)  ⇔      -- Guardian G, own Seeker S, candidate C
      active_wali_link(G, S)
  AND zyra_can_match(S, C)
  AND can_view_under_browse_rules(S, C)      -- A3: no surfacing the unreachable
  AND network_consent(C)                     -- C3, §8
  AND network_consent(S)                     -- S's own card is in play too
```

Symmetric across the introduction: the request is only deliverable if
`can_introduce(G_B, B, A)` also holds at delivery time. Checked at
**every** state transition, not once (Romantic Rules §6 discipline).

---

## 3. Seeker preferences vs Guardian discovery — [PROPOSED, with the Founder's instinct confirmed]

**The Founder's starting instinct stands, and the review strengthens it:
the Guardian searches as the Seeker's agent, so the Seeker's requirements
govern eligibility.** An agent's authority derives from the principal. The
approved architecture already encodes this — the Network runs the same
seeker-level engine as Browse; there has never been a "Guardian preference"
input anywhere in the ratified model.

Precisely:

- **Hard requirements and dealbreakers: the Guardian can never widen
  them.** Not with a toggle, not "just to see". A candidate outside the
  Seeker's hard boundary does not exist in that Guardian's feed (E5).
- **Soft preferences: the engine ranks rather than excludes** — exactly as
  in Browse — so the Guardian naturally sees some lower-ranked-but-eligible
  people deeper in the feed. That IS the legitimate "widening": more
  patience, not more permission.
- **A "show near-matches outside soft preferences" Guardian toggle is NOT
  built in v1** (D3). If ever built, every such card is flagged, and the
  flag survives into what the Seeker sees ("outside your stated
  preference") — the Guardian can advocate, never smuggle.
- Where the Founder ultimately wants the balance is D3; the recommendation
  is the strict version above.

---

## 4. Multi-Seeker context — [APPROVED mechanics + PROPOSED precision]

The system must always answer: **"who am I searching for right now?"**

- The Network is **always scoped to exactly one Seeker context**. There is
  no "all my Seekers" feed — a merged feed is how a catalogue starts and
  how a wrong-seeker suggestion happens.
- One eligible linked Seeker → that context auto-selected, selector shows
  as a single label (Codex: works elegantly with one).
- Multiple → explicit selector; switching swaps feed, saved list, passed
  list, counts — ALL per-seeker state (§7).
- The approved introduction rule already ratifies the shape (WALI_ARCH):
  one eligible Seeker → auto-attributed introduction ("This introduction
  will be sent on behalf of [Name]"); two or more eligible → mandatory
  selection; **maximum one Seeker per introduction request**; gender
  matching automatic.
- A Guardian whose selected Seeker has Network consent OFF sees the
  neutral empty state GN-CONSENT-OFF (§14) — no history of declines, no
  pressure surface (§12.9).

---

## 5. What is discovered — the model — [APPROVED, restated; refinement PROPOSED]

The Founder's §5 asks MODEL A (Seeker directly) / B (Guardian) / C
(combined family card) / D (other). **The ratified architecture already
answers this, and the answer is a precise hybrid — recorded here so
neither Fable nor Codex re-invents it:**

> **The unit of discovery is a represented Seeker: a system-controlled
> Seeker card carrying its family context ("Guided by her father ·
> Verified Guardian"). The unit of contact is Guardian↔Guardian.**

That is: discovery LOOKS like Model C (Seeker + family context on one
card), and action ROUTES like Model B (Family Introduction Request goes to
the other Guardian, never to the Seeker). Both Seekers only ever consent
through their own Guardian's mediation, and nothing reaches either Seeker
until both Guardians have agreed (then BOTH Seekers decide, independently
— consent chain in §7).

Consequences already ratified with it (WALI_ARCH, seeker-level filtering
principle): visibility, filtering and introductions are **per Seeker
card**, never per Guardian — a Guardian with three wards may show two
cards to one viewer, one to another, none to a third; if no ward passes,
that family simply isn't present for that viewer. A Guardian is never
independently discoverable — **only through an eligible ward's card** —
so the Network cannot be used to enumerate Guardians either.

**By construction, both sides are Guardian-represented.** Un-represented
Seekers are neither discoverable in the Network nor able to receive
Network introductions; they remain reachable through Browse alone. (This
follows from the flow — every step is Guardian-to-Guardian — and is
stated here explicitly because it is the property that makes the Network
a family channel rather than a directory. D4 asks the Founder to ratify
it as a named rule.)

---

## 6. Information visibility — the card — [partly APPROVED, field list is D2]

**Progressive disclosure ladder** (each rung is an existing, ratified
stage — the Network adds ONE rung at the bottom, it does not reorder the
ladder):

| Rung | Surface | Governed by |
|---|---|---|
| 0 | **Network Discover card** (pre-everything) | THIS document, D2 |
| 1 | Introduction request card (what G_B sees of A when a request arrives) | same field set as rung 0 — a request adds intent, not data |
| 2 | Seeker sees suggested profile (post both-Guardians-agree) | existing profile visibility rules — the ordinary Browse-level card |
| 3 | Potential → Active Journey | existing trust-model matrix (wali_gate etc.) |
| 4 | Post-`wali_gate` counterpart card between Main Guardians | existing `zyra_counterpart_card()` — Main-only, uniform, no city, no photo |

**Approved v1 card content** (WALI_ARCH, 2026-07-04): Seeker initial
("K."), age, city, Guardian relationship ("Guided by his father"),
Verified Guardian badge. **100% system-controlled: no free text, no
biographies, no Guardian-added anything** — free text is a privacy
loophole and stays banned (APPROVED, restated verbatim in intent).

**However — two later, harder-won rules collide with that field list**
(contradiction C2, §15): the counterpart card work removed CITY from what
even a post-gate Main Guardian sees, and the Opus/Fable field test flagged
city as "the single most useful field for locating someone in a community
that hides being on the app". A pre-introduction surface showing MORE
location than the post-gate surface would invert the ladder.

**Proposed field list for D2** (uniform for everyone — per-user field
choice leaks by its sparseness; all-or-nothing only, per Counterpart Card
§4.2):

| Field | On card? | Reasoning (test: needed to decide whether families should talk?) |
|---|---|---|
| First-name initial | ✅ | approved; you can discuss "K., 27" without naming her to the world |
| Age | ✅ | approved; material fact, already disclosed via `ages_for` discipline |
| Location — **region/country, NOT city** | ✅ coarsened | keeps the genuine assessment value, removes the locating value; city arrives at rung 2 with the Seeker's ordinary profile |
| Guardian relationship ("Guided by her father") | ✅ | approved; the family context IS the product |
| Verified badge | ✅ | approved |
| Availability dot (🟢 only — unavailable people are filtered, not shown grey) | ✅ | DR-097: availability is the only journey fact ever shown |
| Compatibility **band** (e.g. High / Good), never a number | ✅ | the core "why am I seeing this" signal; band not number so it can't be reverse-engineered toward Ch3/4 answers |
| Practice summary chip (the Seeker's own headline self-description, from existing profile fields — not Ch3 answers) | D2 asks | genuinely used by families; comes from data already Browse-visible |
| Photo | **Seeker-controlled (D14, ratified)** — three levels: show on the card / show after the Walis connect (**default**) / never | D14 supersedes the earlier blanket never-at-rung-0. C4 stays a separate, revocable consent; changes are prospective; the surveillance concern is answered by the default sitting at rung 2 and the Seeker owning the choice |
| Name, city, occupation detail, Ch3/4 anything, other Guardians in the family, network membership of anyone | ❌ never | over the line at this rung; some never at any rung |

**Recommendation-reason chips** (Codex's "Why am I seeing this?"): system-
generated, from a fixed taxonomy only — "Within [Name]'s preferences" ·
"High compatibility" · "Also speaks Urdu" · "Practising" · "Nearby region".
Never free text, never a preference the Seeker didn't set.

---

## 7. Actions — **[SUPERSEDED IN PART BY D14 (ratified) — the ladder in §D14 governs; this section retained for history and for the parts D14 keeps]**

**D14 v1 action set: View · Save · Set aside · Suggest to [Seeker] · Request connection** — the FIR flow below is retired within Guardian Network; "Suggest to Seeker" and the View/Save rows remain accurate. (Guardian↔Guardian free-form contact is
deliberately NOT in v1 — D6 unchanged; the pending Family-Stage communication spec
owns that question.)

| Action | Initiator | Receives | Consent required | What is revealed | Notification | After accept | After refuse/ignore |
|---|---|---|---|---|---|---|---|
| **View** (open card) | Guardian | nobody | none new (card is consented via C3) | card fields only (§6) | none — views are never notified | — | — |
| **Save** | Guardian | nobody | none | nothing leaves the Guardian's device-side list | none | private per-Seeker shortlist | removable anytime |
| **Pass** | Guardian | nobody | none | nothing | none | card leaves feed for THIS Seeker context; sits in a reversible Passed list | reversible; re-eligible on undo |
| **Suggest to Seeker** | Guardian | own Seeker | Seeker decides; suggestion is NEVER consent (approved principle) | Seeker sees the rung-2 profile via the EXISTING Introductions card (`wali_suggestions` + DR-157/160 card: Pass/Save/Consider + View Profile) | Seeker: standard-tier feed item (P2: no push) | Seeker may Consider — which routes into the ordinary mutual-interest flow, all existing caps apply | Seeker declines → Guardian sees "declined", never why; repeated re-suggestion of the same person is capped (§12.7) |
| **Family Introduction Request (FIR)** | Guardian A (Main — D7) | Guardian B (Main) | **Seeker A approves BEFORE it sends** (C5 outbound: it transmits A's card); Guardian B consults Seeker B in-app — Seeker B's accept IS the B-side per-introduction consent | Guardian B sees Seeker A's rung-1 card; nothing of B moves yet | G_B: Time-Sensitive (expires); Seeker B: consent request | Both Guardians agreed + both Seekers accepted → introduction completes: the two Seekers see each other's rung-2 profiles and may proceed to mutual interest → Potential Journey under ALL ordinary rules (`zyra_can_match` re-checked at creation) | Declines are final for that pairing for a cooldown (§12.7); expiry after 14 days = quiet lapse, standard-tier notice to sender only ("expired", not "refused") |

**The consent chain, reconciled** (this merges the approved WALI_ARCH flow
with the proposed access-policy C5 — the two differ on WHEN Seeker A
consents; recommendation: the stricter compose):

```
G_A sees B's card (B consented C3)
  → G_A asks Seeker A                       [C5-outbound: A approves her card travelling]
  → FIR sent to G_B
  → G_B reviews A's card, consults Seeker B [B's in-app accept = C5-inbound]
  → both Guardians + both Seekers have now each said yes, independently
  → introduction complete → ordinary ZYRA flow (rung 2 → mutual interest
    → Potential Journey → Ritual → Active), nothing skipped
```

**Guardians agree an introduction is worth presenting. They never accept
on anyone's behalf. Seeker consent precedes every Journey. [APPROVED —
verbatim principle.]**

---

## 8. Consent & Seeker authority — [C-model PROPOSED (D1); authority rules APPROVED]

Adopting the access policy's consent architecture (C1–C5) for the Network:

- **C3 — "my profile may appear in Guardian Network": separate consent,
  opt-in, DEFAULT OFF.** Never bundled into Guardian linking. (The 2026-07-04
  text bundled it into link-time T&C — superseded on ratification;
  contradiction C3 in §15. Bundling several purposes into one consent is
  exactly what UK GDPR Art. 7 disallows, and profile data here is Art. 9
  special-category.)
- **C4 — photo sharing: separate again, independently revocable** — and per
  §6, photos never appear at rung 0 regardless.
- **C5 — per-introduction approval** — built into the chain above.
- **Revocation is instant, unilateral, and purges**: card leaves every
  feed, open FIRs carrying it lapse, cached/signed URLs die. Revocation is
  not a negotiation with the Guardian.
- **The Seeker can always see their own Network presence**: preview of
  their card exactly as others see it, the list of introductions made on
  their behalf and to whom, and the consent switches (D12). A network you
  cannot see is one you cannot meaningfully consent to.
- **Audit trail**: who was shown what, when — required for Article 15 and
  for complaints (server-side; never surfaced to other users).

**Seeker authority rules** (Founder §8 list — each already grounded):

| Rule | Status |
|---|---|
| Guardian cannot create a match for the Seeker | APPROVED — matches arise only from the Seekers' own mutual interest; nothing in the Network writes a match |
| Guardian cannot start a Journey for them | APPROVED — promotion requires the Seekers; Guardian Gate requires Guardians but never substitutes for Seekers (DR-ZYRA-105: participation ≠ entitlement, and neither replaces Seeker consent) |
| Guardian suggestion is not consent | APPROVED — suggestion lands as an Introductions card the Seeker freely Passes |
| Seeker can decline, without explanation reaching anyone | APPROVED + P-rules: decline reasons are never disclosed |
| Guardian cannot bypass Seeker filters/dealbreakers | §3, absolute |
| Existing blocks / safety restrictions always win | APPROVED — I2 (block is terminal), E1/E6; a block extinguishes Network visibility both ways instantly |

---

## 9. Cross-check against existing relationship architecture — [APPROVED, mapping]

| Existing system | Network interaction |
|---|---|
| Matches / Potential Journeys | Network never creates one directly; completed introduction feeds the ORDINARY pipeline; FIR-completed pairs still require mutual interest; `zyra_can_match` re-checked at every write (Romantic Rules §6) |
| Active Journey | E7: a Seeker in one is not discoverable and their Guardian's Network context for them is paused (GN-CAPACITY) |
| Paused Journey | occupies the slot (DR-140) → same as Active for E7 |
| Ended Journeys + restart history | an ended pair is matchable again only through ordinary rules; the Network gets no special power to re-introduce a pair whose history says otherwise; restart flows stay where they are |
| Guardian links | Tier-0 (E1): a Guardian and any of their own wards can never appear to each other, in any direction, ever |
| Shared Guardian | Tier-1 (E1): co-warded pairs never appear (active OR removed links, per DR-123) |
| Romantic history ↔ Guardian bond | `zyra_can_guardian_link` forbids linking over any match incl. ended — unchanged; the Network adds no path around it |
| Blocks | terminal (I2); either-direction block removes both parties from each other's Network world instantly and silently |
| Protection holds | P4 silence — no gap, no trace, no distinguishable absence |
| Dual-role identities | one identity, contexts separated (CLOSED review); §12.5 covers the cross-context risk |
| `can_match` / `can_guardian_link` | consumed as-is; `can_introduce` (§2) composes them and adds A3 + consent — strictly TIGHTER than everything it feeds |
| Main vs Additional | is_main is an existing privilege boundary (7d closure) — §10 extends it to Network actions |

---

## 10. Main vs Additional Guardian — [PROPOSED (D7), aligned to existing boundaries]

| Capability | Main Guardian (Guardian+) | Additional Guardian (Guardian+) |
|---|---|---|
| See the Network feed for the Seeker | ✅ | ✅ |
| Save / Pass (advisory shortlisting) | ✅ | ✅ (own advisory lists) |
| Suggest to the Seeker | ✅ | ✅ — advice is what an Additional Guardian is FOR; the Seeker's own consent is the control |
| Send a Family Introduction Request | ✅ | ❌ — official family representation is a Main act (matches Family Review, Guardian Gate, counterpart card: every designed layer already treats Main as the authority boundary) |
| Receive / accept an incoming FIR | ✅ | ❌ (visible as "handled by [Main]" — no shadow channel) |

Standard (non-Guardian+) Guardians: no Network access at all — existing
ratified gate. (Terminology note: WALI_ARCH V4-V6 also defines a
per-Journey "Primary Guardian" designation that nothing in the build
implements — contradiction C5, §15. This document binds Network authority
to **Main** (`wali_links.is_main`), the concept every live subsystem uses.)

---

## 11. ZYRA Basic / ZYRA One / Guardian+ — [gate APPROVED; caps PROPOSED (D8)]

- **Network access requires Guardian+** — ratified, already gated in-app.
  Guardian+ arrives bundled with a linked Seeker's ZYRA One or bought
  independently (£24.99/mo · £14.99/wk, repriced 2026-08-23, ZYRA_PRICING V2); behaviour identical (AD-081). No change.
- The gate screen must distinguish **not-entitled / entitled-but-unlinked /
  entitled-and-linked** (DR-ZYRA-111's ratified messaging rule; the current
  screen's single-variable gate is the known bug OA-ZYRA-142).
- **No new plan-gated Network features are invented for upsell** (Founder's
  own constraint). The one real capacity rule REUSES existing entitlements:
  a completed introduction leads to the Seeker's ordinary mutual-interest
  flow, which already counts against the Seeker's outstanding-interest cap
  (ZYRA Basic 1 · ZYRA One 5, Journey Entitlement Decision). Recommended
  addition (D8): outstanding FIRs per Seeker count toward that same cap —
  one shared budget, no second meter, and Network pressure cannot exceed
  what the Seeker's own plan permits.
- Recommendation quantity / saved-list size: NOT plan-gated in v1. A single
  universal feed size (e.g. refreshed daily) is a product-quality choice,
  not an entitlement.

---

## 12. Abuse & safety modelling — [each vector bound to a control]

| # | Vector (Founder §12) | Control |
|---|---|---|
| 1 | Guardian harvesting profiles | No search; ranked feed only; rung-0 card is initial+age+region — deliberately not worth harvesting; no photos at rung 0; audit trail; screenshots addressed honestly in Terms (§5.1 of access policy: once visible to a human, technical control ends — so the control is what the card contains) |
| 2 | Guardian accumulating unrelated Seekers | Existing: ward-count disclosure at link time (DR-ZYRA-123 D2 — "Guardian to 14 others" shown to every Seeker deciding to accept); linking needs Seeker consent; institutional-guardian class deferred (DR-123) but the Network adds no new accumulation power |
| 3 | Family enumeration | The feed never reveals who else is in ANY family's network; introductions do not compose into a map (Adversarial Pass 2 §3); Guardians not independently discoverable (§5); no ward lists on cards |
| 4 | Gender bypass | Card minimalism + E1 complementarity + Guardian gender grants nothing; the Guardian sees only cards eligible FOR THEIR SEEKER, not a gender-filtered directory of their own choosing |
| 5 | Guardian discovers someone, later pursues them as a Seeker (dual-role) | Deliberate Network ACTS (Suggest, FIR) are permanently recorded → recommended permanent `can_match` exclusion between the acting Guardian and that candidate (D11) — permanent consequence anchored on permanent data (I1-compliant). Passive views: audit-logged, not exclusion-bearing (a view is transient data; I1 forbids hanging permanence on it). Tier-0 already covers own wards forever |
| 6 | Guardian observing both sides of one introduction | Tier-1 makes co-warded pairs ineligible (E1), so no Guardian can ever legitimately stand on both sides; dual-role contexts are separated; the audit trail exists for the residue. The §1 honesty rule from Adversarial Pass 2 stands: what a human learns cannot be unlearned — the model bounds what a Guardian must know to do the job, only about families genuinely engaged with |
| 7 | Repeated unwanted introductions | **D14 (ratified) governs:** silence discipline 14d expiry / 90d initiator wait after first expiry / 6-month pair cooldown on second expiry or explicit "Not for us", Wali-switch-proof both directions; live-process cap 3; Seeker-declined suggestion cooldown unchanged; all caps server-side |
| 8 | Searching for a known individual | No search of any kind; feed composition is engine-ranked; region-not-city on cards removes the locating field; batch oracles capped (I10) |
| 9 | Consent pressure on the Seeker (implicit vector) | GN-CONSENT-OFF state is neutral — no decline history shown, no "ask again" button; C3 revocation silent to the Guardian beyond the card's disappearance |
| 10 | Block bypass | E1 at every transition; a block mid-flow lapses every open Network object between the pair, silently, both directions (I2/I3 discipline — one ending path) |
| 11 | Multiple-account abuse | One-identity model + verification badge; unverified Guardians' reach is a D9 lever (recommend: unverified Guardians can View only — no Suggest/FIR) |
| 12 | Screenshots / cached info | Cannot be prevented; therefore the card contains only what survives a screenshot harmlessly (initial, age, region, relationship). Terms bind receiving Guardians as data recipients (no saving/forwarding). Purge-on-revocation kills URLs, not memories — stated honestly |
| 13 | Guardian collusion (two Guardians trading access) | Everything each Guardian sees passes the OTHER side's Seeker-level eligibility + consent; there is nothing to trade that consent did not already grant; audit trail attributes every disclosure |

**Notification side-channel rule** (Adversarial Pass 2 A2, binding here):
no Network notification body ever contains more than the recipient's
already-visible rung permits. Names never appear in bodies about pre-rung-2
events ("A family has responded", not "Guardian Hassan declined").

---

## 13. Notifications — [governed by the ratified Notification Specification]

P1–P4 and S1–S5 of `ZYRA_NOTIFICATION_SPECIFICATION_CURRENT_VERSION_V1.md`
apply unchanged. In particular **P2: a Guardian receives a digest, not a
stream.**

| Event | Recipient | Tier |
|---|---|---|
| New recommendations in feed | Guardian | **No notification at all.** Pull surface + at most a weekly digest line. Anything more is surveillance-cadence |
| Seeker responded to your suggestion | Guardian | Standard (feed) |
| Incoming connection request | Guardian (Main) | **Standard + at most one daily digest (D14 calm delivery)** — badge count in-app; no per-request push despite the 14-day expiry |
| Your request's state changed ("No longer active" / Connected) | Guardian (Main) | Standard; body carries the neutral state only, never reasons |
| Consent needed (approve your card travelling / respond to an introduction) | Seeker | **Time-Sensitive** (deadline-bearing) |
| Guardian suggested someone | Seeker | Standard — the existing Introductions surface, not a push |
| Introduction completed → profiles visible | both Seekers | Standard |
| Anything about a protection hold, safety ending, decline reason | anyone | **Never** (P4, S1–S4) |

Implementation note (not a rule): `notifications.type` has a hard CHECK of
three values; Network events need new types — a deliberate migration, per
the constraint's own comment, never a workaround.

---

## 14. States & edge cases — named for Codex — [PROPOSED naming, behaviour mostly forced]

| Code | State | Behaviour |
|---|---|---|
| GN-LOCKED-NOENT | Guardian without Guardian+ | existing upsell, three-variant per DR-111 (not-entitled) |
| GN-LOCKED-UNLINKED | Guardian+ but zero linked Seekers | "your subscription is active; Network opens when a Seeker is linked" — never an upsell (DR-111) |
| GN-NO-SEEKER | no eligible Seeker in context (e.g. all wards are the wrong… none pass E-gates) | explain plainly which precondition is missing, without disclosing another person's state beyond what the Guardian already knows |
| GN-CONSENT-OFF | selected Seeker has C3 off | neutral: "Network is not enabled for [Name]" — no decline history, no nag CTA |
| GN-EMPTY | eligible context, zero recommendations | honest empty state; NEVER suggests loosening dealbreakers; may suggest the Seeker review soft preferences — worded to the Guardian as "the search runs within [Name]'s preferences" |
| GN-NARROW | few results because hard filters are tight | same as GN-EMPTY plus a truthful "within [Name]'s stated requirements" line; no relax control exists on the Guardian side |
| GN-ALL-REVIEWED | everything current is Saved/Passed | "you've reviewed everyone currently suitable — new families appear as they join"; Passed list reachable for undo |
| GN-MULTI | multiple Seeker contexts | selector (§4); per-context state everywhere |
| GN-CAPACITY | Seeker at outstanding-interest cap, or in Active/Paused Journey | feed pauses for that context with the true reason ("Aisha's journey is active — the Network waits with her") |
| GN-PLAN-LAPSE | Guardian+ lapsed with Network state outstanding | read-only freeze of own lists; open FIRs lapse quietly; nothing deleted (subscription-continuity principle) |
| GN-UNAVAILABLE | service failure | truthful failure per DR-ZYRA-167: error-with-retry or stale-banner over cached rows; never an empty state masquerading as "no matches" |
| GN-SUSPENDED | viewer or subject suspended/held | P4: subjects simply absent; a suspended viewer gets the account-level state, not a Network-specific message |

State transitions — **D14 (ratified) process object** (replaces the FIR
object drafted in V1):
`served → requested → (connected | not_for_us | expired_14d | withdrawn | lapsed_eligibility | lapsed_wali_change | lapsed_safety) ; connected → (proceed_one_side → proceed_both → revealed_to_seekers) | (withdrawn | lapsed_*)` —
every closure collapses to the single external state **"No longer
active"**; connected processes never auto-expire; reveal is simultaneous
to both Seekers. All transitions re-check `can_introduce` (§2) and emit
their D14 analytics event.

---

## 15. Contradictions surfaced — NOT silently resolved

| # | Contradiction | Where | Proposed resolution (Founder rules) |
|---|---|---|---|
| C1 | "CONNECTIONS SECTIONS" block inside WALI_ARCHITECTURE V6 lists a Seeker-side tab set (Declined/Review/Likes…) that contradicts the same doc's never-see list and its Guardian nav; flagged as copy-paste defect in DR-ZYRA-104, still present in V6; also uses retired terminology | WALI_ARCH V6 | strike the block in the next V bump; Guardian nav stays Dashboard · Network · Seekers · Notifications · Profile |
| C2 | Approved Network card includes **city** (2026-07-04) vs later ratified counterpart-card discipline (post-gate Main sees **no city**) and the field-test warning that city locates people | WALI_ARCH V6 vs Romantic Rules 7d + Counterpart Card spec | D2: region-not-city at rung 0 (ladder must narrow upward, never widen downward) |
| C3 | Network consent bundled into Guardian-link T&C (2026-07-04) vs C3–C5 separate/opt-in/default-off (access policy, GDPR-grounded) | WALI_ARCH V6 vs WALI_REQUIREMENT_AND_ACCESS_POLICY (PROPOSED) | D1: adopt C3–C5; V6's bundled-consent paragraph superseded on ratification |
| C4 | "A person cannot be both Seeker and Guardian on the same account" (V6) vs the ratified one-identity/two-contexts model (dual-role review CLOSED 2026-08-07) | WALI_ARCH V6 vs dual-role decisions | V6 statement is stale; the one-identity model governs; V6 bump follows the Founder's Guardian-draft review (per DR-ZYRA-171) |
| C5 | "Primary Guardian" (per-Journey designation, V4-V6 concept) vs built reality: **Main** Guardian (`is_main`, one per Seeker) used by every live subsystem; DR-ZYRA-110 explicitly scoped v1 to Main | WALI_ARCH V6 vs live system | D7 binds Network authority to Main; Primary remains an unbuilt concept to be revisited or retired at the V6 bump — this spec does NOT use it |
| C6 | DR-ZYRA-104 (Guardian sight of Browse/Match-list) is still PROPOSED-undecided; two ratified docs currently say never | open DR | Boundary condition here: the Network reveals nothing about anyone's Browse activity regardless of how DR-104 resolves; if DR-104 later widens visibility, that is Journey-side, not Network-side |
| C7 | WALI_ARCH sells "Guardian Network access ✓" under Guardian+ while the access policy correction says it must not be described as available until built with consent infra; the live lock screen sells it today | V6 / access policy / wali_network_screen | Until v1 ships with C3–C5, the Guardian+ pitch copy must present Network as "coming" (truth-in-selling); OA-ZYRA-142's three-state gate work is the vehicle |

---

## 16. NEW DECISIONS REQUIRED FROM FOUNDER

Each with recommendation. One word per line is enough ("D1 yes", "D2 as
recommended", or an amendment).

| # | Decision | Recommendation |
|---|---|---|
| D1 | Consent model: C3 (appear in Network) separate opt-in default-OFF; C4 photos separate+revocable (never at rung 0 regardless); C5 per-introduction approval; instant revocation with purge; audit trail; Seeker-visible sharing record | **Adopt in full** (it is also very likely the legally required shape) |
| D2 | Rung-0 card fields: initial · age · **region (not city)** · relationship · verified badge · 🟢 availability · compatibility **band** · practice chip (the one open sub-item) | **Adopt; include the practice chip** |
| D3 | Guardian widening: none on hard filters ever; no near-miss toggle in v1 | **Adopt strict version** |
| D4 | Name the reciprocity rule: only Guardian-represented, consented Seekers exist in the Network, both directions | **Ratify as named rule** |
| D5 | v1 action set (View/Save/Pass/Suggest/FIR) + merged consent chain (§7) + FIR expiry 14d + decline cooldown 6 months | **Adopt** (cooldown length is yours) |
| D6 | Guardian↔Guardian free-text contact | **Defer** — structured FIR only in v1; revisit with the Family-Stage communication spec |
| D7 | Network authority binds to **Main** Guardian for FIRs (send/receive); Additional = view/save/pass/suggest | **Adopt** |
| D8 | Outstanding FIRs count toward the Seeker's existing outstanding-interest cap (Basic 1 / One 5); no new plan gates; no plan-differentiated feed | **Adopt** |
| D9 | Unverified Guardians: View-only in Network (no Suggest/FIR) until verified | **Adopt** |
| D10 | Notification mapping (§13), incl. NO push for new recommendations | **Adopt** |
| D11 | Dual-role cross-context rule: deliberate Network acts (Suggest/FIR) create a permanent `can_match` exclusion Guardian-actor ↔ candidate; passive views do not | **Adopt** (I1-compliant version) |
| D12 | Seeker-side "My Network presence" surface (card preview, introductions log, consent switches) ships IN v1, not after | **Adopt — consent without visibility isn't consent** |
| D13 | Ratify the §15 contradiction resolutions (C1–C7) so the V6 bump can be drafted | **Adopt** |
| **D14** | **The Guardian Network interaction model** — visible-request ladder (Rungs 0–4), silence discipline (14d / 90d asymmetric / 6m pair cooldown), live-process cap 3 plan-equal, access-ends-on-closure, three-level Seeker photo control defaulting to after-connect, calm delivery, Main-Wali authority + entitlement clarification, "Set aside", per-stage analytics, no-search restated, FIR chain superseded within GN — full text in §D14 at the top | **RATIFIED 2026-08-23 — Founder: "Ratify all" (R-a…R-g + clarifications). Binding.** |

*(D5 and D8 remain open only for their non-Network remainder; within Guardian Network, D14 governs.)*

---

## 17. Phase-2 alignment checklist (for Codex, once the D-list is ratified)

Compare the first-draft UI against: §2 gates enforced server-side (not
UI-hidden only — I4); §4 single-Seeker context everywhere incl. saved/passed
lists; §6 exact field list + reason-chip taxonomy (no free text anywhere);
§7 action availability by role (Main vs Additional) and by consent state;
§8 consent surfaces incl. Seeker's own presence view; §13 notification
types (needs the CHECK-constraint migration, deliberate); §14 state codes
1:1 with the dev-panel stagers (extend `ZyraDevScenario`/the Guardian panel
per DR-ZYRA-152's one-store rule — every staged state must have a real
reader, REFUSED-drawn where it does not); mock data clearly marked
provisional per DR-ZYRA-171's dev-panel discipline ("DESIGN STAND-INS");
no production permission invented to make a mock button work (the
Founder's own rule). Schema work (introduction requests table, consent
records, notification types, `can_introduce()`) lands only against the
ratified D-list — the existing `wali_suggestions` pipe is reused for
Suggest, not duplicated.

---

*Single-current-version model. D14 is RATIFIED and binding (2026-08-23);
the build contract `ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md` is
completed against it. On ratification of the remaining D-list (D1–D13)
this document gains APPROVED status section-by-section and the
WALI_ARCHITECTURE V6→V7 bump propagates C1–C5 corrections. Registered as
OA-ZYRA-244 / OA-ZYRA-247.*
