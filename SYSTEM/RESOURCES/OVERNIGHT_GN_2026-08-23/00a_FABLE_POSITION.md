# Guardian Network — Pre-Build Brief

**Fable → Codex | First-Draft Design Discussion**
*2026-08-22 — before any UI component is written*

---

## Part 1: Ten Non-Negotiable Rules for the First-Draft Screen

These are the constraints Codex must build against, not around. Where a rule rests on an unratified D-number I've marked it **WORKING RULE** — it governs the draft but cannot go to production until the Founder decides.

---

**Rule 1 — No seeker context, no feed. Ever.**
§4. The Network screen must be structurally incapable of rendering a candidate feed without an active, explicitly selected Seeker context. This is not a loading state or an empty state — it is a different screen state entirely (the context-selector). A merged "all my Seekers" feed must never exist, even as a collapsed view. If Codex finds a component pattern that technically produces one, that pattern is wrong regardless of how the data is scoped downstream.

---

**Rule 2 — `can_introduce()` is checked server-side at every state transition, not once at feed load.**
§2, the enforcement-predicate block. The predicate composes `active_wali_link` + `zyra_can_match` + `can_view_under_browse_rules` + `network_consent` (both sides). The UI must never assume that a card rendered at t=0 is still valid at t=FIR-send. Every Network write — Save, Pass, Suggest, FIR — hits the predicate fresh. The front end can optimistically render; the server is the authority. Stale-card failure must surface as a soft dismissal, not a silent write.

---

**Rule 3 — Hard filters are the Seeker's engine, applied symmetrically. The Guardian adds no criteria and widens nothing.**
§3, §2 E5. The feed is the output of the same eligibility engine Browse uses, run for the Seeker both directions. No Guardian-preference input layer exists in v1. The "show near-matches outside soft preferences" toggle is explicitly NOT built (D3 — **WORKING RULE: Founder ratification pending**). Soft preferences produce ranking depth, not a separate filter tier. If a candidate doesn't pass the Seeker's hard requirements, they are absent from the feed — not greyed, not flagged, absent.

---

**Rule 4 — The card exposes exactly the approved field set. City is coarsened to region/country. Photo never appears at rung 0.**
§6, D2 (**WORKING RULE — field list pending Founder ratification, but the photo rule and the city-coarsening are firm**). The specific inversion risk: the counterpart card (post-gate, rung 4) already strips city; a pre-introduction card showing city would be more revealing than the most trusted post-gate surface. That ladder inversion is prohibited by the progressive disclosure architecture. Codex must not design a card component where city is a prop that can be passed — region is the prop; city arrives at rung 2 and lives in a different component.

---

**Rule 5 — Availability is shown by presence or absence, never by a grey dot.**
§2 E7, §6 card field table, DR-097. Unavailable Seekers (Active or Paused Journey) are filtered from the feed entirely — they do not appear with an unavailability indicator. A 🟢 green dot means available; the absence of a card means everything else. Codex must not build an unavailability state on the discover card. The GN-CAPACITY empty state (§9) applies to the Guardian's own context being paused, not to candidate cards.

---

**Rule 6 — The Family Introduction Request requires Seeker A's explicit approval before it sends. The UI must enforce the sequence, not merely request it.**
§7 consent chain, C5. The send action on a FIR is not a single button press. The flow is: Guardian composes intent → Seeker A is asked in-app whether their card may travel → Seeker A approves → FIR transmits. The UI must make it structurally impossible to send the FIR without that approval step completing. "Structurally impossible" means the send call is not available to the client until the approval event is recorded server-side — not a disabled button that JavaScript can bypass.

---

**Rule 7 — Declines and passes reveal nothing about the reason, and repeated suggestion of the same person to the same Seeker is capped.**
§7 action table (Suggest row, FIR row), §12.7. When a Seeker declines a suggestion, the Guardian sees "declined" — no reason string, no reason code. When a FIR expires at 14 days it shows "expired" to the sender only, never "refused." The cap on re-suggestion (same person, same Seeker context) must be enforced in the data layer — I am not specifying the exact number here because §12.7 in the truncated portion owns that figure, but the UI must have a state for "this person cannot be suggested again yet" that shows the Guardian a neutral cooldown notice, not the Seeker's decision.

---

