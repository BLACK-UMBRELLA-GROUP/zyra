# ZYRA — Adversarial pass 2: attacking the PROPOSED model

**Status:** FINDINGS — nothing built
**Date:** 2026-08-08
**🔴 CORRECTED 2026-08-08 (later)** — the Additional-Guardian answer in §3
was WRONG. It said "genuinely closed"; measurement says the opposite. See
the correction box in §3 and
ZYRA_DUAL_ROLE_SURVEILLANCE_RESPONSE §2.1. Left in place rather than
edited away, because a review that was confidently wrong is worth seeing.

The brief: *"prove there is no way a Guardian profile can become an
information-gathering tool."*

**I cannot prove that, and the reason is structural rather than a missing
control.** §1 states it plainly, because a model presented as leak-proof
when it is not is worse than one with a known, bounded residue.

Below that: five holes in the proposed matrix that the first pass missed,
and direct answers to the seven questions.

---

## 1. Why "no way" is not achievable, and what the residue is

Two facts, both of which are deliberate product decisions:

1. **Guardian visibility is broader than Seeker visibility.** It has to be —
   a Guardian vets someone their Seeker is considering, and no gender rule
   applies to them. That breadth *is* the feature.
2. **One identity will hold both roles.** That is the direction agreed.

Together they mean a person can see something in their Guardian context and
know it in their Seeker context. **No predicate closes that**, because the
transfer happens in a human being, not in a query. `can_match()` can stop
them *acting* on it. Nothing stops them *knowing* it.

So the honest formulation is not *"a Guardian cannot gather intelligence"*.
It is:

> **A Guardian learns only what a Guardian must know to do their job, only
> once the family has consented to being known, and only about families
> their own Seeker is genuinely engaged with.**

That is achievable and the matrix gets close to it. Everything in §2 is a
place where it currently does not.

---

## 2. Five holes in the proposed model

### A1 · No cap on how many Seekers one Guardian may hold — the real answer to question 7

**This is the finding the matrix does not close, and I under-weighted it.**

`wali_links` has `UNIQUE (seeker_id, wali_id)` and **no limit per
`wali_id`.** Two seeded Guardians already hold **10 Seekers each**.

The matrix restricts what a Guardian sees *per Journey*. It says nothing
about how many Journeys they are attached to. A Guardian to 50 Seekers,
each with a handful of Journeys reaching the gate, accumulates a catalogue
of counterpart families and their Main Guardians — every entry individually
legitimate.

**And a plausible, sympathetic cover story already exists in the schema.**
The relationship values include `legal_guardian` and
`family_representative` — non-family Guardians are anticipated by design.
Finding a Guardian is genuinely hard for a woman without a father or
brother, so *"I act as Guardian for sisters who have no one"* is a real
service someone would offer, a real need it would meet, and the single best
intelligence position in the product.

Nothing detects it, because every individual link is consented to.

**Options, none free:**

| | Cost |
|---|---|
| Hard cap per Guardian (5? 10?) | Refuses a legitimate large family or a genuine community figure |
| Soft cap with review past N | Needs an admin, which does not exist |
| Rate-limit new links | Slows accumulation, does not bound it |
| Surface it to Seekers — *"this person guards 14 others"* | Cheapest, and puts the judgement with the person who can make it |

The last one is the one I would argue for. It closes nothing technically and
changes the incentive completely: a catalogue-builder is visible to every
new Seeker they approach.

### A2 · Notifications bypass the matrix entirely

**The matrix governs reads. Notifications are pushes, and nothing in the
model covers them.**

`create_notification()` writes free text into `notifications.body`, and the
existing match notification bakes the other person's **first name** into it:

```
COALESCE(b_name, 'Someone') || ' matched with you.'
```

Checked: today Guardians are **not** notified of their Seeker's matches —
only the two Seekers are. So there is no live leak.

But the day someone adds *"tell the Guardian a Journey has started"* — an
obviously reasonable feature — the counterpart's name goes into the body,
and the pre-gate rule in §3.2 of the matrix is dead. Not bypassed:
**irrelevant**, because it governs a different channel.

**Any visibility model must govern notification CONTENT as well as reads**,
or notifications become the side channel, and they are the channel most
likely to be extended by someone who has not read this.

### A3 · `can_introduce()` needs a second condition I missed

Pass 1 required: the Guardian could see the candidate *without*
Guardian-derived visibility.

That is necessary and insufficient. It also needs:

> **The Seeker must be able to see the candidate under ordinary Browse
> rules.**

Without it, a Guardian can surface someone who has **paused their profile,
unpublished, or blocked the Seeker** — putting in front of them a person who
has deliberately made themselves unreachable. Introduction becomes a bypass
of the *target's* privacy choice rather than the Guardian's.

`can_introduce(g, s, c)` therefore requires all of:
`active link(g,s)` · `can_match(s,c)` · `can_view(s,c)` under Browse rules ·
`can_view(g,c)` **without** Guardian clauses.

### A4 · The matrix is silent on REMOVED Guardians

