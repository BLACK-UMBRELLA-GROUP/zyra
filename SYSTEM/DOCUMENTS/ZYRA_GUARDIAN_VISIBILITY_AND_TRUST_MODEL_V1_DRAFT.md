# ZYRA — Guardian Visibility & Trust Model

**Status:** DRAFT FOR REVIEW — nothing built. Supersedes nothing until approved.
**Date:** 2026-08-08

One model covering invitations, visibility, permissions, introductions,
family discovery, commercial unlocks and Journey progression — because
every leak found so far sat in the seam between two of those.

---

## Part 1 — Principles

Four rules. Everything in Part 3 is derived from them, so a future feature
can be checked against these rather than against a table it might not have
read.

### P1 · Visibility follows accountability

**You may see what you could be asked to act on.**

A Main Guardian approves, refuses and speaks for the family — so they see
the counterpart. An Additional Guardian takes no action against the
counterpart family, so they see the Journey, not the strangers in it.

This single rule removes most of the current leak. There is no feature,
built or planned, in which an Additional Guardian does anything involving
the other family's Guardians.

### P2 · Consent is staged, and each stage buys exactly one step

The present bug is a consent-level confusion, and it is worth naming
precisely:

| Act | What the user consented to |
|---|---|
| Mutual Like | *"I am willing to be considered by this person"* |
| Starting a Journey | *"I am willing to be examined by them and their family"* |
| Reaching `wali_gate` | *"Our families may now meet"* |

**Today a mutual Like grants all three.** Two people expressing interest in
each other currently exposes both families' full Guardian rosters, with no
Guardian asked and no Journey begun.

**The product already agrees with this principle** — it has a stage
literally named `wali_gate`, the Guardian Gate, sitting third in the
sequence. The intended moment for families to meet is encoded in the state
machine. Only the visibility rules ignore it.

### P3 · Paid must be strictly greater than free

Unlock+ currently returns **less** than Guardian visibility gives away for
nothing. Any tier must be a superset of the tier beneath it, or the
commercial model is not merely bypassed but inverted.

### P4 · Required, not convenient

For every field, at every stage, for every role, one question:
**what decision does this person make that needs it?**

If no decision needs it, it is convenience, and convenience is how a
matchmaking app becomes an intelligence product.

---

## Part 2 — The actual state machine

Taken from the live constraints, not invented.

```
matches.status         potential → active → ended        (+ paused_by while active)
matches.journey_stage  compatibility_reveal → salam_exchange → wali_gate
                       → phase_1 → phase_2 → phase_3 → family_stage → conversation
```

Six visibility states, which is what the matrix is indexed on:

| State | Meaning |
|---|---|
| **Pre-match** | one-sided Like. No match row exists |
| **Potential** | mutual Like. A match row exists. No Journey started |
| **Active · pre-gate** | `compatibility_reveal`, `salam_exchange` |
| **Active · post-gate** | `wali_gate` onwards |
| **Paused** | active with `paused_by` set |
| **Ended** | with a reason |

---

## Part 3 — The permission matrix

Six roles. `—` is nothing at all: the person is not merely hidden, they are
not discoverable.

### 3.1 · What the SEEKER sees of the counterpart

| | Pre-match | Potential | Active pre-gate | Active post-gate | Paused | Ended |
|---|---|---|---|---|---|---|
| Identity card, photos | Browse rules | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bio | Browse rules | ✅ | ✅ | ✅ | ✅ | ✅ |
| `seeker_details` | Unlock | Unlock | ✅ | ✅ | ✅ | frozen |
| Compatibility answers | — | — | ✅ | ✅ | ✅ | frozen |
| Their Guardian roster | **Unlock+** | **Unlock+** | **Unlock+** | ✅ Main only | ✅ Main only | frozen |
| Conversation | — | — | — | ✅ | read-only | frozen |

**Unchanged from today except the Guardian roster row**, which is the
commercial fix: Unlock+ remains the *only* route before the gate, and after
the gate it is included because the families are by then in contact.

### 3.2 · What the OWN MAIN GUARDIAN sees

