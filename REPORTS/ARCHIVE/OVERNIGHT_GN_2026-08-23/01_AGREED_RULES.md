# AGREED RULES — GUARDIAN NETWORK: `wali_network_screen.dart`

**Build Contract v1.0**
**Closed by:** Fable
**Date:** 2026-08-22
**Status:** Rules 1–47 BINDING on ratification of all referenced D-items; items marked WORKING RULE are binding for the build but Founder-ratification-pending on the named decision. Rules are numbered sequentially and contradiction-free. Every rule traces to the spec (§-reference) or to a named resolution of Codex's challenge.

---

## PART A — ARCHITECTURE & CONTEXT RULES

**Rule 1 — No feed without an active Seeker context.**
The Guardian Network screen MUST NOT render any candidate feed, saved list, passed list, or introduction count unless exactly one linked Seeker is selected as the active context. A Guardian with zero eligible linked Seekers sees the GN-NO-SEEKER empty state (§14, State 6). A Guardian whose selected Seeker has Network consent OFF (C3) sees GN-CONSENT-OFF (§14, State 7). Neither state shows history, declined-candidate traces, or pressure surfaces of any kind.
*Trace: §4; Codex Rule 1 agreement; §12.9.*

**Rule 2 — Single-Seeker context, always.**
There is no merged or combined feed across multiple Seekers. The feed, saved list, passed list, interaction counts, and all per-card state are scoped to exactly one (guardian\_id, seeker\_id) pair at a time. Switching Seeker context swaps ALL of these simultaneously; no state bleeds across contexts.
*Trace: §4; Codex Rule 1 agreement; "wrong-seeker suggestion" risk named in §4.*

**Rule 3 — Seeker selector behaviour.**
• One eligible linked Seeker → context auto-selected; selector renders as a static label, no dropdown.
• Two or more eligible linked Seekers → explicit selector required; no default; the screen does not proceed past the selector until a selection is made.
• "Eligible" means: active `wali_links` row (E3) AND Seeker's Network consent C3 is ON. A linked Seeker with C3 OFF is excluded from the selector entirely; their consent state is not disclosed to the Guardian through the selector.
*Trace: §4; Codex Rule 1 agreement.*

**Rule 4 — Composite key for all per-Seeker state.**
Every table row, client-side cache entry, and subscription channel that records Guardian–Network interaction MUST use the composite key `(guardian_id, seeker_id, candidate_id)` as its primary scope. No interaction recorded under one seeker\_id is ever readable, writable, or aggregatable under another.
*Trace: §4; Codex Additional Constraint — composite key answer to Question 3.*

---

## PART B — ELIGIBILITY & FILTERING RULES

**Rule 5 — `can_introduce()` is the master gate.**
Every feed inclusion, suggestion, and Family Introduction Request (FIR) MUST be gated server-side by the predicate:

```
can_introduce(G, S, C) ⇔
    active_wali_link(G, S)
AND zyra_can_match(S, C)
AND can_view_under_browse_rules(S, C)
AND network_consent(C)       -- C3 on for candidate
AND network_consent(S)       -- C3 on for own Seeker
```

This predicate is evaluated at every state transition, not once at feed generation. The client MUST NOT render a speculative result before server confirmation. No client-side shortcut substitutes for the server evaluation.
*Trace: §2 `can_introduce()` definition; Codex Rule 2 agreement.*

**Rule 6 — Hard filters are absolute; Guardian cannot widen them.**
A candidate who fails any hard filter (E1–E8) does not appear in the feed, does not appear in the Saved list, and cannot be the subject of a FIR. The Guardian has no toggle, override, or "show near-matches" capability in v1. Soft preferences affect ranking only.
*Trace: §3; §2 E1–E8 table; Codex Rule 3 agreement.*

**Rule 7 — `zyra_can_match` is a live predicate, not a snapshot.**
The existing RLS predicate `zyra_can_match(S, C)` governs Tier-0 (Guardian–link conflicts) and Tier-1 (shared Guardian, active or removed). It is consumed as-is by `can_introduce()`. The Network adds no relaxation.
*Trace: §2 E1; §9 mapping.*

**Rule 8 — Blocks are terminal and immediate.**
A block in either direction between Seeker A and Seeker B (or their Guardians) removes both parties from each other's Network world instantly and silently. No gap is shown, no count changes. Real-time enforcement latency target: under 30 seconds. See Rule 27 for subscription mechanism.
*Trace: §2 E1; §9 I2; Codex Rule 8 agreement; Codex Question 1 answer.*

**Rule 9 — Safety holds are silent.**
A Seeker under a safety hold (E6) simply does not appear in any feed. The absence is indistinguishable from ordinary feed variation. No "unavailable" label, no grey dot, no count gap. Guardian sees no indication that a hold exists.
*Trace: §2 E6; Notification spec P4; Codex Rule 7 agreement.*

**Rule 10 — Journey availability filter.** WORKING RULE *(D8 pending)*
A Seeker in an Active or Paused Journey (E7) is excluded from the feed by default. They are filtered out, not shown with a status indicator. If D8 resolves in favour of showing unavailable candidates with 🔴 Unavailable per DR-097, this rule is updated; the default for the build is filter-out.
*Trace: §2 E7; §9 DR-140; Codex Rule 5 agreement.*

