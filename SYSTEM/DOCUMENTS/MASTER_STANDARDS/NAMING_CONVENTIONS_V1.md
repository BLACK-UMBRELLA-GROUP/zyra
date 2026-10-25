---
id: DOC-ZYRA-0270
type: STANDARD
status: CURRENT
feature: ZYRA STANDARDS
purpose: ZYRA — Naming Conventions
links: []
owner: ZYRA chat
---

# ZYRA — Naming Conventions
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/REPOSITORY_ARCHITECTURE_V3

---

## 1. Scope

These naming rules apply to all files within PROJECTS/ZYRA/.
They inherit from and extend REPOSITORY_ARCHITECTURE_V3.

---

## 2. Document Naming

### Current versions
```
DOCUMENT_NAME_CURRENT_VERSION_VN.md
```

### Archived versions
```
DOCUMENT_NAME_YYYY-MM-DD_VN.md
```

### Working drafts
```
DOCUMENT_NAME_WORKING_DRAFT_VN.md
```

> **Scheduled change — not yet in effect.** Current-version filenames will
> drop `_V<n>` and become `DOCUMENT_NAME_CURRENT.md`, so the filename never
> changes. The version stays in the document header (`**Version:** V6`) and
> in archive filenames, which are unaffected. Until the 55 existing files are
> renamed, the format above is the one in force — see the Reference Stability
> Proposal. **Rule 6 applies now regardless of when that rename happens.**

---

## 3. ZYRA-Specific Prefixes

| Prefix | Meaning |
|--------|---------|
| `ZYRA_` | Project-wide documents |
| `PRODUCT_` | Product specifications |
| `SPEC_` | Feature specifications |
| `DESIGN_` | Design decisions |
| `RESEARCH_` | Research documents |
| `OA-ZYRA-` | ZYRA outstanding action IDs |

---

## 4. Outstanding Action IDs

Format: `OA-ZYRA-NNN`
Example: `OA-ZYRA-001`

Sequence starts at OA-ZYRA-001 and increments.

---

## 5. Rules

1. All file names UPPER_CASE with underscores
2. No spaces in file names
3. Version suffix mandatory on all governed documents
4. Working drafts must be promoted or deleted — not left indefinitely
5. References cite the SYSTEM, never a versioned filename — see below

### Rule 5 — References cite the SYSTEM, never a versioned filename

Code comments, database comments and cross-document references name the
system (`WALI_ARCHITECTURE`), not a file (`WALI_ARCHITECTURE_CURRENT_VERSION_V6.md`).

**A reference containing `_V<n>` is a reference that will break, by design,
on a schedule this document mandates.** Rule 3 requires the version suffix;
§2's archive rule then *renames* the file on every bump. So the referenced
name does not go stale — it ceases to exist. Anyone following it finds
nothing and cannot tell whether the document was renamed, deleted, or never
written.

This is invariant I1 applied to documentation: permanent references must not
rest on names the convention requires to change.

**Measured on 2026-08-08, before the rule existed:** 14 dangling reference
sites across 6 documents in `SOURCE/lib` — 8 of them pointing at
`WALI_ARCHITECTURE_CURRENT_VERSION_V6.md`, a file that exists in no form.

Enforced by the `DANGLING DOC REF` check in `tools/zyra_check.py`, which
ships with the 13 pre-existing sites as an explicit baseline. **New dangling
references fail the check and are not added to the baseline** except by
recorded Founder approval. When the scheduled rename completes, the baseline
becomes empty and stays empty.
