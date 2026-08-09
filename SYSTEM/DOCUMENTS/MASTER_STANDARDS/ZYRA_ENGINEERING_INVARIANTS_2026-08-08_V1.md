# ZYRA — Engineering Invariants

> **ARCHIVED 2026-08-08 — reference only. Superseded by V2, which is the
> source of truth.** This version holds I1–I4; V2 adds I5 (semantic
> verification), I6 (tools report, owners decide) and I7 (scope by approval).
> Where this document and V2 differ, V2 wins.

**Status:** APPROVED — Founder, 2026-08-08
**Applies to:** every migration, feature and review, in every area
**Origin:** the same architectural mistake made twice, five days apart, in
two unrelated systems

Sibling to the Six-Layer Review Standard, and written for the same reason.
That standard came from three estimation errors of one class; this comes
from two design errors of one class. Both exist so the class is recognised
next time instead of rediscovered.

**These outrank feature documents.** Where an invariant and a spec conflict,
the invariant wins and the spec is wrong.

---

## I1 · Permanent behaviour must derive from permanent data

> **Temporary state — blocks, invitations, sessions, toggles, publication
> flags — must never be the sole source of a permanent permission or
> restriction.**

### Where it came from

Two bugs, unrelated areas, five days apart, identical shape:

| | Keyed on (temporary) | Corrected to (permanent) |
|---|---|---|
| **Identity freeze** — gender and DOB frozen after publication | `profile_complete`, which the user may switch off | `first_published_at`, written once and never cleared |
| **Block revocation** — visibility revoked when someone is blocked | a `profile_blocks` row, which the user may delete | `end_reason = 'safety_concern'`, recorded on the match forever |

Both read correctly. Both were undone by a state the user controls.

The first became a loophole: un-publish, change your identity, republish.
The second was caught by its own verification within minutes of being
applied — unblocking silently restored visibility the invariant said must
never return.

### The test

For any permanent consequence:

> **Can the user clear the thing this depends on?**

If yes, it is the wrong anchor. Find the fact that cannot be cleared.

### Corollaries

- **A reversible flag is not a fact about the past.** `profile_complete`
  answers *"are they published now"*, never *"were they ever"*.
- **Deletion is a user action.** Any row a user may delete is temporary,
  however permanent its meaning feels.
- **It applies outside the database too.** A reference keyed on a filename
  containing a version number is a permanent link resting on a temporary
  name — see the documentation-reference proposal.

---

## I2 · A block is a terminal safety boundary

> **Nothing may automatically recreate or restore any relationship,
> visibility, conversation or Journey that existed before a block. Any
> future interaction must begin as an entirely new relationship under the
> normal rules.**

What it does **not** forbid: two people who unblock may find each other
through ordinary Browse and start fresh. They are two eligible users, not a
restored pair. **Ordinary discovery is not restoration.**

---

## I3 · One path, or the paths will drift

> **Where two operations must be indistinguishable, they must share one
> implementation — not two implementations kept in step.**

Ordinary Journey endings and safety endings both run through
`zyra_end_match_internal()`. Two paths would eventually diverge, and **the
divergence would itself be the disclosure** that the whole substitution
exists to prevent.

Generalises: any time correctness depends on two things *looking the same*,
sameness must be structural rather than maintained.

---

## I4 · A rule inside one function applies only to that function's callers

> **Enforce at the layer that cannot be skipped. A rule in application code
> is a convention; a rule in a policy or constraint is an invariant.**

Recorded from the same review cycle:

- The romantic-eligibility rules went into the **RLS `WITH CHECK`**, not only
  the match trigger — a trigger can be disabled for a transaction, and this
  project disabled one twice in one day to run backfills.
- `zyra_can_guardian_link()` began as an inline `EXISTS` inside
  `accept_wali_invite()`. Correct for the only write path that existed;
  invisible to the next one. It is now a predicate plus a `BEFORE` trigger.
- Column-level ownership that RLS cannot express — one column, private for
  one value and joint for five — is enforced by **revoking the column** and
  exposing an accessor, following `profiles.date_of_birth`.

### Corollary — grants are three separate things

`PUBLIC`, `anon` and `authenticated` are independent. Revoking one does not
touch the others, and Supabase's default privileges grant `anon` explicitly.
**Verify every grant change with `has_function_privilege()` or
`information_schema`; never assume a statement did what it reads like.**

This project has been caught by that fact three times.

---

## Applying these

Every migration plan states which invariants it touches and how it satisfies
them. A plan that cannot name one is not necessarily wrong — but a plan that
*violates* one needs the invariant changed first, in this document, with the
Founder's approval.

New invariants are added when a mistake has been made **twice**. Once is an
error; twice is a class.
