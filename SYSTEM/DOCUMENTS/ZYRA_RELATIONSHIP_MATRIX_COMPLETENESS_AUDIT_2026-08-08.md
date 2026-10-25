---
id: DOC-ZYRA-0163
type: REPORT
status: CURRENT
feature: GENERAL
purpose: ZYRA — Completeness audit of the Relationship-State Master Matrix
links: []
owner: ZYRA chat
---

# ZYRA — Completeness audit of the Relationship-State Master Matrix V1

**Status:** AUDIT — completeness challenge only. **No solutions proposed, no redesign**, per instruction.
**Date:** 2026-08-08 · **Auditor:** Opus
**Subject:** `ZYRA_RELATIONSHIP_STATE_MASTER_MATRIX_2026-08-08_V1` (Fable)
**Method:** structural critique of the model, plus live verification of its factual "today" claims against the database.

---

## 0. Verdict

The matrix is the best artefact this project has produced on relationship
architecture. Parts 0–7 are a genuine model rather than a list, and the
collapse argument in Part 8 is real reasoning, not decoration.

It is also **not yet complete**, in three distinct ways:

1. **The completeness proof does not hold as written.** It is unfalsifiable,
   its axes are not independent, and it has no composition rule for when two
   cells both apply.
2. **Fifteen dimensions are missing** — not cells, *dimensions*. Your ten areas
   are, with one exception, symptoms of six of them. Nine more are not in your
   list either.
3. **Its "today" column decayed within hours of being written.** I measured it.
   This is a structural flaw in the document's design, not a stale fact.

Point 3 is the one I would fix first, because it determines whether the other
two ever stay fixed.

---

## 1. The completeness argument is the weakest section, not the strongest

### 1.1 The falsification test cannot fail

> *"If a future scenario cannot be located on the three axes + safety overlay +
> viewer, it is genuinely new and this model is incomplete."*

The axes are `Identity configuration`, `Romantic edge`, `Guardian edge`,
`Safety overlay`, `Viewer`. Any scenario whatsoever involving two people and a
permission can be "located" on those axes, because they are categories rather
than coordinates. A test that no input can fail is not a test.

Compare with a test that *can* fail: *"name a scenario in which two identities
hold no romantic edge, no guardian edge, and no shared object, yet one can
observe a state change in the other."* That has answers — several appear in
§2 — and the model does not represent them.

### 1.2 The axes are not independent, so the cross-product double-counts

`Blocked` is a terminal value on Axis 2 (romantic edge) **and** the subject of
S-1…S-5 and S-12 in the safety overlay. A rule attached to the Axis-2 value is
not automatically attached to the overlay, and vice versa. Where a value lives
on two axes, a cell can be specified twice and inconsistently — or once and
assumed twice.

The same applies to `Removed` (Axis 3) versus S-9 (deletion) versus T-6/T-10.

A cross-product is only a completeness argument if the axes are orthogonal.
These are not, and the document does not claim or check orthogonality.

### 1.3 There is no composition operator

X-14 says *"the stricter must win"* when an identity reaches a subject through
two routes. That is the only place in 269 lines where rule composition is
addressed, and it is asserted for one cell rather than defined as a primitive.

Unanswered generally: if route 1 yields ALLOW and route 2 yields FORBID, what
is the result? If a Guardian edge grants sight and a block revokes it, which
governs? If two cells conflict, is that a bug in the model or a PDR?

For a document that will be checked against before every future feature, the
composition rule is not optional — it is the thing a developer will need on
the second question they ask.

### 1.4 Cardinality is enumerated, not derived

"~17 meaningful identity configs" is a count of the rows Fable wrote. It is
evidence of effort, not of exhaustiveness. Nothing in the document generates
the identity-configuration space from first principles, so nothing tells us
whether 17 is all of them.

---

## 2. Missing dimensions

These are the answer to your question. A missing *cell* is a gap; a missing
*dimension* means an entire family of scenarios has no coordinates and
therefore cannot even be written down in the current model.

