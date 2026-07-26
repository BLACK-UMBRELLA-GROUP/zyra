# ZYRA — Changelog — July 2026

**Format:** Keep a Changelog (Added / Changed / Fixed / Removed)
**Governing Reference:** DR-ZYRA-103
**Scope:** Human-readable feature changelog — complements, does not
replace, `SYSTEM/LOGS/OPERATIONAL_LOG_2026-06.md` (agent-run/audit
trail; dormant since 2026-06-26).

**A note on how this file starts:** entries dated before 2026-07-25
are reconstructed from dated artefact filenames (e.g.
`WALI_ARCHITECTURE_2026-07-04_V3.md`) and the repository's own
version history, not from a live day-by-day log — none existed for
most of July. From 2026-07-25 onward, entries are written from direct
session record and should be trusted as complete for that date. If a
gap between two dated versions of the same document implies work that
isn't listed below, the gap is real — this file doesn't claim to
recover everything that happened before it existed.

---

## 2026-07-25

### Added
- Full Pre-Journey Ritual screen (`journey_flow_screen.dart`) — Compatibility Reveal, Salam Exchange, Wali Gate, Phases 1–3, Family Stage (Seeker-only).
- Journey Suspension RPCs and UI (`suspend_journey` / `resume_journey` / `end_journey`), ZYRA One-gated.
- Migration `20260725183724_pre_journey_ritual_tables.sql` (local mirror of live-applied migration).
- Migration `20260725183415_add_potential_match_status_and_journey_stage.sql`.
- 4 Wali dev/test presets (male/female × Basic/One) in Developer Access — previously only 2 male presets existed.
- Female Wali dev account (`dev.wali.f@zyra.test`, Khadija) in live Supabase + seed script.
- Drag/scrub touch interaction on `FloatingNavBar` (press-and-slide to preview/switch tabs).
- Subscription Transparency Touchpoint 2 — Wali-dependency notice on the Upgrade screen.
- 20 seeded, fully photographed fake Browse-candidate profiles (10 male, 10 female; 99 of 100 planned photos uploaded — one upload failed on retry, accepted as a harmless gap).
- `TREEVIEW.md` — generated structural repository map.
- `ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md` — extended schema (Purpose/Owner/Source of Truth/Dependencies/Related), full content refresh.
- This changelog.
- `SYSTEM/SESSION_HANDOVER` document (relocated — see Changed).

### Changed
- OUTSTANDING_ACTIONS_V2.md — all 15 items of OA-ZYRA-140 resolved.
- DR-ZYRA-079 and DR-ZYRA-084 — PROPOSED → RATIFIED.
- Seeker Onboarding Chapter 3/4 — rewritten to 104 + 70 questions across 9 categories, matching `chapter3_categories.dart` and the Classification doc.
- APP/Journey/JOURNEY MANAGEMENT/Summary.md — Pause section now defers directly to JOURNEY_SUSPENSION_CURRENT_VERSION_V1 rather than describing its own (superseded) proposal.
- APP/Premium/Profile Unlocks/ — Wali purchase capability corrected (cannot, was wrongly documented as can); subscription terminology corrected (ZYRA Basic/One, not Pro/Premium/Free); compatibility category count corrected (6, not 8).
- BUSINESS/ZYRA TERMINOLOGY/ — Decline/Like → Pass/Consider swept across the glossary and every cross-referencing document.
- BUSINESS/APP NAME CREATION/Summary.md — Approval Status → APPROVED.
- APP/WIDGETS/ renamed to APP/iOS Widgets/ to disambiguate from `SOURCE/lib/widgets/` (OA-ZYRA-140 item 11).
- `ZYRA_DOCUMENTATION_INDEX` — V1 → V2, renamed to the `_CURRENT_VERSION_` convention used elsewhere in the repo (was previously an inconsistent exception).

### Fixed
- Mutual "Consider" no longer silently dropped when a user already has one Active Journey (second Potential Match now created correctly).
- `SESSION_HANDOVER` document — moved from `SYSTEM/` (incorrectly using `_CURRENT_VERSION_` naming for what is actually a Review/Handover document) to `SYSTEM/RESOURCES/TEMPORARY/SESSION_HANDOVER_2026-07-25.md`, per STANDARDS_LIBRARY §2.5/§3.7 (Handover docs are dated, not versioned, and live in RESOURCES/TEMPORARY/, never DOCUMENTS/).

### Removed
- "STEP BACK/HOLD" proposal language from Journey Management Summary (superseded by the ratified Suspension spec).

---

## 2026-07-19 *(reconstructed from artefact dates)*

### Added
- ZYRA_ARCHITECTURE_CURRENT_VERSION_V2, ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, SUMMARY_STANDARD_CURRENT_VERSION_V3.
- REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md.

### Changed
- ZYRA_EXECUTION V1 → V2 → V3 (both prior versions archived same day).

---

## 2026-07-12 *(reconstructed from artefact dates)*

### Fixed
- ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md — terminology/pricing audit findings (see report for detail; feeds into the 2026-07-25 Decline/Like → Pass/Consider sweep).

---

## 2026-07-04 *(reconstructed from artefact dates)*

### Added
- WALI_ARCHITECTURE (V3, V4 same day) — Wali role architecture formalised.
- JOURNEY_CAPABILITY_GRANT_RULES (V1, V2 same day).
- CHAT_ARCHITECTURE_CURRENT_VERSION_V1 (Black Umbrella level — Architectural Extension Principle, Standard Artefact Package, Context A/B routing).

---

*Maintained going forward at the end of every ZYRA development session.
See `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md`
for what each referenced document is and who owns it.*
