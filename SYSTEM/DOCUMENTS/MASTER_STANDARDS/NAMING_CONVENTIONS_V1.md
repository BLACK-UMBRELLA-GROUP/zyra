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