| | Pre-match | Potential | Active pre-gate | Active post-gate | Paused | Ended |
|---|---|---|---|---|---|---|
| Own Seeker's profile | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| That a Journey exists | — | ✅ count only | ✅ | ✅ | ✅ | ✅ |
| Counterpart identity card | — | **—** | ✅ | ✅ | ✅ | ✅ |
| Counterpart `seeker_details` | — | — | ✅ | ✅ | ✅ | frozen |
| **Counterpart MAIN Guardian** | — | **—** | **—** | ✅ | ✅ | frozen |
| **Counterpart ADDITIONAL Guardians** | — | **—** | **—** | **—** | **—** | **—** |
| Seeker↔Seeker conversation | — | — | — | ✅ read | ✅ read | frozen |
| Main↔Main conversation | — | — | — | ✅ | ✅ | frozen |

**The four bold cells are the fix.** At `potential` a Main Guardian learns
a Journey *may* begin — a count, not a person. They meet the counterpart
when the Journey actually starts, and the other family only at the Guardian
Gate, which is the stage that exists for exactly that.

**Counterpart Additional Guardians are never visible to anyone outside
their own family.** No feature requires it. This is P1 applied.

### 3.3 · What an ADDITIONAL GUARDIAN sees

| | Potential | Active pre-gate | Active post-gate | Paused | Ended |
|---|---|---|---|---|---|
| Own Seeker's profile | ✅ | ✅ | ✅ | ✅ | ✅ |
| That a Journey exists | ✅ count | ✅ | ✅ | ✅ | ✅ |
| Journey stage | — | ✅ | ✅ | ✅ | ✅ |
| Counterpart identity card | — | — | ✅ | ✅ | frozen |
| Counterpart `seeker_details` | — | — | — | — | — |
| **Any counterpart Guardian** | **—** | **—** | **—** | **—** | **—** |
| Seeker↔Seeker conversation | — | — | ✅ read | ✅ read | frozen |
| Main↔Main conversation | **—** | **—** | **—** | **—** | **—** |

**An Additional Guardian is a witness, not a party.** They see their own
Seeker's Journey and, once families have met, who it is with. They never
see the other family's Guardians and never see the Main↔Main channel.

The one place this is stricter than today is deliberate: it is the
difference between oversight and access.

### 3.4 · "Frozen" and "count only"

Two states the current model has no concept of, and both are load-bearing.

**Frozen** — an ended Journey keeps what was already seen, and gains
nothing. Otherwise ending a Journey becomes a way to keep watching, and
`restart_journey()` becomes a re-entry into someone's data.

**Count only** — *"Fatima has 3 potential Journeys"* with no identities.
A Guardian learns their Seeker is active without learning who by, which is
the honest amount of information at a stage where nobody has agreed to
anything.

---

## Part 4 — Invitations are part of the trust model

Not an isolated bug. Invitations are **the entry point to the entire trust
graph** — everything in Part 3 is granted by holding a `wali_links` row, and
an invite is how that row comes to exist.

### Current state

| | |
|---|---|
| Token | `gen_random_bytes(4)` — **32 bits** |
| `preview_wali_invite()` | any authenticated user, no rate limit, no log |
| Returns | the inviter's **first name** and role |
| Found token can be | **accepted**, not just previewed |

Harvesting *any* valid invite from 10,000 outstanding ones takes ~430,000
guesses. Minutes.

### Proposed

1. **16-byte tokens.** Column is `text`; widening is not a migration hazard.
2. **Rate-limit preview and accept per caller** — the `app_feedback` pattern
   already in this codebase (count recent rows, refuse past a threshold).
3. **Log failed previews.** Currently a brute-force attempt is invisible.
4. **Bind invites to a recipient where possible.** A bearer token that
   confers a surveillance position is the wrong shape. This is already open
   as *"Addressed invitations"* and it is the real fix — the rest is
   hardening a design that should change.
5. **Short expiry.** `expires_at` exists; the window should be hours, not
   open-ended, because an unaccepted invite is a live credential.

---

## Part 5 — Introductions, family discovery, unlocks

### Introductions — the third predicate

A Guardian deliberately putting a person in front of their Seeker is
Guardian-derived visibility producing a romantic outcome, which invariant
two forbids. It is legitimate, so it is a **third category**, not an
exception:

