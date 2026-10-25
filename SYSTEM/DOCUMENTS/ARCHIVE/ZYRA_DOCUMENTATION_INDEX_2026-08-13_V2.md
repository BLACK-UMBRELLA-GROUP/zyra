# ZYRA — Documentation Index

**Version:** V2
**Status:** CURRENT_VERSION
**Date:** 2026-07-25
**Supersedes:** ZYRA_DOCUMENTATION_INDEX_2026-07-25_V1.md (SYSTEM/DOCUMENTS/ARCHIVE/)
**Governing Reference:** ZYRA_GOVERNANCE_V1, DR-ZYRA-103
**Related:** TREEVIEW.md (structural map — this file is a registry:
purpose/owner/status per document; TREEVIEW.md is a plain folder
listing with no commentary. Use TREEVIEW.md to see what exists, this
file to see what each thing *is for*.)

---

## Purpose

Single-entry-point index to all ZYRA documentation. Every governed
document is listed here with its location, status, and — from V2
onward — Purpose, Owner, Source of Truth, Dependencies, and Related
fields, so a document's authority and relationships are visible
without opening it.

## What changed from V1 (2026-06-26)

V1 was location + status only, and was last refreshed 2026-06-26 —
before the entire Journey/Ritual/Suspension build, DR-ZYRA-088 through
DR-ZYRA-102, and the OA-ZYRA-140 audit. V2 adds the richer schema
(per DR-ZYRA-103) and a full content refresh: Journey, Journey
Suspension, Guardian Architecture, and roughly a dozen other governing
documents that didn't exist yet in V1 are now listed.

---

## 1. System Documents (Governance)

### PROJECT_OVERVIEW_V1
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** High-level project summary — what ZYRA is, for readers who need the 30-second version.
- **Owner:** Founder
- **Source of Truth:** Yes, for project framing only (not for feature detail — see Section 4).
- **Dependencies:** None.
- **Related:** ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.

### ZYRA_DOCUMENTATION_INDEX (this document)
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Single-entry-point index to all governed documentation.
- **Owner:** Architecture Agent (Claude).
- **Source of Truth:** Yes, for "where does X live and who owns it."
- **Dependencies:** Must be refreshed whenever a governing document is added, superseded, or relocated.
- **Related:** TREEVIEW.md, STANDARDS_LIBRARY_CURRENT_VERSION_V1 (Black Umbrella, governs naming/placement for both).

### TREEVIEW
- **Location:** SYSTEM/DOCUMENTS/TREEVIEW.md
- **Purpose:** Literal, regenerated-not-hand-typed structural listing of the repository. No commentary or status — pure folder map.
- **Owner:** Architecture Agent (Claude) — regenerated whenever top-level structure changes.
- **Source of Truth:** Yes, for "what folders/files exist," no, for "what they mean" (that's this Index).
- **Dependencies:** None.
- **Related:** This Index.

### TERMINOLOGY_STANDARDS_V1
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** System-level terminology rules (distinct from BUSINESS/ZYRA TERMINOLOGY/, which is the actual glossary).
- **Owner:** Founder.
- **Source of Truth:** Yes, for documentation-writing conventions.
- **Dependencies:** BUSINESS/ZYRA TERMINOLOGY/Summary.md is the canonical glossary this defers to for actual terms.
- **Related:** BUSINESS/ZYRA TERMINOLOGY/Summary.md, References.md.

### ZYRA_GOVERNANCE_V1
- **Location:** SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/
- **Purpose:** Project governance contract — how decisions get made, who approves what.
- **Owner:** Founder.
- **Source of Truth:** Yes.
- **Dependencies:** None (top of the governance chain for ZYRA specifically).
- **Related:** DECISIONS_V1 (register of decisions made under this contract).

### ZYRA_EXECUTION_V3
- **Location:** SYSTEM/DOCUMENTS/MASTER_CONTRACTS/
- **Purpose:** Feature workflow contract — how a feature moves from spec to shipped code.
- **Owner:** Founder / Architecture Agent.
- **Source of Truth:** Yes.
- **Dependencies:** ZYRA_GOVERNANCE_V1.
- **Related:** Superseded ZYRA_EXECUTION_2026-07-19_V1, _V2 archived in SYSTEM/DOCUMENTS/ARCHIVE/.

### ZYRA_STANDARDS_LIBRARY_V1
- **Location:** SYSTEM/DOCUMENTS/MASTER_STANDARDS/
- **Purpose:** ZYRA's own standards index (naming/placement specific to this repo — distinct from Black Umbrella's group-wide STANDARDS_LIBRARY_CURRENT_VERSION_V1).
- **Owner:** Architecture Agent.
- **Source of Truth:** Yes, where it doesn't conflict with the Black Umbrella group-wide standard; the group-wide standard wins on conflict.
- **Dependencies:** BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/STANDARDS_LIBRARY_CURRENT_VERSION_V1.md.
- **Related:** NAMING_CONVENTIONS_V1, SUMMARY_STANDARD_CURRENT_VERSION_V3.