**Rule 11 — Network eligibility can never be weaker than Browse.**
`can_view_under_browse_rules(S, C)` is a hard gate. A candidate who has made themselves unreachable under ordinary Browse rules (hidden, inactive, unpublished) does not appear in the Network feed. The Network is never a back-door to unreachable profiles.
*Trace: §2 E2; Adversarial Pass 2 A3.*

---

## PART C — CARD & INFORMATION VISIBILITY RULES

**Rule 12 — Approved field set for the Discover card (Rung 0).** WORKING RULE *(D2 pending)*
The Network Discover card displays exactly these fields, all system-controlled:

| Field | Displayed |
|---|---|
| First-name initial | ✅ |
| Age | ✅ |
| Location — region/country only, NOT city | ✅ |
| Guardian relationship label ("Guided by her father") | ✅ |
| Verified Guardian badge | ✅ |
| Availability indicator — 🟢 only (unavailable profiles filtered, not shown grey) | ✅ |
| Compatibility band (High / Good / etc.) — never a numeric score | ✅ |
| Practice summary chip (Seeker's own headline, from Browse-visible profile fields only) | D2 pending |
| Photo | ❌ never at Rung 0 |
| City, full name, occupation detail, Chapter 3/4 answers, other Guardians, network membership of others | ❌ never |

*Trace: §6 field table; §6 photo prohibition; Codex Rule 4 agreement.*

**Rule 13 — No free text anywhere on the card.**
Guardians cannot add, annotate, or append any free text to a card or to a suggestion. The card is 100% system-controlled. Free text is a privacy loophole and is banned at this rung.
*Trace: §6 "100% system-controlled" statement.*

**Rule 14 — Recommendation-reason chips are taxonomy-controlled.**
"Why am I seeing this?" chips are generated from a fixed system taxonomy only: "Within [Name]'s preferences" · "High compatibility" · "Also speaks [language]" · "Practising" · "Nearby region". No free text. No preference the Seeker did not set.
*Trace: §6 recommendation-reason chips.*

**Rule 15 — Progressive disclosure ladder is never inverted.**
A Rung-0 card may not display more location precision than a post-gate Rung-4 counterpart card. The field set in Rule 12 (region, not city) enforces this. City arrives at Rung 2 when the Seeker's ordinary Browse-level profile is shared. No field from a higher rung appears at a lower rung.
*Trace: §6 contradiction C2 resolution; Counterpart Card §4.1.*

**Rule 16 — Uniform field set; no per-user sparseness.**
All-or-nothing field display only. A card either shows the full approved field set (Rule 12) or does not appear. Selective omission of fields on a per-profile basis is forbidden because sparseness leaks information about the omitted field's value.
*Trace: §6; Counterpart Card §4.2.*

---

## PART D — ACTIONS & CONSENT CHAIN RULES

**Rule 17 — v1 action set.**
The only actions available in v1 are: **View · Save · Pass · Suggest to [Seeker] · Family Introduction Request (FIR)**. Guardian-to-Guardian free-form messaging is explicitly out of scope for v1 (see Part G).
*Trace: §7 v1 action set; Codex Rule 7 agreement; D6.*

**Rule 18 — View is silent.**
Opening a card is never notified to the candidate Seeker, their Guardian, or anyone else. Views are never aggregated into any display shown to other users.
*Trace: §7 View row; DR-104 boundary.*

**Rule 19 — Save and Pass are private.**
Save adds the candidate to the Guardian's per-Seeker shortlist. Pass removes the card from the feed for this Seeker context and moves it to a reversible Passed list. Neither action is notified to the candidate or their Guardian. Neither action is visible to the Seeker. Pass is reversible; the candidate is re-eligible on undo.
*Trace: §7 Save and Pass rows.*

**Rule 20 — Suggestion is not consent.**
"Suggest to [Seeker]" routes the candidate's Rung-2 profile to the Seeker's existing Introductions card (`wali_suggestions`, DR-157/160 card). The Seeker receives a standard-tier feed item (no push notification, P2 rule). The Seeker's response options are Pass / Save / Consider / View Profile — all existing. The suggestion is explicitly NOT the Seeker's consent to an introduction. A repeated suggestion of the same candidate to the same Seeker is capped (Rule 38).
*Trace: §7 Suggest row; §8 "suggestion is never consent" approved principle; Codex Rule 7 agreement.*

**Rule 21 — Decline reasons are never disclosed.**
When a Seeker declines a suggestion, the Guardian sees only "declined" — never the reason. When a FIR is declined by Guardian B or Seeker B, the initiating Guardian sees "declined" — never the reason. The Seeker's decline reason is not stored in any field accessible to the Guardian.
*Trace: §7; §8 Seeker authority table; Codex Rule 7 agreement.*

**Rule 22 — FIR consent chain — sequence is enforced server-side.**
The full consent chain for a Family Introduction Request is:

```
1. G_A selects candidate B from the feed
2. Server confirms can_introduce(G_A, A, B) — hard gate
3. G_A taps "Send Introduction Request"
4. Server requires Seeker A approval (C5-outbound) before the FIR is transmitted
   — the FIR send RPC is unavailable until server-verified A-approval
5. FIR delivered to G_B
6. G_B reviews Seeker A's Rung-1 card (same field set as Rung