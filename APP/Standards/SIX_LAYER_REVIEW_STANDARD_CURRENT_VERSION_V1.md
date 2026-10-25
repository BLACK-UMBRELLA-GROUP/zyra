---
id: DOC-ZYRA-0065
type: STANDARD
status: CURRENT
feature: APP: STANDARDS
purpose: Standards — SIX LAYER REVIEW STANDARD CURRENT VERSION V1: ZYRA — The Six-Layer Review Standard
links: []
owner: ZYRA chat
---

# ZYRA — The Six-Layer Review Standard

**Status:** APPROVED — Founder, 2026-08-06
**Applies to:** every architectural estimate, review and migration plan
**Origin:** three estimation errors of the same class during OA-ZYRA-156

---

## The process

1. **Review the six layers.**
2. **Perform a dependency review across them.**
3. **Verify the implementation against the running system.**

Step 1 tells you what the thing is. Step 2 tells you what breaks when you
touch it. Step 3 tells you whether you were right.

---

## The rule

**No estimate, review or plan is complete until all six layers have been
read.**

| # | Layer | Typical question it answers |
|---|---|---|
| 1 | **Schema** | What tables and columns exist? |
| 2 | **RLS policies** | Who may read or write each row, and under what condition? |
| 3 | **RPC / function bodies** | What business logic runs server-side? |
| 4 | **Triggers** | What happens that nobody called? |
| 5 | **Client implementation** | What does the app actually do with all of it? |
| 6 | **Documentation** | What do we believe is true? |

Reading fewer layers does not produce a smaller estimate. It produces a
**wrong** one, and the error is always in the same direction — the work is
larger than it looked.

---

## Why this exists

Three findings during OA-ZYRA-156, all the same failure:

| Believed | Actual | Layer that would have caught it |
|---|---|---|
| 15 RLS policies | **19** | 2 — RLS policies |
| One authorisation question, mechanically re-pointable | **Four distinct patterns.** Re-pointing them all at one boolean function would have given Guardians the private phase answers Seekers write, shown them Journeys that had not started, and let every additional Guardian read Family Review decisions | 2 — policy *bodies*, not just their count |
| Nine tables to re-point | Nine tables **plus eleven RPCs** reading those tables by `match_id`. The Journey lifecycle lives in the function layer | 3 — RPC bodies |

Each estimate was made competently from the schema. The schema simply does
not contain the answer.

**The pattern:** structure is visible from the outside; behaviour is not.
Layer 1 tells you what exists. Layers 2–5 tell you what it *does*.

---

## Applying it

### Counting is not reading

"There are fifteen policies" is layer-1 thinking applied to layer 2. The
count was also wrong, but the count was never the point — **four different
rules** was the finding, and no amount of counting would have surfaced it.

Read the bodies. Group them by what they actually assert.

### Layer 6 is a source, not the truth

Where documentation and implementation disagree, **the implementation is
what users experience**. Record the drift, follow the code, and correct the
document — in that order.

Every current-state claim in
`ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md` was read from the live
database rather than the specifications, and that is why V3 is trustworthy
where its predecessors were not.

### A layer with nothing in it is still a finding

"No scheduled jobs exist" is why the 30-day auto-End timer was only ever a
paragraph in a specification. Checking layer 4 and finding it empty answered
the question; assuming it was implemented would have produced work that did
not need doing.

---

## Step 2 — the Dependency Review

**Founder addition, 2026-08-06.** Not a seventh layer. A deliberate pass
*across* the six, once each has been read.

> *"Many of the surprises weren't caused by missing schema knowledge, but by
> hidden cross-layer dependencies."*

That is the sharper diagnosis. Reading all six layers tells you what each
one contains. It does not tell you **what breaks when you change one of
them** — because a dependency lives in the gap between two layers and is
therefore invisible from inside either.

### The six questions

For every object you intend to change, ask:

1. What else depends on this that may not be obvious?
2. Which **RPCs** consume it?
3. Which **client code** consumes it?
4. Which **documentation** depends on it?
5. Which **helper functions or security policies** depend on it?
6. Which **future or approved architecture** could be affected?

### What this would have caught in OA-ZYRA-156

Every one of these was found by a failure, not by a plan.

| Dependency | Spans | How it surfaced |
|---|---|---|
| Dropping `match_id` breaks **11 RPCs** | schema → RPC | A deliberate check, and only because the same class of error had already bitten twice |
| An RLS policy reading a **revoked view** | RLS → privileges | Every rewritten policy failed with *permission denied* on first run |
| `zyra_can_view_profile` cannot be dropped because **`profiles_select` depends on it** — and that policy governs Browse | function → policy | `create or replace view` refused; the cascade would have taken Browse with it |
| Changing a Dart return type from `bool` to an enum | client → client | `flutter analyze` caught it; the static checker could not |
| `create_notification` had **no Dart caller** but three RPC callers | RPC → RPC | Checked before revoking; had I assumed either way I would have been wrong |

Note the shape. **Not one of these is visible from inside a single layer.**
The schema does not know which functions read it. A policy body does not
mention the grant it silently requires. A function does not list its callers.

### Direction matters

Layer review is *downward* — what does this thing contain? Dependency
review is *upward* — what points at it?

Postgres will answer most of these directly: `pg_depend`, `pg_policies`,
`pg_proc.prosrc`, `information_schema.role_table_grants`. Grep answers the
client. The documentation index answers the docs. **Ask the system rather
than remembering.**

### Approved architecture counts as a dependency

Question 6 is the one most easily skipped, and it changed the plan twice
here: `restart_journey` was not migrated because OA-ZYRA-159 replaces it,
and no interim consent handshake was built because the approved one would
have replaced it within days. Work that exists only on paper still makes
present work unnecessary.

---

## Step 3 — verification

Reading six layers and their dependencies tells you what the work is. It
does not tell you the work succeeded.

Every change in OA-ZYRA-156 was proved against the live database before and
after — which caught a policy set that failed with *permission denied*
within a minute of being applied, and a baseline test that measured nothing
because its actor had no data.

**Estimate across six layers. Trace the dependencies between them. Verify
against the running system.**

---

## Checklist

Before an estimate or plan is presented:

**Step 1 — the six layers**

- [ ] **Schema** — tables, columns, constraints, indexes read
- [ ] **RLS** — every policy *body* read, not counted; distinct patterns named
- [ ] **RPCs** — every function that touches the affected tables read
- [ ] **Triggers** — including those that fire on tables you are not changing
- [ ] **Client** — call sites counted; which are reads, which are writes
- [ ] **Docs** — checked against the above, drift recorded

**Step 2 — dependency review**, for each object being changed

- [ ] Which **RPCs** consume it?
- [ ] Which **client code** consumes it?
- [ ] Which **documentation** describes it?
- [ ] Which **policies, views, helper functions or grants** depend on it?
- [ ] Which **approved-but-unbuilt architecture** assumes it?
- [ ] Anything else pointing at it that none of the above would reveal?

**Step 3 — verification**

- [ ] Behaviour captured **before** the change
- [ ] Same measurement repeated **after**
- [ ] Negative cases proved, not just positive ones

Any layer or question not covered is stated explicitly as unreviewed, with
the risk that carries. **An estimate with a named gap is useful. One with a
silent gap is not.**

---

## Planned for V2

**An appendix of the actual queries** — dependency inspection, policy
inspection, function inspection and the rest — so each step can be run
rather than remembered.

Founder suggestion, 2026-08-06, deliberately not held back for. A standard
that says *"ask `pg_depend`"* is already better than one that does not; a
standard that hands you the query is better still, and is what makes this
consistent for a contributor who was not here for OA-ZYRA-156.
