# GUARDIAN NETWORK — INTERACTION MODEL · FINAL JOINT RECOMMENDATION

**Status:** AGREED between Fable and ChatGPT (three rounds, 2026-08-23) — **awaiting Founder ratification.**
**On ratification this becomes decision D14:** it enters the Guardian Network specification, the build contract (v1.1) is completed against it, and the UI is implemented to it. The Founder is the final authority on every item; the R-list in §13 is what needs his word.
**Debate record:** `ZYRA/SYSTEM/RESOURCES/GN_MODEL_DEBATE/` (R1, R2, this document). Register: OA-ZYRA-247.

---

## 1. Purpose and principles

The Guardian Network is a **Main-Wali ↔ Main-Wali connection space**. One family may respectfully approach another (visible requests — Model A); the system's job is to prevent pressure, repetition and public rejection, not to pretend approaches don't happen. **Nothing reaches either Seeker until both Walis have independently agreed — and then both Seekers receive it at the same moment.** Seeker-side progress after that lives on the Guardian Dashboard, never on this page.

## 2. The ladder

**Rung 0 — Recommendation.** The algorithm serves ONE family at a time for the selected Seeker context. No browsing ahead, no search, no enumeration. Card: first-name initial · age · region (never city) · compatibility band (never a number) · relationship label · verified-Guardian badge · photo only if the Seeker chose card-level visibility. Actions: **View · Set aside · Request connection.**
*Merge rule (F2):* if the family being served has already sent an incoming request for this pair, no normal card is shown — instead: *"This family has already requested connection."* with primary action **Review request**, opening the existing Incoming item. One process per Seeker pair, always.

**Rung 1 — Request connection.** Sent by the Main Wali (cap rules in §4). The receiving Main Wali sees it in Connections → Incoming with the reciprocal privacy-matched card; the sender sees Connections → Sent as "Awaiting their Wali". The receiver may accept (**Connect with this family**) or clear it internally (**Not for us** — never visible to the sender). A reverse request while one is pending acts as acceptance, never a duplicate.

**Rung 2 — Connected.** Reciprocal, simultaneous, consent-limited unlock: verified Main-Wali profile · Wali relationship · region · verification status · the Seeker's ordinary Browse-level profile · photo per the Seeker's photo permission · structured exchange (preset intents; no free text in v1 — D6). **Never unlocked:** contact information, exact address, private compatibility answers, numeric scores, family-network membership, message history, safety/moderation history, previous Journey history. No "response habits" or responsiveness indicators anywhere.

**Rung 3 — Proceed to the Seekers.** Each Wali confirms independently. Either may withdraw before both have confirmed — silent in notification terms, but the other side's state updates honestly to "No longer active" on next open. A connected process never expires automatically; withdrawal is the deliberate exit, and the live-process cap (§4) is the natural pressure against abandoned connections.

**Rung 4 — Simultaneous introduction.** Both Seekers receive the introduction at the same moment and decide independently under all ordinary ZYRA rules. This page's involvement ends.

## 3. Silence, decline and cooldowns

The DEFAULT decline is silence. A request quietly expires after **14 days**. The sender sees only **"No longer active"** — one external state for every internal cause: explicit decline, expiry, withdrawal, eligibility failure, Main-Wali change, safety restriction. No reasons, ever. No decline notifications, ever. Nothing shown to either Seeker, ever.

After a first quiet expiry (**F1, asymmetric**): the ORIGINAL INITIATING Seeker-side must wait **90 days** before approaching the same pair again — Wali-switch-proof (binds to the Seeker pair and direction, not the Guardian account). The receiving family is NOT blocked: if they later choose to approach the original family themselves, they may. If the initiating side's second request also expires unanswered → the full **6-month pair cooldown, both directions**. An explicit "Not for us" applies the 6-month pair cooldown immediately, both directions, also Wali-switch-proof.

## 4. The live-process cap

**Maximum three LIVE Guardian Network processes per Seeker context — identical for Basic and ZYRA One.** Counting toward the cap: Sent requests awaiting the other Wali · Connected families (Rung 2) · connections awaiting proceed (Rung 3). NOT counting: unaccepted Incoming requests · set-aside cards · closed/expired processes · introductions already passed to the Seekers (Rung 4). Accepting an Incoming request that would exceed the cap requires first closing or withdrawing from an existing live process. Approaching more families simultaneously is never a paid feature; ZYRA One may add insight and tools later, never pressure volume.

## 5. Access ends when the process ends

