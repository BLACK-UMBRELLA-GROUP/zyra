# ZYRA — Reference stability: implementation plan

**Status:** PLAN ONLY — nothing changed. For approval.
**Date:** 2026-08-08
**Approved in principle:** Option D now · Option A scheduled · check in
`zyra_check.py`

No database changes in this plan. One governance change, one tool change.

---

## 1. The problem the plan has to solve first

Adding the check naively **fails immediately and permanently**, because
13 dangling references already exist. A check that is red from the moment it
is installed is a check people learn to ignore — and then it is worse than
not having one, because it looks like coverage.

`zyra_check.py` currently prints `clean` per category and exits non-zero
under `--quiet` when anything is found. Dropping 13 findings into it turns
a tool that has read `0 finding(s)` all week into one that never will.

**So the check ships with a baseline.**

---

## 2. Change 1 · `tools/zyra_check.py` — new check with a baseline

### What it does

For every `.md` filename mentioned in `SOURCE/lib/**/*.dart`, confirm a file
of that name exists anywhere under the ZYRA tree. Report the ones that do
not.

### The baseline

A literal set in the file, listing the 13 known-dangling references:

```python
# BASELINE — references already broken on 2026-08-08, before the check
# existed. Listed so the check reports only NEW breakage. Every entry is
# a reference orphaned by a version bump, and every entry disappears when
# Option A runs. DO NOT ADD TO THIS SET — a new dangling reference is a
# finding, not a baseline entry.
DANGLING_BASELINE = {
    'WALI_ARCHITECTURE_CURRENT_VERSION_V5.md',      # 8 sites, now V6
    'BROWSE_UX_SPEC_CURRENT_VERSION_V3.md',         # 2 sites, now V4
    'BROWSE_UX_SPEC_CURRENT_VERSION_V1.md',         # 1 site,  now V4
    'ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md',      # 1 site,  now V5
    'IMAGE_HANDLING_CURRENT_VERSION_V1.md',         # 1 site,  now V2
}
```

Reported separately as a count, not silence:

```
  DANGLING DOC REF   clean  (5 baselined, see Option A)
```

**Visible, not hidden.** A baseline that reads as `clean` with no
qualification is how debt becomes invisible.

### Two false-positive sources I have to handle

Measured while producing the audit — my first pass produced 20 "dangling"
entries and **7 were artefacts**:

1. **Fragments.** A regex for `[A-Za-z0-9_]+\.md` splits filenames across a
   wrapped comment line, yielding `V1.md`, `VERSION_V1.md`, `26.md`. Fixed
   by joining wrapped comment lines before matching and requiring a minimum
   length and an uppercase-prefix shape.
2. **Documents with spaces in the name.** `Mapping.md`, `Diagram.md`,
   `Values.md` are tails of real filenames containing spaces. Fixed by
   matching against the set of real `.md` basenames including their
   space-separated forms, rather than assuming one token.

Without these the check cries wolf on its first run, which is the same
failure mode as the baseline.

### Not wired into `run.sh`

`zyra_check.py` is advisory and run by hand today. This plan does not change
that — making it block a build is a separate decision with its own
trade-offs.

---

## 3. Change 2 · `NAMING_CONVENTIONS_V1.md` — Rule 6

Governance change. Adds to §5:

> **Rule 6 — References cite the SYSTEM, never a versioned filename.**
>
> Code comments, database comments and cross-document references name the
> system (`WALI_ARCHITECTURE`) or a stable current filename. **A reference
> containing `_V<n>` is a reference that will break, by design, on a
> schedule this convention mandates.**
>
> This is invariant I1 applied to documentation: a permanent reference must
> not rest on a name the convention requires to change. Thirteen references
> across five documents were already broken this way before the rule
> existed — including eight pointing at `WALI_ARCHITECTURE_CURRENT_VERSION_V5.md`,
> a file that no longer exists in any form.

And a forward note under §2, so the eventual rename is not a surprise:

> **Scheduled:** current-version filenames will drop `_V<n>`
> (`WALI_ARCHITECTURE_CURRENT.md`). The version stays in the document header
> and in archive filenames. See the Reference Stability Proposal.

**I am not editing §2's format lines yet** — that is Option A, and changing
the stated convention before the 55 files match it would leave the document
describing a state that does not exist.

---

## 4. What is NOT in this plan

- **Option A itself** — 55 renames and ~127 reference updates. Scheduled, not
  now, and it gets its own plan with its own verification.
- **Any database change.** The two comments I added this week
  (`accept_wali_invite`, `profile_blocks`) cite
  `ZYRA_GUARDIAN_ROMANTIC_RULES_CURRENT_VERSION_V1.md` and are therefore
  already Rule-6 violations. They are correct *today* because that file
  exists. **I would fix them during Option A, not before** — changing them
  now to a system name that does not yet resolve to a stable filename
  trades a working reference for a vaguer one.
- **Blocking the build.** Advisory stays advisory.

---

## 5. Verification

| Check | Expected |
|---|---|
| `zyra_check.py` on the tree as it stands | `0 finding(s)` — baseline absorbs the 13 |
| New category line | `DANGLING DOC REF   clean  (5 baselined, see Option A)` |
| Introduce a fake reference to a non-existent doc | **1 finding**, named, with file and line |
| Reference a real doc whose name contains spaces | no finding |
| A wrapped comment splitting a filename | no finding |
| Existing five categories | unchanged, still clean |
| Run time | within a second of current |

The third row is the one that matters: a check that cannot be shown to catch
the thing it exists for is decoration.

---

## 6. Awaiting

Approval for §2 and §3. Nothing changed.
