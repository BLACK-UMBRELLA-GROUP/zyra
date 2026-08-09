============================================================
ZYRA PROJECT
============================================================
TERMINOLOGY STANDARDS V1
PROJECT-SPECIFIC TERMINOLOGY AND OVERLAP RULES
============================================================
Version:        V1 (corrected in place 2026-07-12 — see
                Section 5, Version History)
Status:         Approved — Active Baseline
Scope:          PROJECTS/ZYRA/ — all ZYRA project documents
Lead Architect: Claude
Project Owner:  Shakeel
Created:        2026-06-26
Migrated from:  EXECUTION_V5 Sections 20.2 and 21
                (per OA-105)
============================================================

CONTENTS

  1.  Purpose
  2.  Relationship to Execution
  3.  Approved Terminology
  4.  Known Document Overlaps
  5.  Version History

============================================================


============================================================
1. PURPOSE
============================================================

This document is the ZYRA project's single source of
truth for:

  • Approved and rejected terminology used across all
    ZYRA documents.
  • Known content overlaps between ZYRA documents,
    including which document is the source of truth
    for each overlap.

It exists so that EXECUTION — a shared Black Umbrella Group level
document — does not carry ZYRA-specific content.

The operational rules for how terminology is enforced
and how overlaps are managed remain in EXECUTION. This
document owns the ZYRA-specific content those rules
apply to.

------------------------------------------------------------


============================================================
2. RELATIONSHIP TO EXECUTION
============================================================

EXECUTION defines the operational workflows:
  • How terminology is enforced on filing (Section 21.1)
  • How new terms are detected (Section 21.3)
  • How terminology conflicts are resolved (Section 21.4)
  • How overlaps are detected (Section 20.1)
  • How merge recommendations are made (Section 20.3)

This document defines the ZYRA-specific content those
workflows operate on:
  • Which terms are approved and rejected for ZYRA.
  • Which documents overlap and which is the source of
    truth for each overlap.

------------------------------------------------------------


============================================================
3. APPROVED TERMINOLOGY
============================================================

Source of truth: PROJECTS/ZYRA/BUSINESS/ZYRA TERMINOLOGY/

The table below is the operational quick-reference.
For full definitions and context, consult ZYRA TERMINOLOGY.

------------------------------------------------------------
3.1 Approved Terms
------------------------------------------------------------

  Roles
  ─────────────────────────────────────────────────────
  Seeker       Person seeking marriage.
  Guardian         Guardian / family representative.

  Profile Decisions (corrected 2026-07-12, DR-076 —
  reverses the previous version of this table, which had
  approved and rejected terms backwards relative to the
  current Product Spec)
  ─────────────────────────────────────────────────────
  Decline      Skip profile (verb and noun).
  Save         Save to come back to later. 10/day cap on
               ZYRA Basic, unlimited on ZYRA One.
               Applies to the Save list only.
  Like         Serious interest. Same daily cap structure
               as Save (10/day ZYRA Basic, unlimited
               ZYRA One).

  Navigation (Seeker — ZYRA Basic / ZYRA One)
  ─────────────────────────────────────────────────────
  Browse • Connections • Guardian • Profile

------------------------------------------------------------
3.2 Rejected Terms
------------------------------------------------------------

  Term          Use instead
  ────────────  ─────────────────────────────────────
  Review        Save
  Consider      Like
  Considering   Like
  Pass          Decline
  Potentials    Save or Like (context-dependent) —
                see PROFILE DECISION SYSTEM for Outgoing/
                Incoming Potential as a separate, later-
                stage concept (post-Save/Like)

------------------------------------------------------------
3.3 Enforcement Rules
------------------------------------------------------------

  • Daily caps apply to both Save and Like (10/day on
    ZYRA Basic; unlimited on ZYRA One).
  • Seeker navigation (any entitlement) is:
    Browse • Connections • Guardian • Profile.
  • Every terminology correction made on filing must
    be flagged to the Project Owner.

------------------------------------------------------------


============================================================
4. KNOWN DOCUMENT OVERLAPS
============================================================

The following overlaps are known and managed. The source
of truth for each is authoritative; all other documents
reference it rather than duplicating it.

------------------------------------------------------------

  Subscription tier features
    Source of truth:  BUSINESS/USER FEATURES
    Referenced in:    Matching/PROFILE DECISION SYSTEM
                      Premium/Profile Unlocks

  Pricing
    Source of truth:  BUSINESS/ZYRA PRICING
    Referenced in:    Premium/Profile Unlocks

  Brand and colour
    Source of truth:  BUSINESS/COLOUR THEME
    Referenced in:    APP LOGO

------------------------------------------------------------

When a new overlap is identified, it is added to this
section after Project Owner confirmation. The Lead
Architect does not modify either overlapping document
until the source of truth is confirmed.

------------------------------------------------------------


============================================================
5. VERSION HISTORY
============================================================

Version V1
  Created 2026-06-26.
  Content migrated from EXECUTION_V5 Sections 20.2
  and 21.2 per OA-105. Execution Sections 20.2 and
  21.2 now replaced with a pointer to this document.

Version V1 (corrected in place 2026-07-12)
  Approved/Rejected terminology table was backwards
  relative to DR-076 (this document rejected Save/Like
  and approved Review/Consider — the opposite of the
  current Product Spec). Corrected against
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 and DR-076.
  Navigation entry updated from "Seeker Basic" to
  "Seeker — ZYRA Basic / ZYRA One" (identical for both
  entitlements). Found during the 2026-07-12 final
  consistency audit — this document was not on the
  original Phase 1-5 correction list because it was not
  flagged by the initial repository grep pass.

============================================================
END OF DOCUMENT
============================================================
