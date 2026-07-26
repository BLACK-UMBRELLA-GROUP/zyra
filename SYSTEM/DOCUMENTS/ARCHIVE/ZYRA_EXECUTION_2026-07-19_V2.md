# ZYRA — Execution Contract
**Version:** V2
**Status:** CURRENT_VERSION
**Date:** 2026-07-19
**Supersedes:** ZYRA_EXECUTION_V1.md (archived: SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_EXECUTION_2026-07-19_V1.md)
**Contract Type:** PROJECT EXECUTION
**Governing Reference:** ZYRA_GOVERNANCE_V1
**Ratified by:** Founder (Shakeel), 2026-07-19, following joint architectural
review (Claude + ChatGPT) and independent review (Fable / Opus 4, two cycles).
Source: Consolidated Governance Review Package, 2026-07-19, Subject 4.

---

## 1. Purpose

Defines how work is executed within ZYRA — from feature idea to deployed code.

---

## 2. Work Stages

| Stage | Description |
|-------|-------------|
| IDEA | Proposed, not yet assessed |
| SPEC | Feature specification written in APP/ or BUSINESS/ |
| APPROVED | Spec approved by Founder |
| IN_DEVELOPMENT | Active development in SOURCE/ |
| IN_REVIEW | Code review / QA underway |
| DONE | Deployed and verified |
| CANCELLED | Will not be built |

---

## 3. Feature Lifecycle

3.1 All features begin as an IDEA in OUTSTANDING_ACTIONS_REGISTER.

3.2 IDEA → SPEC: Lead Architect writes spec in APP/[FEATURE]/Summary.md
    (or the relevant BUSINESS/ Summary.md for cross-cutting concerns).
    Creating or updating a Draft-status Summary is documentation work —
    it does not itself require Founder approval (see 3.3).

    **Before writing or approving a Summary, the following must be
    checked, and any conflict stopped and raised before implementation
    proceeds** (this is the ZYRA-level instantiation of Black Umbrella
    Group's Conflict Flag Before Edit principle,
    `EXECUTION_CURRENT_VERSION_V10.md` §14.5 — not a new principle):

    a. `ZYRA_PRODUCT_SPEC_CURRENT_VERSION` (Master Product Spec)
    b. The relevant BUSINESS/ Summary, if one exists
    c. The relevant APP/ Summary, if one exists
    d. `DECISIONS_V1.md` (Decisions Register)
    e. `OUTSTANDING_ACTIONS_V2.md` (Outstanding Actions)

    The absence of a Summary for a feature area is itself a finding to
    raise, not permission to proceed as if nothing governs it.

    Where the idea introduces or touches a relationship state, it must
    additionally be checked against the **State Integrity Principle
    (AD-082)**, `ZYRA_PRODUCT_SPEC_CURRENT_VERSION` Part 0 §0.1, before a
    new Summary or state is proposed.

3.2a **Ownership — which document owns a given fact is decided by a
    test, not a fixed topic list** (mirrors AD-087 §1.3, the
    Irreducible Question Test, and AD-082, the State Integrity
    Principle — the same family of decision tests, not independently
    invented):

    - Master Product Spec owns a fact if changing it would require
      more than one BUSINESS or APP document to change to stay
      consistent.
    - BUSINESS owns a fact if more than one APP feature would need
      to reference it.
    - APP owns only what applies within one feature's own screens
      and flows.

    Whichever layer owns a fact, other layers **cite it — they do not
    restate it.** Restating a fact that belongs to a higher layer is
    the specific failure that produced the 2026-06-27 Project Check
    drift (Wali Premium / Profile Decision System vs. Product Spec V2)
    and OA-ZYRA-133 (2026-07-19 — an Active Journey proposal that
    re-derived relationship states already ratified in Product Spec V3
    Part 0, because the Master Spec wasn't checked first).

3.3 SPEC → APPROVED: **Founder approves.** (Corrected 2026-07-19 —
    previously read "Lead Architect signs off," which did not match
    actual practice or the Founder-First principle governing this
    document's own Contract Type. Drafting a Summary is Claude's direct
    role per 3.2, above; only the Draft → Approved Specification
    transition requires Founder sign-off, since that is what authorises
    development to begin.)

3.4 APPROVED → IN_DEVELOPMENT: Development Team begins work.

3.5 IN_DEVELOPMENT → DONE: Code complete, reviewed, deployed.

---

## 4. Autonomy Limits

4.1 Development Team may NOT change product scope without approval.
4.2 Development Team may NOT change architecture without approval.
4.3 Development Team resolves implementation questions autonomously
    within the bounds of the approved spec.

---

## 5. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-06-26 | Initial release. |
| V2 | 2026-07-19 | §3.2 expanded with pre-spec governance checklist and ownership/citation rules (Consolidated Governance Review Package, Subject 4, items 1/2/4). §3.3 authority corrected from "Lead Architect signs off" to "Founder approves," matching actual practice. Work Stages table's APPROVED row updated to match. Independently reviewed by Fable (Opus 4), two cycles, before Founder ratification. |