| | Dimension | Why the model cannot express it | Your area |
|---|---|---|---|
| **D-1** | **Multiplicity / degree** | Every relation is modelled pairwise (X↔Y). Nothing represents *how many* edges of a kind an identity holds. G-13 and X-4 gesture at "the accumulator" but there is no axis, so no cell can say "behaviour changes at N wards" | 1, 2, 8 |
| **D-2** | **Ward-to-ward (lateral) edges** | Two Seekers sharing a Guardian have no edge in this model. Same gender ⇒ no romantic edge ⇒ the model treats them as strangers. But information flows laterally between them *through the shared Guardian*, and that channel has no coordinates | 1 |
| **D-3** | **Transitivity, paths and cycles** | A guards B; B guards C. Does A learn anything of C? The model is pairwise and has no notion of path length, reachability, or cycles. Nothing forbids A→B→C→A | 1 |
| **D-4** | **Principals beyond the four identities** | Part 5's viewer axis has four values. The real principal set also includes: the trigger/system, the scheduler (timers), `service_role`, admin/support, the recommender, analytics and logs, backups, and **the client app as a cache**. I-16 lists admin as an *identity state*, never as a *viewer* | 4, 9 |
| **D-5** | **Discovery, as distinct from visibility** | Part 5 asks "can V see surface S of B". It never asks "can V cause B to be surfaced to them". Candidacy, ranking, recommendation and list-membership are upstream of visibility and create bypasses before any visibility rule is consulted | 5 |
| **D-6** | **Indistinguishability / differential observability** | There is no classification symbol for *"these two situations must be observationally equivalent."* The entire `safety_concern` → `prefer_not_to_say` design exists to satisfy such a requirement, and the model cannot state it. S-12 catches one instance by luck | — |
| **D-7** | **Copies and derived artefacts** | Visibility is modelled as a live predicate. Data escapes it: cached photo URLs, push payloads already on a device, email digests, exports, backups, PITR, logs. Revocation reaches the predicate, not the copies. X-10 names one instance | 6 |
| **D-8** | **Joint objects** | The subject model is single-subject: surfaces belong to "B". But conversations, matches, compatibility scores and family reviews are **pair- or group-owned**. "Who owns it" has no answer in a single-subject model, and neither does "what happens when one owner erases" | 7 |
| **D-9** | **Provenance of an edge** | Part 3 records that a guardian edge is `active`; nothing records *how it came to be* — ward-initiated invite, guardian-solicited, admin-created, restored. If authority ever depends on provenance, the model cannot express the dependency | 10 |
| **D-10** | **Time as an actor; concurrency; interleaving** | Part 7 models transitions as instantaneous and serial. Reality has timers that change state with **no actor** (48h review, 7-day invite, cooldowns), non-atomic transitions, and interleavings. X-12 found one interleaving by accident; there is no axis that would generate the rest | 3 |
| **D-11** | **Weaponisation / availability** | Every exclusion rule is simultaneously a griefing primitive. If a guardian edge blocks matching, then *creating* a guardian edge is a way to prevent someone matching. The model classifies rules as ALLOW/FORBID but never asks "can this rule be turned against a user?" X-1 mentions "veto DoS" in a parenthesis and drops it | — |
| **D-12** | **Legal-compulsion events** | GDPR erasure, rectification and subject access; Online Safety Act duties; law-enforcement disclosure. R-10 and T-4 embed a retention policy — *"retained as history; not hard-deleted"*, *"no deletion"* — which is a legal position stated as an architectural one. Erasure is not an axis, and it interacts with D-8 (whose data is a joint conversation?) | — |
| **D-13** | **Age and jurisdiction** | Guardianship of a minor is a legally distinct relationship from guardianship of an adult. Does ZYRA permit under-18 Seekers? What happens when a Seeker turns 18 mid-Journey? A Guardian resident abroad raises transfer questions. Age appears only as a *visible surface* in Part 5, never as a state | — |
| **D-14** | **Entitlement state as a permission input** | Subscription tier gates real capability (Unlock+, save and consider limits, funded Guardian). Tier changes *during* relationships. I-11 and T-11 touch it; it is not an axis, so "what does a lapse make invisible?" has no home | 9 |
| **D-15** | **Model governance** | The document has no rule for how a cell is changed, no permanent cell identifiers, and no statement of what happens to already-built features when a cell changes. For an artefact intended as the reference model, this is the omission that decides whether it survives contact with development | — |

**Six of your ten areas are symptoms of D-1, D-2, D-3, D-4, D-5, D-10.** That
is worth knowing, because fixing them cell-by-cell would produce a longer
document with the same hole.