Rung-2 access exists ONLY while the process is live. On any closure ("No longer active", any cause): reciprocal profile access ends · structured interaction ends · photos are no longer served through that process · neither Wali can reopen the fuller profile from history. The Connections history retains only a privacy-minimal neutral record: Seeker initial · region · relevant date · "No longer active". Honesty clause: ZYRA cannot make anyone unsee or un-screenshot what was already viewed — but it stops serving live access the moment the relationship closes.

## 6. Seeker consent controls (three, separate, prospective)

1. **Participate in Guardian Network** — a Wali link alone never publishes a Seeker into this system.
2. **Photo visibility** — card-level / after-the-Walis-connect / never. **Default: after the Walis connect.**
3. **Pause recommendations** — stops future serving without ending existing processes.
All prospective; changes never claw back what was already seen.

## 7. Eligibility — rechecked at every rung

`can_introduce()` and every related gate run at: card serving · request send · request acceptance · each Wali proceed · the final simultaneous reveal. Any failure between stages (block, Journey status, Guardian removal, pause, safety hold, preference change) closes the process neutrally as "No longer active".

## 8. Calm delivery

No per-request push. One badge count (unaccepted Incoming). At most one daily digest when unread incoming requests exist. Incoming visible immediately inside Connections, oldest first. Lock-screen/notification copy contains zero Seeker identifiers — e.g. *"You have a new Guardian Network request."*

## 9. Authority

Send, accept, withdraw and proceed are **Main-Wali-only** acts. Additional Guardians: view eligible recommendations, save/set aside, advise their own family — no cross-family contact, acceptance, or notifications. If the Main Wali changes before dual proceed, open processes close as "No longer active"; the successor starts deliberately.

## 10. Abuse resistance

No name/Guardian/family search, no enumerable profile URLs, no exports, no lookahead — the algorithm serves; Guardians never query the population. Same-identity-both-sides, romantic-history conflicts, blocks and safety conflicts refuse the process (existing Tier-0/Tier-1 and Guardian-romantic rules). Every request binds to exactly one Seeker on each side; a connection for one Seeker grants nothing for the Guardian's other Seekers; the selected Seeker context stays visible throughout.

## 11. Naming (final)

**Request connection** (opening action) → **Awaiting their Wali** (sender state) → **Connect with this family** (receiver action) → **Connected** (established state) → **Proceed to the Seekers** (final Wali action) → **No longer active** (every closed state). Reversible pass: **Set aside** (manual restore anytime; algorithm may re-serve after 30 days, only while eligible, never recycling while fresh eligible families remain; the set-aside list is a quiet secondary entry under Discover).

## 12. Supersession and continuity

Within the Guardian Network, this ladder **supersedes the earlier initiator-led "Family Introduction Request" draft chain**. "Suggest to Seeker" is unchanged: a private advisory nudge to one's OWN Seeker, never a cross-family act. The build contract's unwritten rules (22+) will be completed against THIS model. Existing ratified gates are unchanged and mapped: participation consent = the existing Network-consent gate + "My Network presence" surface; every-rung recheck = the existing every-transition rule; context isolation = the composite-key rule; conflict refusals = Tier-0/Tier-1.

## 13. FOR THE FOUNDER — ratification list

- **R-a** — Visible-request Model A (one family may respectfully approach another; protections instead of blindness).
- **R-b** — Silence discipline: 14-day quiet expiry · 90-day initiator-side wait after a first expiry (receiver never blocked) · second expiry or explicit "Not for us" → 6-month pair cooldown both directions · single "No longer active" external state.
- **R-c** — Maximum **3 live processes** per Seeker context (Sent + Connected + awaiting-proceed), identical for Basic and ZYRA One — pricing implication: approach volume is never monetised.
- **R-d** — Photo default **after the Walis connect**; Seeker may choose card-level or never; participation and photo consent separate.
- **R-e** — The §11 naming set ("Request connection" opener; your word "Connect" kept for the accept action and the established state).
- **R-f** — "Set aside" with manual restore and 30-day eligible re-serve.
- **R-g** — Supersession of the FIR draft chain within Guardian Network.

Ratify with one word per item, or "ratify all", or amend any item — your amendments override the recommendation.

## 14. After ratification (Fable executes)

Spec updated with D14 (this model) → build contract v1.1 completed against it (rules 22+ rewritten) → UI implemented: algorithm-served single-card Discover with View · Set aside · Request connection, the F2 merge card, Connections with Incoming · Sent · Connected, photo permission handling, live-process cap surfaces — on the chosen 2E chrome with the B1 one-family-at-a-time presentation. Registers and contradiction check updated; Codex briefed for Phase-2 against the ratified model.

— END OF RECOMMENDATION — agreed Fable + ChatGPT, 2026-08-23 —