### ZYRA_ARCHITECTURE_CURRENT_VERSION_V2
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Technical architecture overview (Flutter/Supabase, high-level system shape).
- **Owner:** Architecture Agent.
- **Source of Truth:** Yes, for high-level architecture. Feature-level detail lives in APP/.
- **Dependencies:** ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1, ZYRA_INFRASTRUCTURE_STACK_V1.
- **Related:** APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V6 (Guardian-specific architecture, not covered here).

### ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Schema reference.
- **Owner:** Architecture Agent.
- **Source of Truth:** No — the live Supabase project (`sxoaxonzjqkgajmlagyk`) is authoritative; this document should match it but the database wins on conflict. Verify via Supabase MCP tools before trusting this doc on any disputed point.
- **Dependencies:** SOURCE/supabase/migrations/ (every applied migration should be mirrored here).
- **Related:** ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.

### ZYRA_INFRASTRUCTURE_STACK_V1
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Stack/tooling reference (Flutter, Supabase, hosting).
- **Owner:** Architecture Agent.
- **Source of Truth:** Yes.
- **Dependencies:** None.
- **Related:** ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.

### ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Top-level product specification.
- **Owner:** Founder.
- **Source of Truth:** Yes, for product intent; individual APP/ feature docs are more current on implementation detail.
- **Dependencies:** None.
- **Related:** PROJECT_OVERVIEW_V1, all of Section 4 below.