---

## 3. Your ten areas, assessed individually

| Your area | Present in V1? | Assessment |
|---|---|---|
| **1 · Multi-Seeker Guardian chains** | Partly — G-13, X-4 | Your instinct is right and it is deeper than you framed it. G-13 collapses six genuinely different cases into one row. **Two sisters** and **two unrelated women** differ not in the Guardian's authority but in whether the *wards* have a channel between them (D-2). **Mother and daughter** introduces a ward who may herself be a Guardian — a chain (D-3). **"Guardian later becoming connected to someone already inside one of those family graphs"** is the sharpest of the six and has no coordinates at all: it is a *graph-reachability* question in a pairwise model |
| **2 · Multiple Journey overlap** | Barely — R-13 covers Seeker-side only | Genuinely missing. R-13 enforces one active Journey **per Seeker**; there is no equivalent statement for a Guardian, and no cell anywhere describes a Guardian holding sight of two live Journeys at once. "Main Guardian changes while another Journey already exists" is a pure D-1 × D-10 interaction and the model cannot state it |
| **3 · Time-based transitions** | Partly — Part 7, T-1…T-14 | Part 7 is good on *sequential* transitions and silent on *concurrent* ones. Your five examples are all races or near-races. "Guardian removed immediately after viewing" is D-7 (the copy already left). "Journey ends while invitation pending" is an orphaned-edge case with no row |
| **4 · Notification matrix** | **Declared and never delivered** | The surface legend on line 140 defines `Notif=notifications`. **No table in Part 5 has a Notif column.** This is a literal, checkable gap in the document. Notification *content* leaking protected information is a D-6 problem: a notification that exists at all can reveal a state the recipient should not know |
| **5 · Discovery matrix** | No | Correct and important — this is D-5. Your framing ("discovery often creates bypasses before visibility rules even apply") is exactly right and is the reason it needs to be an axis rather than a section |
| **6 · Historical data** | Partly — R-10, T-4, T-7, T-8 | The model says history is retained; it does not say who can *read* it after the relationship ends. T-7/T-8 raise retroactive exposure forward (new Guardian sees old messages) but never backward (removed Guardian, ended Journey, previous compatibility). Compounded by D-7 and D-12 |
| **7 · Ownership matrix** | No | Missing, and blocked by D-8: you cannot write an ownership matrix while the subject model is single-subject. "Who owns a conversation between A and B" has no expressible answer in V1 |
| **8 · Family expansion** | Partly — G-4…G-8, T-8 | One/two Guardians modelled; three is D-1. Promotion is T-8; **demotion has no row at all** (Main → Additional without removal). Internal consistency under N Guardians cannot be checked without the degree axis |
| **9 · Cross-feature interaction** | Scattered — X-7, I-11, T-11, T-13 | Present as individual attacks, absent as a dimension. This is D-4 plus D-14. The specific unmodelled risk you name — a feature bypassing the relationship model — is structurally guaranteed while features are analysed one cell at a time rather than against a stated interface |
| **10 · State ownership** | No | This is D-9 (provenance) plus D-8 (joint objects). Your four questions — creates / modifies / terminates / observes — are a good primitive and the model currently answers only the fourth |

---

## 4. Classes neither Fable, ChatGPT, nor your list raised

1. **Exclusion rules as weapons (D-11).** The central invariant is a safety
   rule that is also an attack primitive. Any mechanism that *prevents*
   matching can be induced by an attacker to prevent someone else matching.
2. **Erasure versus the retention position (D-12).** "Nothing is deleted" is
   asserted architecturally in R-10 and T-4. Whether that survives a
   right-to-erasure request — particularly for a joint conversation, or a
   safety report that is simultaneously the reporter's and the subject's
   personal data — is a live question the model does not have room for. *I am
   not a lawyer; this needs qualified review rather than an architectural
   ruling.*
3. **Age and jurisdiction (D-13).** Absent entirely, and it is the one
   dimension where getting it wrong is not a product defect.
4. **Indistinguishability as a first-class classification (D-6).** The model
   needs a sixth symbol. Without one, every future feature can satisfy every
   cell and still leak by differential behaviour.
5. **Cycles and self-referential graphs (D-3).** A guards B, B guards C, C
   guards A. Nothing in the four-identity universe forbids or even names it.
