---
id: DOC-ZYRA-0277
type: RULES
status: CURRENT
feature: ZYRA GOVERNANCE
purpose: The few ZYRA-only rules - what needs Shakeel's approval, the check before building anything, and which document owns a fact. Everything else comes from the group rules
replaces: [ZYRA_GOVERNANCE V6, ZYRA_EXECUTION V5]
links: [AD-AIOS-112, DOC-BUG-0002, DR-ZYRA-151, AD-082]
owner: Fable
---

# ZYRA RULES — CURRENT VERSION V1

Approved by Shakeel on 25 Oct 2026. Replaces ZYRA governance V6 and ZYRA execution V5 (archived
in `MASTER_GOVERNANCE/ARCHIVE/` and `MASTER_CONTRACTS/ARCHIVE/`). Their roles table described
the old team; their stages, document rules and reporting repeated the group rules.

**Everything not written here comes from the group:** the core rules at the top of `AGENTS.md`,
the operating model (DOC-BUG-0002: who does what, how work flows, exact-action GO, reporting),
the knowledge routing standard (DOC-BUG-0001), the saving standard (DOC-BUG-0003) and the
implementation handover standard (DOC-BUG-0004). Where they disagree with this page, the core
rules win.

## 1. What needs Shakeel's approval in ZYRA

| Needs approval | Delegated to whoever is building |
|---|---|
| New features or any change of product scope | The implementation approach inside an approved decision |
| Pricing, names and any user-facing commercial wording | Code-level detail inside the approved brief |
| Architecture, the data model and the security posture | Internal tooling and refactoring that change no behaviour |
| Promoting a draft to a governed document; changing this page | Raising an OA for every finding (core rule 5 — DR-ZYRA-151) |

Approval given in conversation is binding and is recorded in the decisions register.
Agreement between AIs is never approval.

## 2. Before writing, approving or building from a spec — check, and stop on a conflict

1. `ZYRA_PRODUCT_SPEC_CURRENT_VERSION` (the master product spec).
2. The BUSINESS/ summary for the area, if there is one.
3. The APP/ summary for the feature, if there is one.
4. The decisions register — start from `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1_INDEX.md`.
5. Open actions — start from `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2_INDEX.md`.
6. The feature's current as-built handover, if there is one.
7. The summary's `References.md` — its **Open Dependencies** section.
8. The summary's `Status:` field. Anything other than 🟢 Finalised (🟡 Under Review,
   🔴 Founder Decision Required, or no status at all) means **stop**: do not pick the likely
   option. Say: *"The [feature] spec still has unresolved options. Which direction should
   become the spec?"* Continue only on Shakeel's explicit decision. Status meanings:
   `MASTER_STANDARDS/SUMMARY_STANDARD_CURRENT_VERSION_V3.md` §2.1.

No summary for a feature area is itself a finding to raise — not permission to proceed.
Anything that adds or touches a relationship state is also checked against the State Integrity
Principle (AD-082, master product spec Part 0 §0.1) before a new state is proposed.

## 3. Which document owns a fact — and the others cite it

| Owner | Owns a fact when… |
|---|---|
| Master product spec | changing it would force more than one BUSINESS or APP document to change |
| BUSINESS/ | more than one APP feature needs it |
| APP/ | it applies only inside one feature's own screens and flows |

Other layers **cite** the owner; they never restate it. Restating a higher layer's fact caused
the June project-check drift (Guardian Premium, Profile Decision System) and OA-ZYRA-133.

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-25 | V1 | Created from the ZYRA-only parts of governance V6 (§3) and execution V5 (§3.2, §3.2a); the rest retired (AIOS review follow-up, OA-AIOS-406) |
