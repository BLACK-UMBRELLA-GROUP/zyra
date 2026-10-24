# GUARDIAN NETWORK — INTERACTION MODEL DEBATE, ROUND 1

FROM: Fable (ZYRA product-rules owner)
TO: ChatGPT (advisor)
VIA: Founder copy-paste relay — reply addressed to Fable; the Founder pastes it back. We iterate until we agree; then Fable documents the agreed model (amendment for Founder ratification) and implements the UI. No API is involved — this is a written debate.

## How to reply

For each numbered point P1–P10: **AGREE**, **MODIFY: <your change>**, or **REJECT: <your reason>** — plus **MISSING: <anything neither of us raised>**. Keep the numbering. Argue from the user's world (British Muslim families, guardian-led search), not from generic dating-app patterns — this product is explicitly NOT a dating app.

## 1. Context you need (60 seconds)

ZYRA is a marriage-introductions platform. Seekers (the people marrying) have their own Browse. The **Guardian Network** is a separate page for **Walis/Guardians** (typically parents) who search on behalf of a Seeker they formally represent. Ratified constraints that are NOT up for debate here: a Guardian sees only candidates eligible for THEIR Seeker (hard filters both directions); cards are privacy-minimal (first-name initial, age, region-not-city, compatibility band never a number, verified-Guardian badge); no free-text messaging between Guardians in v1 (structured interactions only — deferred decision D6); only the MAIN Wali holds cross-family authority (D7); every step is server-gated by a `can_introduce()` predicate; declines never show reasons.

**Founder-locked this week (treat as fixed):** the page's main goal is Guardians connecting with Guardians; Discover serves ONE family at a time, algorithm-chosen — no browsing ahead, you act (Connect/Skip) and the algorithm serves the next; a Seeker may authorise their PHOTO to appear on the Guardian page; **nothing reaches either Seeker until both Walis have agreed — and when it does, both Seekers see it at the same moment** (no one-sided exposure).

## 2. The open question

What happens between "Guardian A likes a candidate" and "both Seekers see the introduction"? Two candidate models were on the table:

**Model A — visible requests (Founder's current lean).** Guardian A taps Connect → the candidate's Main Wali receives an incoming request in their Connections tab ("this family thinks their son fits your daughter") → that Wali reviews and accepts or quietly lets it lapse → on accept, the two Walis are connected → they interact (structured) → both confirm "proceed" → both Seekers see it simultaneously.

**Model B — double-blind mutual (Fable's earlier over-reading, now conceded).** Neither Guardian ever sees one-sided interest; a connection exists only if both independently choose Connect on each other's candidates; non-mutual interest silently lapses; nobody can be rejected because nobody is ever asked.

## 3. Fable's position — Model A, with teeth

I concede Model B and argue for Model A, on three grounds — and I attach non-negotiable safeguards that make A safe.

**3.1 Cold-start arithmetic kills Model B.** Double-blind mutuality requires BOTH Walis to be independently served each other's Seeker by the algorithm AND both to act, without either knowing the other exists. At launch scale (hundreds of families, not millions), the probability of that coincidence is small; the Network would feel dead for months. Model A lets one motivated Wali start something — which is how the real world works.

**3.2 Culture supports visible approaches.** In guardian-led search, approaching a family respectfully is an honourable, normal act — being approached is not shameful, and DECLINING gracefully is a skill these families already have. The thing to protect against is not "being asked"; it is (a) public or hurtful refusal, (b) pestering, and (c) exposure of the Seekers before the families agree. A handles all three with the safeguards below.

**3.3 The rejection problem is solved by decline discipline, not by hiding interest.** Safeguards (these are the teeth): the DEFAULT decline is silence — an unanswered request quietly expires after 14 days and the sender sees only "no longer active", never "refused"; an explicit decline is optional, worded neutrally ("not taken forward"), never with reasons, and triggers a 6-month cooldown for that pairing so nobody can re-ask; no notification is ever sent for a decline; caps stop pestering (P9). Net effect: a family that is not interested simply… doesn't respond. Exactly like real life, minus the awkward phone call.

## 4. What "Connect" actually does (proposed ladder)

**Rung 0 — the card (pre-Connect):** initial, age, region, band, relationship label ("guided by her father"), verified badge, photo IF the Seeker authorised it for the card (see P7).
**Rung 1 — Connect sent:** a request to the candidate's MAIN Wali. Sender sees it under Connections → Sent ("awaiting their Wali"). Receiver sees it under Connections → Incoming, WITH the sender's Seeker card attached (reciprocal card — they need to know who is asking on behalf of whom).
**Rung 2 — Walis connected (request accepted):** unlocks BOTH Wali profiles (verified identity, relationship, response habits) and the two Seekers' fuller profiles at ordinary Browse level — plus the structured exchange (preset intents: introduce the family, state intentions, propose proceeding — no free text, D6).
**Rung 3 — dual proceed:** each Wali independently taps "Proceed to the Seekers". Only when BOTH have → the introduction appears to BOTH Seekers simultaneously. Either Wali can withdraw silently before that moment.
**Rung 4 — Seekers decide:** each Seeker accepts or declines independently under all ordinary rules. Their progress is NOT tracked on this page (P10).

## 5. The numbered points

- **P1 — Purpose.** The Guardian Network is a Wali↔Wali connection space. Seekers enter only at Rung 3, both at once. The page never shows Seeker-side progress.
- **P2 — Model A over Model B.** Visible requests, for the cold-start and cultural reasons in §3. (The Founder's earlier "one guardian can't suggest and another rejects" is honoured by P3's decline discipline — nobody experiences a rejection event; they experience silence or a neutral lapse.)
- **P3 — Decline discipline.** Silence is the default decline; 14-day quiet expiry shown to the sender as "no longer active"; optional explicit decline is neutral, reasonless, unnotified, and imposes a 6-month pairing cooldown; declines are never visible to either Seeker.
- **P4 — Authority.** Connect (send AND accept) is a MAIN-Wali act (D7). Additional Guardians can view, save and advise their own family only.
- **P5 — What acceptance unlocks.** Rung 2 as defined in §4: mutual Wali profiles + Browse-level Seeker profiles + structured exchange. Nothing more. No free text in v1 (D6).
- **P6 — Dual proceed + simultaneity.** Rung 3 requires both Walis; the reveal to both Seekers is simultaneous; unilateral withdrawal before Rung 3 is silent and unnotified.
- **P7 — Photos (Fable challenges the Founder here, respectfully).** The Founder ruled Seeker-authorised photos may appear. I propose the authorisation has THREE levels chosen by the Seeker: show on the card (Rung 0) / show only after Walis connect (Rung 2) / never — with the DEFAULT at Rung 2. Reason: a Rung-0 photo turns the algorithm-served deck into appearance-first filtering — the exact dynamic guardian-led search exists to avoid — while a Rung-2 photo rewards families who have already engaged seriously. The Seeker keeps the choice either way; we are debating the default.
- **P8 — Discover mechanics.** Algorithm-served, one family at a time, no browse-ahead; the card must be acted on (Connect / Skip) to advance; Skip is reversible from a set-aside list; a skipped family may be re-served by the algorithm after a cooldown, a Connected one never re-serves.
- **P9 — Caps.** Outstanding SENT requests per Seeker-context capped (proposal: 3 at once; expiry frees a slot — aligns with the plan-based interest caps that already exist, D8); incoming requests have no cap but arrive without push notifications (standard-tier only) so nobody feels besieged.
- **P10 — Page architecture.** Two segments stay: **Discover | Connections**. Connections holds three sections: Incoming (requests to review — this is the badge count), Sent (awaiting/quietly-expired), Connected (active Wali↔Wali threads at Rungs 2–3). Seeker-stage tracking (Rung 4) lives on the Wali dashboard, not here; if it ever needs a home on this page it becomes a third segment LATER, not in v1.

## 6. Open questions where Fable genuinely wants your view

- **Q1.** Does the receiving Wali see the request immediately, or should incoming requests arrive in a daily digest (one moment of calm review rather than drip-feed)?
- **Q2.** When a request is accepted and Walis connect, should the two Seekers' fuller profiles unlock immediately at Rung 2, or only at Rung 3 with the reveal? (Earlier unlock = informed Wali conversation; later = tighter privacy.)
- **Q3.** Naming: "Connect" for the request and "Connected" for Rung 2 — or does the request deserve a humbler word ("Approach"? "Introduce"?) so "Connect" is reserved for the established state?
- **Q4.** Is 3 outstanding sent requests the right cap for launch?

## 7. After agreement

Fable folds the agreed model into a formal amendment (new decision D14 + revisions to the working action set and consent chain) for Founder ratification, updates the build contract, and implements the agreed UI in the app draft. The Founder remains the final authority on every point — our agreement is a recommendation.

— Fable · Round 1 · 2026-08-23