6. **The client as an untrusted principal (D-4/D-7).** X-13 covers a *user*
   toggling context. It does not cover the *app* holding decrypted state
   across that toggle, or a stale token continuing to authorise reads after
   revocation.
7. **Orphaned edges.** An invite pending when the Journey ends; a review open
   when the Guardian is removed; a notification queued for a revoked
   recipient. The model has states for edges and states for objects, but not
   for *edges whose context has disappeared*.
8. **Observability of counts and absence.** G-9's `expected_count → 1`
   silently reveals that the other family has no Guardian. That is a leak with
   no perpetrator and no surface — it is arithmetic. There is no dimension for
   it (D-6).

---

## 5. Factual corrections required before V1 can be source of truth

I verified the "today" claims against the live database. Most hold. **The
headline one does not.**

| Matrix claim | Measured reality |
|---|---|
| **G-5**: *"FALSIFIED — `is_main` is absent from the participant view, so Additional = Main at the visibility layer. This is the sharpest current gap"* | **No longer true.** `is_main` IS present in `zyra_attempt_participant_rows`, and it gates **seven** RLS policies: `conversations_select`, `messages_select`, `timelines_select`, `timeline_milestones_select`, `journey_family_reviews_read`, `journey_family_review_responses_read`, `journey_family_answers_read` |
| **5C**: the "today" leak table, and *"one Journey → 6 people mutually visible"* | Stale in the same way. Additional Guardians no longer reach conversations, messages, timelines or reviews |
| **X-6 / 5C**: Guardian sees the counterpart's Guardian roster | Needs re-verification. `wali_links_select` is `seeker_id = auth.uid() OR wali_id = auth.uid()` — a Guardian sees only their **own** links, so the roster is not reachable by that path. If the leak is real it runs through `zyra_attempt_participants()`, which the matrix does not name |
| **R-13**: the index pair permits one person as `seeker_a` on one match and `seeker_b` on another | **Accurate.** `matches_seeker_a_active` and `matches_seeker_b_active` are separate partial unique indexes |
| **G-4**: exactly one Main per Seeker | **Accurate** — `wali_links_one_main_per_seeker`, unique on `seeker_id where is_main and status='active'` |
| **G-16**: self-guardianship impossible | **Accurate** — `wali_links_no_self_link CHECK (seeker_id <> wali_id)` |
| **I-1**: 144 of 149 | **Accurate** — 144 seeker / 5 wali |

**The residual gap is now precisely locatable**, and it is narrower and
different from what the matrix says: `matches_select` and
`zyra_can_view_profile` do **not** gate on `is_main`. An Additional Guardian
still sees the match row and the counterpart's profile, while correctly seeing
none of the conversation, timeline or review content.

---

## 6. The structural problem this reveals

**The matrix mixes durable target-state and perishable today-state in the same
cells, and the perishable half decayed inside a single day.** G-5 was true when
Fable wrote it and false by the time I read it — the policies changed while
the document was being authored.

This is invariant **I1** in documentary form: a permanent artefact anchored to
temporary data. It is also exactly the corollary added to the invariants this
morning — *the deployed system outranks the source file*. A source-of-truth
document whose factual column silently rots will be **believed** long after it
stops being true, and its most-quoted claim ("the sharpest current gap") is
precisely the one most likely to be built against.

Three further structural gaps, stated as gaps rather than fixes:

- **No permanent cell identifiers.** Features will cite "G-5" and "X-14". If a
  row is inserted, every citation shifts. This project spent today closing
  exactly that class of defect for documents (Naming Conventions rule 5); the
  matrix reintroduces it at cell granularity.
- **No falsification test that can fail** (§1.1).
- **No composition rule** (§1.3).

---

## 7. Summary

V1 is a strong model of **states**. It is materially incomplete on
**degree, laterality, transitivity, principals, discovery, indistinguishability,
copies, joint ownership, provenance, concurrency, weaponisation, legal
compulsion, age/jurisdiction, entitlement and its own governance.**

Your ten areas are real. Six are symptoms of missing dimensions rather than
missing rows, which matters: adding sixty rows would leave the model exactly as
incomplete as it is now, but longer and harder to check.

The single highest-value change is not a new dimension at all — it is
separating what is *decided* from what is *currently true*, so that the second
can rot without taking the first with it.

No solutions proposed, per instruction.