### ADVANCEMENT_CONDITIONS_CURRENT_VERSION_V1
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Conditions under which a Journey/stage/feature is allowed to advance (gating logic reference).
- **Owner:** Architecture Agent.
- **Source of Truth:** Yes, cross-referenced with APP/Journey/ specs and `zyra_journey_service.dart`.
- **Dependencies:** APP/Journey/* (all subfolders), APP/Standards/JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V3.
- **Related:** APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.

### ZYRA_WIDGET_LIBRARY_CURRENT_VERSION_V1 *(new 2026-07-26, #18)*
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Reference index of `SOURCE/lib/widgets/` — the shared Flutter component library. Closes the gap this Index itself flagged in Section 7 and in `SESSION_HANDOVER_2026-07-25.md`.
- **Owner:** Architecture Agent.
- **Source of Truth:** No — the code in `SOURCE/lib/widgets/` is authoritative; this is a reference document kept in sync with it.
- **Dependencies:** `SOURCE/lib/widgets/*`.
- **Related:** ZYRA_ARCHITECTURE_CURRENT_VERSION_V2, APP/iOS Widgets/ (unrelated — disambiguated by name only).

### ZYRA_PERFORMANCE_ENGINEERING_REVIEW_CURRENT_VERSION_V1 *(new 2026-07-26)*
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Engineering opinion/discussion paper on performance, battery, memory, network, and scalability — requested by the Founder as a discussion-first review, not an implementation. Grounded in a direct read of `SOURCE/` and the Supabase schema on 2026-07-26 (image handling/caching, polling patterns, state-management rebuild scope, indexing, startup path).
- **Owner:** Implementation Lead (Claude).
- **Source of Truth:** Partial — Section 9's "recommended permanent standards" are proposals awaiting separate ratification (as a DR), not yet-binding rules. Everything else is opinion/analysis, not a spec.
- **Dependencies:** None (a review, not a governing spec) — Related documents may be superseded or extended once specific recommendations are ratified.
- **Related:** `SOURCE/lib/screens/browse/browse_screen.dart`, `SOURCE/lib/state/app_state.dart`, `SOURCE/lib/services/zyra_journey_service.dart`, `SOURCE/lib/services/zyra_photo_service.dart`.

### ZYRA_ACCOUNT_TYPE_UX_REVIEW_CURRENT_VERSION_V1 *(new 2026-07-26)*
- **Location:** SYSTEM/DOCUMENTS/
- **Purpose:** Per-account-type UX review requested by OA-ZYRA-124 — reviews Seeker Basic/One and Guardian Basic/One (Male/Female collapse to 4 functional variants, confirmed in the doc) against the 10 criteria OA-124 specified (Navigation, Available tabs, Feature access, Upgrade prompts, User journey, Permissions, UI consistency, Empty states, Settings, Profile behaviour). Lists every gap found with a Build/Modify/Delay/Reject decision and reasoning per this project's Feature Review Process.
- **Owner:** Implementation Lead (Claude).
- **Source of Truth:** Yes, for what was reviewed and what was decided — see DR-ZYRA-107 for the fixes actually implemented from this review.
- **Dependencies:** DR-ZYRA-107 (fixes), DR-ZYRA-106 ("Extended Guardian" → "Guardian+" rename, referenced), DR-ZYRA-094 (gender-gradient parity, referenced).
- **Related:** `SOURCE/lib/screens/guardian/wali_home_shell.dart`, `SOURCE/lib/screens/guardian/wali_profile_screen.dart`, `SOURCE/lib/screens/guardian/wali_notification_settings_screen.dart`, `SOURCE/lib/screens/profile/profile_screen.dart`, `SOURCE/lib/screens/home/home_shell.dart`.

---

## 2. Agent Contracts

| Agent | Location | Version | Purpose |
|-------|----------|---------|---------|
| INSPECTION_AGENT | SYSTEM/AGENTS/INSPECTION_AGENT/ | V4 | Automated repo/quality inspection contract |
| DOCUMENTATION_AGENT | SYSTEM/AGENTS/DOCUMENTATION_AGENT/ | V4 | Documentation maintenance contract |
| REPOSITORY_AGENT | SYSTEM/AGENTS/REPOSITORY_AGENT/ | V4 | Repository structure/hygiene contract |
| RESOLUTION_CLASSIFIER | SYSTEM/AGENTS/RESOLUTION_CLASSIFIER/ | V4 | Classifies findings as resolved/escalated |
| REPORTING_AGENT | SYSTEM/AGENTS/REPORTING_AGENT/ | V4 | Produces run/session reports |
| OUTPUT_REVIEW_AGENT | SYSTEM/AGENTS/OUTPUT_REVIEW_AGENT/ | V3 | Reviews agent output before it's accepted |
| IMPACT_ANALYSIS_AGENT | SYSTEM/AGENTS/IMPACT_ANALYSIS_AGENT/ | V3 | Assesses blast radius of a proposed change |
| PROJECT_READINESS_AGENT | SYSTEM/AGENTS/PROJECT_READINESS_AGENT/ | V3 | Readiness gate before advancing project phases |

**Owner (all):** Architecture Agent. **Source of Truth:** Yes, for
agent behavior contracts. **Note:** these are largely dormant —
`SYSTEM/LOGS/OPERATIONAL_LOG_2026-06.md` (the run-entry log these
agents write to) has had zero entries since 2026-06-26 despite this
being the busiest month in the repo's history. See
`SYSTEM/LOGS/CHANGELOG_2026-07.md` for what actually shipped in that
gap, and `SYSTEM/RESOURCES/TEMPORARY/CHATGPT_REPLY_REPO_NAVIGATION_2026-07-25.md`
for the fuller diagnosis.

---

## 3. Product Documentation

| Document | Location | Owner | Source of Truth |
|----------|----------|-------|-----------------|
| ZYRA_PRODUCT_OVERVIEW_V1 | SYSTEM/DOCUMENTS/ | Founder | Yes, framing only |
| PRODUCT PLANNING / Summary | BUSINESS/PRODUCT PLANNING/ | Founder | Yes, planning framework |
| USER FEATURES / Summary | BUSINESS/USER FEATURES/ | Founder | Yes, feature list — cross-check against Section 4 for implementation status |
| APP BREAKDOWN / Flow Diagram | BUSINESS/APP BREAKDOWN/ | Founder | Yes, app structure |

---

## 4. Feature Specifications (APP/)

This is the section that was most stale in V1 — it had no entries for
Journey (beyond a bare folder reference), Journey Suspension, or Guardian
Architecture at all. Rebuilt below.

### Authentication
- **Location:** APP/Authentication/
- **Owner:** Founder. **SoT:** Yes.
- **Related:** DR-ZYRA-102 (auth scope pivot — Google + Apple only, user-facing; email/password survives only as a hidden Developer Mode test-account backdoor).

### Browse
- **Location:** APP/Browse/ (BROWSE_UX_SPEC_CURRENT_VERSION_V3 is current; _V1/_V2 dated 2026-07-25 are same-day supersessions, both in-folder not yet archived)
- **Owner:** Founder. **SoT:** Yes.
- **Dependencies:** APP/Matching/PROFILE DECISION SYSTEM/ (Save/Pass/Consider terminology and decision flow), `zyra_discovery_service.dart`.
- **Related:** BUSINESS/ZYRA TERMINOLOGY/Summary.md (Save/Pass/Consider is the ratified terminology, DR-ZYRA-099).

### Journey — Availability
- **Location:** APP/Journey/JOURNEY AVAILABILITY/Summary.md
- **Owner:** Founder. **SoT:** Yes.
- **Related:** Journey — Management, Journey — Suspension.

### Journey — Management
- **Location:** APP/Journey/JOURNEY MANAGEMENT/Summary.md
- **Owner:** Founder. **SoT:** Yes.
- **Note:** Pause section now cites JOURNEY_SUSPENSION_CURRENT_VERSION_V1 directly (fixed 2026-07-25, OA-ZYRA-140) — do not treat this doc as authoritative on Pause/Suspend behavior; it defers to the Suspension spec.
- **Related:** JOURNEY SUSPENSION, PRE-JOURNEY RITUAL.

### Journey — Philosophy
- **Location:** APP/Journey/JOURNEY PHILOSOPHY/Summary.md
- **Owner:** Founder. **SoT:** Yes, for intent/rationale, not mechanics.

### Journey — Suspension *(new in V2 — missing entirely from V1)*
- **Location:** APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes — the single authority on Pause/Resume/End Journey behavior.
- **Dependencies:** `suspend_journey`/`resume_journey`/`end_journey` RPCs (migration `20260725183724_pre_journey_ritual_tables.sql`), ZYRA One gating.
- **Known gap:** no 30-day auto-end timer yet (needs a server-side scheduled job) — flagged, not silently missing.
- **Related:** Journey — Management (defers to this doc for Pause).

### Pre-Journey Ritual *(new in V2)*
- **Location:** APP/Journey/PRE-JOURNEY RITUAL/Summary.md
- **Owner:** Founder. **SoT:** Yes.
- **Dependencies:** `journey_flow_screen.dart`, `zyra_journey_service.dart`, `journey_questions.dart`.
- **Stages:** compatibility_reveal → salam_exchange → wali_gate → phase_1 → phase_2 → phase_3 → family_stage → conversation.
- **Known gap:** Family Stage is Seeker-only UI; Guardian-side answering UI doesn't exist yet.

### Matches Page
- **Location:** APP/Matches/MATCHES PAGE/Summary.md
- **Owner:** Founder. **SoT:** Yes.

### Relationship Space
- **Location:** APP/Matches/RELATIONSHIP SPACE/Summary.md
- **Owner:** Founder. **SoT:** Yes.

### Match UX Spec *(new in V2)*
- **Location:** APP/Matching/MATCH UX/MATCH_UX_SPEC_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.

### Profile Decision System
- **Location:** APP/Matching/PROFILE DECISION SYSTEM/
- **Owner:** Founder. **SoT:** Yes.
- **Related:** Terminology corrected 2026-07-25 (Save/Pass/Consider, not Decline/Save/Like — DR-ZYRA-099).

### Seeker Navigation
- **Location:** APP/Navigation/SEEKER NAVIGATION/
- **Owner:** Founder. **SoT:** Yes.
- **Note:** Nav bar is Browse/Matches/Profile for Seekers (was already correct); the touch interaction was fixed 2026-07-25 to be drag/scrub-enabled per `floating_nav_bar.dart`.

### Profile Completion
- **Location:** APP/Onboarding/PROFILE COMPLETION/Summary.md
- **Owner:** Founder. **SoT:** Yes.

### Seeker Onboarding
- **Location:** APP/Onboarding/SEEKER ONBOARDING QUESTIONS/
- **Owner:** Founder. **SoT:** "Chapter 3 Classification — Ch4 Mapping.md" is authoritative for the 104+70 question / 9-category structure; Summary.md and Flow Diagram.md were rewritten 2026-07-25 to match it, per DR-ZYRA-079/084 (ratified).
- **Dependencies:** `chapter3_categories.dart` (confirmed matching, 9 categories in code).

### Profile Unlocks
- **Location:** APP/Premium/Profile Unlocks/
- **Owner:** Founder. **SoT:** Yes.
- **Note:** Terminology corrected 2026-07-25 (Guardian cannot purchase — was wrongly documented as "can"; ZYRA Basic/One not Pro/Premium/Free; 6 compatibility categories not 8).

### Guardian+ ("GUARDIAN PREMIUM" — legacy folder name)
- **Location:** APP/Premium/GUARDIAN PREMIUM/Summary.md
- **Owner:** Founder. **SoT:** Yes, though folder name is legacy (kept to avoid churn — content is current).
- **Related:** APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V6, `subscriptions.plan_type = 'wali_premium'` — real gating wired 2026-07-26 (#19) via `wali_has_extended_wali()`, replacing the local `AppState.waliHasExtendedWali` mock toggle. The four Guardian+ capabilities themselves (Network browse, Family Introduction Requests, Suggest profiles, AI Summary) remain unbuilt.

### Guardian Architecture *(new in V2 — missing entirely from V1)*
- **Location:** APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
- **Owner:** Founder. **SoT:** Yes — the authority on Guardian role structure, linking, and gating.
- **Dependencies:** `wali_links` table, `zyra_wali_link_service.dart`.
- **Related:** Guardian+, DEPENDENCY COMMUNICATION.

### Journey Capability Grant Rules *(new in V2)*
- **Location:** APP/Standards/ARCHIVE/JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V4.md
- **Owner:** Founder. **SoT:** Yes.
- **Related:** ADVANCEMENT_CONDITIONS_CURRENT_VERSION_V1.

### Image Handling Standard *(new in V2)*
- **Location:** APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md
- **Owner:** Founder. **SoT:** Yes.
- **Related:** `zyra_photo_service.dart`, `profile-photos` Storage bucket (private, signed URLs).

### Global Platform Principles *(new in V2)*
- **Location:** APP/Platform/GLOBAL_PLATFORM_PRINCIPLES_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.

### Subscription Transparency *(new in V2)*
- **Location:** APP/Premium/SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.
- **Dependencies:** Touchpoint 2 (Guardian-dependency notice) implemented 2026-07-25 in `upgrade_screen.dart`.

### Dependency Communication *(new in V2)*
- **Location:** APP/Premium/DEPENDENCY COMMUNICATION/DEPENDENCY_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.

### AI Tiering *(new in V2)*
- **Location:** APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.
- **Known gap:** no AI/LLM integration exists anywhere in the app yet — this spec describes intended tiering, not current behavior.

### Advertising Standard *(new in V2)*
- **Location:** APP/Premium/ADVERTISING/ADVERTISING_STANDARD_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.

### Safety *(new in V2 — was previously undocumented in the index)*
- **Location:** APP/Safety/SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md, Summary.md
- **Owner:** Founder. **SoT:** Yes.

### UX Writing
- **Location:** APP/UX Writing/, ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md
- **Owner:** Founder. **SoT:** Yes.

### iOS Widgets
- **Location:** APP/iOS Widgets/ (renamed 2026-07-25 from APP/WIDGETS/, OA-ZYRA-140 item 11, to disambiguate from `SOURCE/lib/widgets/` — the unrelated Flutter shared-component library).
- **Owner:** Founder. **SoT:** Yes.
- **Note:** `SOURCE/lib/widgets/` is now documented — see ZYRA_WIDGET_LIBRARY_CURRENT_VERSION_V1 (SYSTEM/DOCUMENTS/), built 2026-07-26 (#18).

---

## 5. Business Documentation (BUSINESS/)

| Document | Location | Owner | Note |
|----------|----------|-------|------|
| AI Strategy | BUSINESS/AI STRATEGY/ | Founder | |
| App Breakdown | BUSINESS/APP BREAKDOWN/ | Founder | |
| App Logo | BUSINESS/APP LOGO/ | Founder | |
| App Name Creation | BUSINESS/APP NAME CREATION/ | Founder | Approved 2026-07-25 |
| Brand Messaging | BUSINESS/BRAND MESSAGING/ | Founder | |
| Colour Theme | BUSINESS/COLOUR THEME/ | Founder | Gender-based theming (Blue/male, Pink/female, neutral Purple pre-auth) |
| Competitor Research | BUSINESS/COMPETITOR RESEARCH/ | Founder | Not in V1 index |
| Product Planning | BUSINESS/PRODUCT PLANNING/ | Founder | |
| User Features | BUSINESS/USER FEATURES/ | Founder | |
| Launch Guide | BUSINESS/ZYRA LAUNCH GUIDE/ | Founder | |
| Pricing | BUSINESS/ZYRA PRICING/ | Founder | |
| Terminology | BUSINESS/ZYRA TERMINOLOGY/ | Founder | Canonical glossary — Save/Pass/Consider (DR-ZYRA-099), ZYRA Basic/One, 6 compatibility categories |

---

## 6. Registers

| Register | Location | Owner | Next Identifier |
|---------|----------|-------|-----------------|
| Outstanding Actions V2 | SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md | Founder | OA-ZYRA-141 |
| Decisions V1 | SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md | Founder | DR-ZYRA-104 |

Both registers are Source of Truth for their domain — if any other
document contradicts a ratified DR or an OA resolution, the register
wins.

---

## 7. Source Code

| Location | Contents | Owner |
|----------|----------|-------|
| SOURCE/ | Flutter app (Dart) — iOS, Android | Implementation Agent / Founder |
| SOURCE/lib/main.dart | App entry point | |
| SOURCE/pubspec.yaml | Flutter dependencies | |
| SOURCE/supabase/migrations/ | Local mirror of every applied Supabase migration | Must stay in sync with the live project (`sxoaxonzjqkgajmlagyk`) |
| SOURCE/lib/widgets/ | Shared Flutter component library — documented 2026-07-26 in ZYRA_WIDGET_LIBRARY_CURRENT_VERSION_V1 (SYSTEM/DOCUMENTS/) | |

---

## 8. Autonomous Systems

| System | Location | Status |
|--------|----------|--------|
| Project Inspector | BLACK UMBRELLA GROUP/SOURCE/ai_org/project_runner.py | Level 4 (planned) |
| Project Memory | SYSTEM/RESOURCES/MEMORY/ | Level 5 (planned) |
| Project State | SYSTEM/RESOURCES/ORGANISATION_STATE.md | Level 5 (planned) |

---

## 9. Structural Note — Legacy Parallel Folders (RESOLVED 2026-07-26)

`DEVELOPMENT_TEAM/` and `LIVE_OPERATIONS/` previously sat at repo root
alongside `SYSTEM/`, containing their own agent contracts, logs, and
registers that overlapped in purpose with `SYSTEM/AGENTS/`,
`SYSTEM/LOGS/`, and `SYSTEM/OUTSTANDING_ACTIONS/`. Flagged here per
TREEVIEW.md's discovery (2026-07-25) as OA-ZYRA-141, pending Founder
decision. Resolved 2026-07-26 (#26): both were confirmed dead
scaffolding from a single 2026-06-26 session, never used again, and
are now archived under `ARCHIVE/DEVELOPMENT_TEAM_2026-06-26/` and
`ARCHIVE/LIVE_OPERATIONS_2026-06-26/` — see `ARCHIVE/README.md` and
OA-ZYRA-141's Resolution note. Repo root no longer carries
undocumented top-level folders.

---

## 10. Change History

Day-to-day changes are tracked in `SYSTEM/LOGS/CHANGELOG_2026-07.md`
(monthly, Added/Changed/Fixed/Removed format) going forward. This
Index records structure and ownership, not a chronological log.