**Rule 8 — Block is terminal and instant. A block extinguishes Network visibility both directions with no distinguishable trace.**
§2 E1, §9, I2. If either party blocks, `zyra_can_match` returns false, and the blocked person's card disappears from the feed silently — no gap marker, no "profile unavailable," nothing that signals a block occurred. This applies to cards already rendered: a real-time subscription must remove the card from the active feed without a tombstone. Safety holds (E6, P4) follow the same silence rule.

---

**Rule 9 — Network consent (C3) is a separate, independent opt-in, default OFF. It must not be bundled with Guardian linking.**
§8, C3 (**WORKING RULE — full C-model pending D1 ratification, but the unbundling from link-time T&C is firm**). The Seeker's card appearing in the Network is contingent on a discrete consent record, not on having accepted linking terms. The consent screen must be its own surface, independently revocable, with its own record. A Seeker whose Guardian is linked but who has not granted C3 produces the GN-CONSENT-OFF empty state (§14), not a feed gap. Revocation of C3 is instant: card leaves every feed, open FIRs carrying that card lapse, cached URLs die — the UI must handle mid-session card removal as a first-class event.

---

**Rule 10 — The Main Guardian holds the FIR send action. Additional Guardians hold Save, Pass, and Suggest only.**
§10, D7 (**WORKING RULE — Main/Additional action split pending Founder ratification**). This boundary maps to the existing `is_main` privilege from the 7d visibility closure. The FIR compose/send affordance must not render at all for an Additional Guardian — not disabled, not locked, not tooltipped. The action simply does not exist in their context. Codex must not build a single "actions" component that conditionally hides the FIR button; the Additional and Main action surfaces are structurally different components or the button's absence must be guaranteed by role-gated routing, not CSS visibility.

---

## Part 2: Five Questions Where I Want Your Technical Challenge

These are the places I think the spec's rules create real implementation tension. I want your honest assessment before I lock anything down. Push back hard.

---

**Question 1 — Real-time card removal when C3 is revoked or a block fires mid-session.**

Rule 8 and Rule 9 both require that a card already rendered in an active feed disappears instantly and silently when its eligibility changes. In practice this means the client needs a subscription — probably a Supabase Realtime channel — on the eligibility state of every card currently in the viewport.

My concern: at scale, a per-card subscription is expensive. But a polling approach introduces a window where a revoked card stays visible. Batch-polling on a short interval (say, 30 seconds) might be acceptable given that the privacy harm of a 30-second lag on a card that is already rendered — not newly surfaced — is low. But I'm not certain that reasoning is defensible for a block, which the spec treats as terminal and immediate.

**What I need from you:** What is the realistic implementation for instant silent removal without a per-card subscription blowing up connection limits? Does Supabase Realtime's channel-per-table approach handle this, or do we need a separate eligibility-event channel? And what is your read on whether a 30-second polling window on block events is a meaningful safety gap or an acceptable engineering trade?

---

**Question 2 — The FIR send-gate: enforcing sequence server-side without a race condition.**

Rule 6 says the FIR cannot transmit until Seeker A's approval event is recorded server-side. The clean implementation is a two-step transaction: create a pending FIR row, then a separate Seeker-approval write promotes it to sent. The server only delivers a FIR that has both rows.

My concern: if the Seeker approval and the FIR send are two separate API calls, there is a window — however small — where the Guardian's client could attempt the send before the approval is confirmed, and depending on how optimistic the client is, that could produce confusing failure states. Alternatively, if we gate the send call behind a server-generated token that the approval step mints, we introduce a token-management dependency.

**What I need from you:** What is your preferred pattern for enforcing a server-side prerequisite on a two-step flow in the current stack? Does the existing journey-gate pattern (which presumably has a similar prerequisite structure) give us a precedent we can reuse here, or is the FIR pattern genuinely novel?

---

**Question 3 — Per-Seeker feed state: how isolated is "isolated"?**

Rule 1 says all per-Seeker state — feed, saved list, passed list, counts — is entirely scoped to the Seeker context. Switching context swaps everything. My question is about the data layer, not the UI.

If a Guardian has two Seekers and passes a candidate in Seeker A's context, then switches to Seeker B's context, that same candidate (if eligible for B) should appear fresh in B's feed. That's correct by the spec. But the `wali_suggestions` table and the passed/saved lists — are these currently keyed by (guardian_id, seeker_id, candidate_id), or just (guardian_id, candidate_