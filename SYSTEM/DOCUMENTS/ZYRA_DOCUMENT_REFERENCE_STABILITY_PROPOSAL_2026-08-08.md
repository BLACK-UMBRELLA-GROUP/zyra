# ZYRA — Stable document references: proposal

**Status:** PROPOSAL — nothing changed. For decision, not urgent.
**Date:** 2026-08-08

---

## 1. The debt is not hypothetical. It has already happened five times.

You raised this as a risk. It is a live defect.

Measured across `SOURCE/lib`: **127 reference sites naming 36 distinct
documents.** Of those, references to **13 sites across 5 documents point at
filenames that no longer exist.**

| Dangling reference | Sites | Why |
|---|---|---|
| `WALI_ARCHITECTURE_CURRENT_VERSION_V5.md` | **8** | now at V6 |
| `BROWSE_UX_SPEC_CURRENT_VERSION_V3.md` | 2 | now at V4 |
| `BROWSE_UX_SPEC_CURRENT_VERSION_V1.md` | 1 | now at V4 |
| `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md` | 1 | now at V5 |
| `IMAGE_HANDLING_CURRENT_VERSION_V1.md` | 1 | now at V2 |

Every one was created by a version bump doing exactly what the convention
says it should.

**And it fails in the worst available way.** The archive rule renames the old
file to `<SYSTEM>_<DATE>_V<n>.md`, so the referenced name does not become
*outdated* — it **ceases to exist**. A developer following
`WALI_ARCHITECTURE_CURRENT_VERSION_V5.md` finds nothing, and cannot tell
whether the document was renamed, deleted, or never existed. Eight comments
in the Guardian system are in that state today.

The two database comments I added this week join the same queue.

---

## 2. This is I1 again

From the invariants document, written this morning:

> Permanent behaviour must derive from permanent data.

A code comment is a permanent reference. A filename containing a version
number is **temporary data** — it changes by design, on a schedule the
convention itself mandates.

Same mistake as `profile_complete` and the block row: something durable
anchored to something the system is expected to change. Third instance, and
the first outside the database.

---

## 3. Options

### A · Drop the version from the current filename — RECOMMENDED

```
Current   WALI_ARCHITECTURE_CURRENT.md          ← never changes
Archive   WALI_ARCHITECTURE_2026-06-12_V5.md    ← unchanged convention
```

The version number moves into the document header, where it already is:
`**Version:** V6`.

| | |
|---|---|
| **Cost** | Rename 55 files; update 127 reference sites, most by deleting `_V<n>` |
| **Ongoing cost** | None. References never break again |
| **Infrastructure** | None |
| **Risk** | One mechanical pass, verifiable by re-running the dangling-reference check |

**What the version in the filename actually buys:** knowing the version
without opening the file. The header already says it, and the archive
filenames still carry it. That convenience is what is breaking every link.

### B · A stable pointer file per system

`WALI_ARCHITECTURE.md` contains one line: *"Current version:
WALI_ARCHITECTURE_CURRENT_VERSION_V6.md"*.

Non-invasive, and it adds a 56th thing to keep in sync — which is a new
instance of the same problem it is solving. **Not recommended.**

### C · A registry table in the database

`zyra_governance_docs(doc_key, title, current_path)`; comments cite
`doc_key`. Resolvable by query, and makes documents discoverable from the
schema.

But the database now has to be updated whenever a document is versioned —
two sources of truth, kept in step by hand. **I3 says sameness must be
structural, not maintained.** Not recommended as the primary fix, though
worth revisiting later purely for discoverability.

### D · Reference the system name, no filename

*"See WALI_ARCHITECTURE (current version)."* Zero cost, no rename, and a
glob finds it.

Weaker than A — a reader must know the convention to resolve it — but it is
the **right rule for new references regardless of whether A happens**, and
it costs nothing to adopt today.

---

## 4. Recommendation

**Adopt D immediately as the rule for all new references. Schedule A as a
one-off cleanup.**

D stops the debt growing from this moment for free. A clears the 13 existing
dangling references and removes the class permanently.

They compose: after A, a bare system name resolves to `<SYSTEM>_CURRENT.md`
directly, so D becomes the natural way to cite it rather than a workaround.

---

## 5. What would change in `NAMING_CONVENTIONS_V1`

§2 currently reads:

```
Current versions   DOCUMENT_NAME_CURRENT_VERSION_VN.md
Archived versions  DOCUMENT_NAME_YYYY-MM-DD_VN.md
```

Proposed:

```
Current versions   DOCUMENT_NAME_CURRENT.md      — filename NEVER changes
                   Version lives in the header:  **Version:** V6
Archived versions  DOCUMENT_NAME_YYYY-MM-DD_VN.md      (unchanged)
```

Plus a new rule in §5:

> **Rule 6 — References cite the SYSTEM, never a versioned filename.**
> Code comments, database comments and cross-document references name the
> system (`WALI_ARCHITECTURE`) or its stable current filename. A reference
> containing `_V<n>` is a reference that will break, by design, on a
> schedule this convention mandates.

---

## 6. A verification worth keeping

The check that produced §1 is ten lines and answers *"does every document a
comment names still exist?"* Worth running whenever a document is versioned
— it turns a silent breakage into a visible one, which is the same move as
revoking a grant so a failure becomes loud rather than a no-op.

I can add it to `tools/zyra_check.py`, which already runs before every build
and reports clean or not. That would make it structural rather than
remembered — I3 again.

---

## 7. Awaiting

Your decision on A, D, or both. Nothing changed. The 13 dangling references
are stable and have been for weeks; this is debt to schedule, not an
incident.