"Frozen" is defined for ended Journeys. It is not defined for a Guardian who
is **removed**, and the natural implementation — reuse frozen — is wrong.

An ended Journey is two people concluding something together. A removed
Guardian is one party withdrawing trust from another, often for cause. That
should **revoke immediately**, not freeze.

The distinction matters most in the case where it is most likely to be
used: a Seeker removing a Guardian who was behaving badly.

### A5 · `ages_for()` is a batch confirmation oracle

It accepts an **array** of UUIDs and returns rows only for those the caller
may view. That is a thousand visibility hypotheses per call.

Not an enumeration vector on its own — UUIDs are v4 and unguessable — but it
turns any leaked list of IDs into a fast map of who-can-see-whom. It should
take one id, or be limited to ids the caller has a relationship with.

---

## 3. The seven questions, answered against the proposed model

| | Answer |
|---|---|
| Discover another family's **Main** Guardian earlier than intended? | **No**, once §3.2 is built — gated at `wali_gate` |
| Ever discover **Additional** Guardians? | ~~**No.** Never visible outside their own family, at any stage. This one is genuinely closed~~ **🔴 FALSE — see below** |
| Family Network as an enumeration tool? | **Only if built wrong.** Introduction-only is necessary; it must also never reveal who *else* is in a family's network, or consented introductions compose into a map |
| Guardian-only visibility revealing what a Seeker could not learn? | **Yes — by design, and this is the irreducible part.** §1 |
| Unlock / Unlock+ bypassed again? | **No.** The free post-gate path needs the counterpart's cooperation to reach the gate, and an attacker cannot manufacture that. Verified: reaching `wali_gate` requires mutual Like, mutual promotion, and three stages |
| Introductions as an indirect bypass? | **Not once A3 is applied.** As drafted in pass 1, yes |
| Become a Guardian purely to catalogue families? | **Yes. A1 is not closed by the matrix** and is the most serious remaining item |

---

### 🔴 Correction — the Additional-Guardian answer above is false

**Measured 2026-08-08 against a real active Journey.** An Additional
Guardian of Seeker A can see Seeker B, B's Main Guardian **and** B's
Additional Guardian. The other family can see them back.

The cause is not in clause 3. It is in the participant view:

```sql
join wali_links w on w.status = 'active'
                 and (w.seeker_id = m.seeker_a_id or w.seeker_id = m.seeker_b_id)
```

**`is_main` is not referenced anywhere in `zyra_attempt_participant_rows`.**
Every active Guardian of either Seeker is a full participant of the attempt.

This was answered from the *intended* model rather than from the view, which
is the layer-1-thinking-applied-to-layer-2 error CLAUDE.md §3b names. Counting
the clauses of clause 3 was never going to surface it; the fact lives one join
away, in a view neither pass read.

**It also undermines the authority model.** The Main-vs-Additional split in
ZYRA_SAFETY_CONCERN_DISCLOSURE_AND_AUTHORITY_MODEL §2 assumes Additional is
the low-privilege tier. At the visibility layer it is not a tier at all — it
is a label on a row that grants exactly what Main grants.

---

## 4. On the Guardian presentation — confirmed, with one addition

Agreed as stated: no automatic copy, choose from photos already uploaded,
or upload a Guardian-specific one, same for the bio.

One addition, from A1. **If a Guardian's presentation is separate, it must
still be attributable.** A Guardian catalogue-builder benefits from a
Guardian presentation that looks unconnected to their Seeker profile. The
identity fields — name, surname, age — stay shared, which is what keeps the
two attributable to one person. That is already the model; it is worth
recording as a *safety* property and not only a data-modelling convenience,
so nobody later "improves" it by allowing a Guardian alias.

---

## 5. Revised sequence

Unchanged from pass 1, with three insertions:

| | | |
|---|---|---|
| 1 | Status guard on clause 3 | unchanged — do this now, standalone |
| 2 | Invite hardening | unchanged |
| **2b** | **Notification content rules** — A2 | before anyone extends notifications |
| 3 | Agree the matrix — plus A4, removed-Guardian revocation | |
| 4 | Build `zyra_can_view(viewer, target, surface)` | |
| **4b** | **`ages_for()` narrowed** — A5 | trivial, do it alongside |
| 5 | `can_introduce()` — **with A3's second condition** | |
| 6 | Family Network | |
| **—** | **A1: decide the Guardian-count position** | not sequenced, because it is a product decision rather than a build |

---

## 6. What I would put to you

**A1 is the one that needs your judgement rather than my analysis.**

Every technical option refuses something legitimate. Capping Guardians at
five turns away the uncle who genuinely looks after four nieces. Capping at
fifty is not a cap. Requiring review needs an admin that does not exist.

Showing the number — *"Hassan is Guardian to 14 other Seekers"* — is the only
option that costs a legitimate Guardian nothing and costs a
catalogue-builder everything. It also fits the product: ZYRA's proposition
is that families can see who they are dealing with.

I would not build any of the caps. I would show the number.