```
can_view(a, b)        may this person see this?
can_match(a, b)       may these two pursue each other?
can_introduce(g, s, c) may Guardian g put candidate c in front of Seeker s?
```

`can_introduce` must require: an active link between g and s, `can_match(s,
c)` **true**, and — the part that does not exist today — that the Guardian
could already see c **without** using Guardian-derived visibility.

Otherwise Introductions launder the leak: a Guardian sees a candidate only
because of Part 3 access, then introduces them, converting privileged
visibility into a romantic edge.

### Family discovery

**Nothing may enumerate the family graph.** Family Network is a 205-line UI
shell with no backend, which makes this cheap to state now and expensive
later. **Introduction-only, explicit consent from both families, no
browsing, no counts, no "families near you".**

### Commercial unlocks

| Tier | Buys |
|---|---|
| Free | Browse rules only |
| Unlock | `seeker_details` |
| **Unlock+** | **the Guardian roster — Main and Additional, with relationship** |
| Post-gate | Main only, free, because the families have met |

**Unlock+ must remain the only pre-gate route to the roster**, and it
returns strictly more than the post-gate free view. That restores P3 and
makes the purchase worth something: earlier access, and more of it.

---

## Part 6 — What this means in code

Not attempted. Scoped so the size is visible.

1. **`zyra_can_view_profile()` is retired as a single function.** It grew to
   four clauses over months and clause 3 is the leak. Replaced by
   `zyra_can_view(viewer, target, surface)` — surface being identity,
   details, photos, roster, conversation — so each cell of Part 3 is one
   testable answer rather than an emergent property of four ORs.
2. **The participant view stops conferring visibility.**
   `zyra_attempt_participant_rows` is a good model of *who is party to an
   attempt* and a bad basis for *who may see whom*. Those are different
   questions and it is currently answering both.
3. **Role and stage become explicit inputs**, replacing the current
   any-participant-sees-any-participant rule.
4. **`guardians_for_unlocked()` gains the post-gate free path** and keeps
   its paid path.
5. **Invite hardening** — Part 4.
6. **`can_introduce()`** — Part 5.

**Honest estimate, and estimates on this project have been wrong in one
direction:** larger than the write-side work, because the read side has more
surfaces and every one needs a test per role per stage. The matrix has
roughly 90 cells. That is 90 tests, and it is the point — the write side is
now provable, and this is what makes the read side provable too.

---

## Part 7 — Decisions needed before building

1. **Is `wali_gate` the right threshold** for families meeting? It is where
   the state machine says so. Confirm rather than assume.
2. **Count-only at `potential`** — is even a count too much? *"Fatima has 3
   potential Journeys"* tells a Guardian something. The alternative is
   nothing until a Journey starts.
3. **Does an Additional Guardian ever need the counterpart's identity?**
   Part 3.3 grants it post-gate. Defensible either way.
4. **Frozen on ended** — confirm that ending stops the clock rather than
   revoking. Revoking is stricter and may be right, but it would remove a
   family's record of who their daughter spoke to.
5. **Main Guardian changes mid-Journey.** If the Main changes after the
   gate, the outgoing Main has seen the counterpart family. Do they keep it?
   Frozen says yes. **This is the one cell I am least sure of.**
6. **Photo choice** — agreed: no automatic copy, user picks from photos
   already uploaded or adds a Guardian-specific one. Needs the presentation
   table from the two-profile challenge to exist first.

---

## Part 8 — What I would sequence

| | | Why here |
|---|---|---|
| 1 | **Status guard on clause 3** | One condition. Closes the "before a Journey begins" half today, without waiting for the matrix |
| 2 | **Invite hardening** | Independent, small, and it is a live credential |
| 3 | **Agree the matrix** — Part 7 | Six decisions, no code |
| 4 | **Build `zyra_can_view(viewer, target, surface)`** | The real fix |
| 5 | **`can_introduce()`** | Depends on 4 |
| 6 | **Family Network** | Only after 4 and 5 exist |

Step 1 is worth doing immediately and separately. It is a one-line change to
an existing clause, it closes the most serious half of the leak, and it does
not depend on a single decision in Part 7.
